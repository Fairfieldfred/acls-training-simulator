import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ecg_rhythm_model.dart';
import '../models/event_log_model.dart';
import '../models/medication_model.dart';
import '../models/medication_timing_model.dart';
import '../models/patient_model.dart';
import '../models/scenario_model.dart';
import '../models/performance_model.dart';
import '../models/training_config.dart';
import 'medication_eligibility_service.dart';

class SimulationService extends ChangeNotifier {
  Scenario? _currentScenario;
  PatientState _patientState =
      PatientState.cardiacArrest(ECGRhythm.vf);
  TrainingConfig _trainingConfig = const TrainingConfig();

  // Timers
  Timer? _codeTimer;
  Timer? _cprCycleTimer;
  Timer? _autoCprTimer;
  int _codeSeconds = 0;
  int _cprCycleSeconds = 0;
  bool _isRunning = false;
  bool _autoCprPaused = false;

  // CPR tracking
  int _compressions = 0;
  int _ventilations = 0;
  int _currentCycleCompressions = 0;
  int _currentCycleVentilations = 0;
  int _compressionBatch = 0;

  // Compression rate tracking (for timing mode)
  final List<DateTime> _recentCompressionTimes = [];

  // Defibrillator
  bool _isCharging = false;
  int _selectedEnergy = 200;
  int _shockCount = 0;
  int? _timeToFirstShock;

  // Medications
  final List<MedicationDoseRecord> _doseHistory = [];
  final MedicationEligibilityService _eligibilityService =
      MedicationEligibilityService();
  int? _timeToFirstEpinephrine;
  double _roscBoost = 0.0;

  // Post-shock CPR cycle tracking
  int _postShockCprSeconds = 0;

  // Reversible causes
  final Map<String, bool> _reversibleCausesChecked = {};

  // Airway
  String _airwayDevice = 'BVM';

  // Auto-CPR
  int _autoCycleCompressions = 0;

  // Event log
  final List<SimulationEvent> _eventLog = [];

  final _random = Random();

  // ── Getters ────────────────────────────────────────────

  Scenario? get currentScenario => _currentScenario;
  PatientState get patientState => _patientState;
  TrainingConfig get trainingConfig => _trainingConfig;
  bool get isRunning => _isRunning;
  int get codeSeconds => _codeSeconds;
  int get cprCycleSeconds => _cprCycleSeconds;
  int get compressions => _compressions;
  int get ventilations => _ventilations;
  int get currentCycleCompressions =>
      _currentCycleCompressions;
  int get currentCycleVentilations =>
      _currentCycleVentilations;
  bool get isCharging => _isCharging;
  int get selectedEnergy => _selectedEnergy;
  int get shockCount => _shockCount;
  Map<String, bool> get reversibleCausesChecked =>
      _reversibleCausesChecked;
  String get airwayDevice => _airwayDevice;
  List<MedicationDoseRecord> get doseHistory =>
      _doseHistory;
  List<SimulationEvent> get eventLog => _eventLog;

  List<String> get medicationsGiven =>
      _doseHistory.map((d) => d.displayString).toList();

  String get formattedCodeTime {
    final minutes = _codeSeconds ~/ 60;
    final seconds = _codeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedCprCycleTime {
    final minutes = _cprCycleSeconds ~/ 60;
    final seconds = _cprCycleSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  double get cprRatio {
    if (_ventilations == 0) return 0;
    return _compressions / _ventilations;
  }

  double get compressionRate {
    if (_recentCompressionTimes.isEmpty) return 0;
    final now = DateTime.now();
    final cutoff = now.subtract(
      const Duration(seconds: 10),
    );
    _recentCompressionTimes
        .removeWhere((t) => t.isBefore(cutoff));
    if (_recentCompressionTimes.isEmpty) return 0;
    return _recentCompressionTimes.length * 6.0;
  }

  // ── Medication timing getters ──────────────────────────

  int? get secondsSinceLastEpi {
    final lastEpi = _doseHistory.lastWhereOrNull(
      (d) => d.medicationName == 'Epinephrine',
    );
    if (lastEpi == null) return null;
    return _codeSeconds - lastEpi.timeSeconds;
  }

  bool get isEpiOverdue {
    final elapsed = secondsSinceLastEpi;
    if (elapsed == null) return _codeSeconds > 60;
    return elapsed > 300;
  }

  int? get nextEpiDueSeconds {
    final elapsed = secondsSinceLastEpi;
    if (elapsed == null) return null;
    final remaining = 180 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  int get postShockCprSeconds => _postShockCprSeconds;
  bool get cprCycleComplete =>
      _postShockCprSeconds >= 120;

  MedicationEligibility getMedicationEligibility(
    Medication med,
  ) {
    return _eligibilityService.checkEligibility(
      med: med,
      doseHistory: _doseHistory,
      currentShockCount: _shockCount,
      codeTimeSeconds: _codeSeconds,
      currentRhythm: _patientState.rhythm,
    );
  }

  // ── Event logging ──────────────────────────────────────

  void _log(
    String description,
    EventCategory category, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    _eventLog.add(SimulationEvent(
      timeSeconds: _codeSeconds,
      description: description,
      category: category,
      isError: isError,
      isSuccess: isSuccess,
    ));
  }

  // ── Scenario lifecycle ─────────────────────────────────

  void startScenario(
    Scenario scenario, {
    TrainingConfig config = const TrainingConfig(),
  }) {
    _currentScenario = scenario;
    _trainingConfig = config;
    _patientState = scenario.initialRhythm.hasPulse
        ? PatientState.pulsedRhythm(
            scenario.initialRhythm)
        : PatientState.cardiacArrest(
            scenario.initialRhythm);
    _codeSeconds = 0;
    _cprCycleSeconds = 0;
    _compressions = 0;
    _ventilations = 0;
    _currentCycleCompressions = 0;
    _currentCycleVentilations = 0;
    _compressionBatch = 0;
    _shockCount = 0;
    _timeToFirstShock = null;
    _doseHistory.clear();
    _timeToFirstEpinephrine = null;
    _reversibleCausesChecked.clear();
    _airwayDevice = 'BVM';
    _isRunning = true;
    _autoCprPaused = false;
    _autoCycleCompressions = 0;
    _recentCompressionTimes.clear();
    _roscBoost = 0.0;
    _postShockCprSeconds = 0;
    _eventLog.clear();

    _log(
      'Scenario started: ${scenario.title} '
      '— Initial rhythm: '
      '${scenario.initialRhythm.displayName}',
      EventCategory.info,
    );

    _startTimers();
    notifyListeners();
  }

  void _startTimers() {
    _codeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _codeSeconds++;
        if (!_patientState.hasROSC) {
          _postShockCprSeconds++;
        }
        notifyListeners();
      },
    );

    if (!_patientState.hasROSC &&
        !_patientState.hasPulse) {
      _cprCycleTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          _cprCycleSeconds++;
          notifyListeners();
        },
      );

      if (_trainingConfig.isProtocolMode) {
        _startAutoCpr();
      }
    }
  }

  void _startAutoCpr() {
    _autoCprTimer?.cancel();
    _autoCycleCompressions = 0;
    _autoCprTimer = Timer.periodic(
      const Duration(milliseconds: 545),
      (timer) {
        if (!_isRunning || _autoCprPaused) return;
        _performAutoCprTick();
      },
    );
  }

  void _performAutoCprTick() {
    if (_patientState.hasROSC) {
      _autoCprTimer?.cancel();
      return;
    }
    final ratio = _trainingConfig.cprRatio;

    if (ratio == CprRatio.continuous) {
      _compressions++;
      _currentCycleCompressions++;
      _compressionBatch++;
    } else {
      if (_autoCycleCompressions < ratio.compressions) {
        _compressions++;
        _currentCycleCompressions++;
        _autoCycleCompressions++;
        _compressionBatch++;
      } else {
        _ventilations++;
        _currentCycleVentilations++;
        _autoCycleCompressions++;
        final cycleTotal =
            ratio.compressions + ratio.ventilations;
        if (_autoCycleCompressions >= cycleTotal) {
          _autoCycleCompressions = 0;
        }
      }
    }

    // Log every 30 compressions.
    if (_compressionBatch >= 30) {
      _compressionBatch = 0;
      _log('30 compressions', EventCategory.cpr);
    }

    notifyListeners();
  }

  void _pauseAutoCpr() {
    _autoCprPaused = true;
  }

  void _resumeAutoCpr() {
    _autoCprPaused = false;
    _autoCycleCompressions = 0;
  }

  void pauseResume() {
    _isRunning = !_isRunning;
    if (_isRunning) {
      _startTimers();
    } else {
      _codeTimer?.cancel();
      _cprCycleTimer?.cancel();
      _autoCprTimer?.cancel();
    }
    notifyListeners();
  }

  void performCompression() {
    if (!_isRunning || _patientState.hasROSC) return;
    _compressions++;
    _currentCycleCompressions++;
    _compressionBatch++;
    _recentCompressionTimes.add(DateTime.now());
    if (_compressionBatch >= 30) {
      _compressionBatch = 0;
      _log('30 compressions', EventCategory.cpr);
    }
    notifyListeners();
  }

  void performVentilation() {
    if (!_isRunning || _patientState.hasROSC) return;
    _ventilations++;
    _currentCycleVentilations++;
    notifyListeners();
  }

  void resetCprCycle() {
    _cprCycleSeconds = 0;
    _currentCycleCompressions = 0;
    _currentCycleVentilations = 0;
    _autoCycleCompressions = 0;
    _log(
      '2-minute CPR cycle complete',
      EventCategory.cpr,
    );
    notifyListeners();
  }

  void setEnergy(int joules) {
    _selectedEnergy = joules;
    notifyListeners();
  }

  Future<void> analyzeRhythm() async {
    if (!_isRunning) return;
    _pauseAutoCpr();
    _log(
      'Rhythm analyzed: '
      '${_patientState.rhythm.displayName}',
      EventCategory.assessment,
    );
    await Future.delayed(const Duration(seconds: 2));
    _resumeAutoCpr();
    notifyListeners();
  }

  Future<void> chargeDefibrillator() async {
    if (!_isRunning) return;
    _isCharging = true;
    _pauseAutoCpr();
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _isCharging = false;
    notifyListeners();
  }

  void deliverShock() {
    if (!_isRunning || !_isCharging) return;

    _shockCount++;
    _timeToFirstShock ??= _codeSeconds;

    String result = 'rhythm persists';
    if (_patientState.rhythm.isShockable) {
      final baseProbability = 0.15 + _roscBoost;
      final roll = _random.nextDouble();
      if (roll < baseProbability) {
        _achieveROSC();
        result = 'ROSC';
      } else if (_random.nextDouble() < 0.4) {
        _patientState = _patientState.copyWith(
          rhythm: ECGRhythm.pea,
        );
        result = 'changed to PEA';
      }
    }

    _log(
      'Shock #$_shockCount delivered '
      '(${_selectedEnergy}J) — $result',
      EventCategory.shock,
    );

    _isCharging = false;
    _postShockCprSeconds = 0;
    resetCprCycle();
    if (!_patientState.hasROSC) {
      _resumeAutoCpr();
    }
    notifyListeners();
  }

  // ── Medication administration ──────────────────────────

  void administerMedication(
    Medication med, {
    bool forceEarly = false,
  }) {
    if (!_isRunning) return;

    final eligibility = getMedicationEligibility(med);
    if (!eligibility.canAdminister && !forceEarly) return;

    final wasEarly =
        eligibility.secondsUntilEligible != null &&
            eligibility.secondsUntilEligible! > 0;

    final record = MedicationDoseRecord(
      medicationName: med.name,
      dose: med.dose,
      timeSeconds: _codeSeconds,
      wasEarly: wasEarly,
      wasEligible: eligibility.canAdminister,
    );
    _doseHistory.add(record);

    // Log the administration.
    if (wasEarly) {
      final lastDose = _doseHistory
          .where((d) => d.medicationName == med.name)
          .toList();
      final prevDose = lastDose.length >= 2
          ? lastDose[lastDose.length - 2]
          : null;
      final sinceStr = prevDose != null
          ? _fmtSec(_codeSeconds - prevDose.timeSeconds)
          : '?';
      _log(
        '${med.name} ${med.dose} administered '
        '(too early: $sinceStr since last dose)',
        EventCategory.medication,
        isError: true,
      );
    } else {
      _log(
        '${med.name} ${med.dose} administered',
        EventCategory.medication,
      );
    }

    if (med.name == 'Epinephrine') {
      _timeToFirstEpinephrine ??= _codeSeconds;
      if (!wasEarly) _roscBoost += 0.15;
    }

    if (med.name == 'Amiodarone' &&
        med.dose == '300 mg') {
      if (_shockCount >= 3) {
        _roscBoost = max(_roscBoost, 0.30);
      }
    }

    if (med.name == 'Amiodarone' &&
        med.dose == '150 mg') {
      _roscBoost = max(_roscBoost, 0.40);
    }

    if (med.name == 'Lidocaine') {
      _roscBoost = max(_roscBoost, 0.20);
    }

    if (med.name == 'Magnesium Sulfate' &&
        _patientState.rhythm == ECGRhythm.torsades) {
      Future.delayed(
        const Duration(seconds: 120),
        () {
          if (_isRunning &&
              !_patientState.hasROSC &&
              _random.nextDouble() < 0.70) {
            _achieveROSC();
          }
        },
      );
    }

    if (med.name == 'Epinephrine' &&
        !_patientState.rhythm.isShockable &&
        _patientState.rhythm !=
            ECGRhythm.normalSinus) {
      if (_random.nextDouble() < 0.08) {
        _patientState = _patientState.copyWith(
          rhythm: ECGRhythm.pea,
        );
      }
    }

    notifyListeners();
  }

  void toggleReversibleCause(String causeId) {
    final wasChecked =
        _reversibleCausesChecked[causeId] ?? false;
    _reversibleCausesChecked[causeId] = !wasChecked;

    if (!wasChecked) {
      _log(
        'H&T checked: $causeId',
        EventCategory.assessment,
      );
    }

    if (_reversibleCausesChecked.values
            .where((v) => v)
            .length >=
        6) {
      if (_random.nextDouble() < 0.2 &&
          !_patientState.hasROSC) {
        _achieveROSC();
      }
    }

    notifyListeners();
  }

  void setAirwayDevice(String device) {
    _airwayDevice = device;
    _log(
      'Airway: $device placed',
      EventCategory.airway,
    );
    notifyListeners();
  }

  void _achieveROSC() {
    _patientState = PatientState.withROSC();
    _autoCprTimer?.cancel();
    _cprCycleTimer?.cancel();
    _log(
      'ROSC achieved at ${_fmtSec(_codeSeconds)}',
      EventCategory.rosc,
      isSuccess: true,
    );
    notifyListeners();
  }

  PerformanceScore calculatePerformance() {
    final metrics = PerformanceMetrics(
      totalCompressions: _compressions,
      totalVentilations: _ventilations,
      cprRatio: cprRatio,
      shocksDelivered: _shockCount,
      timeToFirstShock: _timeToFirstShock ?? 0,
      medicationsGiven: medicationsGiven,
      timeToFirstEpinephrine:
          _timeToFirstEpinephrine ?? 0,
      achievedROSC: _patientState.hasROSC,
      totalTimeSeconds: _codeSeconds,
      reversibleCausesChecked:
          _reversibleCausesChecked,
      airwayUsed: _airwayDevice,
    );

    return PerformanceScore.calculate(
      metrics,
      _currentScenario?.id ?? '',
      trainingConfig: _trainingConfig,
    );
  }

  void endScenario() {
    _isRunning = false;
    _codeTimer?.cancel();
    _cprCycleTimer?.cancel();
    _autoCprTimer?.cancel();
    _log('Scenario ended', EventCategory.info);
    notifyListeners();
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _cprCycleTimer?.cancel();
    _autoCprTimer?.cancel();
    super.dispose();
  }

  String _fmtSec(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

extension _IterableExt<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    T? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}

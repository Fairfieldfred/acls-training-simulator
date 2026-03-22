import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ecg_rhythm_model.dart';
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

  // Compression rate tracking (for timing mode)
  final List<DateTime> _recentCompressionTimes = [];

  // Defibrillator
  bool _isCharging = false;
  int _selectedEnergy = 200;
  int _shockCount = 0;
  int? _timeToFirstShock;

  // Medications — dose history replaces old string list
  final List<MedicationDoseRecord> _doseHistory = [];
  final MedicationEligibilityService _eligibilityService =
      MedicationEligibilityService();
  int? _timeToFirstEpinephrine;

  // ROSC probability boost from medications
  double _roscBoost = 0.0;

  // Post-shock CPR cycle tracking
  int _postShockCprSeconds = 0;

  // Reversible causes
  final Map<String, bool> _reversibleCausesChecked = {};

  // Airway
  String _airwayDevice = 'BVM';

  // Auto-CPR cycle tracking (for protocol mode)
  int _autoCycleCompressions = 0;

  final _random = Random();

  // Getters
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
  List<MedicationDoseRecord> get doseHistory => _doseHistory;

  /// Backward-compatible display strings for results.
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

  /// Compressions per minute over the last 10 seconds.
  double get compressionRate {
    if (_recentCompressionTimes.isEmpty) return 0;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(seconds: 10));
    _recentCompressionTimes
        .removeWhere((t) => t.isBefore(cutoff));
    if (_recentCompressionTimes.isEmpty) return 0;
    return _recentCompressionTimes.length * 6.0;
  }

  // ── Medication timing getters ──────────────────────────

  /// Seconds since last epinephrine dose, or null if none.
  int? get secondsSinceLastEpi {
    final lastEpi = _doseHistory.lastWhereOrNull(
      (d) => d.medicationName == 'Epinephrine',
    );
    if (lastEpi == null) return null;
    return _codeSeconds - lastEpi.timeSeconds;
  }

  /// Whether epinephrine is overdue (> 300s since last).
  bool get isEpiOverdue {
    final elapsed = secondsSinceLastEpi;
    if (elapsed == null) {
      return _codeSeconds > 60;
    }
    return elapsed > 300;
  }

  /// Seconds until next epi is due (3-min mark), or null.
  int? get nextEpiDueSeconds {
    final elapsed = secondsSinceLastEpi;
    if (elapsed == null) return null;
    final remaining = 180 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Post-shock CPR seconds (resets after each shock).
  int get postShockCprSeconds => _postShockCprSeconds;

  /// Whether a full 2-min CPR cycle is complete.
  bool get cprCycleComplete => _postShockCprSeconds >= 120;

  /// Check eligibility for a given medication.
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

  // ── Scenario lifecycle ─────────────────────────────────

  void startScenario(
    Scenario scenario, {
    TrainingConfig config = const TrainingConfig(),
  }) {
    _currentScenario = scenario;
    _trainingConfig = config;
    // Pulsed rhythms start with vitals, not arrest.
    _patientState = scenario.initialRhythm.hasPulse
        ? PatientState.pulsedRhythm(scenario.initialRhythm)
        : PatientState.cardiacArrest(scenario.initialRhythm);
    _codeSeconds = 0;
    _cprCycleSeconds = 0;
    _compressions = 0;
    _ventilations = 0;
    _currentCycleCompressions = 0;
    _currentCycleVentilations = 0;
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

    if (!_patientState.hasROSC) {
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

  /// Starts automatic CPR in protocol mode.
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
    } else {
      if (_autoCycleCompressions < ratio.compressions) {
        _compressions++;
        _currentCycleCompressions++;
        _autoCycleCompressions++;
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
    _recentCompressionTimes.add(DateTime.now());
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
    notifyListeners();
  }

  void setEnergy(int joules) {
    _selectedEnergy = joules;
    notifyListeners();
  }

  Future<void> analyzeRhythm() async {
    if (!_isRunning) return;
    _pauseAutoCpr();
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

    if (_patientState.rhythm.isShockable) {
      // Base ROSC probability + medication boosts.
      final baseProbability = 0.15 + _roscBoost;
      final roll = _random.nextDouble();
      if (roll < baseProbability) {
        _achieveROSC();
      } else if (_random.nextDouble() < 0.4) {
        _patientState =
            _patientState.copyWith(rhythm: ECGRhythm.pea);
      }
    }

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

    // If fully ineligible and not forcing, skip.
    if (!eligibility.canAdminister && !forceEarly) return;

    final wasEarly = eligibility.secondsUntilEligible != null &&
        eligibility.secondsUntilEligible! > 0;

    final record = MedicationDoseRecord(
      medicationName: med.name,
      dose: med.dose,
      timeSeconds: _codeSeconds,
      wasEarly: wasEarly,
      wasEligible: eligibility.canAdminister,
    );
    _doseHistory.add(record);

    if (med.name == 'Epinephrine') {
      _timeToFirstEpinephrine ??= _codeSeconds;
      // Epi boosts next shock ROSC probability.
      if (!wasEarly) {
        _roscBoost += 0.15;
      }
    }

    // Amiodarone 300 mg after 3rd shock.
    if (med.name == 'Amiodarone' && med.dose == '300 mg') {
      if (_shockCount >= 3) {
        _roscBoost = max(_roscBoost, 0.30);
      }
    }

    // Amiodarone 150 mg 2nd dose.
    if (med.name == 'Amiodarone' && med.dose == '150 mg') {
      _roscBoost = max(_roscBoost, 0.40);
    }

    // Lidocaine.
    if (med.name == 'Lidocaine') {
      _roscBoost = max(_roscBoost, 0.20);
    }

    // Magnesium in torsades: delayed conversion.
    if (med.name == 'Magnesium Sulfate' &&
        _patientState.rhythm == ECGRhythm.torsades) {
      Future.delayed(const Duration(seconds: 120), () {
        if (_isRunning &&
            !_patientState.hasROSC &&
            _random.nextDouble() < 0.70) {
          _achieveROSC();
        }
      });
    }

    // PEA/asystole: epi has small conversion chance.
    if (med.name == 'Epinephrine' &&
        !_patientState.rhythm.isShockable &&
        _patientState.rhythm != ECGRhythm.normalSinus) {
      if (_random.nextDouble() < 0.08) {
        _patientState =
            _patientState.copyWith(rhythm: ECGRhythm.pea);
      }
    }

    notifyListeners();
  }

  void toggleReversibleCause(String causeId) {
    _reversibleCausesChecked[causeId] =
        !(_reversibleCausesChecked[causeId] ?? false);

    if (_reversibleCausesChecked.values
            .where((v) => v)
            .length >=
        6) {
      final roll = _random.nextDouble();
      if (roll < 0.2 && !_patientState.hasROSC) {
        _achieveROSC();
      }
    }

    notifyListeners();
  }

  void setAirwayDevice(String device) {
    _airwayDevice = device;
    notifyListeners();
  }

  void _achieveROSC() {
    _patientState = PatientState.withROSC();
    _autoCprTimer?.cancel();
    _cprCycleTimer?.cancel();
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
      timeToFirstEpinephrine: _timeToFirstEpinephrine ?? 0,
      achievedROSC: _patientState.hasROSC,
      totalTimeSeconds: _codeSeconds,
      reversibleCausesChecked: _reversibleCausesChecked,
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
    notifyListeners();
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _cprCycleTimer?.cancel();
    _autoCprTimer?.cancel();
    super.dispose();
  }
}

/// Extension to add lastWhereOrNull to iterables.
extension _IterableExt<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    T? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}

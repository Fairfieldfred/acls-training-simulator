import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ecg_rhythm_model.dart';
import '../models/medication_model.dart';
import '../models/patient_model.dart';
import '../models/scenario_model.dart';
import '../models/performance_model.dart';

class SimulationService extends ChangeNotifier {
  Scenario? _currentScenario;
  PatientState _patientState = PatientState.cardiacArrest(ECGRhythm.vf);

  // Timers
  Timer? _codeTimer;
  Timer? _cprCycleTimer;
  int _codeSeconds = 0;
  int _cprCycleSeconds = 0;
  bool _isRunning = false;

  // CPR tracking
  int _compressions = 0;
  int _ventilations = 0;
  int _currentCycleCompressions = 0;
  int _currentCycleVentilations = 0;

  // Defibrillator
  bool _isCharging = false;
  int _selectedEnergy = 200;
  int _shockCount = 0;
  int? _timeToFirstShock;

  // Medications
  final List<String> _medicationsGiven = [];
  int? _timeToFirstEpinephrine;

  // Reversible causes
  final Map<String, bool> _reversibleCausesChecked = {};

  // Airway
  String _airwayDevice = 'BVM';

  // Getters
  Scenario? get currentScenario => _currentScenario;
  PatientState get patientState => _patientState;
  bool get isRunning => _isRunning;
  int get codeSeconds => _codeSeconds;
  int get cprCycleSeconds => _cprCycleSeconds;
  int get compressions => _compressions;
  int get ventilations => _ventilations;
  int get currentCycleCompressions => _currentCycleCompressions;
  int get currentCycleVentilations => _currentCycleVentilations;
  bool get isCharging => _isCharging;
  int get selectedEnergy => _selectedEnergy;
  int get shockCount => _shockCount;
  List<String> get medicationsGiven => _medicationsGiven;
  Map<String, bool> get reversibleCausesChecked => _reversibleCausesChecked;
  String get airwayDevice => _airwayDevice;

  String get formattedCodeTime {
    final minutes = _codeSeconds ~/ 60;
    final seconds = _codeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedCprCycleTime {
    final minutes = _cprCycleSeconds ~/ 60;
    final seconds = _cprCycleSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get cprRatio {
    if (_ventilations == 0) return 0;
    return _compressions / _ventilations;
  }

  void startScenario(Scenario scenario) {
    _currentScenario = scenario;
    _patientState = PatientState.cardiacArrest(scenario.initialRhythm);
    _codeSeconds = 0;
    _cprCycleSeconds = 0;
    _compressions = 0;
    _ventilations = 0;
    _currentCycleCompressions = 0;
    _currentCycleVentilations = 0;
    _shockCount = 0;
    _timeToFirstShock = null;
    _medicationsGiven.clear();
    _timeToFirstEpinephrine = null;
    _reversibleCausesChecked.clear();
    _airwayDevice = 'BVM';
    _isRunning = true;

    _startTimers();
    notifyListeners();
  }

  void _startTimers() {
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _codeSeconds++;
      notifyListeners();
    });

    _cprCycleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cprCycleSeconds++;
      notifyListeners();
    });
  }

  void pauseResume() {
    _isRunning = !_isRunning;
    if (_isRunning) {
      _startTimers();
    } else {
      _codeTimer?.cancel();
      _cprCycleTimer?.cancel();
    }
    notifyListeners();
  }

  void performCompression() {
    if (!_isRunning) return;
    _compressions++;
    _currentCycleCompressions++;
    notifyListeners();
  }

  void performVentilation() {
    if (!_isRunning) return;
    _ventilations++;
    _currentCycleVentilations++;
    notifyListeners();
  }

  void resetCprCycle() {
    _cprCycleSeconds = 0;
    _currentCycleCompressions = 0;
    _currentCycleVentilations = 0;
    notifyListeners();
  }

  void setEnergy(int joules) {
    _selectedEnergy = joules;
    notifyListeners();
  }

  Future<void> analyzeRhythm() async {
    if (!_isRunning) return;
    // Pause for rhythm check
    await Future.delayed(const Duration(seconds: 2));
    notifyListeners();
  }

  Future<void> chargeDefibrillator() async {
    if (!_isRunning) return;
    _isCharging = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _isCharging = false;
    notifyListeners();
  }

  void deliverShock() {
    if (!_isRunning || !_isCharging) return;

    _shockCount++;
    _timeToFirstShock ??= _codeSeconds;

    // Simulate rhythm change after shock
    if (_patientState.rhythm.isShockable) {
      // 30% chance of ROSC, 40% chance of non-shockable, 30% stays VF
      final random = DateTime.now().millisecond % 10;
      if (random < 3) {
        _achieveROSC();
      } else if (random < 7) {
        _patientState = _patientState.copyWith(rhythm: ECGRhythm.pea);
      }
      // else stays in VF/pVT
    }

    _isCharging = false;
    resetCprCycle();
    notifyListeners();
  }

  void administerMedication(Medication med) {
    if (!_isRunning) return;

    _medicationsGiven.add('${med.name} ${med.dose}');

    if (med.name.toLowerCase().contains('epinephrine')) {
      _timeToFirstEpinephrine ??= _codeSeconds;
    }

    // Simulate medication effects
    if (med.name.toLowerCase().contains('epinephrine')) {
      // Small chance of rhythm improvement
      final random = DateTime.now().millisecond % 20;
      if (random < 2 && !_patientState.rhythm.isShockable) {
        _patientState = _patientState.copyWith(rhythm: ECGRhythm.pea);
      }
    }

    notifyListeners();
  }

  void toggleReversibleCause(String causeId) {
    _reversibleCausesChecked[causeId] = !(_reversibleCausesChecked[causeId] ?? false);

    // Simulate treating a cause leading to ROSC
    if (_reversibleCausesChecked.values.where((v) => v).length >= 6) {
      final random = DateTime.now().millisecond % 10;
      if (random < 2 && !_patientState.hasROSC) {
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
    notifyListeners();
  }

  PerformanceScore calculatePerformance() {
    final metrics = PerformanceMetrics(
      totalCompressions: _compressions,
      totalVentilations: _ventilations,
      cprRatio: cprRatio,
      shocksDelivered: _shockCount,
      timeToFirstShock: _timeToFirstShock ?? 0,
      medicationsGiven: _medicationsGiven,
      timeToFirstEpinephrine: _timeToFirstEpinephrine ?? 0,
      achievedROSC: _patientState.hasROSC,
      totalTimeSeconds: _codeSeconds,
      reversibleCausesChecked: _reversibleCausesChecked,
      airwayUsed: _airwayDevice,
    );

    return PerformanceScore.calculate(metrics, _currentScenario?.id ?? '');
  }

  void endScenario() {
    _isRunning = false;
    _codeTimer?.cancel();
    _cprCycleTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _cprCycleTimer?.cancel();
    super.dispose();
  }
}

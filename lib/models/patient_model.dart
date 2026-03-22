import 'ecg_rhythm_model.dart';

class PatientState {
  final ECGRhythm rhythm;
  final int heartRate;
  final String bloodPressure;
  final int respiratoryRate;
  final int oxygenSaturation;
  final bool hasPulse;
  final bool isBreathing;
  final bool isConscious;
  final bool hasROSC; // Return of Spontaneous Circulation

  const PatientState({
    required this.rhythm,
    required this.heartRate,
    required this.bloodPressure,
    required this.respiratoryRate,
    required this.oxygenSaturation,
    required this.hasPulse,
    required this.isBreathing,
    required this.isConscious,
    this.hasROSC = false,
  });

  static PatientState cardiacArrest(ECGRhythm rhythm) {
    return PatientState(
      rhythm: rhythm,
      heartRate: 0,
      bloodPressure: '--/--',
      respiratoryRate: 0,
      oxygenSaturation: 0,
      hasPulse: false,
      isBreathing: false,
      isConscious: false,
    );
  }

  /// Pulsed tachycardia or bradycardia patient (not arrest).
  static PatientState pulsedRhythm(ECGRhythm rhythm) {
    final isTachy = rhythm.heartRate > 100;
    return PatientState(
      rhythm: rhythm,
      heartRate: rhythm.heartRate,
      bloodPressure: isTachy ? '90/60' : '100/65',
      respiratoryRate: 18,
      oxygenSaturation: 94,
      hasPulse: true,
      isBreathing: true,
      isConscious: true,
    );
  }

  static PatientState withROSC() {
    return const PatientState(
      rhythm: ECGRhythm.normalSinus,
      heartRate: 75,
      bloodPressure: '110/70',
      respiratoryRate: 16,
      oxygenSaturation: 95,
      hasPulse: true,
      isBreathing: true,
      isConscious: false,
      hasROSC: true,
    );
  }

  PatientState copyWith({
    ECGRhythm? rhythm,
    int? heartRate,
    String? bloodPressure,
    int? respiratoryRate,
    int? oxygenSaturation,
    bool? hasPulse,
    bool? isBreathing,
    bool? isConscious,
    bool? hasROSC,
  }) {
    return PatientState(
      rhythm: rhythm ?? this.rhythm,
      heartRate: heartRate ?? this.heartRate,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      hasPulse: hasPulse ?? this.hasPulse,
      isBreathing: isBreathing ?? this.isBreathing,
      isConscious: isConscious ?? this.isConscious,
      hasROSC: hasROSC ?? this.hasROSC,
    );
  }
}

enum ECGRhythm {
  vf,           // Ventricular Fibrillation
  pvt,          // Pulseless Ventricular Tachycardia
  torsades,     // Torsades de Pointes
  pea,          // Pulseless Electrical Activity
  asystole,     // Asystole
  normalSinus,  // Normal Sinus Rhythm
}

extension ECGRhythmExtension on ECGRhythm {
  String get displayName {
    return switch (this) {
      ECGRhythm.vf => 'Ventricular Fibrillation',
      ECGRhythm.pvt => 'Pulseless V-Tach',
      ECGRhythm.torsades => 'Torsades de Pointes',
      ECGRhythm.pea => 'PEA',
      ECGRhythm.asystole => 'Asystole',
      ECGRhythm.normalSinus => 'Normal Sinus Rhythm',
    };
  }

  bool get isShockable {
    return this == ECGRhythm.vf ||
        this == ECGRhythm.pvt ||
        this == ECGRhythm.torsades;
  }

  int get heartRate {
    return switch (this) {
      ECGRhythm.vf => 0,
      ECGRhythm.pvt => 180,
      ECGRhythm.torsades => 200,
      ECGRhythm.pea => 60,
      ECGRhythm.asystole => 0,
      ECGRhythm.normalSinus => 75,
    };
  }
}

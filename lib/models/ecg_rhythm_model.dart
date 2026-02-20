enum ECGRhythm {
  vf,           // Ventricular Fibrillation
  pvt,          // Pulseless Ventricular Tachycardia
  pea,          // Pulseless Electrical Activity
  asystole,     // Asystole
  normalSinus,  // Normal Sinus Rhythm
}

extension ECGRhythmExtension on ECGRhythm {
  String get displayName {
    switch (this) {
      case ECGRhythm.vf:
        return 'Ventricular Fibrillation';
      case ECGRhythm.pvt:
        return 'Pulseless V-Tach';
      case ECGRhythm.pea:
        return 'PEA';
      case ECGRhythm.asystole:
        return 'Asystole';
      case ECGRhythm.normalSinus:
        return 'Normal Sinus Rhythm';
    }
  }

  bool get isShockable {
    return this == ECGRhythm.vf || this == ECGRhythm.pvt;
  }

  int get heartRate {
    switch (this) {
      case ECGRhythm.vf:
        return 0;
      case ECGRhythm.pvt:
        return 180;
      case ECGRhythm.pea:
        return 60;
      case ECGRhythm.asystole:
        return 0;
      case ECGRhythm.normalSinus:
        return 75;
    }
  }
}

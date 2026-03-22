enum ECGRhythm {
  vf,                // Ventricular Fibrillation
  pvt,               // Pulseless Ventricular Tachycardia
  torsades,          // Torsades de Pointes — shockable
  pea,               // Pulseless Electrical Activity
  asystole,          // Asystole
  aivr,              // Accelerated Idioventricular Rhythm
  normalSinus,       // Normal Sinus Rhythm
  sinusBradycardia,  // Sinus Bradycardia < 50bpm
  sinusTachycardia,  // Sinus Tachycardia 100-150bpm
  svt,               // SVT / AVNRT
  afib,              // Atrial Fibrillation
  aflutter,          // Atrial Flutter
  vtachPulsed,       // VT with pulse
  avBlock1,          // 1st degree AV block
  avBlock2Mobitz2,   // Mobitz II
  avBlock3,          // Complete Heart Block
  junctional,        // Junctional rhythm
}

extension ECGRhythmExtension on ECGRhythm {
  String get displayName {
    return switch (this) {
      ECGRhythm.vf => 'Ventricular Fibrillation',
      ECGRhythm.pvt => 'Pulseless V-Tach',
      ECGRhythm.torsades => 'Torsades de Pointes',
      ECGRhythm.pea => 'PEA',
      ECGRhythm.asystole => 'Asystole',
      ECGRhythm.aivr => 'AIVR',
      ECGRhythm.normalSinus => 'Normal Sinus Rhythm',
      ECGRhythm.sinusBradycardia => 'Sinus Bradycardia',
      ECGRhythm.sinusTachycardia => 'Sinus Tachycardia',
      ECGRhythm.svt => 'SVT',
      ECGRhythm.afib => 'Atrial Fibrillation',
      ECGRhythm.aflutter => 'Atrial Flutter',
      ECGRhythm.vtachPulsed => 'VT with Pulse',
      ECGRhythm.avBlock1 => '1st Degree AV Block',
      ECGRhythm.avBlock2Mobitz2 => 'Mobitz Type II',
      ECGRhythm.avBlock3 => 'Complete Heart Block',
      ECGRhythm.junctional => 'Junctional Rhythm',
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
      ECGRhythm.aivr => 55,
      ECGRhythm.normalSinus => 75,
      ECGRhythm.sinusBradycardia => 40,
      ECGRhythm.sinusTachycardia => 120,
      ECGRhythm.svt => 200,
      ECGRhythm.afib => 110,
      ECGRhythm.aflutter => 75,
      ECGRhythm.vtachPulsed => 170,
      ECGRhythm.avBlock1 => 70,
      ECGRhythm.avBlock2Mobitz2 => 35,
      ECGRhythm.avBlock3 => 35,
      ECGRhythm.junctional => 50,
    };
  }

  /// Whether this rhythm typically has a pulse.
  bool get hasPulse {
    return switch (this) {
      ECGRhythm.vf => false,
      ECGRhythm.pvt => false,
      ECGRhythm.torsades => false,
      ECGRhythm.pea => false,
      ECGRhythm.asystole => false,
      ECGRhythm.aivr => true,
      ECGRhythm.normalSinus => true,
      ECGRhythm.sinusBradycardia => true,
      ECGRhythm.sinusTachycardia => true,
      ECGRhythm.svt => true,
      ECGRhythm.afib => true,
      ECGRhythm.aflutter => true,
      ECGRhythm.vtachPulsed => true,
      ECGRhythm.avBlock1 => true,
      ECGRhythm.avBlock2Mobitz2 => true,
      ECGRhythm.avBlock3 => true,
      ECGRhythm.junctional => true,
    };
  }
}

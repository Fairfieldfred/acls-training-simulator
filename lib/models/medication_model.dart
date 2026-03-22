import 'medication_timing_model.dart';

class Medication {
  final String name;
  final String dose;
  final String route;
  final String indication;
  final bool isQuickAccess;

  const Medication({
    required this.name,
    required this.dose,
    required this.route,
    required this.indication,
    this.isQuickAccess = false,
  });

  /// Unique key combining name and dose for tracking.
  String get key => '${name}_$dose';

  /// AHA 2025 timing rules for this medication.
  MedicationTiming get timing {
    if (name == 'Epinephrine') {
      return const MedicationTiming(
        medicationName: 'Epinephrine',
        minIntervalSeconds: 180,
        clinicalNote: 'Epinephrine every 3-5 minutes '
            'during cardiac arrest.',
      );
    }
    if (name == 'Amiodarone' && dose == '300 mg') {
      return const MedicationTiming(
        medicationName: 'Amiodarone',
        minIntervalSeconds: 0,
        maxDoses: 1,
        requiresShockCount: 3,
        clinicalNote: 'Amiodarone 300 mg after 3rd '
            'shock for refractory VF/pVT.',
      );
    }
    if (name == 'Amiodarone' && dose == '150 mg') {
      return const MedicationTiming(
        medicationName: 'Amiodarone 2nd',
        minIntervalSeconds: 300,
        maxDoses: 1,
        requiresShockCount: 5,
        clinicalNote: 'Amiodarone 150 mg after 5th '
            'shock or 5 min after first dose.',
      );
    }
    if (name == 'Lidocaine') {
      return const MedicationTiming(
        medicationName: 'Lidocaine',
        minIntervalSeconds: 0,
        maxDoses: 2,
        requiresShockCount: 3,
        requiresNoAmiodarone: true,
        clinicalNote: 'Lidocaine alternative to '
            'amiodarone. Do not mix.',
      );
    }
    if (name == 'Magnesium Sulfate') {
      return const MedicationTiming(
        medicationName: 'Magnesium Sulfate',
        minIntervalSeconds: 0,
        maxDoses: 1,
        requiresRhythm: 'torsades',
        clinicalNote: 'Magnesium 2 g for torsades '
            'de pointes only.',
      );
    }
    if (name == 'Atropine') {
      return const MedicationTiming(
        medicationName: 'Atropine',
        minIntervalSeconds: 180,
        maxDoses: 6,
        clinicalNote: 'Atropine 0.5 mg q3-5 min, '
            'max 3 mg. Bradycardia only.',
      );
    }
    return MedicationTiming(
      medicationName: name,
      minIntervalSeconds: 0,
      clinicalNote: '$name: no specific timing rule.',
    );
  }

  static const epinephrine = Medication(
    name: 'Epinephrine',
    dose: '1 mg',
    route: 'IV/IO',
    indication: 'Cardiac arrest (every 3-5 min)',
    isQuickAccess: true,
  );

  static const amiodarone = Medication(
    name: 'Amiodarone',
    dose: '300 mg',
    route: 'IV/IO',
    indication: 'VF/pVT (first dose)',
    isQuickAccess: true,
  );

  static const amiodarone2nd = Medication(
    name: 'Amiodarone',
    dose: '150 mg',
    route: 'IV/IO',
    indication: 'VF/pVT (second dose)',
    isQuickAccess: false,
  );

  static const lidocaine = Medication(
    name: 'Lidocaine',
    dose: '1-1.5 mg/kg',
    route: 'IV/IO',
    indication: 'VF/pVT (alternative to amiodarone)',
    isQuickAccess: true,
  );

  static const atropine = Medication(
    name: 'Atropine',
    dose: '1 mg',
    route: 'IV/IO',
    indication: 'Bradycardia (no longer used in cardiac arrest)',
    isQuickAccess: false,
  );

  static const calcium = Medication(
    name: 'Calcium Chloride',
    dose: '1 g',
    route: 'IV/IO',
    indication: 'Hyperkalemia, hypocalcemia, calcium channel blocker toxicity',
    isQuickAccess: false,
  );

  static const magnesium = Medication(
    name: 'Magnesium Sulfate',
    dose: '2 g',
    route: 'IV/IO',
    indication: 'Torsades de pointes',
    isQuickAccess: false,
  );

  static const bicarb = Medication(
    name: 'Sodium Bicarbonate',
    dose: '1 mEq/kg',
    route: 'IV/IO',
    indication: 'Hyperkalemia, tricyclic overdose, acidosis',
    isQuickAccess: false,
  );

  static const dextrose = Medication(
    name: 'Dextrose 50%',
    dose: '25 g',
    route: 'IV',
    indication: 'Hypoglycemia',
    isQuickAccess: false,
  );

  static const naloxone = Medication(
    name: 'Naloxone',
    dose: '0.4-2 mg',
    route: 'IV/IO/IN',
    indication: 'Opioid overdose',
    isQuickAccess: false,
  );

  static List<Medication> get quickAccessMeds =>
      allMedications.where((m) => m.isQuickAccess).toList();

  static List<Medication> get allMedications => [
        epinephrine,
        amiodarone,
        amiodarone2nd,
        lidocaine,
        atropine,
        calcium,
        magnesium,
        bicarb,
        dextrose,
        naloxone,
      ];
}

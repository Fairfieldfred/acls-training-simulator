/// Timing rules for a medication per AHA 2025 guidelines.
class MedicationTiming {
  final String medicationName;
  final int minIntervalSeconds;
  final int? maxDoses;
  final int? requiresShockCount;
  final bool requiresNoAmiodarone;
  final String? requiresRhythm;
  final String clinicalNote;

  const MedicationTiming({
    required this.medicationName,
    required this.minIntervalSeconds,
    this.maxDoses,
    this.requiresShockCount,
    this.requiresNoAmiodarone = false,
    this.requiresRhythm,
    required this.clinicalNote,
  });
}

/// Record of a single medication dose during a simulation.
class MedicationDoseRecord {
  final String medicationName;
  final String dose;
  final int timeSeconds;
  final bool wasEarly;
  final bool wasEligible;

  const MedicationDoseRecord({
    required this.medicationName,
    required this.dose,
    required this.timeSeconds,
    this.wasEarly = false,
    this.wasEligible = true,
  });

  /// Display string for event log and results.
  String get displayString => '$medicationName $dose';
}

/// Result of checking whether a medication can be given.
class MedicationEligibility {
  final bool canAdminister;
  final String? reason;
  final int? secondsUntilEligible;
  final bool isOverdue;
  final String? overdueMessage;

  const MedicationEligibility({
    required this.canAdminister,
    this.reason,
    this.secondsUntilEligible,
    this.isOverdue = false,
    this.overdueMessage,
  });

  /// Fully eligible with no warnings.
  static const eligible = MedicationEligibility(
    canAdminister: true,
  );
}

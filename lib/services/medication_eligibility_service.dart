import '../models/ecg_rhythm_model.dart';
import '../models/medication_model.dart';
import '../models/medication_timing_model.dart';

/// Checks whether a medication can be administered based on
/// AHA 2025 timing rules, shock count, rhythm, and history.
class MedicationEligibilityService {
  /// Evaluate eligibility for [med] given current state.
  MedicationEligibility checkEligibility({
    required Medication med,
    required List<MedicationDoseRecord> doseHistory,
    required int currentShockCount,
    required int codeTimeSeconds,
    required ECGRhythm currentRhythm,
  }) {
    final timing = med.timing;

    // Check max doses reached.
    if (timing.maxDoses != null) {
      final doseCount = _doseCountFor(med, doseHistory);
      if (doseCount >= timing.maxDoses!) {
        return MedicationEligibility(
          canAdminister: false,
          reason: 'Maximum doses reached '
              '($doseCount/${timing.maxDoses}).',
        );
      }
    }

    // Amiodarone 2nd dose: also check that 1st dose was given.
    if (med.name == 'Amiodarone' && med.dose == '150 mg') {
      final firstDoseGiven = doseHistory.any(
        (d) => d.medicationName == 'Amiodarone' &&
            d.dose == '300 mg',
      );
      if (!firstDoseGiven) {
        return const MedicationEligibility(
          canAdminister: false,
          reason: 'Give Amiodarone 300 mg first dose '
              'before second dose.',
        );
      }
    }

    // Check shock count requirement.
    if (timing.requiresShockCount != null) {
      if (currentShockCount < timing.requiresShockCount!) {
        return MedicationEligibility(
          canAdminister: false,
          reason: 'Requires ${timing.requiresShockCount} '
              'shocks (current: $currentShockCount).',
        );
      }
    }

    // Check amiodarone conflict (for lidocaine).
    if (timing.requiresNoAmiodarone) {
      final amioGiven = doseHistory.any(
        (d) => d.medicationName == 'Amiodarone',
      );
      if (amioGiven) {
        return const MedicationEligibility(
          canAdminister: false,
          reason: 'Cannot give Lidocaine — Amiodarone '
              'already administered.',
        );
      }
    }

    // Check rhythm requirement (e.g. magnesium for torsades).
    if (timing.requiresRhythm != null) {
      final rhythmMatch = _rhythmMatches(
        timing.requiresRhythm!,
        currentRhythm,
      );
      if (!rhythmMatch) {
        return MedicationEligibility(
          canAdminister: false,
          reason: 'Only indicated for '
              '${timing.requiresRhythm} rhythm.',
        );
      }
    }

    // Check interval requirement.
    if (timing.minIntervalSeconds > 0) {
      final lastDose = _lastDoseOf(med, doseHistory);
      if (lastDose != null) {
        final elapsed = codeTimeSeconds - lastDose.timeSeconds;
        final remaining =
            timing.minIntervalSeconds - elapsed;
        if (remaining > 0) {
          return MedicationEligibility(
            canAdminister: true,
            reason: 'Early: ${_formatSeconds(remaining)} '
                'until recommended interval.',
            secondsUntilEligible: remaining,
          );
        }
      }
    }

    // Check overdue (epi > 5 min since last dose).
    if (med.name == 'Epinephrine') {
      final lastDose = _lastDoseOf(med, doseHistory);
      if (lastDose != null) {
        final elapsed = codeTimeSeconds - lastDose.timeSeconds;
        if (elapsed > 300) {
          return MedicationEligibility(
            canAdminister: true,
            isOverdue: true,
            overdueMessage: 'Epi OVERDUE by '
                '${_formatSeconds(elapsed - 300)}.',
          );
        }
      }
      // No previous dose and code > 60s → epi is due.
      if (lastDose == null && codeTimeSeconds > 60) {
        return const MedicationEligibility(
          canAdminister: true,
          isOverdue: true,
          overdueMessage: 'Epinephrine not yet given.',
        );
      }
    }

    return MedicationEligibility.eligible;
  }

  int _doseCountFor(
    Medication med,
    List<MedicationDoseRecord> history,
  ) {
    return history
        .where((d) =>
            d.medicationName == med.name &&
            d.dose == med.dose)
        .length;
  }

  MedicationDoseRecord? _lastDoseOf(
    Medication med,
    List<MedicationDoseRecord> history,
  ) {
    final doses = history
        .where((d) => d.medicationName == med.name)
        .toList();
    if (doses.isEmpty) return null;
    return doses.last;
  }

  bool _rhythmMatches(String required, ECGRhythm current) {
    if (required == 'torsades') {
      return current == ECGRhythm.torsades;
    }
    return false;
  }

  String _formatSeconds(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/ecg_rhythm_model.dart';
import 'package:acls_simulator/models/patient_model.dart';

void main() {
  group('PatientState', () {
    group('cardiacArrest factory', () {
      test('sets rhythm to provided value', () {
        final state = PatientState.cardiacArrest(ECGRhythm.vf);
        expect(state.rhythm, ECGRhythm.vf);
      });

      test('sets all vitals to arrest state', () {
        final state = PatientState.cardiacArrest(ECGRhythm.pea);
        expect(state.heartRate, 0);
        expect(state.bloodPressure, '--/--');
        expect(state.respiratoryRate, 0);
        expect(state.oxygenSaturation, 0);
        expect(state.hasPulse, isFalse);
        expect(state.isBreathing, isFalse);
        expect(state.isConscious, isFalse);
        expect(state.hasROSC, isFalse);
      });
    });

    group('withROSC factory', () {
      test('sets rhythm to normal sinus', () {
        final state = PatientState.withROSC();
        expect(state.rhythm, ECGRhythm.normalSinus);
      });

      test('sets viable vital signs', () {
        final state = PatientState.withROSC();
        expect(state.heartRate, 75);
        expect(state.bloodPressure, '110/70');
        expect(state.respiratoryRate, 16);
        expect(state.oxygenSaturation, 95);
        expect(state.hasPulse, isTrue);
        expect(state.isBreathing, isTrue);
        expect(state.hasROSC, isTrue);
      });

      test('patient is not conscious after ROSC', () {
        final state = PatientState.withROSC();
        expect(state.isConscious, isFalse);
      });
    });

    group('copyWith', () {
      test('changes only specified fields', () {
        final original = PatientState.cardiacArrest(ECGRhythm.vf);
        final updated = original.copyWith(rhythm: ECGRhythm.pea);

        expect(updated.rhythm, ECGRhythm.pea);
        expect(updated.heartRate, 0);
        expect(updated.hasPulse, isFalse);
        expect(updated.hasROSC, isFalse);
      });

      test('can set hasROSC', () {
        final original = PatientState.cardiacArrest(ECGRhythm.vf);
        final updated = original.copyWith(hasROSC: true);

        expect(updated.hasROSC, isTrue);
        expect(updated.rhythm, ECGRhythm.vf);
      });

      test('preserves all fields when no arguments given', () {
        final state = PatientState.withROSC();
        final copy = state.copyWith();

        expect(copy.rhythm, state.rhythm);
        expect(copy.heartRate, state.heartRate);
        expect(copy.bloodPressure, state.bloodPressure);
        expect(copy.respiratoryRate, state.respiratoryRate);
        expect(copy.oxygenSaturation, state.oxygenSaturation);
        expect(copy.hasPulse, state.hasPulse);
        expect(copy.isBreathing, state.isBreathing);
        expect(copy.isConscious, state.isConscious);
        expect(copy.hasROSC, state.hasROSC);
      });
    });
  });
}

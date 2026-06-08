import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/ecg_rhythm_model.dart';
import 'package:acls_simulator/models/scenario_model.dart';

void main() {
  group('Scenario', () {
    group('predefined scenarios', () {
      test('all returns 8 scenarios', () {
        expect(Scenario.all.length, 8);
      });

      test('all scenarios have unique IDs', () {
        final ids = Scenario.all.map((s) => s.id).toSet();
        expect(ids.length, 8);
      });
    });

    group('vfArrest', () {
      test('has correct ID', () {
        expect(Scenario.vfArrest.id, 'vf_arrest');
      });

      test('uses VF rhythm', () {
        expect(
          Scenario.vfArrest.initialRhythm,
          ECGRhythm.vf,
        );
      });

      test('is beginner difficulty', () {
        expect(
          Scenario.vfArrest.difficulty,
          ScenarioDifficulty.beginner,
        );
      });

      test('has non-empty key actions', () {
        expect(Scenario.vfArrest.keyActions, isNotEmpty);
      });
    });

    group('asystoleArrest', () {
      test('has correct ID', () {
        expect(Scenario.asystoleArrest.id, 'asystole_arrest');
      });

      test('uses asystole rhythm', () {
        expect(
          Scenario.asystoleArrest.initialRhythm,
          ECGRhythm.asystole,
        );
      });

      test('is beginner difficulty', () {
        expect(
          Scenario.asystoleArrest.difficulty,
          ScenarioDifficulty.beginner,
        );
      });
    });

    group('peaArrest', () {
      test('has correct ID', () {
        expect(Scenario.peaArrest.id, 'pea_arrest');
      });

      test('uses PEA rhythm', () {
        expect(
          Scenario.peaArrest.initialRhythm,
          ECGRhythm.pea,
        );
      });

      test('is intermediate difficulty', () {
        expect(
          Scenario.peaArrest.difficulty,
          ScenarioDifficulty.intermediate,
        );
      });
    });

    group('refractoryVF', () {
      test('has correct ID', () {
        expect(Scenario.refractoryVF.id, 'refractory_vf');
      });

      test('uses VF rhythm', () {
        expect(
          Scenario.refractoryVF.initialRhythm,
          ECGRhythm.vf,
        );
      });

      test('is advanced difficulty', () {
        expect(
          Scenario.refractoryVF.difficulty,
          ScenarioDifficulty.advanced,
        );
      });
    });

    group('all scenarios have required fields', () {
      for (final scenario in Scenario.all) {
        test('${scenario.id} has non-empty title', () {
          expect(scenario.title, isNotEmpty);
        });

        test('${scenario.id} has non-empty description', () {
          expect(scenario.description, isNotEmpty);
        });

        test('${scenario.id} has non-empty objectives', () {
          expect(scenario.objectives, isNotEmpty);
        });

        test('${scenario.id} has key actions', () {
          expect(scenario.keyActions, isNotEmpty);
        });
      }
    });
  });
}

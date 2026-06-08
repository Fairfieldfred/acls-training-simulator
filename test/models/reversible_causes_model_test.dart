import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/reversible_causes_model.dart';

void main() {
  group('ReversibleCause', () {
    group('allCauses', () {
      test('contains 12 total causes', () {
        expect(ReversibleCause.allCauses.length, 12);
      });

      test('all have unique IDs', () {
        final ids = ReversibleCause.allCauses.map((c) => c.id).toSet();
        expect(ids.length, 12);
      });
    });

    group('hCauses', () {
      test('contains 6 H causes', () {
        expect(ReversibleCause.hCauses.length, 6);
      });

      test('all have category H', () {
        for (final cause in ReversibleCause.hCauses) {
          expect(cause.category, 'H');
        }
      });

      test('includes expected causes', () {
        final names = ReversibleCause.hCauses.map((c) => c.id).toList();
        expect(names, contains('hypovolemia'));
        expect(names, contains('hypoxia'));
        expect(names, contains('hypothermia'));
      });
    });

    group('tCauses', () {
      test('contains 6 T causes', () {
        expect(ReversibleCause.tCauses.length, 6);
      });

      test('all have category T', () {
        for (final cause in ReversibleCause.tCauses) {
          expect(cause.category, 'T');
        }
      });

      test('includes expected causes', () {
        final names = ReversibleCause.tCauses.map((c) => c.id).toList();
        expect(names, contains('tension'));
        expect(names, contains('tamponade'));
        expect(names, contains('toxins'));
      });
    });

    group('individual causes have required data', () {
      for (final cause in ReversibleCause.allCauses) {
        test('${cause.id} has non-empty signs', () {
          expect(cause.signs, isNotEmpty);
        });

        test('${cause.id} has non-empty treatments', () {
          expect(cause.treatments, isNotEmpty);
        });

        test('${cause.id} has non-empty name', () {
          expect(cause.name, isNotEmpty);
        });

        test('${cause.id} has non-empty description', () {
          expect(cause.description, isNotEmpty);
        });
      }
    });
  });
}

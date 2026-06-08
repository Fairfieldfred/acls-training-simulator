import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/medication_model.dart';

void main() {
  group('Medication', () {
    group('allMedications', () {
      test('contains 10 medications', () {
        expect(Medication.allMedications.length, 10);
      });

      test('includes epinephrine', () {
        final names = Medication.allMedications.map((m) => m.name).toList();
        expect(names, contains('Epinephrine'));
      });

      test('includes both amiodarone doses', () {
        final amiodarones = Medication.allMedications
            .where((m) => m.name == 'Amiodarone')
            .toList();
        expect(amiodarones.length, 2);
      });
    });

    group('quickAccessMeds', () {
      test('contains only quick access medications', () {
        for (final med in Medication.quickAccessMeds) {
          expect(med.isQuickAccess, isTrue);
        }
      });

      test('includes epinephrine', () {
        final names = Medication.quickAccessMeds.map((m) => m.name);
        expect(names, contains('Epinephrine'));
      });

      test('includes amiodarone', () {
        final names = Medication.quickAccessMeds.map((m) => m.name);
        expect(names, contains('Amiodarone'));
      });

      test('includes lidocaine', () {
        final names = Medication.quickAccessMeds.map((m) => m.name);
        expect(names, contains('Lidocaine'));
      });
    });

    group('individual medications', () {
      test('epinephrine has correct dose and route', () {
        expect(Medication.epinephrine.dose, '1 mg');
        expect(Medication.epinephrine.route, 'IV/IO');
      });

      test('amiodarone first dose is 300 mg', () {
        expect(Medication.amiodarone.dose, '300 mg');
      });

      test('amiodarone second dose is 150 mg', () {
        expect(Medication.amiodarone2nd.dose, '150 mg');
        expect(Medication.amiodarone2nd.isQuickAccess, isFalse);
      });

      test('all medications have non-empty fields', () {
        for (final med in Medication.allMedications) {
          expect(med.name, isNotEmpty);
          expect(med.dose, isNotEmpty);
          expect(med.route, isNotEmpty);
          expect(med.indication, isNotEmpty);
        }
      });
    });
  });
}

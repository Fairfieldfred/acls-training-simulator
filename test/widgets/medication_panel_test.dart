import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/models/medication_model.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/widgets/medication_panel.dart';

void main() {
  group('MedicationPanel', () {
    late SimulationService service;

    setUp(() {
      service = SimulationService();
    });

    tearDown(() {
      service.dispose();
    });

    Widget buildWidget() {
      return ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
            child: MedicationPanel(),
          )),
        ),
      );
    }

    testWidgets('renders Medications title', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Medications'), findsOneWidget);
    });

    testWidgets('renders quick access medication buttons', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('Epinephrine'), findsOneWidget);
      expect(find.text('Amiodarone'), findsOneWidget);
      expect(find.text('Lidocaine'), findsOneWidget);
    });

    testWidgets('renders All Meds button', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('All Meds'), findsOneWidget);
    });

    testWidgets('tapping medication administers it', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Epinephrine'));
      await tester.pump();

      expect(
        service.medicationsGiven,
        contains('Epinephrine 1 mg'),
      );
    });

    testWidgets('shows given medications section after admin', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
        service.administerMedication(Medication.epinephrine);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('Given:'), findsOneWidget);
      expect(find.text('Epinephrine 1 mg'), findsOneWidget);
    });
  });
}

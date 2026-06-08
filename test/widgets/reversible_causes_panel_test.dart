import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/widgets/reversible_causes_panel.dart';

void main() {
  group('ReversibleCausesPanel', () {
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
              child: ReversibleCausesPanel(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders H\'s and T\'s title', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text("H's and T's"), findsOneWidget);
    });

    testWidgets('shows checked count chip', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('0/12 checked'), findsOneWidget);
    });

    testWidgets('renders H\'s section header', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(
        find.textContaining("H's"),
        findsWidgets,
      );
    });

    testWidgets('renders T\'s section header', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(
        find.textContaining("T's"),
        findsWidgets,
      );
    });

    testWidgets('renders cause names', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('Hypovolemia'), findsOneWidget);
      expect(find.text('Hypoxia'), findsOneWidget);
    });

    testWidgets('tapping checkbox toggles cause', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      // Find the first checkbox and tap it
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      await tester.tap(checkboxes.first);
      await tester.pump();

      // Verify the service registered the toggle
      final checkedCount =
          service.reversibleCausesChecked.values.where((v) => v).length;
      expect(checkedCount, 1);
    });

    testWidgets('updates chip count after toggling', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
        service.toggleReversibleCause('hypoxia');
        service.toggleReversibleCause('hypovolemia');
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('2/12 checked'), findsOneWidget);
    });
  });
}

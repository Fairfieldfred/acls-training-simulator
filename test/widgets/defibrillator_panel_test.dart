import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/widgets/defibrillator_panel.dart';

void main() {
  group('DefibrillatorPanel', () {
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
          home: Scaffold(body: DefibrillatorPanel()),
        ),
      );
    }

    testWidgets('renders Defibrillator title', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Defibrillator'), findsOneWidget);
    });

    testWidgets('renders energy choice chips', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('120J'), findsOneWidget);
      expect(find.text('150J'), findsOneWidget);
      expect(find.text('200J'), findsOneWidget);
    });

    testWidgets('renders ANALYZE and CHARGE buttons', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('ANALYZE'), findsOneWidget);
      expect(find.text('CHARGE'), findsOneWidget);
    });

    testWidgets('shows SHOCK button with energy', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(find.textContaining('SHOCK'), findsOneWidget);
      expect(find.textContaining('200J'), findsWidgets);
    });

    testWidgets('shows shock count chip after shock', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
        service.chargeDefibrillator();
        async.flushMicrotasks();
        service.deliverShock();
      });
      await tester.pumpWidget(buildWidget());

      expect(find.text('Shocks: 1'), findsOneWidget);
    });

    testWidgets('shows non-shockable warning for PEA rhythm', (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.peaArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(
        find.text('NON-SHOCKABLE RHYTHM - Continue CPR'),
        findsOneWidget,
      );
    });

    testWidgets('does not show non-shockable warning for VF rhythm',
        (tester) async {
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());

      expect(
        find.text('NON-SHOCKABLE RHYTHM - Continue CPR'),
        findsNothing,
      );
    });
  });
}

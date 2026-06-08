import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/widgets/timer_display.dart';

void main() {
  group('TimerDisplay', () {
    testWidgets('displays Code Time and CPR Cycle labels', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SimulationService(),
          child: const MaterialApp(
            home: Scaffold(body: TimerDisplay()),
          ),
        ),
      );

      expect(find.text('Code Time'), findsOneWidget);
      expect(find.text('CPR Cycle'), findsOneWidget);
    });

    testWidgets('displays 00:00 initially', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SimulationService(),
          child: const MaterialApp(
            home: Scaffold(body: TimerDisplay()),
          ),
        ),
      );

      expect(find.text('00:00'), findsNWidgets(2));
    });

    testWidgets('shows warning when CPR cycle >= 120s', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SimulationService service;
      fakeAsync((async) {
        service = SimulationService();
        service.startScenario(Scenario.vfArrest);
        async.elapse(const Duration(seconds: 120));
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: const MaterialApp(
            home: Scaffold(body: TimerDisplay()),
          ),
        ),
      );

      expect(
        find.text('2-minute cycle complete - Check rhythm'),
        findsOneWidget,
      );
      expect(find.text('Reset Cycle'), findsOneWidget);

      service.dispose();
    });

    testWidgets('does not show warning when cycle < 120s', (tester) async {
      late SimulationService service;
      fakeAsync((async) {
        service = SimulationService();
        service.startScenario(Scenario.vfArrest);
        async.elapse(const Duration(seconds: 60));
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: const MaterialApp(
            home: Scaffold(body: TimerDisplay()),
          ),
        ),
      );

      expect(
        find.text('2-minute cycle complete - Check rhythm'),
        findsNothing,
      );

      service.dispose();
    });

    testWidgets('Reset Cycle button calls resetCprCycle', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SimulationService service;
      fakeAsync((async) {
        service = SimulationService();
        service.startScenario(Scenario.vfArrest);
        async.elapse(const Duration(seconds: 120));
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: const MaterialApp(
            home: Scaffold(body: TimerDisplay()),
          ),
        ),
      );

      await tester.tap(find.text('Reset Cycle'));
      await tester.pump();

      expect(service.cprCycleSeconds, 0);

      service.dispose();
    });
  });
}

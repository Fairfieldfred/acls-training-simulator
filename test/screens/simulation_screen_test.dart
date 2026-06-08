import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/models/training_config.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/services/theme_service.dart';
import 'package:acls_simulator/screens/simulation_screen.dart';

void main() {
  group('SimulationScreen', () {
    late SimulationService service;

    setUp(() {
      service = SimulationService();
    });

    tearDown(() {
      service.dispose();
    });

    Widget buildWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider(
            create: (_) => ThemeService(),
          ),
        ],
        child: const MaterialApp(
          home: SimulationScreen(),
        ),
      );
    }

    void setLargeScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('renders scenario title in AppBar', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('VF Cardiac Arrest'), findsOneWidget);
    });

    testWidgets('renders pause button when running', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('renders stop button', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('C key performs compression in timing mode', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(
          Scenario.vfArrest,
          config: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();

      expect(service.compressions, 1);
    });

    testWidgets('B key performs ventilation in timing mode', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(
          Scenario.vfArrest,
          config: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();

      expect(service.ventilations, 1);
    });

    testWidgets('Space key toggles pause', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(service.isRunning, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(service.isRunning, isFalse);
    });

    testWidgets('stop button shows confirmation dialog', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(Scenario.vfArrest);
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(find.text('End Simulation?'), findsOneWidget);
    });

    testWidgets('shows keyboard hints in timing mode', (tester) async {
      setLargeScreen(tester);
      fakeAsync((async) {
        service.startScenario(
          Scenario.vfArrest,
          config: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
      });
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Compress'), findsOneWidget);
      expect(find.text('Breathe'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/services/simulation_service.dart';
import 'package:acls_simulator/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    Widget buildWidget() {
      return ChangeNotifierProvider(
        create: (_) => SimulationService(),
        child: const MaterialApp(home: HomeScreen()),
      );
    }

    testWidgets('renders ACLS title', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('ACLS'), findsOneWidget);
    });

    testWidgets('renders Training Simulator subtitle', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.text('Training Simulator'),
        findsOneWidget,
      );
    });

    testWidgets('renders 2025 AHA Guidelines', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.text('2025 AHA Guidelines'),
        findsOneWidget,
      );
    });

    testWidgets('renders Shockable Arrest category', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.text('Shockable Arrest'),
        findsOneWidget,
      );
    });

    testWidgets('renders VF Cardiac Arrest scenario', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.text('VF Cardiac Arrest'),
        findsOneWidget,
      );
    });

    testWidgets('renders Asystole scenario', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.scrollUntilVisible(
        find.text('Asystole'),
        200,
      );
      expect(find.text('Asystole'), findsOneWidget);
    });

    testWidgets('renders PEA Arrest scenario', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Scroll to find it if not visible
      await tester.scrollUntilVisible(
        find.text('PEA Arrest'),
        200,
      );
      expect(find.text('PEA Arrest'), findsOneWidget);
    });

    testWidgets('renders Refractory VF scenario', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.scrollUntilVisible(
        find.text('Refractory VF'),
        200,
      );
      expect(find.text('Refractory VF'), findsOneWidget);
    });
  });
}

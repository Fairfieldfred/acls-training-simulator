import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:acls_simulator/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full simulation flow', () {
    testWidgets('complete VF arrest scenario end-to-end', (tester) async {
      await tester.pumpWidget(const ACLSSimulatorApp());
      await tester.pumpAndSettle();

      // Verify HomeScreen is visible
      expect(find.text('ACLS'), findsOneWidget);
      expect(
        find.text('Training Simulator'),
        findsOneWidget,
      );

      // Tap VF Cardiac Arrest scenario
      await tester.tap(find.text('VF Cardiac Arrest'));
      await tester.pumpAndSettle();

      // Config bottom sheet should appear
      expect(find.text('Start Simulation'), findsOneWidget);

      // Tap Start Simulation
      await tester.tap(find.text('Start Simulation'));
      await tester.pumpAndSettle();

      // Simulation screen should be visible
      expect(find.text('VF Cardiac Arrest'), findsOneWidget);

      // Verify key controls are present
      expect(find.text('Defibrillator'), findsOneWidget);
      expect(find.text('Medications'), findsOneWidget);

      // Perform some compressions via button tap
      final compressButton = find.text('COMPRESS');
      if (compressButton.evaluate().isNotEmpty) {
        await tester.tap(compressButton);
        await tester.pump();
        await tester.tap(compressButton);
        await tester.pump();
      }

      // Wait a moment for timers
      await tester.pump(const Duration(seconds: 1));

      // Tap stop button to end simulation
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('End Simulation?'), findsOneWidget);

      // Confirm end
      await tester.tap(find.text('End'));
      await tester.pumpAndSettle();

      // Results screen should be visible
      expect(find.text('Performance'), findsWidgets);
    });
  });
}

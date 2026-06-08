import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/ecg_rhythm_model.dart';
import 'package:acls_simulator/widgets/ecg_monitor.dart';

void main() {
  group('ECGMonitor', () {
    for (final rhythm in ECGRhythm.values) {
      testWidgets('renders without error for ${rhythm.name}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ECGMonitor(rhythm: rhythm),
            ),
          ),
        );

        // Pump a few frames to trigger animation
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ECGMonitor), findsOneWidget);
      });
    }

    testWidgets('displays rhythm display name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ECGMonitor(rhythm: ECGRhythm.vf),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.text('Ventricular Fibrillation'),
        findsOneWidget,
      );
    });

    testWidgets('displays heart rate', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ECGMonitor(rhythm: ECGRhythm.normalSinus),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('HR: 75'), findsOneWidget);
    });

    testWidgets('clears data when rhythm changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ECGMonitor(rhythm: ECGRhythm.vf),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Change rhythm
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ECGMonitor(rhythm: ECGRhythm.asystole),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Asystole'), findsOneWidget);
      expect(find.text('HR: 0'), findsOneWidget);
    });
  });
}

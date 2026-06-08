import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acls_simulator/services/simulation_service.dart';

/// Pumps a widget wrapped in MaterialApp and Provider.
///
/// Use [service] to provide a pre-configured SimulationService
/// instance. If null, creates a fresh one.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  SimulationService? service,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SimulationService>(
      create: (_) => service ?? SimulationService(),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

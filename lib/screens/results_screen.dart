import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';
import '../models/performance_model.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SimulationService>();
    final performance = service.calculatePerformance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Score Card
            Card(
              color: _getGradeColor(performance.grade),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Overall Performance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          performance.grade,
                          style: const TextStyle(
                            fontSize: 96,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${performance.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${performance.totalPoints} / ${performance.maxPoints} points',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      performance.feedback,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Performance Metrics Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MetricRow(
                      icon: Icons.timer,
                      label: 'Total Time',
                      value: service.formattedCodeTime,
                    ),
                    _MetricRow(
                      icon: Icons.favorite,
                      label: 'Total Compressions',
                      value: performance.metrics.totalCompressions.toString(),
                    ),
                    _MetricRow(
                      icon: Icons.air,
                      label: 'Total Ventilations',
                      value: performance.metrics.totalVentilations.toString(),
                    ),
                    _MetricRow(
                      icon: Icons.compare_arrows,
                      label: 'CPR Ratio',
                      value: '${performance.metrics.cprRatio.toStringAsFixed(1)}:1',
                    ),
                    _MetricRow(
                      icon: Icons.flash_on,
                      label: 'Shocks Delivered',
                      value: performance.metrics.shocksDelivered.toString(),
                    ),
                    if (performance.metrics.timeToFirstShock > 0)
                      _MetricRow(
                        icon: Icons.speed,
                        label: 'Time to First Shock',
                        value: '${performance.metrics.timeToFirstShock}s',
                      ),
                    _MetricRow(
                      icon: Icons.medication,
                      label: 'Medications Given',
                      value: performance.metrics.medicationsGiven.length.toString(),
                    ),
                    _MetricRow(
                      icon: Icons.psychology,
                      label: 'Airway Device',
                      value: performance.metrics.airwayUsed,
                    ),
                    _MetricRow(
                      icon: Icons.checklist,
                      label: 'Reversible Causes Checked',
                      value: '${performance.metrics.reversibleCausesChecked.values.where((v) => v).length}/12',
                    ),
                    _MetricRow(
                      icon: Icons.celebration,
                      label: 'ROSC',
                      value: performance.metrics.achievedROSC ? 'Yes' : 'No',
                      valueColor: performance.metrics.achievedROSC
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Performance Criteria Details
            const Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...performance.criteria.map((criterion) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    criterion.achieved ? Icons.check_circle : Icons.cancel,
                    color: criterion.achieved ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    criterion.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(criterion.description),
                  trailing: Text(
                    '${criterion.achieved ? criterion.maxPoints : 0}/${criterion.maxPoints}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Medications Given
            if (performance.metrics.medicationsGiven.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medications Administered',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: performance.metrics.medicationsGiven.map((med) {
                          return Chip(
                            label: Text(med),
                            backgroundColor: Colors.green[100],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Restart same scenario
                      final scenario = service.currentScenario;
                      if (scenario != null) {
                        service.startScenario(scenario);
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event_log_model.dart';
import '../services/simulation_service.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SimulationService>();
    final performance = service.calculatePerformance();
    final events = service.eventLog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // Overall Score
            Card(
              color: _gradeColor(performance.grade),
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
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.baseline,
                      textBaseline:
                          TextBaseline.alphabetic,
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
                      '${performance.totalPoints} / '
                      '${performance.maxPoints} points',
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

            // Key Metrics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                      value:
                          service.formattedCodeTime,
                    ),
                    _MetricRow(
                      icon: Icons.favorite,
                      label: 'Total Compressions',
                      value: performance
                          .metrics.totalCompressions
                          .toString(),
                    ),
                    _MetricRow(
                      icon: Icons.air,
                      label: 'Total Ventilations',
                      value: performance
                          .metrics.totalVentilations
                          .toString(),
                    ),
                    _MetricRow(
                      icon: Icons.flash_on,
                      label: 'Shocks Delivered',
                      value: performance
                          .metrics.shocksDelivered
                          .toString(),
                    ),
                    if (performance.metrics
                            .timeToFirstShock >
                        0)
                      _MetricRow(
                        icon: Icons.speed,
                        label: 'Time to First Shock',
                        value:
                            '${performance.metrics.timeToFirstShock}s',
                        benchmark: '< 30s',
                        isGood: performance
                                .metrics
                                .timeToFirstShock <=
                            30,
                      ),
                    if (performance.metrics
                            .timeToFirstEpinephrine >
                        0)
                      _MetricRow(
                        icon: Icons.medication,
                        label: 'Time to First Epi',
                        value:
                            '${performance.metrics.timeToFirstEpinephrine}s',
                        benchmark: '< 300s',
                        isGood: performance
                                .metrics
                                .timeToFirstEpinephrine <=
                            300,
                      ),
                    _MetricRow(
                      icon: Icons.celebration,
                      label: 'ROSC',
                      value: performance
                              .metrics.achievedROSC
                          ? 'Yes'
                          : 'No',
                      valueColor: performance
                              .metrics.achievedROSC
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Breakdown
            const Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...performance.criteria.map((c) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    c.achieved
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: c.achieved
                        ? Colors.green
                        : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(c.description),
                  trailing: Text(
                    '${c.achieved ? c.maxPoints : 0}'
                    '/${c.maxPoints}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Event Timeline
            if (events.isNotEmpty) ...[
              const Text(
                'Event Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: events.map((e) {
                      return _TimelineEvent(event: e);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final scenario =
                          service.currentScenario;
                      if (scenario != null) {
                        service.startScenario(
                          scenario,
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.all(16),
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
                          builder: (context) =>
                              const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.all(16),
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

  Color _gradeColor(String grade) {
    return switch (grade) {
      'A' => Colors.green,
      'B' => Colors.lightGreen,
      'C' => Colors.orange,
      'D' => Colors.deepOrange,
      _ => Colors.red,
    };
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? benchmark;
  final bool? isGood;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.benchmark,
    this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (benchmark != null) ...[
            const SizedBox(width: 8),
            Text(
              '(Target: $benchmark)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isGood == true
                  ? Icons.check
                  : Icons.close,
              size: 16,
              color: isGood == true
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final SimulationEvent event;

  const _TimelineEvent({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(event.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.formattedTime,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: event.isError
                  ? const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    )
                  : null,
              decoration: event.isError
                  ? BoxDecoration(
                      color: Colors.red[50],
                      borderRadius:
                          BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                event.description,
                style: TextStyle(
                  fontSize: 13,
                  color: event.isError
                      ? Colors.red[700]
                      : event.isSuccess
                          ? Colors.green[700]
                          : Colors.grey[800],
                  fontWeight: event.isError ||
                          event.isSuccess
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _catColor(EventCategory cat) {
    return switch (cat) {
      EventCategory.cpr => Colors.blue,
      EventCategory.medication => Colors.purple,
      EventCategory.shock => Colors.orange,
      EventCategory.airway => Colors.indigo,
      EventCategory.assessment => Colors.teal,
      EventCategory.rosc => Colors.green,
      EventCategory.error => Colors.red,
      EventCategory.info => Colors.grey,
    };
  }
}

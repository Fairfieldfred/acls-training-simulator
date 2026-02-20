import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';

class CPRControls extends StatelessWidget {
  const CPRControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final ratio = service.ventilations > 0 ? service.cprRatio : 0.0;
        final targetRatio = 15.0; // 30:2 = 15:1
        final ratioGood = ratio >= 13.0 && ratio <= 17.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CPR Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CPRButton(
                        label: 'COMPRESSION',
                        count: service.compressions,
                        cycleCount: service.currentCycleCompressions,
                        color: Colors.red,
                        onPressed: service.isRunning
                            ? service.performCompression
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CPRButton(
                        label: 'VENTILATION',
                        count: service.ventilations,
                        cycleCount: service.currentCycleVentilations,
                        color: Colors.blue,
                        onPressed: service.isRunning
                            ? service.performVentilation
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (service.ventilations > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Compression:Ventilation Ratio'),
                          Text(
                            '${ratio.toStringAsFixed(1)}:1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ratioGood ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (ratio / (targetRatio * 1.5)).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ratioGood ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: 30:2 (15:1)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CPRButton extends StatelessWidget {
  final String label;
  final int count;
  final int cycleCount;
  final Color color;
  final VoidCallback? onPressed;

  const _CPRButton({
    required this.label,
    required this.count,
    required this.cycleCount,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24),
            minimumSize: const Size(double.infinity, 80),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cycle: $cycleCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

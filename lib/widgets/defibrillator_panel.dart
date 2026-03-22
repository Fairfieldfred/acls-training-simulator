import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ecg_rhythm_model.dart';
import '../services/simulation_service.dart';

class DefibrillatorPanel extends StatelessWidget {
  const DefibrillatorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final isShockable =
            service.patientState.rhythm.isShockable;
        final cprComplete = service.cprCycleComplete;
        final postShock = service.postShockCprSeconds;
        final isProtocol =
            service.trainingConfig.isProtocolMode;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Defibrillator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (service.shockCount > 0)
                      Chip(
                        label: Text(
                          'Shocks: ${service.shockCount}',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Energy selector
                Row(
                  children: [
                    const Text('Energy: '),
                    ...[120, 150, 200].map((joules) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                        ),
                        child: ChoiceChip(
                          label: Text('${joules}J'),
                          selected:
                              service.selectedEnergy ==
                                  joules,
                          onSelected: service.isRunning
                              ? (_) => service.setEnergy(
                                    joules,
                                  )
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: service.isRunning
                            ? service.analyzeRhythm
                            : null,
                        icon: const Icon(
                          Icons.graphic_eq,
                        ),
                        label: const Text('ANALYZE'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: service.isRunning &&
                                !service.isCharging
                            ? service.chargeDefibrillator
                            : null,
                        icon: service.isCharging
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons
                                    .battery_charging_full,
                              ),
                        label: Text(
                          service.isCharging
                              ? 'CHARGING...'
                              : 'CHARGE',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: service.isRunning &&
                                service.isCharging
                            ? service.deliverShock
                            : null,
                        icon: const Icon(Icons.flash_on),
                        label: Text(
                          'SHOCK\n'
                          '${service.selectedEnergy}J',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // Non-shockable warning
                if (!isShockable)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'NON-SHOCKABLE RHYTHM '
                              '- Continue CPR',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // CPR cycle progress bar after shock
                if (service.shockCount > 0 &&
                    !service.patientState.hasROSC) ...[
                  const SizedBox(height: 12),
                  _CprCycleProgress(
                    seconds: postShock,
                    isComplete: cprComplete,
                    isProtocol: isProtocol,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shows CPR cycle progress (0-120s) after a shock.
class _CprCycleProgress extends StatelessWidget {
  final int seconds;
  final bool isComplete;
  final bool isProtocol;

  const _CprCycleProgress({
    required this.seconds,
    required this.isComplete,
    required this.isProtocol,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / 120).clamp(0.0, 1.0);
    final remaining = 120 - seconds;
    final m = remaining.abs() ~/ 60;
    final s = remaining.abs() % 60;
    final timeStr =
        '${m.toString().padLeft(1, '0')}:'
        '${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green[50]
            : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? Colors.green : Colors.blue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? 'CPR Cycle Complete'
                    : 'CPR Cycle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? Colors.green[800]
                      : Colors.blue[800],
                ),
              ),
              Text(
                isComplete
                    ? 'Check rhythm now'
                    : 'Check in: $timeStr',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? Colors.green[800]
                      : Colors.blue[800],
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_model.dart';
import '../models/medication_timing_model.dart';
import '../services/simulation_service.dart';

/// Medication panel with eligibility checking, epi countdown,
/// and early-administration confirmation dialogs.
class MedicationPanel extends StatelessWidget {
  const MedicationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAllMeds(
                        context,
                        service,
                      ),
                      icon: const Icon(Icons.medication),
                      label: const Text('All Meds'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _EpiTimer(service: service),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Medication.quickAccessMeds
                      .map((med) => _MedButton(
                            med: med,
                            service: service,
                          ))
                      .toList(),
                ),
                if (service.medicationsGiven.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const Text(
                    'Given:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: service.doseHistory.map((d) {
                      final color = d.wasEarly
                          ? Colors.orange[100]
                          : Colors.green[100];
                      return Chip(
                        label: Text(
                          d.displayString,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: color,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllMeds(
    BuildContext context,
    SimulationService service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Medications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: Medication
                          .allMedications.length,
                      itemBuilder: (context, index) {
                        final med = Medication
                            .allMedications[index];
                        final elig = service
                            .getMedicationEligibility(med);
                        return Card(
                          child: ListTile(
                            title: Text(
                              med.name,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  '${med.dose} '
                                  '${med.route}',
                                ),
                                Text(
                                  med.indication,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey[600],
                                  ),
                                ),
                                if (!elig.canAdminister)
                                  Text(
                                    elig.reason ?? '',
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed:
                                  service.isRunning &&
                                          elig
                                              .canAdminister
                                      ? () {
                                          _giveMed(
                                            context,
                                            service,
                                            med,
                                            elig,
                                          );
                                          Navigator.pop(
                                            context,
                                          );
                                        }
                                      : null,
                              child: const Text('Give'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _giveMed(
    BuildContext context,
    SimulationService service,
    Medication med,
    MedicationEligibility elig,
  ) {
    if (elig.secondsUntilEligible != null &&
        elig.secondsUntilEligible! > 0) {
      _showEarlyWarning(context, service, med, elig);
    } else {
      service.administerMedication(med);
    }
  }

  void _showEarlyWarning(
    BuildContext context,
    SimulationService service,
    Medication med,
    MedicationEligibility elig,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Protocol Advisory'),
          ],
        ),
        content: Text(
          elig.reason ?? 'Medication given early.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.administerMedication(
                med,
                forceEarly: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Administer Anyway'),
          ),
        ],
      ),
    );
  }
}

// ── Epi countdown timer ──────────────────────────────────

class _EpiTimer extends StatelessWidget {
  final SimulationService service;

  const _EpiTimer({required this.service});

  @override
  Widget build(BuildContext context) {
    final nextDue = service.nextEpiDueSeconds;
    final overdue = service.isEpiOverdue;
    final sinceLastEpi = service.secondsSinceLastEpi;

    // Before first epi.
    if (sinceLastEpi == null && !overdue) {
      return _buildContainer(
        color: Colors.grey,
        text: 'Epi: not yet given',
        icon: Icons.access_time,
      );
    }

    if (overdue) {
      return _EpiOverdueFlasher();
    }

    if (nextDue != null && nextDue > 0) {
      final m = nextDue ~/ 60;
      final s = nextDue % 60;
      final timeStr =
          '${m.toString().padLeft(1, '0')}:'
          '${s.toString().padLeft(2, '0')}';
      return _buildContainer(
        color: Colors.green,
        text: 'Next Epi in: $timeStr',
        icon: Icons.timer,
      );
    }

    // Due window (0 remaining, not yet overdue).
    return _buildContainer(
      color: Colors.green,
      text: 'Epi Due NOW',
      icon: Icons.medication,
    );
  }

  Widget _buildContainer({
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpiOverdueFlasher extends StatefulWidget {
  @override
  State<_EpiOverdueFlasher> createState() =>
      _EpiOverdueFlasherState();
}

class _EpiOverdueFlasherState
    extends State<_EpiOverdueFlasher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final opacity = 0.3 + _ctrl.value * 0.7;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withValues(
              alpha: opacity * 0.2,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withValues(alpha: opacity),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                size: 18,
                color: Colors.red.withValues(
                  alpha: opacity,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Epi OVERDUE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.withValues(
                    alpha: opacity,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Individual medication button ─────────────────────────

class _MedButton extends StatelessWidget {
  final Medication med;
  final SimulationService service;

  const _MedButton({
    required this.med,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final elig = service.getMedicationEligibility(med);
    final canGive = elig.canAdminister && service.isRunning;
    final isEarly = elig.secondsUntilEligible != null &&
        elig.secondsUntilEligible! > 0;
    final isOverdue = elig.isOverdue;

    Color bgColor;
    if (!elig.canAdminister) {
      bgColor = Colors.grey;
    } else if (isOverdue) {
      bgColor = Colors.red;
    } else if (isEarly) {
      bgColor = Colors.orange;
    } else {
      bgColor = Colors.green;
    }

    return Tooltip(
      message: elig.reason ??
          elig.overdueMessage ??
          med.timing.clinicalNote,
      child: ElevatedButton(
        onPressed: canGive
            ? () => _onPressed(context, elig)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Colors.grey.withValues(alpha: 0.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              med.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              med.dose,
              style: const TextStyle(fontSize: 12),
            ),
            if (!elig.canAdminister &&
                elig.reason != null)
              Text(
                _shortReason(elig.reason!),
                style: const TextStyle(fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            if (isEarly)
              Text(
                'Early: ${_fmtSec(elig.secondsUntilEligible!)}',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  void _onPressed(
    BuildContext context,
    MedicationEligibility elig,
  ) {
    if (elig.secondsUntilEligible != null &&
        elig.secondsUntilEligible! > 0) {
      _showEarlyDialog(context, elig);
    } else {
      service.administerMedication(med);
    }
  }

  void _showEarlyDialog(
    BuildContext context,
    MedicationEligibility elig,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Protocol Advisory'),
          ],
        ),
        content: Text(
          elig.reason ?? 'Medication given early.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.administerMedication(
                med,
                forceEarly: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Administer Anyway'),
          ),
        ],
      ),
    );
  }

  String _shortReason(String reason) {
    if (reason.length > 30) {
      return '${reason.substring(0, 27)}...';
    }
    return reason;
  }

  String _fmtSec(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

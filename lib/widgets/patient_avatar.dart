import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reversible_causes_model.dart';
import '../services/simulation_service.dart';

class PatientAvatar extends StatefulWidget {
  const PatientAvatar({super.key});

  @override
  State<PatientAvatar> createState() =>
      _PatientAvatarState();
}

class _PatientAvatarState extends State<PatientAvatar> {
  Timer? _quizTimer;
  Timer? _autoDismissTimer;
  ReversibleCause? _currentQuiz;
  bool _noPressedFlash = false;
  final _random = Random();

  @override
  void dispose() {
    _quizTimer?.cancel();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextQuiz() {
    _quizTimer?.cancel();
    final delay = 15 + _random.nextInt(11);
    _quizTimer = Timer(
      Duration(seconds: delay),
      _showQuiz,
    );
  }

  void _showQuiz() {
    final service = context.read<SimulationService>();
    if (!service.isRunning ||
        service.patientState.hasROSC) {
      return;
    }

    final causes = ReversibleCause.allCauses;
    setState(() {
      _currentQuiz = causes[_random.nextInt(causes.length)];
      _noPressedFlash = false;
    });

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(
      const Duration(seconds: 8),
      _dismissQuiz,
    );
  }

  void _dismissQuiz() {
    _autoDismissTimer?.cancel();
    setState(() => _currentQuiz = null);
    _scheduleNextQuiz();
  }

  void _onNoPressed() {
    setState(() => _noPressedFlash = true);
    Future.delayed(
      const Duration(milliseconds: 400),
      _dismissQuiz,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final patient = service.patientState;

        // Start quiz timer when running, stop on ROSC
        if (service.isRunning && !patient.hasROSC) {
          _quizTimer ??= Timer(
            Duration(seconds: 15 + _random.nextInt(11)),
            _showQuiz,
          );
        }
        if (patient.hasROSC) {
          _quizTimer?.cancel();
          _quizTimer = null;
          _autoDismissTimer?.cancel();
          if (_currentQuiz != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _currentQuiz = null),
            );
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main vitals card
            _VitalsCard(patient: patient),
            // H&T quiz pop-up
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _currentQuiz != null
                  ? _HtQuizCard(
                      key: ValueKey(_currentQuiz!.id),
                      cause: _currentQuiz!,
                      noPressedFlash: _noPressedFlash,
                      onNoPressed: _onNoPressed,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Compact vitals card
// ──────────────────────────────────────────────────────────

class _VitalsCard extends StatelessWidget {
  final dynamic patient;

  const _VitalsCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: patient.hasROSC
          ? Colors.green[50]
          : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 48,
                  color: patient.hasROSC
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _VitalSign(
                        icon: Icons.favorite,
                        label: 'HR',
                        value:
                            patient.heartRate.toString(),
                        color: patient.hasPulse
                            ? Colors.red
                            : Colors.grey,
                      ),
                      _VitalSign(
                        icon: Icons.water_drop,
                        label: 'BP',
                        value: patient.bloodPressure,
                        color: patient.hasPulse
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      _VitalSign(
                        icon: Icons.air,
                        label: 'RR',
                        value: patient.respiratoryRate
                            .toString(),
                        color: patient.isBreathing
                            ? Colors.green
                            : Colors.grey,
                      ),
                      _VitalSign(
                        icon: Icons.spa,
                        label: 'SpO2',
                        value:
                            '${patient.oxygenSaturation}%',
                        color:
                            patient.oxygenSaturation > 90
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _StatusChip(
                  label:
                      patient.hasPulse ? 'Pulse' : 'No Pulse',
                  active: patient.hasPulse,
                ),
                _StatusChip(
                  label: patient.isBreathing
                      ? 'Breathing'
                      : 'Apneic',
                  active: patient.isBreathing,
                ),
                _StatusChip(
                  label: patient.isConscious
                      ? 'Conscious'
                      : 'Unresponsive',
                  active: patient.isConscious,
                ),
              ],
            ),
            if (patient.hasROSC)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ROSC ACHIEVED!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalSign extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VitalSign({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// H&T quiz pop-up card
// ──────────────────────────────────────────────────────────

class _HtQuizCard extends StatelessWidget {
  final ReversibleCause cause;
  final bool noPressedFlash;
  final VoidCallback onNoPressed;

  const _HtQuizCard({
    super.key,
    required this.cause,
    required this.noPressedFlash,
    required this.onNoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber[50],
      elevation: 4,
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Cause info
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          cause.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          cause.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cause.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Yes button (disabled placeholder)
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Yes',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),

            // No button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: noPressedFlash
                    ? [
                        BoxShadow(
                          color: Colors.green
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: FilledButton(
                onPressed:
                    noPressedFlash ? null : onNoPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: noPressedFlash
                      ? Colors.green[300]
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'No',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

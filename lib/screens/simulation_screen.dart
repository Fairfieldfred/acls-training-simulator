import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/simulation_service.dart';
import '../widgets/airway_panel.dart';
import '../widgets/cpr_controls.dart';
import '../widgets/defibrillator_panel.dart';
import '../widgets/ecg_monitor.dart';
import '../widgets/event_log_panel.dart';
import '../widgets/medication_panel.dart';
import '../widgets/patient_avatar.dart';
import '../widgets/reference_panel.dart';
import '../widgets/reversible_causes_panel.dart';
import '../widgets/timer_display.dart';
import 'post_rosc_screen.dart';
import 'results_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() =>
      _SimulationScreenState();
}

class _SimulationScreenState
    extends State<SimulationScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _showReference = false;
  bool _roscNavigated = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final service = context.read<SimulationService>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyC) {
      service.performCompression();
    } else if (key == LogicalKeyboardKey.keyB) {
      service.performVentilation();
    } else if (key == LogicalKeyboardKey.space) {
      service.pauseResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Consumer<SimulationService>(
        builder: (context, service, child) {
          final isProtocol =
              service.trainingConfig.isProtocolMode;
          final isPulsed =
              service.patientState.hasPulse &&
              !service.patientState.hasROSC;

          // Navigate to post-ROSC when ROSC achieved.
          if (service.patientState.hasROSC &&
              !_roscNavigated) {
            _roscNavigated = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PostRoscScreen(),
                ),
              );
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                service.currentScenario?.title ??
                    'ACLS Simulation',
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _showReference
                        ? Icons.menu_book
                        : Icons.menu_book_outlined,
                  ),
                  onPressed: () => setState(
                    () => _showReference =
                        !_showReference,
                  ),
                  tooltip: 'Reference',
                ),
                IconButton(
                  icon: Icon(
                    service.isRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: service.pauseResume,
                  tooltip: service.isRunning
                      ? 'Pause'
                      : 'Resume',
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => _endSimulation(
                    context,
                    service,
                  ),
                  tooltip: 'End Simulation',
                ),
              ],
            ),
            body: Column(
              children: [
                _KeyboardHintBar(
                  isProtocol: isProtocol,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Expanded(
                              child: ECGMonitor(
                                rhythm: service
                                    .patientState
                                    .rhythm,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            const Expanded(
                              flex: 2,
                              child:
                                  PatientAvatar(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const TimerDisplay(),
                        const SizedBox(height: 16),
                        if (!isPulsed)
                          const CPRControls(),
                        if (!isPulsed)
                          const SizedBox(
                            height: 16,
                          ),
                        const DefibrillatorPanel(),
                        const SizedBox(height: 16),
                        const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Expanded(
                              child:
                                  MedicationPanel(),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AirwayPanel(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const
                            ReversibleCausesPanel(),
                        const SizedBox(height: 16),
                        if (_showReference)
                          const ReferencePanel(),
                        if (_showReference)
                          const SizedBox(
                            height: 16,
                          ),
                        const EventLogPanel(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _endSimulation(
    BuildContext context,
    SimulationService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Simulation?'),
        content: const Text(
          'Are you sure you want to end this '
          'simulation and view your performance?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.endScenario();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ResultsScreen(),
                ),
              );
            },
            child: const Text('End Simulation'),
          ),
        ],
      ),
    );
  }
}

class _KeyboardHintBar extends StatelessWidget {
  final bool isProtocol;

  const _KeyboardHintBar({
    required this.isProtocol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.keyboard,
            size: 16,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          if (!isProtocol) ...[
            const _KeyChip(
              label: 'C',
              action: 'Compress',
            ),
            const SizedBox(width: 12),
            const _KeyChip(
              label: 'B',
              action: 'Breathe',
            ),
            const SizedBox(width: 12),
          ],
          if (isProtocol)
            Text(
              'CPR Auto  ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          const _KeyChip(
            label: 'Space',
            action: 'Pause',
          ),
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String label;
  final String action;

  const _KeyChip({
    required this.label,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

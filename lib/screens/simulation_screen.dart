import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';
import '../widgets/ecg_monitor.dart';
import '../widgets/timer_display.dart';
import '../widgets/cpr_controls.dart';
import '../widgets/defibrillator_panel.dart';
import '../widgets/medication_panel.dart';
import '../widgets/reversible_causes_panel.dart';
import '../widgets/patient_avatar.dart';
import '../widgets/airway_panel.dart';
import 'results_screen.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(service.currentScenario?.title ?? 'ACLS Simulation'),
            actions: [
              IconButton(
                icon: Icon(service.isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: service.pauseResume,
                tooltip: service.isRunning ? 'Pause' : 'Resume',
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _endSimulation(context, service),
                tooltip: 'End Simulation',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient and ECG Monitor
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ECGMonitor(rhythm: service.patientState.rhythm),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 1,
                      child: PatientAvatar(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timers
                const TimerDisplay(),
                const SizedBox(height: 16),

                // CPR Controls
                const CPRControls(),
                const SizedBox(height: 16),

                // Defibrillator
                const DefibrillatorPanel(),
                const SizedBox(height: 16),

                // Medications and Airway in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: MedicationPanel()),
                    SizedBox(width: 16),
                    Expanded(child: AirwayPanel()),
                  ],
                ),
                const SizedBox(height: 16),

                // Reversible Causes
                const ReversibleCausesPanel(),
                const SizedBox(height: 80), // Extra space at bottom
              ],
            ),
          ),
        );
      },
    );
  }

  void _endSimulation(BuildContext context, SimulationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Simulation?'),
        content: const Text('Are you sure you want to end this simulation and view your performance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.endScenario();
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultsScreen(),
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

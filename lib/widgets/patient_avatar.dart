import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final patient = service.patientState;

        return Card(
          color: patient.hasROSC ? Colors.green[50] : Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 80,
                      color: patient.hasROSC ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _VitalSign(
                          icon: Icons.favorite,
                          label: 'HR',
                          value: patient.heartRate.toString(),
                          color: patient.hasPulse ? Colors.red : Colors.grey,
                        ),
                        _VitalSign(
                          icon: Icons.water_drop,
                          label: 'BP',
                          value: patient.bloodPressure,
                          color: patient.hasPulse ? Colors.blue : Colors.grey,
                        ),
                        _VitalSign(
                          icon: Icons.air,
                          label: 'RR',
                          value: patient.respiratoryRate.toString(),
                          color: patient.isBreathing ? Colors.green : Colors.grey,
                        ),
                        _VitalSign(
                          icon: Icons.spa,
                          label: 'SpO2',
                          value: '${patient.oxygenSaturation}%',
                          color: patient.oxygenSaturation > 90
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        patient.hasPulse ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      label: Text(patient.hasPulse ? 'Pulse' : 'No Pulse'),
                      backgroundColor: patient.hasPulse ? Colors.green : Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    Chip(
                      avatar: Icon(
                        patient.isBreathing ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      label: Text(patient.isBreathing ? 'Breathing' : 'Not Breathing'),
                      backgroundColor: patient.isBreathing ? Colors.green : Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    Chip(
                      avatar: Icon(
                        patient.isConscious ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      label: Text(patient.isConscious ? 'Conscious' : 'Unconscious'),
                      backgroundColor: patient.isConscious ? Colors.green : Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                if (patient.hasROSC)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.celebration, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'ROSC ACHIEVED!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
      },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

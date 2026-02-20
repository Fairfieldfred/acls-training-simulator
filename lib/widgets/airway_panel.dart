import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';

class AirwayPanel extends StatelessWidget {
  const AirwayPanel({super.key});

  static const airwayDevices = [
    {'name': 'BVM', 'fullName': 'Bag-Valve-Mask', 'icon': Icons.masks},
    {'name': 'King LT', 'fullName': 'King Laryngeal Tube', 'icon': Icons.linear_scale},
    {'name': 'i-gel', 'fullName': 'i-gel Supraglottic Airway', 'icon': Icons.trip_origin},
    {'name': 'ETT', 'fullName': 'Endotracheal Tube', 'icon': Icons.psychology},
  ];

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
                const Text(
                  'Airway Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Current Device:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: airwayDevices.map((device) {
                    final isSelected = service.airwayDevice == device['name'];
                    return ChoiceChip(
                      avatar: Icon(
                        device['icon'] as IconData,
                        color: isSelected ? Colors.white : null,
                      ),
                      label: Text(device['name'] as String),
                      selected: isSelected,
                      onSelected: service.isRunning
                          ? (_) => service.setAirwayDevice(device['name'] as String)
                          : null,
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        airwayDevices.firstWhere(
                          (d) => d['name'] == service.airwayDevice,
                        )['fullName'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_getDeviceDescription(service.airwayDevice)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDeviceDescription(String device) {
    switch (device) {
      case 'BVM':
        return 'Basic airway device. Requires 2-person technique for optimal ventilation. Pause compressions for ventilations (30:2 ratio).';
      case 'King LT':
        return 'Supraglottic airway device. Easy to insert, minimal training required. Allows continuous compressions with asynchronous ventilation (10 breaths/min).';
      case 'i-gel':
        return 'Supraglottic airway with anatomic seal. Quick insertion, no cuff inflation needed. Allows continuous compressions.';
      case 'ETT':
        return 'Gold standard definitive airway. Requires skilled provider. Provides best airway protection. Allows continuous compressions with 10 breaths/min.';
      default:
        return '';
    }
  }
}

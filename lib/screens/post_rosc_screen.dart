import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_service.dart';
import 'results_screen.dart';

/// Post-ROSC care management phase after achieving ROSC.
class PostRoscScreen extends StatefulWidget {
  const PostRoscScreen({super.key});

  @override
  State<PostRoscScreen> createState() =>
      _PostRoscScreenState();
}

class _PostRoscScreenState extends State<PostRoscScreen> {
  double _o2Percentage = 100;
  int _sbp = 80;
  int _o2Sat = 88;
  bool _ecgObtained = false;
  bool _stemiDetected = false;
  bool _cathLabActivated = false;
  bool _tempManaged = false;
  bool _vasopressorGiven = false;
  int _postRoscScore = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _stemiDetected = _random.nextBool();
  }

  void _optimizeO2(double value) {
    setState(() {
      _o2Percentage = value;
      // Target SpO2 94-99%
      if (value <= 60) {
        _o2Sat = 88 + (value / 60 * 8).round();
      } else if (value <= 80) {
        _o2Sat = 96;
      } else {
        _o2Sat = 100;
      }
    });
  }

  void _giveVasopressor() {
    if (_vasopressorGiven) return;
    setState(() {
      _vasopressorGiven = true;
      _sbp = 95 + _random.nextInt(20);
      _postRoscScore += 20;
    });
  }

  void _obtain12Lead() {
    setState(() {
      _ecgObtained = true;
      _postRoscScore += 15;
    });
  }

  void _activateCathLab() {
    if (!_ecgObtained || !_stemiDetected) return;
    setState(() {
      _cathLabActivated = true;
      _postRoscScore += 25;
    });
  }

  void _manageTemperature() {
    setState(() {
      _tempManaged = true;
      _postRoscScore += 15;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SimulationService>();
    final hyperoxia = _o2Percentage > 80;
    final o2Good = _o2Sat >= 94 && _o2Sat <= 99;

    if (o2Good && !hyperoxia) {
      // only add once
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-ROSC Care'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[700],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ROSC Achieved',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Post-Cardiac Arrest Care',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vitals display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _VitalBox(
                      label: 'BP',
                      value: '$_sbp/50',
                      color: _sbp > 90
                          ? Colors.green
                          : Colors.red,
                    ),
                    _VitalBox(
                      label: 'SpO2',
                      value: '$_o2Sat%',
                      color: o2Good
                          ? Colors.green
                          : Colors.orange,
                    ),
                    _VitalBox(
                      label: 'HR',
                      value: '75',
                      color: Colors.green,
                    ),
                    _VitalBox(
                      label: 'Temp',
                      value: _tempManaged
                          ? '36.0°C'
                          : '37.8°C',
                      color: _tempManaged
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // O2 optimization
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          o2Good
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: o2Good
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Optimize Oxygen '
                          '(Target SpO2 94-99%)',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('FiO2: '),
                        Expanded(
                          child: Slider(
                            value: _o2Percentage,
                            min: 21,
                            max: 100,
                            divisions: 79,
                            label:
                                '${_o2Percentage.round()}%',
                            onChanged: _optimizeO2,
                          ),
                        ),
                        Text(
                          '${_o2Percentage.round()}%',
                        ),
                      ],
                    ),
                    if (hyperoxia)
                      Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hyperoxia associated '
                                'with worse outcomes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vasopressor
            Card(
              child: ListTile(
                leading: Icon(
                  _vasopressorGiven
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: _vasopressorGiven
                      ? Colors.green
                      : _sbp < 90
                          ? Colors.red
                          : Colors.grey,
                ),
                title: const Text(
                  'Target SBP > 90 mmHg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _vasopressorGiven
                      ? 'Norepinephrine started'
                      : 'Start vasopressor',
                ),
                trailing: ElevatedButton(
                  onPressed: _vasopressorGiven
                      ? null
                      : _giveVasopressor,
                  child: const Text(
                    'Norepinephrine',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 12-lead ECG
            Card(
              child: ListTile(
                leading: Icon(
                  _ecgObtained
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: _ecgObtained
                      ? Colors.green
                      : Colors.grey,
                ),
                title: const Text(
                  'Obtain 12-Lead ECG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: _ecgObtained
                    ? Text(
                        _stemiDetected
                            ? 'STEMI pattern detected'
                            : 'No STEMI',
                        style: TextStyle(
                          color: _stemiDetected
                              ? Colors.red
                              : Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      )
                    : null,
                trailing: ElevatedButton(
                  onPressed: _ecgObtained
                      ? null
                      : _obtain12Lead,
                  child: const Text('Obtain'),
                ),
              ),
            ),

            // Cath lab
            if (_ecgObtained && _stemiDetected)
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                ),
                child: Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading: Icon(
                      _cathLabActivated
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: _cathLabActivated
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: const Text(
                      'Activate Cath Lab',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _cathLabActivated
                          ? null
                          : _activateCathLab,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor:
                            Colors.white,
                      ),
                      child: const Text('Activate'),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Temperature management
            Card(
              child: ListTile(
                leading: Icon(
                  _tempManaged
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: _tempManaged
                      ? Colors.green
                      : Colors.grey,
                ),
                title: const Text(
                  'Temperature Management '
                  '(Target 36°C)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: _tempManaged
                      ? null
                      : _manageTemperature,
                  child: const Text('Initiate'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transfer button
            FilledButton.icon(
              onPressed: () {
                service.endScenario();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ResultsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.local_hospital,
              ),
              label: const Text(
                'Transfer to ICU',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VitalBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

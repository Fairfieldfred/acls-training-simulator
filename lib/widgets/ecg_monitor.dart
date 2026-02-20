import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ecg_rhythm_model.dart';

class ECGMonitor extends StatefulWidget {
  final ECGRhythm rhythm;

  const ECGMonitor({super.key, required this.rhythm});

  @override
  State<ECGMonitor> createState() => _ECGMonitorState();
}

class _ECGMonitorState extends State<ECGMonitor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FlSpot> _dataPoints = [];
  int _pointIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        setState(() {
          _updateWaveform();
        });
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateWaveform() {
    final newPoint = _generatePoint(_pointIndex);
    _dataPoints.add(newPoint);

    if (_dataPoints.length > 100) {
      _dataPoints.removeAt(0);
    }

    _pointIndex++;
  }

  FlSpot _generatePoint(int index) {
    final x = index.toDouble();
    double y;

    switch (widget.rhythm) {
      case ECGRhythm.vf:
        // Chaotic, irregular waveform
        y = (Random().nextDouble() - 0.5) * 2.0;
        break;

      case ECGRhythm.pvt:
        // Fast, wide QRS complexes
        final pos = index % 10;
        y = pos == 5 ? 1.5 : 0.0;
        break;

      case ECGRhythm.pea:
        // Organized rhythm (looks like normal but no pulse)
        y = _normalSinusPattern(index);
        break;

      case ECGRhythm.asystole:
        // Flat line with minimal artifact
        y = (Random().nextDouble() - 0.5) * 0.1;
        break;

      case ECGRhythm.normalSinus:
        // Normal PQRST pattern
        y = _normalSinusPattern(index);
        break;
    }

    return FlSpot(x, y);
  }

  double _normalSinusPattern(int index) {
    final pos = index % 60; // One heartbeat every 60 points (~75 bpm)

    if (pos < 5) {
      // P wave
      return sin(pos * pi / 5) * 0.3;
    } else if (pos >= 10 && pos < 20) {
      // QRS complex
      if (pos == 13) return -0.3; // Q
      if (pos == 15) return 1.5;  // R
      if (pos == 17) return -0.2; // S
      return 0.0;
    } else if (pos >= 25 && pos < 40) {
      // T wave
      return sin((pos - 25) * pi / 15) * 0.5;
    }

    return 0.0; // Baseline
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.rhythm.displayName,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'HR: ${widget.rhythm.heartRate}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _dataPoints.isEmpty
                ? const SizedBox()
                : LineChart(
                    LineChartData(
                      minY: -2,
                      maxY: 2,
                      minX: _dataPoints.first.x,
                      maxX: _dataPoints.last.x,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: widget.rhythm == ECGRhythm.vf,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      titlesData: const FlTitlesData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.5,
                        verticalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.green.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.green.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

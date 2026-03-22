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

class _ECGMonitorState extends State<ECGMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Store only y-values; x is derived from index.
  final List<double> _yValues = [];
  int _sampleIndex = 0;

  // Show 120 samples = ~3 beats at 75 bpm.
  static const _maxSamples = 120;

  // Normal sinus: 40 samples/beat = 75 bpm.
  static const _sinusCycle = 40;

  // pVT: 14 samples/beat ≈ 214 bpm.
  static const _pvtCycle = 14;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    )..addListener(_tick);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(ECGMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rhythm != widget.rhythm) {
      _yValues.clear();
      _sampleIndex = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    setState(() {
      _yValues.add(_generateY(_sampleIndex));
      if (_yValues.length > _maxSamples) {
        _yValues.removeAt(0);
      }
      _sampleIndex++;
    });
  }

  double _generateY(int index) {
    return switch (widget.rhythm) {
      ECGRhythm.vf => _vfPattern(),
      ECGRhythm.pvt => _pvtPattern(index),
      ECGRhythm.torsades => _torsadesPattern(index),
      ECGRhythm.pea => _sinusPattern(index),
      ECGRhythm.asystole => _asystolePattern(),
      ECGRhythm.normalSinus => _sinusPattern(index),
    };
  }

  double _torsadesPattern(int index) {
    const cycle = 15;
    final pos = index % cycle;
    final t = pos / cycle;
    final envelope = sin(index / 60 * pi);
    return sin(t * 2 * pi) * (0.5 + envelope.abs() * 1.0);
  }

  double _vfPattern() =>
      (_random.nextDouble() - 0.5) * 2.0;

  double _asystolePattern() =>
      (_random.nextDouble() - 0.5) * 0.1;

  double _pvtPattern(int index) {
    final pos = index % _pvtCycle;
    final t = pos / _pvtCycle;
    if (t < 0.7) return sin(t / 0.7 * pi) * 1.5;
    return 0.0;
  }

  double _sinusPattern(int index) {
    final pos = index % _sinusCycle;
    final t = pos / _sinusCycle;

    if (t < 0.10) return sin(t / 0.10 * pi) * 0.25;
    if (t < 0.18) return 0.0;
    if (t < 0.32) {
      final qrs = (t - 0.18) / 0.14;
      if (qrs < 0.25) {
        return -0.3 * sin(qrs / 0.25 * pi);
      }
      if (qrs < 0.50) {
        return 1.6 * sin((qrs - 0.25) / 0.25 * pi);
      }
      if (qrs < 0.75) {
        return -0.4 * sin((qrs - 0.50) / 0.25 * pi);
      }
      return 0.0;
    }
    if (t < 0.42) return 0.0;
    if (t < 0.62) {
      return sin((t - 0.42) / 0.20 * pi) * 0.4;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Build FlSpots with x = 0..N from the y-values.
    // This keeps x values small regardless of session
    // length, avoiding precision issues in fl_chart.
    final spots = <FlSpot>[];
    for (var i = 0; i < _yValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), _yValues[i]));
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.green,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.rhythm.displayName,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'HR: ${widget.rhythm.heartRate}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: spots.isEmpty
                ? const SizedBox()
                : LineChart(
                    LineChartData(
                      minY: -1,
                      maxY: 2,
                      minX: 0,
                      maxX: _maxSamples.toDouble(),
                      clipData: const FlClipData.all(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved:
                              widget.rhythm ==
                              ECGRhythm.vf,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: const FlDotData(
                            show: false,
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        show: false,
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.5,
                        verticalInterval:
                            _sinusCycle.toDouble(),
                        getDrawingHorizontalLine:
                            (value) {
                          return FlLine(
                            color: Colors.green
                                .withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine:
                            (value) {
                          return FlLine(
                            color: Colors.green
                                .withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData:
                          FlBorderData(show: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

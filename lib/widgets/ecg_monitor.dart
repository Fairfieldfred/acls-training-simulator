import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ecg_rhythm_model.dart';

/// ECG monitor with clinically accurate waveform generation.
///
/// Sample rate: 50 samples/second (20 ms tick).
class ECGMonitor extends StatefulWidget {
  final ECGRhythm rhythm;

  const ECGMonitor({super.key, required this.rhythm});

  @override
  State<ECGMonitor> createState() => _ECGMonitorState();
}

class _ECGMonitorState extends State<ECGMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<double> _yValues = [];
  int _sampleIndex = 0;

  static const _maxSamples = 120;
  static const _sampleRate = 50;

  final _random = Random(42);

  // Pre-computed irregular RR for afib.
  static const _afibCycles = [
    38, 45, 32, 51, 39, 44, 36, 48, 41, 37,
  ];

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
      ECGRhythm.vf => _vfPattern(index),
      ECGRhythm.pvt => _pvtPattern(index),
      ECGRhythm.torsades => _torsadesPattern(index),
      ECGRhythm.pea => _peaPattern(index),
      ECGRhythm.asystole => _asystolePattern(),
      ECGRhythm.aivr => _aivrPattern(index),
      ECGRhythm.normalSinus =>
        _sinusPattern(index, bpm: 75),
      ECGRhythm.sinusBradycardia =>
        _sinusPattern(index, bpm: 40),
      ECGRhythm.sinusTachycardia =>
        _sinusPattern(index, bpm: 120),
      ECGRhythm.svt => _svtPattern(index),
      ECGRhythm.afib => _afibPattern(index),
      ECGRhythm.aflutter => _aflutterPattern(index),
      ECGRhythm.vtachPulsed => _vtachPattern(index),
      ECGRhythm.avBlock1 =>
        _avBlock1Pattern(index),
      ECGRhythm.avBlock2Mobitz2 =>
        _avBlock2Mobitz2Pattern(index),
      ECGRhythm.avBlock3 => _avBlock3Pattern(index),
      ECGRhythm.junctional =>
        _junctionalPattern(index),
    };
  }

  // ── Normal sinus pattern (parameterized BPM) ──────────

  double _sinusPattern(int index, {required int bpm}) {
    final cycleLen = (60.0 / bpm * _sampleRate).round();
    final pos = index % cycleLen;
    final t = pos / cycleLen;

    // P-wave: 0.00–0.10
    if (t < 0.10) {
      return sin(t / 0.10 * pi) * 0.15;
    }
    // PR segment: 0.10–0.18
    if (t < 0.18) return 0.0;
    // QRS complex: 0.18–0.30
    if (t < 0.30) {
      final qrs = (t - 0.18) / 0.12;
      if (qrs < 0.20) {
        return -0.3 * sin(qrs / 0.20 * pi);
      }
      if (qrs < 0.50) {
        return 1.5 * sin((qrs - 0.20) / 0.30 * pi);
      }
      if (qrs < 0.75) {
        return -0.35 * sin((qrs - 0.50) / 0.25 * pi);
      }
      return 0.0;
    }
    // ST segment: 0.30–0.42
    if (t < 0.42) return 0.0;
    // T-wave: 0.42–0.62 (asymmetric)
    if (t < 0.62) {
      final tw = (t - 0.42) / 0.20;
      if (tw < 0.6) {
        return sin(tw / 0.6 * pi * 0.5) * 0.35;
      }
      return cos((tw - 0.6) / 0.4 * pi * 0.5) * 0.35;
    }
    return 0.0;
  }

  // ── VF — chaotic with envelope ────────────────────────

  double _vfPattern(int index) {
    final base = (_random.nextDouble() - 0.5) * 2.0;
    final envelope = 0.7 + sin(index / 80.0) * 0.3;
    final periodic = sin(index / 5.0) * 0.3;
    return (base + periodic) * envelope;
  }

  // ── Asystole — near-flat with slight noise ────────────

  double _asystolePattern() {
    return (_random.nextDouble() - 0.5) * 0.08;
  }

  // ── Pulseless VT — sinusoidal with beat variation ─────

  double _pvtPattern(int index) {
    const cycle = 14;
    final pos = index % cycle;
    final t = pos / cycle;
    final ampVar = 1.2 + sin(index * 0.3) * 0.3;
    if (t < 0.7) return sin(t / 0.7 * pi) * ampVar;
    return 0.0;
  }

  // ── Torsades — waxing/waning sinusoidal ───────────────

  double _torsadesPattern(int index) {
    const cycle = 15;
    final pos = index % cycle;
    final t = pos / cycle;
    final envelope = sin(index / 60.0 * pi);
    return sin(t * 2 * pi) * (0.5 + envelope.abs() * 1.0);
  }

  // ── PEA — small sinus-like at 60bpm ───────────────────

  double _peaPattern(int index) {
    return _sinusPattern(index, bpm: 60) * 0.3;
  }

  // ── AIVR — wide QRS at 55–70bpm ──────────────────────

  double _aivrPattern(int index) {
    const cycleLen = 55; // ~55bpm
    final pos = index % cycleLen;
    final t = pos / cycleLen;
    // Wide QRS (no P-wave)
    if (t < 0.12) {
      return sin(t / 0.12 * pi) * 1.0;
    }
    if (t < 0.20) {
      return -sin((t - 0.12) / 0.08 * pi) * 0.4;
    }
    if (t < 0.45) return 0.0;
    if (t < 0.60) {
      return sin((t - 0.45) / 0.15 * pi) * 0.25;
    }
    return 0.0;
  }

  // ── SVT — narrow QRS, no P, ~200bpm ───────────────────

  double _svtPattern(int index) {
    final cycleLen = (60.0 / 200 * _sampleRate).round();
    final pos = index % cycleLen;
    final t = pos / cycleLen;
    // No P-wave, narrow QRS
    if (t < 0.30) {
      final qrs = t / 0.30;
      if (qrs < 0.20) {
        return -0.2 * sin(qrs / 0.20 * pi);
      }
      if (qrs < 0.50) {
        return 1.3 * sin((qrs - 0.20) / 0.30 * pi);
      }
      if (qrs < 0.75) {
        return -0.3 * sin((qrs - 0.50) / 0.25 * pi);
      }
      return 0.0;
    }
    if (t < 0.65) return 0.0;
    if (t < 0.90) {
      return sin((t - 0.65) / 0.25 * pi) * 0.2;
    }
    return 0.0;
  }

  // ── AFib — irregular RR, no P-waves ───────────────────

  double _afibPattern(int index) {
    // Determine which beat we're in using irregular cycles.
    int cum = 0;
    int cycleIdx = 0;
    for (int i = 0; i < 1000; i++) {
      final c = _afibCycles[i % _afibCycles.length];
      if (index < cum + c) {
        cycleIdx = i;
        break;
      }
      cum += c;
    }
    final cycle = _afibCycles[cycleIdx % _afibCycles.length];
    final pos = (index - cum).abs() % cycle;
    final t = pos / cycle;

    // Fibrillatory baseline noise instead of P-wave.
    final fib = sin(index * 1.7) * 0.04 +
        sin(index * 2.3) * 0.03;

    // QRS
    if (t >= 0.20 && t < 0.40) {
      final qrs = (t - 0.20) / 0.20;
      if (qrs < 0.25) {
        return fib + -0.25 * sin(qrs / 0.25 * pi);
      }
      if (qrs < 0.55) {
        return fib + 1.4 * sin((qrs - 0.25) / 0.30 * pi);
      }
      if (qrs < 0.80) {
        return fib + -0.3 * sin((qrs - 0.55) / 0.25 * pi);
      }
      return fib;
    }
    // T-wave
    if (t >= 0.50 && t < 0.70) {
      return fib +
          sin((t - 0.50) / 0.20 * pi) * 0.3;
    }
    return fib;
  }

  // ── Atrial Flutter — sawtooth + QRS every 4th ─────────

  double _aflutterPattern(int index) {
    // Sawtooth at 300bpm: cycle = 10 samples.
    const sawCycle = 10;
    final sawPos = index % sawCycle;
    final sawT = sawPos / sawCycle;
    // Linear ramp -0.3 to +0.3 then sharp drop.
    final saw = -0.3 + sawT * 0.6;

    // QRS every 4th sawtooth (75bpm).
    const ventCycle = 40;
    final ventPos = index % ventCycle;
    final ventT = ventPos / ventCycle;
    if (ventT >= 0.10 && ventT < 0.25) {
      final qrs = (ventT - 0.10) / 0.15;
      if (qrs < 0.30) {
        return saw + 1.5 * sin(qrs / 0.30 * pi);
      }
      if (qrs < 0.60) {
        return saw +
            -0.4 * sin((qrs - 0.30) / 0.30 * pi);
      }
      return saw;
    }
    return saw;
  }

  // ── VT with pulse — monomorphic wide QRS ──────────────

  double _vtachPattern(int index) {
    final cycleLen = (60.0 / 170 * _sampleRate).round();
    final pos = index % cycleLen;
    final t = pos / cycleLen;
    // Wide QRS: 0.12s
    if (t < 0.35) {
      final qrs = t / 0.35;
      if (qrs < 0.15) {
        return -0.2 * sin(qrs / 0.15 * pi);
      }
      if (qrs < 0.50) {
        return 1.3 * sin((qrs - 0.15) / 0.35 * pi);
      }
      if (qrs < 0.75) {
        return -0.5 * sin((qrs - 0.50) / 0.25 * pi);
      }
      return 0.0;
    }
    if (t < 0.60) return 0.0;
    if (t < 0.80) {
      return sin((t - 0.60) / 0.20 * pi) * 0.3;
    }
    return 0.0;
  }

  // ── 1st degree AV block — prolonged PR ────────────────

  double _avBlock1Pattern(int index) {
    final cycleLen = (60.0 / 70 * _sampleRate).round();
    final pos = index % cycleLen;
    final t = pos / cycleLen;

    // P-wave: 0.00–0.08
    if (t < 0.08) {
      return sin(t / 0.08 * pi) * 0.15;
    }
    // Prolonged PR segment: 0.08–0.25
    if (t < 0.25) return 0.0;
    // QRS: 0.25–0.35
    if (t < 0.35) {
      final qrs = (t - 0.25) / 0.10;
      if (qrs < 0.20) {
        return -0.25 * sin(qrs / 0.20 * pi);
      }
      if (qrs < 0.55) {
        return 1.4 * sin((qrs - 0.20) / 0.35 * pi);
      }
      if (qrs < 0.80) {
        return -0.35 * sin((qrs - 0.55) / 0.25 * pi);
      }
      return 0.0;
    }
    if (t < 0.48) return 0.0;
    if (t < 0.65) {
      return sin((t - 0.48) / 0.17 * pi) * 0.3;
    }
    return 0.0;
  }

  // ── Mobitz II — fixed PR, dropped QRS ─────────────────

  double _avBlock2Mobitz2Pattern(int index) {
    // P-waves at 70bpm. QRS every 2nd P (2:1 block).
    final pCycle = (60.0 / 70 * _sampleRate).round();
    final ventCycle = pCycle * 2; // 35bpm
    final pPos = index % pCycle;
    final pT = pPos / pCycle;
    final ventPos = index % ventCycle;
    final isQrsBeat = ventPos < pCycle;

    // P-wave always present.
    if (pT < 0.08) {
      return sin(pT / 0.08 * pi) * 0.15;
    }

    // QRS only on conducted beats.
    if (isQrsBeat && pT >= 0.16 && pT < 0.28) {
      final qrs = (pT - 0.16) / 0.12;
      if (qrs < 0.20) {
        return -0.25 * sin(qrs / 0.20 * pi);
      }
      if (qrs < 0.55) {
        return 1.4 * sin((qrs - 0.20) / 0.35 * pi);
      }
      if (qrs < 0.80) {
        return -0.35 * sin((qrs - 0.55) / 0.25 * pi);
      }
      return 0.0;
    }

    // T-wave only on conducted beats.
    if (isQrsBeat && pT >= 0.38 && pT < 0.55) {
      return sin((pT - 0.38) / 0.17 * pi) * 0.25;
    }

    return 0.0;
  }

  // ── 3rd degree (complete) AV block ────────────────────

  double _avBlock3Pattern(int index) {
    // P-waves at 70bpm, independent QRS at 35bpm.
    final pCycle = (60.0 / 70 * _sampleRate).round();
    final qrsCycle = (60.0 / 35 * _sampleRate).round();

    double y = 0.0;

    // P-wave layer.
    final pPos = index % pCycle;
    final pT = pPos / pCycle;
    if (pT < 0.10) {
      y += sin(pT / 0.10 * pi) * 0.15;
    }

    // QRS layer (independent).
    final qrsPos = index % qrsCycle;
    final qrsT = qrsPos / qrsCycle;
    if (qrsT >= 0.10 && qrsT < 0.22) {
      final q = (qrsT - 0.10) / 0.12;
      if (q < 0.20) {
        y += -0.3 * sin(q / 0.20 * pi);
      } else if (q < 0.55) {
        y += 1.4 * sin((q - 0.20) / 0.35 * pi);
      } else if (q < 0.80) {
        y += -0.35 * sin((q - 0.55) / 0.25 * pi);
      }
    }
    // T-wave for QRS.
    if (qrsT >= 0.30 && qrsT < 0.45) {
      y += sin((qrsT - 0.30) / 0.15 * pi) * 0.3;
    }

    return y;
  }

  // ── Junctional — no P-wave, narrow QRS at 50bpm ──────

  double _junctionalPattern(int index) {
    final cycleLen = (60.0 / 50 * _sampleRate).round();
    final pos = index % cycleLen;
    final t = pos / cycleLen;
    // No P-wave (or very small inverted P just before QRS).
    if (t >= 0.08 && t < 0.12) {
      return -sin((t - 0.08) / 0.04 * pi) * 0.08;
    }
    // Narrow QRS.
    if (t >= 0.12 && t < 0.24) {
      final qrs = (t - 0.12) / 0.12;
      if (qrs < 0.20) {
        return -0.25 * sin(qrs / 0.20 * pi);
      }
      if (qrs < 0.55) {
        return 1.4 * sin((qrs - 0.20) / 0.35 * pi);
      }
      if (qrs < 0.80) {
        return -0.3 * sin((qrs - 0.55) / 0.25 * pi);
      }
      return 0.0;
    }
    if (t >= 0.35 && t < 0.52) {
      return sin((t - 0.35) / 0.17 * pi) * 0.3;
    }
    return 0.0;
  }

  // ── Widget build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < _yValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), _yValues[i]));
    }

    final isTorsades = widget.rhythm == ECGRhythm.torsades;

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
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.rhythm.displayName,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isTorsades)
                      const Text(
                        'TORSADES',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
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
                        verticalInterval: 40,
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

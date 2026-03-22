import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_config.dart';
import '../services/simulation_service.dart';

/// CPR controls panel that adapts to training mode.
///
/// In **timing mode**: manual compress/breathe buttons with
/// a visual metronome and live compression-rate readout.
///
/// In **protocol mode**: an animated auto-CPR status
/// indicator showing compressions ticking up automatically.
class CPRControls extends StatelessWidget {
  const CPRControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        if (service.patientState.hasROSC) {
          return _RoscPanel(service: service);
        }

        final config = service.trainingConfig;
        if (config.isProtocolMode) {
          return _AutoCprPanel(service: service);
        }
        return _ManualCprPanel(service: service);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// ROSC achieved: CPR stopped
// ──────────────────────────────────────────────────────────

class _RoscPanel extends StatelessWidget {
  final SimulationService service;

  const _RoscPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'CPR Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STOPPED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.check_circle,
              color: Colors.green[700],
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Spontaneous pulse and respirations '
              'detected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CPR stopped \u2014 begin post-ROSC care',
              style: TextStyle(
                fontSize: 13,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                _StatBox(
                  label: 'Total Compressions',
                  value:
                      service.compressions.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'Total Ventilations',
                  value:
                      service.ventilations.toString(),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Protocol mode: auto-CPR status indicator
// ──────────────────────────────────────────────────────────

class _AutoCprPanel extends StatelessWidget {
  final SimulationService service;

  const _AutoCprPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    final ratio = service.trainingConfig.cprRatio;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CPR Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated heartbeat indicator
            const _AutoCprHeartbeat(),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatBox(
                  label: 'Compressions',
                  value: service.compressions.toString(),
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'Ventilations',
                  value: service.ventilations.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'Ratio',
                  value: ratio.displayName,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoCprHeartbeat extends StatefulWidget {
  const _AutoCprHeartbeat();

  @override
  State<_AutoCprHeartbeat> createState() =>
      _AutoCprHeartbeatState();
}

class _AutoCprHeartbeatState
    extends State<_AutoCprHeartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red[200]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'CPR in progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Timing mode: manual buttons + metronome + rate display
// ──────────────────────────────────────────────────────────

class _ManualCprPanel extends StatelessWidget {
  final SimulationService service;

  const _ManualCprPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    final config = service.trainingConfig;
    final ratio = config.cprRatio;
    final isContinuous = ratio == CprRatio.continuous;

    final cprRatioValue =
        service.ventilations > 0 ? service.cprRatio : 0.0;

    final (minR, maxR) = ratio.acceptableRange;
    final ratioGood = isContinuous ||
        (cprRatioValue >= minR && cprRatioValue <= maxR);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CPR Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Metronome
            const _Metronome(),
            const SizedBox(height: 12),

            // Compression rate readout
            _CompressionRate(service: service),
            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _CPRButton(
                    label: 'COMPRESS',
                    keyHint: 'C',
                    count: service.compressions,
                    cycleCount:
                        service.currentCycleCompressions,
                    color: Colors.red,
                    onPressed: service.isRunning
                        ? service.performCompression
                        : null,
                  ),
                ),
                if (!isContinuous) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CPRButton(
                      label: 'BREATHE',
                      keyHint: 'B',
                      count: service.ventilations,
                      cycleCount:
                          service
                              .currentCycleVentilations,
                      color: Colors.blue,
                      onPressed: service.isRunning
                          ? service.performVentilation
                          : null,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Ratio indicator
            if (!isContinuous &&
                service.ventilations > 0)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Compression:Ventilation Ratio',
                      ),
                      Text(
                        '${cprRatioValue.toStringAsFixed(1)}:1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ratioGood
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (cprRatioValue /
                            (ratio.targetRatio * 1.5))
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      ratioGood
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${ratio.displayName} '
                    '(${ratio.targetRatio.toStringAsFixed(1)}:1)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Visual metronome at 110 bpm
// ──────────────────────────────────────────────────────────

class _Metronome extends StatefulWidget {
  const _Metronome();

  @override
  State<_Metronome> createState() => _MetronomeState();
}

class _MetronomeState extends State<_Metronome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 110 bpm = 545ms per beat
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SimulationService>();
    if (!service.isRunning) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(
                  alpha: 0.3 + _animation.value * 0.7,
                ),
                Colors.green.withValues(
                  alpha: 0.3 +
                      (1 - _animation.value) * 0.7,
                ),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _animation.value *
                    (MediaQuery.of(context).size.width -
                        80),
                child: Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(4),
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

// ──────────────────────────────────────────────────────────
// Live compression rate (per minute, last 10 seconds)
// ──────────────────────────────────────────────────────────

class _CompressionRate extends StatelessWidget {
  final SimulationService service;

  const _CompressionRate({required this.service});

  @override
  Widget build(BuildContext context) {
    final rate = service.compressionRate.round();
    final isGood = rate >= 100 && rate <= 120;
    final color = rate == 0
        ? Colors.grey
        : isGood
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$rate /min',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'target 100-120',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// CPR button with keyboard hint
// ──────────────────────────────────────────────────────────

class _CPRButton extends StatelessWidget {
  final String label;
  final String keyHint;
  final int count;
  final int cycleCount;
  final Color color;
  final VoidCallback? onPressed;

  const _CPRButton({
    required this.label,
    required this.keyHint,
    required this.count,
    required this.cycleCount,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 24),
            minimumSize:
                const Size(double.infinity, 80),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: Text(
                      keyHint,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cycle: $cycleCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

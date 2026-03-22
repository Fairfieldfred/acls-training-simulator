import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ecg_rhythm_model.dart';
import '../models/scenario_model.dart';
import '../models/training_config.dart';
import '../services/simulation_service.dart';
import 'simulation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = Scenario.byCategory;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACLS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Training Simulator',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2025 AHA Guidelines',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      for (final cat
                          in ScenarioCategory.values)
                        if (grouped.containsKey(cat))
                          _CategorySection(
                            category: cat,
                            scenarios: grouped[cat]!,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ScenarioCategory category;
  final List<Scenario> scenarios;

  const _CategorySection({
    required this.category,
    required this.scenarios,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (category) {
      ScenarioCategory.shockableArrest => (
          Icons.flash_on,
          'Shockable Arrest',
        ),
      ScenarioCategory.nonShockableArrest => (
          Icons.heart_broken,
          'Non-Shockable Arrest',
        ),
      ScenarioCategory.tachycardia => (
          Icons.speed,
          'Tachycardia',
        ),
      ScenarioCategory.bradycardia => (
          Icons.slow_motion_video,
          'Bradycardia',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        ...scenarios.map((s) => _ScenarioCard(
              scenario: s,
            )),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;

  const _ScenarioCard({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showConfigSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      scenario.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _DifficultyBadge(
                    difficulty: scenario.difficulty,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                scenario.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Objectives:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.objectives,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: scenario.keyActions
                    .map((action) {
                  return Chip(
                    label: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    visualDensity:
                        VisualDensity.compact,
                    backgroundColor:
                        Colors.green[100],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfigSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return _TrainingConfigSheet(
          scenario: scenario,
          onStart: (config) {
            Navigator.pop(sheetContext);
            final service =
                context.read<SimulationService>();
            service.startScenario(
              scenario,
              config: config,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SimulationScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainingConfigSheet extends StatefulWidget {
  final Scenario scenario;
  final ValueChanged<TrainingConfig> onStart;

  const _TrainingConfigSheet({
    required this.scenario,
    required this.onStart,
  });

  @override
  State<_TrainingConfigSheet> createState() =>
      _TrainingConfigSheetState();
}

class _TrainingConfigSheetState
    extends State<_TrainingConfigSheet> {
  TrainingFocus _focus = TrainingFocus.timing;
  CprRatio _ratio = CprRatio.ratio30to2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPulsed =
        widget.scenario.initialRhythm.hasPulse;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.scenario.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (!isPulsed) ...[
            Text(
              'Training Focus',
              style:
                  theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TrainingFocus>(
              segments: const [
                ButtonSegment(
                  value: TrainingFocus.timing,
                  label: Text('CPR Timing'),
                  icon: Icon(Icons.timer),
                ),
                ButtonSegment(
                  value: TrainingFocus.protocol,
                  label: Text('Protocol'),
                  icon: Icon(Icons.checklist),
                ),
              ],
              selected: {_focus},
              onSelectionChanged: (selected) {
                setState(
                  () => _focus = selected.first,
                );
              },
            ),
            const SizedBox(height: 8),
            _FocusDescription(focus: _focus),
            const SizedBox(height: 20),
            Text(
              'Compression : Ventilation Ratio',
              style:
                  theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<CprRatio>(
              segments: const [
                ButtonSegment(
                  value: CprRatio.ratio30to2,
                  label: Text('30:2'),
                ),
                ButtonSegment(
                  value: CprRatio.ratio15to2,
                  label: Text('15:2'),
                ),
                ButtonSegment(
                  value: CprRatio.continuous,
                  label: Text('Continuous'),
                ),
              ],
              selected: {_ratio},
              onSelectionChanged: (selected) {
                setState(
                  () => _ratio = selected.first,
                );
              },
            ),
            const SizedBox(height: 8),
            _RatioDescription(ratio: _ratio),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This scenario involves a '
                      'patient with a pulse. CPR '
                      'controls will be hidden.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keyboard: C = Compress, '
                    'B = Breathe, Space = Pause',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              widget.onStart(TrainingConfig(
                focus: isPulsed
                    ? TrainingFocus.protocol
                    : _focus,
                cprRatio: _ratio,
              ));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Simulation'),
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
    );
  }
}

class _FocusDescription extends StatelessWidget {
  final TrainingFocus focus;

  const _FocusDescription({required this.focus});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (focus) {
      TrainingFocus.timing => (
          Icons.speed,
          'Practice compression rate and ratio '
              'timing. Press C and B keys with '
              'correct rhythm.',
        ),
      TrainingFocus.protocol => (
          Icons.medical_services,
          'CPR runs automatically so you can focus '
              'on medication timing, shock decisions, '
              "and identifying reversible causes.",
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatioDescription extends StatelessWidget {
  final CprRatio ratio;

  const _RatioDescription({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final text = switch (ratio) {
      CprRatio.ratio30to2 =>
        'Standard adult: 30 compressions, '
            'pause for 2 breaths.',
      CprRatio.ratio15to2 =>
        'Pediatric / two-rescuer: 15 '
            'compressions, pause for 2 breaths.',
      CprRatio.continuous =>
        'Continuous compressions with no pause '
            '(advanced airway in place).',
    };

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final ScenarioDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      ScenarioDifficulty.beginner =>
        (Colors.green, 'Beginner'),
      ScenarioDifficulty.intermediate =>
        (Colors.orange, 'Intermediate'),
      ScenarioDifficulty.advanced =>
        (Colors.red, 'Advanced'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

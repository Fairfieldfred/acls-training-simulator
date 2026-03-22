import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reversible_causes_model.dart';
import '../services/simulation_service.dart';

class ReversibleCausesPanel extends StatelessWidget {
  const ReversibleCausesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final checkedCount =
            service.reversibleCausesChecked.values.where((v) => v).length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'H\'s and T\'s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('$checkedCount/12 checked'),
                      backgroundColor:
                          checkedCount >= 6 ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ExpansionPanelList(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  children: [
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        final hCount = ReversibleCause.hCauses
                            .where((c) =>
                                service.reversibleCausesChecked[c.id] ?? false)
                            .length;
                        return ListTile(
                          title: Text(
                            'H\'s ($hCount/${ReversibleCause.hCauses.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      body: Column(
                        children: ReversibleCause.hCauses.map((cause) {
                          return _CauseCheckbox(
                            cause: cause,
                            checked:
                                service.reversibleCausesChecked[cause.id] ??
                                    false,
                            onChanged: service.isRunning
                                ? (_) => service.toggleReversibleCause(cause.id)
                                : null,
                          );
                        }).toList(),
                      ),
                      isExpanded: true,
                      canTapOnHeader: true,
                    ),
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        final tCount = ReversibleCause.tCauses
                            .where((c) =>
                                service.reversibleCausesChecked[c.id] ?? false)
                            .length;
                        return ListTile(
                          title: Text(
                            'T\'s ($tCount/${ReversibleCause.tCauses.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      body: Column(
                        children: ReversibleCause.tCauses.map((cause) {
                          return _CauseCheckbox(
                            cause: cause,
                            checked:
                                service.reversibleCausesChecked[cause.id] ??
                                    false,
                            onChanged: service.isRunning
                                ? (_) => service.toggleReversibleCause(cause.id)
                                : null,
                          );
                        }).toList(),
                      ),
                      isExpanded: true,
                      canTapOnHeader: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CauseCheckbox extends StatelessWidget {
  final ReversibleCause cause;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  const _CauseCheckbox({
    required this.cause,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Checkbox(
        value: checked,
        onChanged: onChanged,
      ),
      title: Text(
        cause.name,
        style: TextStyle(
          fontWeight: checked ? FontWeight.bold : FontWeight.normal,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(cause.description),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Signs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...cause.signs.map((sign) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• $sign'),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Treatments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...cause.treatments.map((treatment) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• $treatment'),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

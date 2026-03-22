import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_log_model.dart';
import '../services/simulation_service.dart';

/// Scrolling real-time event log with color-coded categories.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key});

  @override
  State<EventLogPanel> createState() =>
      _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> {
  final _scrollController = ScrollController();
  bool _isExpanded = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationService>(
      builder: (context, service, child) {
        final events = service.eventLog;

        // Auto-scroll when new events arrive.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _isExpanded = !_isExpanded,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Event Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${events.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: events.isEmpty
                        ? Center(
                            child: Text(
                              'No events yet',
                              style: TextStyle(
                                color:
                                    Colors.grey[400],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller:
                                _scrollController,
                            itemCount: events.length,
                            itemBuilder:
                                (context, index) {
                              return _EventRow(
                                event: events[index],
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  final SimulationEvent event;

  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(event.category);
    final textColor = event.isError
        ? Colors.red
        : event.isSuccess
            ? Colors.green[700]
            : Colors.grey[800];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.formattedTime,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.description,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: event.isError ||
                        event.isSuccess
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(EventCategory cat) {
    return switch (cat) {
      EventCategory.cpr => Colors.blue,
      EventCategory.medication => Colors.purple,
      EventCategory.shock => Colors.orange,
      EventCategory.airway => Colors.indigo,
      EventCategory.assessment => Colors.teal,
      EventCategory.rosc => Colors.green,
      EventCategory.error => Colors.red,
      EventCategory.info => Colors.grey,
    };
  }
}

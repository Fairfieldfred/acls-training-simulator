/// Categories for simulation events.
enum EventCategory {
  cpr,
  medication,
  shock,
  airway,
  assessment,
  rosc,
  error,
  info,
}

/// A single timestamped event during a simulation.
class SimulationEvent {
  final int timeSeconds;
  final String description;
  final EventCategory category;
  final bool isError;
  final bool isSuccess;

  const SimulationEvent({
    required this.timeSeconds,
    required this.description,
    required this.category,
    this.isError = false,
    this.isSuccess = false,
  });

  /// Formatted time as MM:SS.
  String get formattedTime {
    final m = timeSeconds ~/ 60;
    final s = timeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

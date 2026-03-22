import 'training_config.dart';

class PerformanceCriteria {
  final String id;
  final String name;
  final String description;
  final int maxPoints;
  final bool achieved;

  const PerformanceCriteria({
    required this.id,
    required this.name,
    required this.description,
    required this.maxPoints,
    this.achieved = false,
  });

  PerformanceCriteria copyWith({bool? achieved}) {
    return PerformanceCriteria(
      id: id,
      name: name,
      description: description,
      maxPoints: maxPoints,
      achieved: achieved ?? this.achieved,
    );
  }
}

class PerformanceMetrics {
  final int totalCompressions;
  final int totalVentilations;
  final double cprRatio;
  final int shocksDelivered;
  final int timeToFirstShock;
  final List<String> medicationsGiven;
  final int timeToFirstEpinephrine;
  final bool achievedROSC;
  final int totalTimeSeconds;
  final Map<String, bool> reversibleCausesChecked;
  final String airwayUsed;

  const PerformanceMetrics({
    this.totalCompressions = 0,
    this.totalVentilations = 0,
    this.cprRatio = 0,
    this.shocksDelivered = 0,
    this.timeToFirstShock = 0,
    this.medicationsGiven = const [],
    this.timeToFirstEpinephrine = 0,
    this.achievedROSC = false,
    this.totalTimeSeconds = 0,
    this.reversibleCausesChecked = const {},
    this.airwayUsed = 'BVM',
  });

  PerformanceMetrics copyWith({
    int? totalCompressions,
    int? totalVentilations,
    double? cprRatio,
    int? shocksDelivered,
    int? timeToFirstShock,
    List<String>? medicationsGiven,
    int? timeToFirstEpinephrine,
    bool? achievedROSC,
    int? totalTimeSeconds,
    Map<String, bool>? reversibleCausesChecked,
    String? airwayUsed,
  }) {
    return PerformanceMetrics(
      totalCompressions:
          totalCompressions ?? this.totalCompressions,
      totalVentilations:
          totalVentilations ?? this.totalVentilations,
      cprRatio: cprRatio ?? this.cprRatio,
      shocksDelivered:
          shocksDelivered ?? this.shocksDelivered,
      timeToFirstShock:
          timeToFirstShock ?? this.timeToFirstShock,
      medicationsGiven:
          medicationsGiven ?? this.medicationsGiven,
      timeToFirstEpinephrine:
          timeToFirstEpinephrine ??
              this.timeToFirstEpinephrine,
      achievedROSC: achievedROSC ?? this.achievedROSC,
      totalTimeSeconds:
          totalTimeSeconds ?? this.totalTimeSeconds,
      reversibleCausesChecked: reversibleCausesChecked ??
          this.reversibleCausesChecked,
      airwayUsed: airwayUsed ?? this.airwayUsed,
    );
  }
}

class PerformanceScore {
  final List<PerformanceCriteria> criteria;
  final PerformanceMetrics metrics;

  const PerformanceScore({
    required this.criteria,
    required this.metrics,
  });

  int get totalPoints => criteria.fold(
      0, (sum, c) => sum + (c.achieved ? c.maxPoints : 0));

  int get maxPoints =>
      criteria.fold(0, (sum, c) => sum + c.maxPoints);

  double get percentage =>
      maxPoints > 0 ? (totalPoints / maxPoints) * 100 : 0;

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  String get feedback {
    if (percentage >= 90) {
      return 'Excellent! You demonstrated mastery of '
          'ACLS protocols.';
    }
    if (percentage >= 80) {
      return 'Good job! Minor improvements needed.';
    }
    if (percentage >= 70) {
      return 'Satisfactory. Review key protocols '
          'and try again.';
    }
    if (percentage >= 60) {
      return 'Needs improvement. Focus on '
          'critical actions.';
    }
    return 'Unsatisfactory. Please review ACLS '
        'guidelines thoroughly.';
  }

  static PerformanceScore calculate(
    PerformanceMetrics metrics,
    String scenarioId, {
    TrainingConfig trainingConfig = const TrainingConfig(),
  }) {
    final criteria = <PerformanceCriteria>[];
    final isProtocol = trainingConfig.isProtocolMode;
    final isTiming = trainingConfig.isTimingMode;
    final ratio = trainingConfig.cprRatio;

    // Time to first shock (for shockable rhythms)
    if (scenarioId == 'vf_arrest' ||
        scenarioId == 'refractory_vf') {
      criteria.add(PerformanceCriteria(
        id: 'time_to_shock',
        name: 'Early Defibrillation',
        description: 'Shock delivered within 60 seconds',
        maxPoints: isProtocol ? 25 : 20,
        achieved: metrics.timeToFirstShock > 0 &&
            metrics.timeToFirstShock <= 60,
      ));
    }

    // CPR quality — skip in protocol mode (auto-CPR)
    if (!isProtocol &&
        ratio != CprRatio.continuous) {
      final (minR, maxR) = ratio.acceptableRange;
      criteria.add(PerformanceCriteria(
        id: 'cpr_quality',
        name: 'CPR Quality',
        description:
            'Maintained ${ratio.displayName} ratio',
        maxPoints: isTiming ? 20 : 15,
        achieved: metrics.cprRatio >= minR &&
            metrics.cprRatio <= maxR,
      ));
    }

    // Adequate compressions — skip in protocol mode
    if (!isProtocol) {
      criteria.add(PerformanceCriteria(
        id: 'compression_count',
        name: 'Adequate Compressions',
        description:
            'Performed sufficient compressions '
            '(>100/min average)',
        maxPoints: isTiming ? 15 : 10,
        achieved: metrics.totalCompressions >=
            (metrics.totalTimeSeconds / 60 * 100),
      ));
    }

    // Epinephrine timing
    criteria.add(PerformanceCriteria(
      id: 'epi_timing',
      name: 'Epinephrine Timing',
      description: 'First dose within 3-5 minutes',
      maxPoints: isProtocol ? 20 : 15,
      achieved: metrics.timeToFirstEpinephrine > 0 &&
          metrics.timeToFirstEpinephrine <= 300,
    ));

    // Appropriate medications
    if (scenarioId == 'vf_arrest' ||
        scenarioId == 'refractory_vf') {
      criteria.add(PerformanceCriteria(
        id: 'antiarrhythmic',
        name: 'Antiarrhythmic Given',
        description:
            'Amiodarone or Lidocaine administered',
        maxPoints: isProtocol ? 15 : 10,
        achieved: metrics.medicationsGiven.any((m) =>
            m.toLowerCase().contains('amiodarone') ||
            m.toLowerCase().contains('lidocaine')),
      ));
    }

    // Reversible causes
    criteria.add(PerformanceCriteria(
      id: 'reversible_causes',
      name: "H's and T's Considered",
      description: 'Checked at least 6 reversible causes',
      maxPoints: isProtocol ? 20 : 15,
      achieved: metrics.reversibleCausesChecked.values
              .where((v) => v)
              .length >=
          6,
    ));

    // Airway management
    criteria.add(PerformanceCriteria(
      id: 'airway',
      name: 'Airway Management',
      description:
          'Advanced airway placed when appropriate',
      maxPoints: 10,
      achieved: metrics.airwayUsed != 'BVM',
    ));

    // ROSC achievement
    criteria.add(PerformanceCriteria(
      id: 'rosc',
      name: 'ROSC Achieved',
      description: 'Successfully achieved return of '
          'spontaneous circulation',
      maxPoints: 15,
      achieved: metrics.achievedROSC,
    ));

    return PerformanceScore(
      criteria: criteria,
      metrics: metrics,
    );
  }
}

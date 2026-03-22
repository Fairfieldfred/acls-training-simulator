/// Training focus modes for the ACLS simulator.
enum TrainingFocus {
  /// Practice CPR timing, rate, and compression-to-breath ratio.
  timing,

  /// Practice protocol decisions: meds, shocks, and H&T's.
  /// CPR runs automatically so the user can focus on decisions.
  protocol,
}

/// Selectable compression-to-ventilation ratios.
enum CprRatio {
  /// Standard adult ratio: 30 compressions then 2 breaths.
  ratio30to2(compressions: 30, ventilations: 2),

  /// Pediatric / two-rescuer ratio: 15 compressions then 2 breaths.
  ratio15to2(compressions: 15, ventilations: 2),

  /// Continuous compressions with no pause for ventilation
  /// (used with advanced airway in place).
  continuous(compressions: 0, ventilations: 0);

  const CprRatio({
    required this.compressions,
    required this.ventilations,
  });

  /// Number of compressions before pausing for breaths.
  final int compressions;

  /// Number of ventilations per cycle.
  final int ventilations;

  /// Display label shown in the UI.
  String get displayName {
    return switch (this) {
      CprRatio.ratio30to2 => '30:2',
      CprRatio.ratio15to2 => '15:2',
      CprRatio.continuous => 'Continuous',
    };
  }

  /// The ideal ratio value (compressions / ventilations).
  /// Returns 0 for continuous (no ratio to maintain).
  double get targetRatio {
    if (ventilations == 0) return 0;
    return compressions / ventilations;
  }

  /// Acceptable range around the target ratio for scoring.
  (double min, double max) get acceptableRange {
    return switch (this) {
      CprRatio.ratio30to2 => (13.0, 17.0),
      CprRatio.ratio15to2 => (6.0, 9.0),
      CprRatio.continuous => (0, 0),
    };
  }
}

/// Configuration selected before starting a simulation.
class TrainingConfig {
  final TrainingFocus focus;
  final CprRatio cprRatio;

  const TrainingConfig({
    this.focus = TrainingFocus.timing,
    this.cprRatio = CprRatio.ratio30to2,
  });

  bool get isTimingMode => focus == TrainingFocus.timing;
  bool get isProtocolMode => focus == TrainingFocus.protocol;
}

/// Configuration parameters governing interval calculation and ease factor adaptation.
class SchedulerParameters {
  /// Default ease factor assigned to newly created flashcards.
  final double startingEase;

  /// Absolute minimum allowable ease factor to prevent ease depression.
  final double floorEase;

  /// Interval in days assigned to the first successful review (streak 0 -> 1).
  final int initialStepDays;

  /// Interval in days assigned to the second successful review (streak 1 -> 2).
  final int graduatingStepDays;

  /// Additional multiplier applied to interval growth when rating as easy.
  final double easyMultiplier;

  /// Multiplier applied to interval growth when rating as hard.
  final double hardMultiplier;

  /// Upper bound cap on scheduled intervals in days.
  final int ceilingIntervalDays;

  /// Creates an immutable [SchedulerParameters] configuration.
  const SchedulerParameters({
    this.startingEase = 2.5,
    this.floorEase = 1.3,
    this.initialStepDays = 1,
    this.graduatingStepDays = 6,
    this.easyMultiplier = 1.3,
    this.hardMultiplier = 1.15,
    this.ceilingIntervalDays = 36500,
  })  : assert(startingEase >= 1.3, 'startingEase must be at least 1.3'),
        assert(floorEase >= 1.1, 'floorEase must be at least 1.1'),
        assert(initialStepDays >= 1, 'initialStepDays must be at least 1'),
        assert(
            graduatingStepDays >= 1, 'graduatingStepDays must be at least 1'),
        assert(easyMultiplier >= 1.0, 'easyMultiplier must be at least 1.0'),
        assert(hardMultiplier >= 1.0, 'hardMultiplier must be at least 1.0'),
        assert(
          ceilingIntervalDays >= 1,
          'ceilingIntervalDays must be at least 1',
        );

  /// Creates a copy of this configuration with the specified fields replaced.
  SchedulerParameters copyWith({
    double? startingEase,
    double? floorEase,
    int? initialStepDays,
    int? graduatingStepDays,
    double? easyMultiplier,
    double? hardMultiplier,
    int? ceilingIntervalDays,
  }) {
    return SchedulerParameters(
      startingEase: startingEase ?? this.startingEase,
      floorEase: floorEase ?? this.floorEase,
      initialStepDays: initialStepDays ?? this.initialStepDays,
      graduatingStepDays: graduatingStepDays ?? this.graduatingStepDays,
      easyMultiplier: easyMultiplier ?? this.easyMultiplier,
      hardMultiplier: hardMultiplier ?? this.hardMultiplier,
      ceilingIntervalDays: ceilingIntervalDays ?? this.ceilingIntervalDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchedulerParameters &&
        other.startingEase == startingEase &&
        other.floorEase == floorEase &&
        other.initialStepDays == initialStepDays &&
        other.graduatingStepDays == graduatingStepDays &&
        other.easyMultiplier == easyMultiplier &&
        other.hardMultiplier == hardMultiplier &&
        other.ceilingIntervalDays == ceilingIntervalDays;
  }

  @override
  int get hashCode => Object.hash(
        startingEase,
        floorEase,
        initialStepDays,
        graduatingStepDays,
        easyMultiplier,
        hardMultiplier,
        ceilingIntervalDays,
      );

  @override
  String toString() => 'SchedulerParameters('
      'startingEase: $startingEase, '
      'floorEase: $floorEase, '
      'initialStepDays: $initialStepDays, '
      'graduatingStepDays: $graduatingStepDays, '
      'easyMultiplier: $easyMultiplier, '
      'hardMultiplier: $hardMultiplier, '
      'ceilingIntervalDays: $ceilingIntervalDays)';
}

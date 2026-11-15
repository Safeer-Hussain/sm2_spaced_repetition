import 'dart:math' as math;

/// Immutable representation of a flashcard's spaced repetition schedule state.
class MemoryCardSnapshot {
  /// Unique identifier of the card.
  final String id;

  /// Number of consecutive successful recall reviews.
  final int streak;

  /// Current interval in days until the next scheduled review.
  final int intervalDays;

  /// Current ease multiplier governing interval expansion.
  final double easeFactor;

  /// Coordinated Universal Time (UTC) timestamp when the card was last reviewed.
  final DateTime? lastReviewedUtc;

  /// Coordinated Universal Time (UTC) timestamp when the card is next due.
  final DateTime nextDueUtc;

  /// Total count of recall failures (grades with score < 3) experienced by the card.
  final int lapses;

  /// Creates an immutable [MemoryCardSnapshot].
  const MemoryCardSnapshot({
    required this.id,
    this.streak = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.lastReviewedUtc,
    required this.nextDueUtc,
    this.lapses = 0,
  })  : assert(streak >= 0, 'streak must be non-negative'),
        assert(intervalDays >= 0, 'intervalDays must be non-negative'),
        assert(easeFactor > 0, 'easeFactor must be positive'),
        assert(lapses >= 0, 'lapses must be non-negative');

  /// Creates a new unreviewed card scheduled to be due immediately.
  ///
  /// If [createdAtUtc] is omitted, [DateTime.now] in UTC is used.
  factory MemoryCardSnapshot.fresh({
    required String id,
    DateTime? createdAtUtc,
    double startingEase = 2.5,
  }) {
    final created = (createdAtUtc ?? DateTime.now()).toUtc();
    return MemoryCardSnapshot(
      id: id,
      streak: 0,
      intervalDays: 0,
      easeFactor: startingEase,
      lastReviewedUtc: null,
      nextDueUtc: created,
      lapses: 0,
    );
  }

  /// Determines whether this card is due for review at the given [referenceUtc] timestamp.
  ///
  /// If [referenceUtc] is omitted, the current UTC time is used.
  bool isDue([DateTime? referenceUtc]) {
    final reference = (referenceUtc ?? DateTime.now()).toUtc();
    return !nextDueUtc.isAfter(reference);
  }

  /// Estimates the probability of successful recall at the specified [referenceUtc] timestamp.
  ///
  /// Uses an exponential forgetting curve model calibrated for an expected 90%
  /// retention target at the scheduled interval:
  /// `R(t) = 0.9 ^ (elapsed / interval)`
  ///
  /// Returns a floating-point value clamped between `0.0` and `1.0`.
  double retentionProbability([DateTime? referenceUtc]) {
    final reference = (referenceUtc ?? DateTime.now()).toUtc();

    if (lastReviewedUtc == null) {
      if (!reference.isAfter(nextDueUtc)) {
        return 1.0;
      }
      final overdueSeconds = reference.difference(nextDueUtc).inSeconds;
      final overdueDays = overdueSeconds / 86400.0;
      return math.exp(math.log(0.9) * overdueDays).clamp(0.0, 1.0);
    }

    final elapsedSeconds = reference.difference(lastReviewedUtc!).inSeconds;
    if (elapsedSeconds <= 0) {
      return 1.0;
    }

    final elapsedDays = elapsedSeconds / 86400.0;
    final effectiveInterval = intervalDays <= 0 ? 1.0 : intervalDays.toDouble();
    final retention =
        math.exp(math.log(0.9) * (elapsedDays / effectiveInterval));
    return retention.clamp(0.0, 1.0);
  }

  /// Creates a copy of this card snapshot with the specified fields replaced.
  MemoryCardSnapshot copyWith({
    String? id,
    int? streak,
    int? intervalDays,
    double? easeFactor,
    DateTime? lastReviewedUtc,
    DateTime? nextDueUtc,
    int? lapses,
    bool resetLastReviewed = false,
  }) {
    return MemoryCardSnapshot(
      id: id ?? this.id,
      streak: streak ?? this.streak,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      lastReviewedUtc:
          resetLastReviewed ? null : (lastReviewedUtc ?? this.lastReviewedUtc),
      nextDueUtc: nextDueUtc ?? this.nextDueUtc,
      lapses: lapses ?? this.lapses,
    );
  }

  /// Serializes this card snapshot to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'streak': streak,
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'lastReviewedUtc': lastReviewedUtc?.toIso8601String(),
        'nextDueUtc': nextDueUtc.toIso8601String(),
        'lapses': lapses,
      };

  /// Deserializes a [MemoryCardSnapshot] from a JSON map.
  factory MemoryCardSnapshot.fromJson(Map<String, dynamic> json) {
    return MemoryCardSnapshot(
      id: json['id'] as String,
      streak: json['streak'] as int? ?? 0,
      intervalDays: json['intervalDays'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      lastReviewedUtc: json['lastReviewedUtc'] != null
          ? DateTime.parse(json['lastReviewedUtc'] as String).toUtc()
          : null,
      nextDueUtc: DateTime.parse(json['nextDueUtc'] as String).toUtc(),
      lapses: json['lapses'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MemoryCardSnapshot) return false;

    final reviewedSame =
        (lastReviewedUtc == null && other.lastReviewedUtc == null) ||
            (lastReviewedUtc != null &&
                other.lastReviewedUtc != null &&
                lastReviewedUtc!.isAtSameMomentAs(other.lastReviewedUtc!));

    return other.id == id &&
        other.streak == streak &&
        other.intervalDays == intervalDays &&
        other.easeFactor == easeFactor &&
        other.lapses == lapses &&
        other.nextDueUtc.isAtSameMomentAs(nextDueUtc) &&
        reviewedSame;
  }

  @override
  int get hashCode => Object.hash(
        id,
        streak,
        intervalDays,
        easeFactor,
        lastReviewedUtc?.millisecondsSinceEpoch,
        nextDueUtc.millisecondsSinceEpoch,
        lapses,
      );

  @override
  String toString() => 'MemoryCardSnapshot('
      'id: $id, '
      'streak: $streak, '
      'intervalDays: $intervalDays, '
      'easeFactor: $easeFactor, '
      'lastReviewedUtc: $lastReviewedUtc, '
      'nextDueUtc: $nextDueUtc, '
      'lapses: $lapses)';
}

/// Aggregated metrics and learning statistics for a collection of flashcards.
class DeckAnalytics {
  /// Total number of cards tracked in the deck.
  final int totalCount;

  /// Count of cards currently due for review.
  final int dueCount;

  /// Count of cards that have never been reviewed.
  final int unseenCount;

  /// Count of mature cards that have achieved a streak >= 3 and interval >= 21 days.
  final int matureCount;

  /// Arithmetic mean of ease factors across all cards in the deck.
  final double meanEaseFactor;

  /// Arithmetic mean of estimated recall retention probabilities across all cards in the deck.
  final double meanRetention;

  /// Creates an immutable [DeckAnalytics] summary.
  const DeckAnalytics({
    required this.totalCount,
    required this.dueCount,
    required this.unseenCount,
    required this.matureCount,
    required this.meanEaseFactor,
    required this.meanRetention,
  })  : assert(totalCount >= 0, 'totalCount must be non-negative'),
        assert(dueCount >= 0, 'dueCount must be non-negative'),
        assert(unseenCount >= 0, 'unseenCount must be non-negative'),
        assert(matureCount >= 0, 'matureCount must be non-negative'),
        assert(meanEaseFactor >= 0.0, 'meanEaseFactor must be non-negative'),
        assert(
          meanRetention >= 0.0 && meanRetention <= 1.0,
          'meanRetention must be between 0.0 and 1.0',
        );

  /// Creates a copy of this summary with the specified fields replaced.
  DeckAnalytics copyWith({
    int? totalCount,
    int? dueCount,
    int? unseenCount,
    int? matureCount,
    double? meanEaseFactor,
    double? meanRetention,
  }) {
    return DeckAnalytics(
      totalCount: totalCount ?? this.totalCount,
      dueCount: dueCount ?? this.dueCount,
      unseenCount: unseenCount ?? this.unseenCount,
      matureCount: matureCount ?? this.matureCount,
      meanEaseFactor: meanEaseFactor ?? this.meanEaseFactor,
      meanRetention: meanRetention ?? this.meanRetention,
    );
  }

  /// Serializes this deck summary to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'totalCount': totalCount,
        'dueCount': dueCount,
        'unseenCount': unseenCount,
        'matureCount': matureCount,
        'meanEaseFactor': meanEaseFactor,
        'meanRetention': meanRetention,
      };

  /// Deserializes a [DeckAnalytics] from a JSON map.
  factory DeckAnalytics.fromJson(Map<String, dynamic> json) {
    return DeckAnalytics(
      totalCount: json['totalCount'] as int? ?? 0,
      dueCount: json['dueCount'] as int? ?? 0,
      unseenCount: json['unseenCount'] as int? ?? 0,
      matureCount: json['matureCount'] as int? ?? 0,
      meanEaseFactor: (json['meanEaseFactor'] as num?)?.toDouble() ?? 0.0,
      meanRetention: (json['meanRetention'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeckAnalytics &&
        other.totalCount == totalCount &&
        other.dueCount == dueCount &&
        other.unseenCount == unseenCount &&
        other.matureCount == matureCount &&
        other.meanEaseFactor == meanEaseFactor &&
        other.meanRetention == meanRetention;
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        dueCount,
        unseenCount,
        matureCount,
        meanEaseFactor,
        meanRetention,
      );

  @override
  String toString() => 'DeckAnalytics('
      'total: $totalCount, '
      'due: $dueCount, '
      'unseen: $unseenCount, '
      'mature: $matureCount, '
      'meanEase: $meanEaseFactor, '
      'meanRetention: $meanRetention)';
}

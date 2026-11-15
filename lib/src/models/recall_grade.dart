/// Standard recall evaluation grades based on the SM-2 algorithm.
enum RecallGrade {
  /// Complete failure to recall; blackout or total lapse.
  totalLapse(0),

  /// Incorrect recall; upon seeing the correct answer, it was remembered.
  failedRecognized(1),

  /// Incorrect recall; the correct answer seemed easy once revealed.
  failedNearRecall(2),

  /// Successful recall achieved with significant effort or hesitation.
  recalledWithEffort(3),

  /// Successful recall achieved after a brief hesitation.
  recalledSteady(4),

  /// Perfect recall achieved instantly and effortlessly.
  recalledInstant(5);

  /// Numeric score corresponding to the SM-2 grade scale (0 to 5).
  final int score;

  /// Creates a [RecallGrade] with the associated numeric [score].
  const RecallGrade(this.score);

  /// Returns `true` if this grade represents a successful recall event (score >= 3).
  bool get isSuccessful => score >= 3;

  /// Resolves the corresponding [RecallGrade] from an integer [score] between 0 and 5.
  ///
  /// Throws an [ArgumentError] if [score] is outside the inclusive range of 0 to 5.
  static RecallGrade fromScore(int score) {
    switch (score) {
      case 0:
        return RecallGrade.totalLapse;
      case 1:
        return RecallGrade.failedRecognized;
      case 2:
        return RecallGrade.failedNearRecall;
      case 3:
        return RecallGrade.recalledWithEffort;
      case 4:
        return RecallGrade.recalledSteady;
      case 5:
        return RecallGrade.recalledInstant;
      default:
        throw ArgumentError.value(
          score,
          'score',
          'Recall score must be an integer between 0 and 5.',
        );
    }
  }
}

/// Simplified 4-button rating scale commonly used in modern flashcard interfaces.
enum StudyRating {
  /// Review failed; requires immediate re-study.
  again,

  /// Card recalled with significant difficulty.
  hard,

  /// Card recalled steadily with normal hesitation.
  good,

  /// Card recalled easily without any effort.
  easy;

  /// Maps this 4-button study rating to its corresponding [RecallGrade].
  RecallGrade toRecallGrade() {
    switch (this) {
      case StudyRating.again:
        return RecallGrade.failedRecognized;
      case StudyRating.hard:
        return RecallGrade.recalledWithEffort;
      case StudyRating.good:
        return RecallGrade.recalledSteady;
      case StudyRating.easy:
        return RecallGrade.recalledInstant;
    }
  }
}

import 'dart:math' as math;

import '../models/deck_analytics.dart';
import '../models/memory_card_snapshot.dart';
import '../models/recall_grade.dart';
import '../models/scheduler_parameters.dart';

/// Deterministic spaced-repetition scheduling engine implementing the SM-2 algorithm.
class SpacedRepetitionEngine {
  /// Configuration parameters governing interval calculation and ease bounds.
  final SchedulerParameters parameters;

  /// Creates a [SpacedRepetitionEngine] with the provided [parameters].
  const SpacedRepetitionEngine({
    this.parameters = const SchedulerParameters(),
  });

  /// Evaluates a review event using a specific [RecallGrade], returning an updated [MemoryCardSnapshot].
  ///
  /// The review timestamp defaults to the current UTC time if [reviewedAtUtc] is not specified.
  MemoryCardSnapshot evaluate(
    MemoryCardSnapshot card,
    RecallGrade grade, {
    DateTime? reviewedAtUtc,
  }) {
    final reviewTime = (reviewedAtUtc ?? DateTime.now()).toUtc();

    // Standard SM-2 ease factor delta formula:
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final scoreDelta = 5 - grade.score;
    final easeDelta = 0.1 - scoreDelta * (0.08 + scoreDelta * 0.02);
    final rawEase = card.easeFactor + easeDelta;
    final updatedEase = math.max(parameters.floorEase, rawEase);

    int updatedStreak;
    int intervalDays;
    int updatedLapses;

    if (grade.isSuccessful) {
      if (card.streak == 0) {
        intervalDays = parameters.initialStepDays;
      } else if (card.streak == 1) {
        intervalDays = parameters.graduatingStepDays;
      } else {
        var calculatedInterval = card.intervalDays * updatedEase;
        if (grade == RecallGrade.recalledInstant) {
          calculatedInterval *= parameters.easyMultiplier;
        } else if (grade == RecallGrade.recalledWithEffort) {
          calculatedInterval *= parameters.hardMultiplier;
        }
        intervalDays = calculatedInterval.round();
      }

      if (intervalDays < 1) {
        intervalDays = 1;
      }
      if (intervalDays > parameters.ceilingIntervalDays) {
        intervalDays = parameters.ceilingIntervalDays;
      }

      updatedStreak = card.streak + 1;
      updatedLapses = card.lapses;
    } else {
      updatedStreak = 0;
      intervalDays = parameters.initialStepDays;
      if (intervalDays > parameters.ceilingIntervalDays) {
        intervalDays = parameters.ceilingIntervalDays;
      }
      updatedLapses = card.lapses + 1;
    }

    final nextDueUtc = reviewTime.add(Duration(days: intervalDays));

    return card.copyWith(
      streak: updatedStreak,
      intervalDays: intervalDays,
      easeFactor: updatedEase,
      lastReviewedUtc: reviewTime,
      nextDueUtc: nextDueUtc,
      lapses: updatedLapses,
    );
  }

  /// Evaluates a review event using a simplified [StudyRating], returning an updated [MemoryCardSnapshot].
  MemoryCardSnapshot evaluateRating(
    MemoryCardSnapshot card,
    StudyRating rating, {
    DateTime? reviewedAtUtc,
  }) {
    return evaluate(
      card,
      rating.toRecallGrade(),
      reviewedAtUtc: reviewedAtUtc,
    );
  }

  /// Calculates a preview of next interval durations in days for each possible [StudyRating].
  Map<StudyRating, int> previewNextIntervals(
    MemoryCardSnapshot card, {
    DateTime? referenceUtc,
  }) {
    final preview = <StudyRating, int>{};
    for (final rating in StudyRating.values) {
      final updated = evaluateRating(
        card,
        rating,
        reviewedAtUtc: referenceUtc,
      );
      preview[rating] = updated.intervalDays;
    }
    return preview;
  }

  /// Filters and orders all cards currently due for review, sorted earliest [MemoryCardSnapshot.nextDueUtc] first.
  List<MemoryCardSnapshot> dueQueue(
    Iterable<MemoryCardSnapshot> cards, {
    DateTime? referenceUtc,
  }) {
    final reference = (referenceUtc ?? DateTime.now()).toUtc();
    final queue = cards.where((card) => card.isDue(reference)).toList();
    queue.sort((a, b) => a.nextDueUtc.compareTo(b.nextDueUtc));
    return queue;
  }

  /// Computes deck-wide metrics, retention estimates, and progress statistics.
  DeckAnalytics summarizeDeck(
    Iterable<MemoryCardSnapshot> cards, {
    DateTime? referenceUtc,
  }) {
    final cardList = cards.toList();
    final total = cardList.length;
    if (total == 0) {
      return const DeckAnalytics(
        totalCount: 0,
        dueCount: 0,
        unseenCount: 0,
        matureCount: 0,
        meanEaseFactor: 0.0,
        meanRetention: 0.0,
      );
    }

    final reference = (referenceUtc ?? DateTime.now()).toUtc();
    var due = 0;
    var unseen = 0;
    var mature = 0;
    var totalEase = 0.0;
    var totalRetention = 0.0;

    for (final card in cardList) {
      if (card.isDue(reference)) {
        due++;
      }
      if (card.lastReviewedUtc == null) {
        unseen++;
      }
      if (card.streak >= 3 && card.intervalDays >= 21) {
        mature++;
      }
      totalEase += card.easeFactor;
      totalRetention += card.retentionProbability(reference);
    }

    return DeckAnalytics(
      totalCount: total,
      dueCount: due,
      unseenCount: unseen,
      matureCount: mature,
      meanEaseFactor: totalEase / total,
      meanRetention: totalRetention / total,
    );
  }
}

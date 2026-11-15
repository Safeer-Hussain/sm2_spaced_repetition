import 'dart:convert';
import 'package:sm2_spaced_repetition/sm2_spaced_repetition.dart';
import 'package:test/test.dart';

void main() {
  group('RecallGrade & StudyRating', () {
    test('RecallGrade values map to expected scores and success status', () {
      expect(RecallGrade.totalLapse.score, equals(0));
      expect(RecallGrade.totalLapse.isSuccessful, isFalse);

      expect(RecallGrade.failedRecognized.score, equals(1));
      expect(RecallGrade.failedRecognized.isSuccessful, isFalse);

      expect(RecallGrade.failedNearRecall.score, equals(2));
      expect(RecallGrade.failedNearRecall.isSuccessful, isFalse);

      expect(RecallGrade.recalledWithEffort.score, equals(3));
      expect(RecallGrade.recalledWithEffort.isSuccessful, isTrue);

      expect(RecallGrade.recalledSteady.score, equals(4));
      expect(RecallGrade.recalledSteady.isSuccessful, isTrue);

      expect(RecallGrade.recalledInstant.score, equals(5));
      expect(RecallGrade.recalledInstant.isSuccessful, isTrue);
    });

    test('RecallGrade.fromScore maps valid integer scores accurately', () {
      for (var i = 0; i <= 5; i++) {
        final grade = RecallGrade.fromScore(i);
        expect(grade.score, equals(i));
      }
      expect(() => RecallGrade.fromScore(-1), throwsArgumentError);
      expect(() => RecallGrade.fromScore(6), throwsArgumentError);
    });

    test('StudyRating correctly maps to designated RecallGrade', () {
      expect(
        StudyRating.again.toRecallGrade(),
        equals(RecallGrade.failedRecognized),
      );
      expect(
        StudyRating.hard.toRecallGrade(),
        equals(RecallGrade.recalledWithEffort),
      );
      expect(
        StudyRating.good.toRecallGrade(),
        equals(RecallGrade.recalledSteady),
      );
      expect(
        StudyRating.easy.toRecallGrade(),
        equals(RecallGrade.recalledInstant),
      );
    });
  });

  group('SchedulerParameters', () {
    test('default parameters adhere to specified SM-2 standard constraints',
        () {
      const params = SchedulerParameters();
      expect(params.startingEase, equals(2.5));
      expect(params.floorEase, equals(1.3));
      expect(params.initialStepDays, equals(1));
      expect(params.graduatingStepDays, equals(6));
      expect(params.easyMultiplier, equals(1.3));
      expect(params.hardMultiplier, equals(1.15));
      expect(params.ceilingIntervalDays, equals(36500));
    });

    test('copyWith updates specified fields while retaining others', () {
      const params = SchedulerParameters();
      final modified = params.copyWith(
        startingEase: 2.6,
        floorEase: 1.4,
        initialStepDays: 2,
      );
      expect(modified.startingEase, equals(2.6));
      expect(modified.floorEase, equals(1.4));
      expect(modified.initialStepDays, equals(2));
      expect(modified.graduatingStepDays, equals(6));
      expect(modified, isNot(equals(params)));
      expect(modified.hashCode, isNot(equals(params.hashCode)));
    });

    test('equality and toString behave as expected', () {
      const p1 = SchedulerParameters();
      const p2 = SchedulerParameters();
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1.toString(), contains('SchedulerParameters'));
    });
  });

  group('MemoryCardSnapshot', () {
    test('fresh factory constructor initializes clean card state', () {
      final baseTime = DateTime.utc(2026, 3, 15, 12, 0);
      final card = MemoryCardSnapshot.fresh(
        id: 'card-1',
        createdAtUtc: baseTime,
      );

      expect(card.id, equals('card-1'));
      expect(card.streak, equals(0));
      expect(card.intervalDays, equals(0));
      expect(card.easeFactor, equals(2.5));
      expect(card.lastReviewedUtc, isNull);
      expect(card.nextDueUtc, equals(baseTime));
      expect(card.lapses, equals(0));
      expect(card.isDue(baseTime), isTrue);
      expect(
          card.isDue(baseTime.subtract(const Duration(minutes: 1))), isFalse);
    });

    test('retentionProbability decays exponentially past review and due date',
        () {
      final reviewTime = DateTime.utc(2026, 1, 1, 0, 0);
      final card = MemoryCardSnapshot(
        id: 'decay-test',
        streak: 2,
        intervalDays: 10,
        easeFactor: 2.5,
        lastReviewedUtc: reviewTime,
        nextDueUtc: reviewTime.add(const Duration(days: 10)),
        lapses: 0,
      );

      // At review time, retention is 100%
      expect(card.retentionProbability(reviewTime), closeTo(1.0, 0.001));

      // At scheduled interval (10 days), retention equals calibrated 90%
      final dueTime = reviewTime.add(const Duration(days: 10));
      expect(card.retentionProbability(dueTime), closeTo(0.9, 0.001));

      // At double the interval (20 days), retention is 0.9^2 = 0.81
      final doubleTime = reviewTime.add(const Duration(days: 20));
      expect(card.retentionProbability(doubleTime), closeTo(0.81, 0.001));

      // In the distant future, retention approaches 0.0 but remains >= 0.0
      final farFuture = reviewTime.add(const Duration(days: 3650));
      expect(card.retentionProbability(farFuture), inInclusiveRange(0.0, 0.05));
    });

    test(
        'retentionProbability for fresh unreviewed card handles due and overdue state',
        () {
      final dueTime = DateTime.utc(2026, 1, 1, 0, 0);
      final card = MemoryCardSnapshot.fresh(
        id: 'fresh-decay',
        createdAtUtc: dueTime,
      );

      // Before due date
      final beforeTime = dueTime.subtract(const Duration(days: 1));
      expect(card.retentionProbability(beforeTime), equals(1.0));

      // At due date
      expect(card.retentionProbability(dueTime), equals(1.0));

      // Overdue by 1 day
      final oneDayLate = dueTime.add(const Duration(days: 1));
      expect(card.retentionProbability(oneDayLate), closeTo(0.9, 0.001));
    });

    test('JSON serialization round-trip restores equivalent state', () {
      final card = MemoryCardSnapshot(
        id: 'json-123',
        streak: 4,
        intervalDays: 28,
        easeFactor: 2.46,
        lastReviewedUtc: DateTime.utc(2026, 5, 1, 10, 30),
        nextDueUtc: DateTime.utc(2026, 5, 29, 10, 30),
        lapses: 1,
      );

      final map = card.toJson();
      final jsonString = jsonEncode(map);
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = MemoryCardSnapshot.fromJson(decodedMap);

      expect(restored, equals(card));
      expect(restored.hashCode, equals(card.hashCode));
      expect(restored.id, equals('json-123'));
      expect(restored.streak, equals(4));
      expect(restored.intervalDays, equals(28));
      expect(restored.easeFactor, equals(2.46));
      expect(restored.lapses, equals(1));
    });

    test('copyWith allows resetting lastReviewedUtc', () {
      final card = MemoryCardSnapshot(
        id: 'reset-reviewed',
        lastReviewedUtc: DateTime.utc(2026, 1, 1),
        nextDueUtc: DateTime.utc(2026, 1, 5),
      );
      final updated = card.copyWith(resetLastReviewed: true);
      expect(updated.lastReviewedUtc, isNull);
    });
  });

  group('SpacedRepetitionEngine Review Scheduling', () {
    const engine = SpacedRepetitionEngine();
    final epoch = DateTime.utc(2026, 1, 1, 0, 0);

    test(
        'first successful review advances streak to 1 and sets initialStepDays',
        () {
      final card = MemoryCardSnapshot.fresh(id: 'c1', createdAtUtc: epoch);
      final reviewed = engine.evaluate(
        card,
        RecallGrade.recalledSteady,
        reviewedAtUtc: epoch,
      );

      expect(reviewed.streak, equals(1));
      expect(reviewed.intervalDays, equals(1));
      expect(reviewed.easeFactor, equals(2.5));
      expect(reviewed.lastReviewedUtc, equals(epoch));
      expect(reviewed.nextDueUtc, equals(epoch.add(const Duration(days: 1))));
      expect(reviewed.lapses, equals(0));
    });

    test(
        'second successful review advances streak to 2 and sets graduatingStepDays',
        () {
      final card = MemoryCardSnapshot.fresh(id: 'c2', createdAtUtc: epoch);
      final r1 = engine.evaluate(
        card,
        RecallGrade.recalledSteady,
        reviewedAtUtc: epoch,
      );
      final day1 = epoch.add(const Duration(days: 1));
      final r2 = engine.evaluate(
        r1,
        RecallGrade.recalledSteady,
        reviewedAtUtc: day1,
      );

      expect(r2.streak, equals(2));
      expect(r2.intervalDays, equals(6));
      expect(r2.easeFactor, equals(2.5));
      expect(r2.nextDueUtc, equals(day1.add(const Duration(days: 6))));
    });

    test('third review scales interval by ease factor and increments streak',
        () {
      final card = MemoryCardSnapshot(
        id: 'c3',
        streak: 2,
        intervalDays: 6,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 6)),
        lapses: 0,
      );

      final day6 = epoch.add(const Duration(days: 6));
      final r3 = engine.evaluate(
        card,
        RecallGrade.recalledSteady,
        reviewedAtUtc: day6,
      );

      expect(r3.streak, equals(3));
      // 6 * 2.5 = 15 days
      expect(r3.intervalDays, equals(15));
      expect(r3.easeFactor, equals(2.5));
      expect(r3.nextDueUtc, equals(day6.add(const Duration(days: 15))));
    });

    test(
        'perfect recall (recalledInstant) increases ease factor and applies easy multiplier',
        () {
      final card = MemoryCardSnapshot(
        id: 'c-easy',
        streak: 2,
        intervalDays: 6,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 6)),
      );

      final day6 = epoch.add(const Duration(days: 6));
      final r = engine.evaluate(
        card,
        RecallGrade.recalledInstant,
        reviewedAtUtc: day6,
      );

      // SM-2 formula for score 5: ease increases by +0.10 -> 2.60
      expect(r.easeFactor, closeTo(2.6, 0.001));
      // Interval = round(6 * 2.6 * 1.3) = round(20.28) = 20 days
      expect(r.intervalDays, equals(20));
      expect(r.streak, equals(3));
    });

    test(
        'hard recall (recalledWithEffort) decreases ease factor and applies hard multiplier',
        () {
      final card = MemoryCardSnapshot(
        id: 'c-hard',
        streak: 2,
        intervalDays: 6,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 6)),
      );

      final day6 = epoch.add(const Duration(days: 6));
      final r = engine.evaluate(
        card,
        RecallGrade.recalledWithEffort,
        reviewedAtUtc: day6,
      );

      // SM-2 formula for score 3: ease decreases by -0.14 -> 2.36
      expect(r.easeFactor, closeTo(2.36, 0.001));
      // Interval = round(6 * 2.36 * 1.15) = round(16.284) = 16 days
      expect(r.intervalDays, equals(16));
      expect(r.streak, equals(3));
    });

    test('ease factor delta clamps at floorEase', () {
      var card = MemoryCardSnapshot(
        id: 'c-floor',
        streak: 2,
        intervalDays: 6,
        easeFactor: 1.35,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 6)),
      );

      // Lapse with score 0 subtracts 0.80 from ease factor
      card = engine.evaluate(
        card,
        RecallGrade.totalLapse,
        reviewedAtUtc: epoch.add(const Duration(days: 6)),
      );

      expect(card.easeFactor, equals(1.3));
    });

    test(
        'failing grade resets streak, resets interval to initial step, and increments lapses',
        () {
      final card = MemoryCardSnapshot(
        id: 'c-lapse',
        streak: 5,
        intervalDays: 45,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 45)),
        lapses: 0,
      );

      final reviewTime = epoch.add(const Duration(days: 45));
      final lapsed = engine.evaluate(
        card,
        RecallGrade.failedRecognized,
        reviewedAtUtc: reviewTime,
      );

      expect(lapsed.streak, equals(0));
      expect(lapsed.intervalDays, equals(1));
      expect(lapsed.lapses, equals(1));
      expect(
          lapsed.nextDueUtc, equals(reviewTime.add(const Duration(days: 1))));
    });

    test('ceiling interval caps excessively large calculated intervals', () {
      const customEngine = SpacedRepetitionEngine(
        parameters: SchedulerParameters(ceilingIntervalDays: 30),
      );

      final card = MemoryCardSnapshot(
        id: 'c-cap',
        streak: 4,
        intervalDays: 20,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 20)),
      );

      final reviewed = customEngine.evaluate(
        card,
        RecallGrade.recalledSteady,
        reviewedAtUtc: epoch.add(const Duration(days: 20)),
      );

      // 20 * 2.5 = 50, but cap is 30
      expect(reviewed.intervalDays, equals(30));
    });

    test('evaluateRating maps accurately to evaluate', () {
      final card =
          MemoryCardSnapshot.fresh(id: 'rating-check', createdAtUtc: epoch);

      final ratedGood = engine.evaluateRating(
        card,
        StudyRating.good,
        reviewedAtUtc: epoch,
      );
      final gradedGood = engine.evaluate(
        card,
        RecallGrade.recalledSteady,
        reviewedAtUtc: epoch,
      );

      expect(ratedGood, equals(gradedGood));
    });

    test(
        'previewNextIntervals returns accurate interval predictions for all 4 ratings',
        () {
      final card = MemoryCardSnapshot(
        id: 'preview-card',
        streak: 2,
        intervalDays: 6,
        easeFactor: 2.5,
        lastReviewedUtc: epoch,
        nextDueUtc: epoch.add(const Duration(days: 6)),
      );

      final preview = engine.previewNextIntervals(card, referenceUtc: epoch);
      expect(preview.keys, containsAll(StudyRating.values));
      expect(preview[StudyRating.again], equals(1));
      expect(preview[StudyRating.hard], equals(16));
      expect(preview[StudyRating.good], equals(15));
      expect(preview[StudyRating.easy], equals(20));
    });
  });

  group('Deck Operations & Queue Filtering', () {
    const engine = SpacedRepetitionEngine();
    final now = DateTime.utc(2026, 6, 1, 12, 0);

    test(
        'dueQueue filters due cards and sorts them in ascending order of nextDueUtc',
        () {
      final pastDue = MemoryCardSnapshot(
        id: 'past-due',
        nextDueUtc: now.subtract(const Duration(days: 2)),
      );
      final dueNow = MemoryCardSnapshot(
        id: 'due-now',
        nextDueUtc: now,
      );
      final dueLater = MemoryCardSnapshot(
        id: 'due-later',
        nextDueUtc: now.add(const Duration(days: 3)),
      );

      final queue =
          engine.dueQueue([dueLater, dueNow, pastDue], referenceUtc: now);

      expect(queue.length, equals(2));
      expect(queue[0].id, equals('past-due'));
      expect(queue[1].id, equals('due-now'));
    });

    test('summarizeDeck aggregates comprehensive deck performance metrics', () {
      final card1 = MemoryCardSnapshot(
        id: 'mature-1',
        streak: 4,
        intervalDays: 25,
        easeFactor: 2.5,
        lastReviewedUtc: now.subtract(const Duration(days: 10)),
        nextDueUtc: now.add(const Duration(days: 15)),
      );
      final card2 = MemoryCardSnapshot.fresh(
        id: 'unseen-1',
        createdAtUtc: now,
      );
      final card3 = MemoryCardSnapshot(
        id: 'due-1',
        streak: 1,
        intervalDays: 1,
        easeFactor: 2.3,
        lastReviewedUtc: now.subtract(const Duration(days: 2)),
        nextDueUtc: now.subtract(const Duration(days: 1)),
      );

      final summary =
          engine.summarizeDeck([card1, card2, card3], referenceUtc: now);

      expect(summary.totalCount, equals(3));
      expect(summary.dueCount,
          equals(2)); // unseen card is due at now, card3 is past due
      expect(summary.unseenCount, equals(1));
      expect(summary.matureCount, equals(1));
      expect(summary.meanEaseFactor, closeTo((2.5 + 2.5 + 2.3) / 3, 0.001));
      expect(summary.meanRetention, inInclusiveRange(0.0, 1.0));
    });

    test('summarizeDeck handles empty deck gracefully', () {
      final summary = engine.summarizeDeck([]);
      expect(summary.totalCount, equals(0));
      expect(summary.dueCount, equals(0));
      expect(summary.unseenCount, equals(0));
      expect(summary.matureCount, equals(0));
      expect(summary.meanEaseFactor, equals(0.0));
      expect(summary.meanRetention, equals(0.0));
    });
  });

  group('DeckAnalytics Model', () {
    test('DeckAnalytics JSON serialization and equality work seamlessly', () {
      const analytics = DeckAnalytics(
        totalCount: 10,
        dueCount: 3,
        unseenCount: 2,
        matureCount: 5,
        meanEaseFactor: 2.45,
        meanRetention: 0.88,
      );

      final json = analytics.toJson();
      final restored = DeckAnalytics.fromJson(json);

      expect(restored, equals(analytics));
      expect(restored.hashCode, equals(analytics.hashCode));
      expect(restored.toString(), contains('DeckAnalytics'));

      final modified = analytics.copyWith(dueCount: 4);
      expect(modified.dueCount, equals(4));
      expect(modified, isNot(equals(analytics)));
    });
  });
}

import 'dart:convert';
import 'package:sm2_spaced_repetition/sm2_spaced_repetition.dart';

void main() {
  const engine = SpacedRepetitionEngine();
  final now = DateTime.utc(2026, 1, 1, 10, 0);

  print('=== SM-2 Spaced Repetition Demo ===');

  // 1. Create fresh cards
  final cardA = MemoryCardSnapshot.fresh(
    id: 'card-dart-records',
    createdAtUtc: now,
  );
  final cardB = MemoryCardSnapshot.fresh(
    id: 'card-dart-patterns',
    createdAtUtc: now,
  );
  final cardC = MemoryCardSnapshot.fresh(
    id: 'card-dart-macros',
    createdAtUtc: now,
  );

  print('\n[1] Fresh Card Created:');
  print('  ID: ${cardA.id}');
  print('  Streak: ${cardA.streak}');
  print('  Interval: ${cardA.intervalDays} days');
  print('  Ease Factor: ${cardA.easeFactor}');
  print('  Is Due: ${cardA.isDue(now)}');

  // 2. Preview next intervals before answering
  print('\n[2] Interval Preview for card-dart-records:');
  final preview = engine.previewNextIntervals(cardA, referenceUtc: now);
  for (final entry in preview.entries) {
    print('  Rating ${entry.key.name.padRight(5)} -> ${entry.value} days');
  }

  // 3. Review cards with various grades
  print('\n[3] Reviewing card-dart-records across consecutive days:');
  var currentCard = cardA;

  // Day 1: Good recall
  final day1Time = now;
  currentCard = engine.evaluateRating(
    currentCard,
    StudyRating.good,
    reviewedAtUtc: day1Time,
  );
  print(
    '  Review 1 (Good): streak=${currentCard.streak}, '
    'interval=${currentCard.intervalDays}d, ease=${currentCard.easeFactor.toStringAsFixed(2)}, '
    'nextDue=${currentCard.nextDueUtc.toIso8601String()}',
  );

  // Day 2: Graduating step (Easy)
  final day2Time = currentCard.nextDueUtc;
  currentCard = engine.evaluateRating(
    currentCard,
    StudyRating.easy,
    reviewedAtUtc: day2Time,
  );
  print(
    '  Review 2 (Easy): streak=${currentCard.streak}, '
    'interval=${currentCard.intervalDays}d, ease=${currentCard.easeFactor.toStringAsFixed(2)}, '
    'nextDue=${currentCard.nextDueUtc.toIso8601String()}',
  );

  // Day 8: Third review (Good)
  final day8Time = currentCard.nextDueUtc;
  currentCard = engine.evaluateRating(
    currentCard,
    StudyRating.good,
    reviewedAtUtc: day8Time,
  );
  print(
    '  Review 3 (Good): streak=${currentCard.streak}, '
    'interval=${currentCard.intervalDays}d, ease=${currentCard.easeFactor.toStringAsFixed(2)}, '
    'nextDue=${currentCard.nextDueUtc.toIso8601String()}',
  );

  // Simulate lapse (Again)
  final day24Time = currentCard.nextDueUtc;
  final lapsedCard = engine.evaluateRating(
    currentCard,
    StudyRating.again,
    reviewedAtUtc: day24Time,
  );
  print(
    '  Review 4 (Again): streak=${lapsedCard.streak}, '
    'interval=${lapsedCard.intervalDays}d, lapses=${lapsedCard.lapses}, '
    'ease=${lapsedCard.easeFactor.toStringAsFixed(2)}',
  );

  // 4. Due queue filtering and sorting
  print('\n[4] Due Queue Ordering:');
  final deck = <MemoryCardSnapshot>[
    currentCard,
    cardB.copyWith(nextDueUtc: now.add(const Duration(days: 3))),
    cardC.copyWith(nextDueUtc: now.subtract(const Duration(hours: 4))),
  ];

  final dueCards = engine.dueQueue(deck, referenceUtc: now);
  print('  Cards currently due: ${dueCards.length} / ${deck.length}');
  for (final card in dueCards) {
    print('  - Card ${card.id} (due: ${card.nextDueUtc.toIso8601String()})');
  }

  // 5. Deck analytics summary
  print('\n[5] Deck Analytics:');
  final analytics = engine.summarizeDeck(deck, referenceUtc: now);
  print('  Total Cards: ${analytics.totalCount}');
  print('  Due Cards: ${analytics.dueCount}');
  print('  Unseen Cards: ${analytics.unseenCount}');
  print('  Mature Cards: ${analytics.matureCount}');
  print('  Mean Ease: ${analytics.meanEaseFactor.toStringAsFixed(2)}');
  print(
    '  Mean Retention: ${(analytics.meanRetention * 100).toStringAsFixed(1)}%',
  );

  // 6. JSON round-trip serialization
  print('\n[6] JSON Round-Trip Serialization:');
  final jsonString = jsonEncode(currentCard.toJson());
  print('  Serialized JSON: $jsonString');

  final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
  final restoredCard = MemoryCardSnapshot.fromJson(decodedMap);
  print('  Restored ID: ${restoredCard.id}');
  print('  Matches Original: ${restoredCard == currentCard}');
}

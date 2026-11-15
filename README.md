# sm2_spaced_repetition

[![pub package](https://img.shields.io/pub/v/sm2_spaced_repetition.svg)](https://pub.dev/packages/sm2_spaced_repetition)
[![package publisher](https://img.shields.io/pub/publisher/sm2_spaced_repetition.svg)](https://pub.dev/packages/sm2_spaced_repetition)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A pure Dart implementation of the SuperMemo SM-2 spaced-repetition algorithm engineered for cross-platform applications, command-line tools, and WebAssembly targets.

Provides deterministic interval calculation, adaptive ease factor adjustment, exponential retention probability estimation, deck-wide analytics, and JSON serialization.

---

## Features

- Pure Dart SDK: Zero external runtime dependencies. Compatible with Linux, macOS, Windows, Android, iOS, Web, and Wasm.
- SM-2 Algorithm: Accurate implementation with configurable ease floors, initial steps, graduating steps, and interval caps.
- Dual Grading Systems: Full 6-grade academic scale (`RecallGrade`) alongside modern 4-button study controls (`StudyRating`).
- Predictive Lookahead: Preview prospective interval growth across all rating choices prior to submitting a review.
- Exponential Forgetting Curve: Compute calibrated recall retention probabilities (`retentionProbability`) at any point in time.
- Deck Analytics: Calculate total, due, unseen, and mature card tallies alongside deck-wide mean ease factors and retention rates.
- State Persistence: Immutable data snapshots with complete ISO-8601 JSON serialization and deserialization support.

---

## Installation

Add `sm2_spaced_repetition` to your `pubspec.yaml` using the Dart package manager:

```console
dart pub add sm2_spaced_repetition
```

---

## Grade Mapping Table

| StudyRating | RecallGrade | Score | Semantic Meaning |
|---|---|---|---|
| `again` | `failedRecognized` | 1 | Incorrect response; answer was recognized upon reveal |
| - | `totalLapse` | 0 | Complete blackout or total failure to recall |
| - | `failedNearRecall` | 2 | Incorrect response; answer seemed easy once revealed |
| `hard` | `recalledWithEffort` | 3 | Correct response recalled with significant difficulty |
| `good` | `recalledSteady` | 4 | Correct response recalled with moderate hesitation |
| `easy` | `recalledInstant` | 5 | Perfect response recalled effortlessly and immediately |

Grades with scores of 3 or higher (`score >= 3`) are classified as passing (`isSuccessful == true`), advancing card intervals and streaks. Failing scores reset the consecutive streak and increment the lapse counter.

---

## Quick Start

```dart
import 'package:sm2_spaced_repetition/sm2_spaced_repetition.dart';

void main() {
  const engine = SpacedRepetitionEngine();
  final now = DateTime.now().toUtc();

  // Create a new unreviewed card
  final card = MemoryCardSnapshot.fresh(
    id: 'vocab-101',
    createdAtUtc: now,
  );

  // Inspect prospective intervals before grading
  final preview = engine.previewNextIntervals(card, referenceUtc: now);
  print('Preview good rating: ${preview[StudyRating.good]} days');

  // Submit a review rating
  final reviewedCard = engine.evaluateRating(
    card,
    StudyRating.good,
    reviewedAtUtc: now,
  );

  print('New interval: ${reviewedCard.intervalDays} days');
  print('Next due date: ${reviewedCard.nextDueUtc}');
  print('Ease factor: ${reviewedCard.easeFactor}');

  // Serialize to JSON for persistent storage
  final jsonMap = reviewedCard.toJson();
  final restoredCard = MemoryCardSnapshot.fromJson(jsonMap);
  assert(restoredCard == reviewedCard);
}
```

---

## Deck Analytics and Due Queue

```dart
import 'package:sm2_spaced_repetition/sm2_spaced_repetition.dart';

void main() {
  const engine = SpacedRepetitionEngine();
  final cards = <MemoryCardSnapshot>[
    // Collection of card snapshots
  ];

  // Retrieve cards currently due for study, sorted chronologically
  final queue = engine.dueQueue(cards);
  print('Due cards to review: ${queue.length}');

  // Summarize overall deck statistics
  final analytics = engine.summarizeDeck(cards);
  print('Total Cards: ${analytics.totalCount}');
  print('Due Cards: ${analytics.dueCount}');
  print('Unseen Cards: ${analytics.unseenCount}');
  print('Mature Cards: ${analytics.matureCount}');
  print('Mean Retention: ${(analytics.meanRetention * 100).toStringAsFixed(1)}%');
}
```

---

## Algorithm Specifications

### Ease Factor Adaptation

Ease factor adjustments follow the standard SM-2 quadratic differential:

`EF' = max(floorEase, EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))`

where `q` represents the integer grade score between 0 and 5.

### Interval Progression

- Streak 0 to 1: `interval = initialStepDays` (default: 1 day)
- Streak 1 to 2: `interval = graduatingStepDays` (default: 6 days)
- Streak 2+: `interval = round(previousInterval * updatedEase * multiplier)`
  - `multiplier` is `easyMultiplier` (default: 1.3) for `recalledInstant` (5).
  - `multiplier` is `hardMultiplier` (default: 1.15) for `recalledWithEffort` (3).
  - `multiplier` is `1.0` for `recalledSteady` (4).
- Failing grades (score < 3): reset streak to 0, reset interval to `initialStepDays`, and increment `lapses`.

---

## Links

- Repository: [https://github.com/Safeer-Hussain/sm2_spaced_repetition](https://github.com/Safeer-Hussain/sm2_spaced_repetition)
- Issue Tracker: [https://github.com/Safeer-Hussain/sm2_spaced_repetition/issues](https://github.com/Safeer-Hussain/sm2_spaced_repetition/issues)
- License: [MIT License](https://github.com/Safeer-Hussain/sm2_spaced_repetition/blob/main/LICENSE)

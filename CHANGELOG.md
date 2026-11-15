## 0.1.0

Initial stable release of `sm2_spaced_repetition`.

- Pure Dart implementation of the SM-2 spaced-repetition memory scheduling algorithm.
- Standard 6-point recall grade scale (`RecallGrade`) and 4-button UI study ratings (`StudyRating`).
- Deterministic review scheduling with configurable ease factors, multipliers, and interval ceilings (`SchedulerParameters`).
- Immutable card state management with ISO-8601 JSON serialization (`MemoryCardSnapshot`).
- Exponential forgetting curve retention probability estimation.
- Deck-level performance analytics and due-card filtering queue (`DeckAnalytics`, `SpacedRepetitionEngine`).
- Zero external runtime dependencies; multi-platform and WebAssembly compatible.

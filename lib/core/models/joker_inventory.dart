import 'dart:math' as math;

import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';

class JokerInventory {
  static const maxPerType = 99;
  final int bomb;
  final int wildcard;
  final int reducer;
  final int radar;
  final int evolution;
  final int megaBomb;

  const JokerInventory({
    this.bomb = JokerStartingCounts.bomb,
    this.wildcard = JokerStartingCounts.wildcard,
    this.reducer = JokerStartingCounts.reducer,
    this.radar = 0,
    this.evolution = 0,
    this.megaBomb = 0,
  });

  const JokerInventory.initial()
      : bomb = JokerStartingCounts.bomb,
        wildcard = JokerStartingCounts.wildcard,
        reducer = JokerStartingCounts.reducer,
        radar = JokerStartingCounts.radar,
        evolution = JokerStartingCounts.evolution,
        megaBomb = JokerStartingCounts.megaBomb;

  int countOf(JokerType type) => switch (type) {
        JokerType.bomb => bomb,
        JokerType.wildcard => wildcard,
        JokerType.reducer => reducer,
        JokerType.radar => radar,
        JokerType.evolution => evolution,
        JokerType.megaBomb => megaBomb,
      };

  JokerInventory use(JokerType type) => switch (type) {
        JokerType.bomb => copyWith(bomb: bomb - 1),
        JokerType.wildcard => copyWith(wildcard: wildcard - 1),
        JokerType.reducer => copyWith(reducer: reducer - 1),
        JokerType.radar => copyWith(radar: radar - 1),
        JokerType.evolution => copyWith(evolution: evolution - 1),
        JokerType.megaBomb => copyWith(megaBomb: megaBomb - 1),
      };

  JokerInventory add(JokerType type, [int amount = 1]) => switch (type) {
        JokerType.bomb => copyWith(bomb: math.min(bomb + amount, maxPerType)),
        JokerType.wildcard => copyWith(wildcard: math.min(wildcard + amount, maxPerType)),
        JokerType.reducer => copyWith(reducer: math.min(reducer + amount, maxPerType)),
        JokerType.radar => copyWith(radar: math.min(radar + amount, maxPerType)),
        JokerType.evolution => copyWith(evolution: math.min(evolution + amount, maxPerType)),
        JokerType.megaBomb => copyWith(megaBomb: math.min(megaBomb + amount, maxPerType)),
      };

  JokerInventory addAll(int amount) {
    return JokerInventory(
      bomb: bomb + amount,
      wildcard: wildcard + amount,
      reducer: reducer + amount,
      radar: radar + amount,
      evolution: evolution + amount,
      megaBomb: megaBomb + amount,
    );
  }

  JokerInventory copyWith({
    int? bomb,
    int? wildcard,
    int? reducer,
    int? radar,
    int? evolution,
    int? megaBomb,
  }) {
    return JokerInventory(
      bomb: bomb ?? this.bomb,
      wildcard: wildcard ?? this.wildcard,
      reducer: reducer ?? this.reducer,
      radar: radar ?? this.radar,
      evolution: evolution ?? this.evolution,
      megaBomb: megaBomb ?? this.megaBomb,
    );
  }

  /// Merge two inventories by taking the max of each joker type.
  /// Used when a guest signs in to avoid losing locally-purchased jokers.
  JokerInventory mergeMax(JokerInventory other) => JokerInventory(
        bomb: math.max(bomb, other.bomb),
        wildcard: math.max(wildcard, other.wildcard),
        reducer: math.max(reducer, other.reducer),
        radar: math.max(radar, other.radar),
        evolution: math.max(evolution, other.evolution),
        megaBomb: math.max(megaBomb, other.megaBomb),
      );

  Map<String, int> toMap() => {
        'bomb': bomb,
        'wildcard': wildcard,
        'reducer': reducer,
        'radar': radar,
        'evolution': evolution,
        'megaBomb': megaBomb,
      };

  factory JokerInventory.fromMap(Map<String, Object?> map) {
    return JokerInventory(
      bomb: map['bomb'] as int? ?? 0,
      wildcard: map['wildcard'] as int? ?? 0,
      reducer: map['reducer'] as int? ?? 0,
      radar: map['radar'] as int? ?? 0,
      evolution: map['evolution'] as int? ?? 0,
      megaBomb: map['megaBomb'] as int? ?? 0,
    );
  }
}

import 'package:shape_merge/core/constants/joker_types.dart';

class JokerInventory {
  final int bomb;
  final int wildcard;
  final int reducer;
  final int radar;
  final int evolution;
  final int megaBomb;

  const JokerInventory({
    this.bomb = initialJokerCount,
    this.wildcard = initialJokerCount,
    this.reducer = initialJokerCount,
    this.radar = 0,
    this.evolution = 0,
    this.megaBomb = 0,
  });

  const JokerInventory.initial()
      : bomb = initialJokerCount,
        wildcard = initialJokerCount,
        reducer = initialJokerCount,
        radar = initialRadarCount,
        evolution = initialEvolutionCount,
        megaBomb = initialMegaBombCount;

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
        JokerType.bomb => copyWith(bomb: bomb + amount),
        JokerType.wildcard => copyWith(wildcard: wildcard + amount),
        JokerType.reducer => copyWith(reducer: reducer + amount),
        JokerType.radar => copyWith(radar: radar + amount),
        JokerType.evolution => copyWith(evolution: evolution + amount),
        JokerType.megaBomb => copyWith(megaBomb: megaBomb + amount),
      };

  JokerInventory addAll(int amount) {
    return JokerInventory(
      bomb: bomb + amount,
      wildcard: wildcard + amount,
      reducer: reducer + amount,
      radar: radar,
      evolution: evolution,
      megaBomb: megaBomb,
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

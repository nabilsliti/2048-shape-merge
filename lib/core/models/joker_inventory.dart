import 'package:shape_merge/core/constants/joker_types.dart';

class JokerInventory {
  final int bomb;
  final int wildcard;
  final int reducer;

  const JokerInventory({
    this.bomb = initialJokerCount,
    this.wildcard = initialJokerCount,
    this.reducer = initialJokerCount,
  });

  int countOf(JokerType type) => switch (type) {
        JokerType.bomb => bomb,
        JokerType.wildcard => wildcard,
        JokerType.reducer => reducer,
      };

  JokerInventory use(JokerType type) {
    return switch (type) {
      JokerType.bomb => copyWith(bomb: bomb - 1),
      JokerType.wildcard => copyWith(wildcard: wildcard - 1),
      JokerType.reducer => copyWith(reducer: reducer - 1),
    };
  }

  JokerInventory add(JokerType type, [int amount = 1]) {
    return switch (type) {
      JokerType.bomb => copyWith(bomb: bomb + amount),
      JokerType.wildcard => copyWith(wildcard: wildcard + amount),
      JokerType.reducer => copyWith(reducer: reducer + amount),
    };
  }

  JokerInventory addAll(int amount) {
    return JokerInventory(
      bomb: bomb + amount,
      wildcard: wildcard + amount,
      reducer: reducer + amount,
    );
  }

  JokerInventory copyWith({int? bomb, int? wildcard, int? reducer}) {
    return JokerInventory(
      bomb: bomb ?? this.bomb,
      wildcard: wildcard ?? this.wildcard,
      reducer: reducer ?? this.reducer,
    );
  }

  Map<String, int> toMap() => {
        'bomb': bomb,
        'wildcard': wildcard,
        'reducer': reducer,
      };

  factory JokerInventory.fromMap(Map<String, Object?> map) {
    return JokerInventory(
      bomb: map['bomb'] as int? ?? 0,
      wildcard: map['wildcard'] as int? ?? 0,
      reducer: map['reducer'] as int? ?? 0,
    );
  }
}

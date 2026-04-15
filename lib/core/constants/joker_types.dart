enum JokerType { bomb, wildcard, reducer, radar, evolution, megaBomb }

extension JokerTypeX on JokerType {
  bool get isPremium =>
      this == JokerType.radar ||
      this == JokerType.evolution ||
      this == JokerType.megaBomb;
}

enum JokerType { bomb, wildcard, reducer, radar, evolution, megaBomb }

const int initialJokerCount = 5;
const int initialRadarCount = 3;
const int initialEvolutionCount = 2;
const int initialMegaBombCount = 2;

extension JokerTypeX on JokerType {
  bool get isPremium =>
      this == JokerType.radar ||
      this == JokerType.evolution ||
      this == JokerType.megaBomb;
}

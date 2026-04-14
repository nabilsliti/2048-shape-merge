import 'package:shape_merge/core/config/game_tuning.dart';

enum JokerType { bomb, wildcard, reducer, radar, evolution, megaBomb }

/// @Deprecated('Use JokerStartingCounts.bomb etc.')
const int initialJokerCount = JokerStartingCounts.bomb;
/// @Deprecated('Use JokerStartingCounts.radar')
const int initialRadarCount = JokerStartingCounts.radar;
/// @Deprecated('Use JokerStartingCounts.evolution')
const int initialEvolutionCount = JokerStartingCounts.evolution;
/// @Deprecated('Use JokerStartingCounts.megaBomb')
const int initialMegaBombCount = JokerStartingCounts.megaBomb;

extension JokerTypeX on JokerType {
  bool get isPremium =>
      this == JokerType.radar ||
      this == JokerType.evolution ||
      this == JokerType.megaBomb;
}

// Re-export from game_tuning so existing imports keep working.
// New code should import game_tuning.dart directly.
export 'package:shape_merge/core/config/game_tuning.dart'
    show BoardTuning, ShapeSizing, Scoring;

import 'package:shape_merge/core/config/game_tuning.dart';

/// @Deprecated('Use BoardTuning.maxShapes')
const int maxShapes = BoardTuning.maxShapes;
/// @Deprecated('Use BoardTuning.startShapes')
const int startShapes = BoardTuning.startShapes;
/// @Deprecated('Use BoardTuning.spawnPerMove')
const int spawnPerMove = BoardTuning.spawnPerMove;
/// @Deprecated('Use BoardTuning.snapRadius')
const double snapRadius = BoardTuning.snapRadius;
/// @Deprecated('Use BoardTuning.maxSpawnAttempts')
const int maxSpawnAttempts = BoardTuning.maxSpawnAttempts;
/// @Deprecated('Use BoardTuning.smartSpawnChance')
const double smartSpawnChance = BoardTuning.smartSpawnChance;
/// @Deprecated('Use BoardTuning.levelCopyChance')
const double levelCopyChance = BoardTuning.levelCopyChance;

/// @Deprecated('Use ShapeSizing.forLevel()')
double shapeSize(int level) => ShapeSizing.forLevel(level);

/// @Deprecated('Use Scoring.forMerge()')
int scoreForMerge(int newLevel) => Scoring.forMerge(newLevel);

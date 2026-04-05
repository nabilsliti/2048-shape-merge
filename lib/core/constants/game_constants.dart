const int maxLevel = 8;
const int maxShapes = 30;
const int startShapes = 10;
const int spawnPerMove = 1;
const double snapRadius = 60.0;
const int maxSpawnAttempts = 40;
const double smartSpawnChance = 0.70;
const double levelCopyChance = 0.55;

double shapeSize(int level) {
  final size = 38.0 + level * 8.0;
  return size > 86.0 ? 86.0 : size;
}

int scoreForMerge(int newLevel) => (1 << newLevel) * 10;

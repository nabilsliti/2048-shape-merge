const int maxShapes = 32;
const int startShapes = 8;
const int spawnPerMove = 1;
const double snapRadius = 60.0;
const int maxSpawnAttempts = 80;
const double smartSpawnChance = 0.60;
const double levelCopyChance = 0.55;

double shapeSize(int level) {
  final size = 49.0 + level * 6.0;
  return size > 82.0 ? 82.0 : size;
}

int scoreForMerge(int newLevel) => (1 << newLevel) * 10;

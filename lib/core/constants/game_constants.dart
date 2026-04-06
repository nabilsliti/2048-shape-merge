const int maxShapes = 30;
const int startShapes = 10;
const int spawnPerMove = 1;
const double snapRadius = 60.0;
const int maxSpawnAttempts = 80;
const double smartSpawnChance = 0.60;
const double levelCopyChance = 0.55;

double shapeSize(int level) {
  final size = 50.0 + level * 7.0;
  return size > 85.0 ? 85.0 : size;
}

int scoreForMerge(int newLevel) => (1 << newLevel) * 10;

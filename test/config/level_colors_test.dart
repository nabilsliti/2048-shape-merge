import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/level_colors.dart';

void main() {
  group('LevelColors.forLevel', () {
    test('level 1 → first color', () {
      expect(LevelColors.forLevel(1), LevelColors.palette.first);
    });

    test('level matches index (1-based)', () {
      for (var i = 0; i < LevelColors.palette.length; i++) {
        expect(LevelColors.forLevel(i + 1), LevelColors.palette[i]);
      }
    });

    test('level beyond palette → clamped to last color', () {
      expect(LevelColors.forLevel(999), LevelColors.palette.last);
    });

    test('level 0 or negative → first color (clamped)', () {
      expect(LevelColors.forLevel(0), LevelColors.palette.first);
      expect(LevelColors.forLevel(-5), LevelColors.palette.first);
    });
  });
}

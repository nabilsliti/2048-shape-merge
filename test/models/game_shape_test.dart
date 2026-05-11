import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';

void main() {
  GameShape make({
    String id = 'a',
    ShapeType type = ShapeType.circle,
    Color color = const Color(0xFF4FC3F7),
    int level = 1,
    bool isWildcard = false,
  }) =>
      GameShape(
        id: id, x: 0, y: 0,
        type: type, color: color, level: level,
        isWildcard: isWildcard,
      );

  group('GameShape', () {
    test('value = 2^level', () {
      expect(make(level: 1).value, 2);
      expect(make(level: 5).value, 32);
      expect(make(level: 10).value, 1024);
    });

    test('canMergeWith requires same level', () {
      expect(make(level: 1).canMergeWith(make(id: 'b', level: 2)), false);
    });

    test('canMergeWith same type+color+level → true', () {
      expect(make().canMergeWith(make(id: 'b')), true);
    });

    test('canMergeWith different type → false', () {
      expect(
        make().canMergeWith(make(id: 'b', type: ShapeType.square)),
        false,
      );
    });

    test('canMergeWith different color → false', () {
      expect(
        make().canMergeWith(make(id: 'b', color: const Color(0xFF69F0AE))),
        false,
      );
    });

    test('canMergeWith wildcard ignores type/color (level still required)', () {
      final wildcard = make(id: 'w', type: ShapeType.star,
          color: Colors.white, isWildcard: true);
      expect(wildcard.canMergeWith(make()), true);
      expect(make().canMergeWith(wildcard), true);
      // Different level still blocks
      expect(
        wildcard.canMergeWith(make(id: 'b', level: 2)),
        false,
      );
    });

    test('copyWith overrides only supplied fields', () {
      final s = make(level: 3);
      final updated = s.copyWith(level: 4, x: 99);
      expect(updated.level, 4);
      expect(updated.x, 99);
      expect(updated.id, s.id);
      expect(updated.type, s.type);
      expect(updated.color, s.color);
      expect(updated.isWildcard, s.isWildcard);
    });
  });
}

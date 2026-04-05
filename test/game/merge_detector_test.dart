import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/game/logic/merge_detector.dart';

void main() {
  group('MergeDetector', () {
    final shapeA = GameShape(
      id: 'a', x: 0, y: 0,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
    );
    final shapeB = GameShape(
      id: 'b', x: 10, y: 0,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
    );
    final shapeDiffType = GameShape(
      id: 'c', x: 20, y: 0,
      type: ShapeType.square, color: const Color(0xFF4FC3F7), level: 1,
    );
    final shapeDiffColor = GameShape(
      id: 'd', x: 30, y: 0,
      type: ShapeType.circle, color: const Color(0xFF69F0AE), level: 1,
    );
    final shapeDiffLevel = GameShape(
      id: 'e', x: 40, y: 0,
      type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 2,
    );

    test('canMerge with identical shapes returns true', () {
      expect(MergeDetector.canMerge(shapeA, shapeB), true);
    });

    test('canMerge with same shape returns false', () {
      expect(MergeDetector.canMerge(shapeA, shapeA), false);
    });

    test('canMerge with different type returns false', () {
      expect(MergeDetector.canMerge(shapeA, shapeDiffType), false);
    });

    test('canMerge with different color returns false', () {
      expect(MergeDetector.canMerge(shapeA, shapeDiffColor), false);
    });

    test('canMerge with different level returns false', () {
      expect(MergeDetector.canMerge(shapeA, shapeDiffLevel), false);
    });

    test('canMerge with wildcard returns true regardless of type/color', () {
      final wildcard = GameShape(
        id: 'w', x: 0, y: 0,
        type: ShapeType.star, color: Colors.white, level: 1,
        isWildcard: true,
      );
      expect(MergeDetector.canMerge(wildcard, shapeA), true);
      expect(MergeDetector.canMerge(shapeA, wildcard), true);
    });

    test('hasPairs returns true when pairs exist', () {
      expect(MergeDetector.hasPairs([shapeA, shapeB]), true);
    });

    test('hasPairs returns false when no pairs', () {
      expect(MergeDetector.hasPairs([shapeA, shapeDiffType, shapeDiffColor]),
          false);
    });

    test('countPairs counts correctly', () {
      final shapes = [shapeA, shapeB, shapeDiffType, shapeDiffColor];
      expect(MergeDetector.countPairs(shapes), 1);
    });

    test('findBestTarget returns closest match within snap radius', () {
      final nearMatch = GameShape(
        id: 'near', x: 50, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );
      final farMatch = GameShape(
        id: 'far', x: 200, y: 0,
        type: ShapeType.circle, color: const Color(0xFF4FC3F7), level: 1,
      );

      final result = MergeDetector.findBestTarget(
        shapeA,
        [nearMatch, farMatch],
        const Offset(45, 0),
      );
      expect(result?.id, 'near');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/game_tuning.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/constants/shape_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/game/logic/joker_suggestion_engine.dart';

void main() {
  GameShape mk(String id, {int level = 1, ShapeType type = ShapeType.circle}) =>
      GameShape(
        id: id, x: 0, y: 0,
        type: type, color: const Color(0xFF4FC3F7), level: level,
      );

  // Inventory containing every joker, so triggers select on board state alone.
  const fullInv = JokerInventory(
    bomb: 5, wildcard: 5, reducer: 5,
    radar: 5, evolution: 5, megaBomb: 5,
  );

  // Padding helper to reach a desired board fill ratio.
  List<GameShape> pad(int n, {int level = 1}) =>
      List.generate(n, (i) => mk('pad_$i', level: level));

  group('cooldown gate', () {
    test('returns null while cooldown not elapsed', () {
      final s = JokerSuggestionEngine.evaluate(
        shapes: pad(BoardTuning.maxShapes),
        inventory: fullInv,
        recentMergeRate: 0.1,
        movesSinceLastSuggestion: SuggestionTuning.cooldownMoves - 1,
      );
      expect(s, isNull);
    });
  });

  group('low fill gate', () {
    test('returns null when fewer than minFillToSuggest shapes', () {
      final s = JokerSuggestionEngine.evaluate(
        shapes: pad(2),
        inventory: fullInv,
        recentMergeRate: 0.0,
        movesSinceLastSuggestion: 999,
      );
      expect(s, isNull);
    });
  });

  group('critical (board nearly full, no pairs)', () {
    test('mostly singletons → suggests bomb (or megaBomb if cluster)', () {
      // 30 shapes (≥ 90% of max=32), all distinct types/colors so 0 pairs
      final shapes = <GameShape>[];
      for (var i = 0; i < 30; i++) {
        final type = ShapeType.values[i % ShapeType.values.length];
        // Distinct color per shape: tweak alpha so no two share color
        final color = Color(0xFF000000 | (i * 13));
        shapes.add(GameShape(
          id: '$i', x: 0, y: 0, type: type, color: color, level: 1,
        ));
      }
      final s = JokerSuggestionEngine.evaluate(
        shapes: shapes,
        inventory: const JokerInventory(bomb: 1),
        recentMergeRate: 0.5,
        movesSinceLastSuggestion: 999,
      );
      expect(s, isNotNull);
      expect(s!.urgency, SuggestionUrgency.critical);
      expect(s.type, JokerType.bomb);
    });

    test('falls back to reducer when no bomb available', () {
      final shapes = <GameShape>[];
      for (var i = 0; i < 30; i++) {
        shapes.add(GameShape(
          id: '$i', x: 0, y: 0,
          type: ShapeType.values[i % ShapeType.values.length],
          color: Color(0xFF000000 | (i * 13)),
          level: 1,
        ));
      }
      final s = JokerSuggestionEngine.evaluate(
        shapes: shapes,
        inventory: const JokerInventory(bomb: 0, reducer: 1),
        recentMergeRate: 0.5,
        movesSinceLastSuggestion: 999,
      );
      expect(s?.type, JokerType.reducer);
      expect(s?.urgency, SuggestionUrgency.critical);
    });
  });

  group('megaBomb cluster', () {
    test('≥4 shapes at same level + high fill → suggests megaBomb', () {
      // Fill the board to trigger the HIGH branch (fillRatio ≥ 0.75).
      // 4 shapes at level 5 (the "cluster") + 24 distinct level-1 fillers.
      final shapes = <GameShape>[
        ...List.generate(4, (i) => mk('cluster_$i', level: 5,
            type: ShapeType.values[i])),
        ...List.generate(24, (i) => GameShape(
              id: 'pad_$i', x: 0, y: 0,
              type: ShapeType.values[i % ShapeType.values.length],
              color: Color(0xFF000000 | (i * 17 + 1)),
              level: 1,
            )),
      ];
      final s = JokerSuggestionEngine.evaluate(
        shapes: shapes,
        inventory: fullInv,
        recentMergeRate: 0.5,
        movesSinceLastSuggestion: 999,
      );
      expect(s, isNotNull);
      expect(s!.type, JokerType.megaBomb);
    });

    test('cluster but no megaBomb → returns a different suggestion', () {
      final shapes = [
        ...List.generate(4, (i) => mk('c_$i', level: 5)),
        ...pad(20),
      ];
      final s = JokerSuggestionEngine.evaluate(
        shapes: shapes,
        inventory: const JokerInventory(megaBomb: 0, bomb: 1, wildcard: 0),
        recentMergeRate: 0.5,
        movesSinceLastSuggestion: 999,
      );
      // Should not be megaBomb (none in inventory)
      expect(s?.type != JokerType.megaBomb, true);
    });
  });

  group('struggling (low merge rate)', () {
    test('low merge rate at medium fill → suggests radar', () {
      final s = JokerSuggestionEngine.evaluate(
        shapes: pad(BoardTuning.maxShapes ~/ 2),
        inventory: const JokerInventory(radar: 1),
        recentMergeRate: 0.1,
        movesSinceLastSuggestion: 999,
      );
      expect(s?.type, JokerType.radar);
      expect(s?.urgency, SuggestionUrgency.medium);
    });
  });
}

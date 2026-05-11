import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';

void main() {
  group('JokerInventory', () {
    test('default constructor uses starting counts (matches initial())', () {
      const inv = JokerInventory();
      const init = JokerInventory.initial();
      expect(inv.bomb, init.bomb);
      expect(inv.wildcard, init.wildcard);
      expect(inv.reducer, init.reducer);
    });

    test('countOf returns the correct field per type', () {
      const inv = JokerInventory(
        bomb: 1, wildcard: 2, reducer: 3,
        radar: 4, evolution: 5, megaBomb: 6,
      );
      expect(inv.countOf(JokerType.bomb), 1);
      expect(inv.countOf(JokerType.wildcard), 2);
      expect(inv.countOf(JokerType.reducer), 3);
      expect(inv.countOf(JokerType.radar), 4);
      expect(inv.countOf(JokerType.evolution), 5);
      expect(inv.countOf(JokerType.megaBomb), 6);
    });

    test('use decrements the corresponding count', () {
      const inv = JokerInventory(bomb: 3, wildcard: 3, reducer: 3);
      expect(inv.use(JokerType.bomb).bomb, 2);
      expect(inv.use(JokerType.wildcard).wildcard, 2);
      expect(inv.use(JokerType.reducer).reducer, 2);
    });

    test('add caps at maxPerType (99)', () {
      const inv = JokerInventory(bomb: 95);
      final added = inv.add(JokerType.bomb, 100);
      expect(added.bomb, JokerInventory.maxPerType);
    });

    test('add with default amount adds 1', () {
      const inv = JokerInventory(bomb: 0);
      expect(inv.add(JokerType.bomb).bomb, 1);
    });

    test('addAll bumps every type by the same amount (no cap)', () {
      const inv = JokerInventory(
        bomb: 1, wildcard: 1, reducer: 1,
        radar: 1, evolution: 1, megaBomb: 1,
      );
      final result = inv.addAll(2);
      expect(result.bomb, 3);
      expect(result.wildcard, 3);
      expect(result.reducer, 3);
      expect(result.radar, 3);
      expect(result.evolution, 3);
      expect(result.megaBomb, 3);
    });

    test('mergeMax keeps the max of each field', () {
      const a = JokerInventory(
        bomb: 5, wildcard: 1, reducer: 7,
        radar: 0, evolution: 4, megaBomb: 2,
      );
      const b = JokerInventory(
        bomb: 2, wildcard: 9, reducer: 3,
        radar: 5, evolution: 4, megaBomb: 0,
      );
      final merged = a.mergeMax(b);
      expect(merged.bomb, 5);
      expect(merged.wildcard, 9);
      expect(merged.reducer, 7);
      expect(merged.radar, 5);
      expect(merged.evolution, 4);
      expect(merged.megaBomb, 2);
    });

    test('toMap → fromMap round-trip', () {
      const inv = JokerInventory(
        bomb: 1, wildcard: 2, reducer: 3,
        radar: 4, evolution: 5, megaBomb: 6,
      );
      final restored = JokerInventory.fromMap(inv.toMap());
      expect(restored.bomb, 1);
      expect(restored.wildcard, 2);
      expect(restored.reducer, 3);
      expect(restored.radar, 4);
      expect(restored.evolution, 5);
      expect(restored.megaBomb, 6);
    });

    test('fromMap with missing keys defaults to 0', () {
      final inv = JokerInventory.fromMap(const {});
      expect(inv.bomb, 0);
      expect(inv.wildcard, 0);
      expect(inv.reducer, 0);
      expect(inv.radar, 0);
      expect(inv.evolution, 0);
      expect(inv.megaBomb, 0);
    });

    test('copyWith only overrides supplied fields', () {
      const inv = JokerInventory(bomb: 1, wildcard: 2, reducer: 3);
      final updated = inv.copyWith(bomb: 9);
      expect(updated.bomb, 9);
      expect(updated.wildcard, 2);
      expect(updated.reducer, 3);
    });
  });

  group('JokerTypeX.isPremium', () {
    test('radar/evolution/megaBomb are premium', () {
      expect(JokerType.radar.isPremium, true);
      expect(JokerType.evolution.isPremium, true);
      expect(JokerType.megaBomb.isPremium, true);
    });

    test('bomb/wildcard/reducer are not premium', () {
      expect(JokerType.bomb.isPremium, false);
      expect(JokerType.wildcard.isPremium, false);
      expect(JokerType.reducer.isPremium, false);
    });
  });
}

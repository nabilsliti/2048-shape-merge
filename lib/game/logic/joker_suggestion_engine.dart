import 'package:shape_merge/core/constants/game_constants.dart';
import 'package:shape_merge/core/constants/joker_types.dart';
import 'package:shape_merge/core/models/game_shape.dart';
import 'package:shape_merge/core/models/joker_inventory.dart';
import 'package:shape_merge/game/logic/merge_detector.dart';

/// Priority level for joker suggestions.
enum SuggestionUrgency { low, medium, high, critical }

/// A suggestion to use a specific joker type at the right moment.
class JokerSuggestion {
  final JokerType type;
  final SuggestionUrgency urgency;
  final String reasonKey; // l10n key for the reason text

  const JokerSuggestion({
    required this.type,
    required this.urgency,
    required this.reasonKey,
  });
}

/// Pure logic engine — analyzes board state and returns the best joker to suggest.
///
/// Trigger conditions (checked in priority order):
/// 1. **Critical** — board ≥90% full & ≤2 pairs → Bomb/MegaBomb
/// 2. **High** — board ≥75% full → Bomb or MegaBomb (if many same-level)
/// 3. **Medium** — low merge rate (<30%) for last 20 attempts → Radar
/// 4. **Medium** — a dominant level cluster (≥4 same-level shapes) → MegaBomb
/// 5. **Low** — high-level shape with no pair → Reducer or Evolution
class JokerSuggestionEngine {
  const JokerSuggestionEngine._();

  /// Returns the best suggestion, or `null` if no suggestion is appropriate.
  ///
  /// [shapes] — current board shapes
  /// [inventory] — available jokers
  /// [recentMergeRate] — 0.0–1.0 success rate of last 20 drags
  /// [movesSinceLastSuggestion] — avoid spamming; require ≥5 moves between suggestions
  static JokerSuggestion? evaluate({
    required List<GameShape> shapes,
    required JokerInventory inventory,
    required double recentMergeRate,
    required int movesSinceLastSuggestion,
  }) {
    // Don't spam — at least 5 moves between suggestions
    if (movesSinceLastSuggestion < 5) return null;

    // Don't suggest if board is mostly empty
    if (shapes.length < maxShapes * 0.5) return null;

    final fillRatio = shapes.length / maxShapes;
    final pairCount = MergeDetector.countPairs(shapes);

    // ── 1. CRITICAL — about to game over ──
    if (fillRatio >= 0.9 && pairCount <= 2) {
      final megaBombSuggestion = _suggestMegaBombIfWorthIt(shapes, inventory);
      if (megaBombSuggestion != null) return megaBombSuggestion;

      if (inventory.bomb > 0) {
        return const JokerSuggestion(
          type: JokerType.bomb,
          urgency: SuggestionUrgency.critical,
          reasonKey: 'jokerSuggestCriticalBomb',
        );
      }

      if (inventory.reducer > 0) {
        return const JokerSuggestion(
          type: JokerType.reducer,
          urgency: SuggestionUrgency.critical,
          reasonKey: 'jokerSuggestCriticalReducer',
        );
      }
    }

    // ── 2. HIGH — board getting full ──
    if (fillRatio >= 0.75) {
      final megaBombSuggestion = _suggestMegaBombIfWorthIt(shapes, inventory);
      if (megaBombSuggestion != null) return megaBombSuggestion;

      if (inventory.bomb > 0) {
        return const JokerSuggestion(
          type: JokerType.bomb,
          urgency: SuggestionUrgency.high,
          reasonKey: 'jokerSuggestHighBomb',
        );
      }
    }

    // ── 3. MEDIUM — struggling (low merge rate) ──
    if (recentMergeRate < 0.30 && fillRatio >= 0.5) {
      if (inventory.radar > 0) {
        return const JokerSuggestion(
          type: JokerType.radar,
          urgency: SuggestionUrgency.medium,
          reasonKey: 'jokerSuggestRadar',
        );
      }
      if (inventory.wildcard > 0) {
        return const JokerSuggestion(
          type: JokerType.wildcard,
          urgency: SuggestionUrgency.medium,
          reasonKey: 'jokerSuggestWildcard',
        );
      }
    }

    // ── 4. MEDIUM — dominant level cluster ──
    final clusterSuggestion = _suggestMegaBombIfWorthIt(shapes, inventory);
    if (clusterSuggestion != null && fillRatio >= 0.6) {
      return clusterSuggestion;
    }

    // ── 5. LOW — lonely high-level shape ──
    if (fillRatio >= 0.5) {
      final lonely = _findLonelyHighLevel(shapes);
      if (lonely != null) {
        if (inventory.evolution > 0) {
          return const JokerSuggestion(
            type: JokerType.evolution,
            urgency: SuggestionUrgency.low,
            reasonKey: 'jokerSuggestEvolution',
          );
        }
        if (inventory.reducer > 0) {
          return const JokerSuggestion(
            type: JokerType.reducer,
            urgency: SuggestionUrgency.low,
            reasonKey: 'jokerSuggestReducer',
          );
        }
      }
    }

    return null;
  }

  /// Returns a MegaBomb suggestion if there's a level cluster of ≥4 shapes.
  static JokerSuggestion? _suggestMegaBombIfWorthIt(
    List<GameShape> shapes,
    JokerInventory inventory,
  ) {
    if (inventory.megaBomb <= 0) return null;

    final levelCounts = <int, int>{};
    for (final s in shapes) {
      levelCounts[s.level] = (levelCounts[s.level] ?? 0) + 1;
    }

    // Find the level with most shapes (≥4 to be worth a megaBomb)
    var maxCount = 0;
    for (final count in levelCounts.values) {
      if (count > maxCount) maxCount = count;
    }

    if (maxCount >= 4) {
      return const JokerSuggestion(
        type: JokerType.megaBomb,
        urgency: SuggestionUrgency.high,
        reasonKey: 'jokerSuggestMegaBomb',
      );
    }

    return null;
  }

  /// Finds a high-level shape (≥3) that has no merge partner.
  static GameShape? _findLonelyHighLevel(List<GameShape> shapes) {
    for (final s in shapes) {
      if (s.level < 3) continue;
      final hasPair = shapes.any((o) => o.id != s.id && MergeDetector.canMerge(s, o));
      if (!hasPair) return s;
    }
    return null;
  }
}

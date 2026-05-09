import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the currently active branch in the bottom navigation
/// (`StatefulShellRoute.indexedStack`). Published by `AdShell` on every build
/// and consumed by tab content widgets that need to pause animations / heavy
/// work when their tab is not visible.
///
/// Branch indexes:
///   0 = Shop
///   1 = Leaderboard
///   2 = Home (center)
///   3 = Profile
///   4 = Settings
final currentBranchIndexProvider = StateProvider<int>((_) => 2);

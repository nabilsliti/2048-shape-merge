import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/player.dart';
import 'package:shape_merge/providers/auth_providers.dart';
import 'package:shape_merge/providers/leaderboard_provider.dart';

final playerProvider = FutureProvider<Player?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final player = await ref.watch(firestoreServiceProvider).getPlayer(user.uid);
  if (player != null) return player;
  // First time: create player from Google profile
  return Player(
    uid: user.uid,
    displayName: user.displayName ?? user.email ?? 'Player',
    photoUrl: user.photoURL,
  );
});

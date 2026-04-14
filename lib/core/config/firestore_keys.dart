// ─────────────────────────────────────────────────────────────
// Firestore Keys — collection/document names.
//
// To rename a collection: change here + run migration.
// ─────────────────────────────────────────────────────────────

abstract final class FirestoreKeys {
  static const leaderboard = 'leaderboard';
  static const players = 'players';
  static const playerData = 'data';
  static const dailyChallenges = 'dailyChallenges';
}

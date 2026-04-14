// ─────────────────────────────────────────────────────────────
// App Routes — all route paths in one place.
//
// To add a new route: add a constant here, then register
// in app.dart GoRouter config.
// ─────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const game = '/home/game';
  static const shop = '/shop';
  static const leaderboard = '/leaderboard';
}

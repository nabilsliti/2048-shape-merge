import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` while the post-sign-in account merge is running (replay pending
/// purchases, fetch player from Firestore, merge guest jokers/XP/scores).
///
/// While true, the app shows a full-screen overlay (see `AccountSyncOverlay`)
/// to prevent the visible "joker count jumps" the user would otherwise see
/// when local guest values are replaced by the merged Firestore values.
final accountSyncProvider = StateProvider<bool>((_) => false);

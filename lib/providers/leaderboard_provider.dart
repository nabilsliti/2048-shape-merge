import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';
import 'package:shape_merge/core/services/firestore_service.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(firestoreServiceProvider).leaderboardStream();
});

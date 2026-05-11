import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry.fromFirestore', () {
    test('uses explicit uid when present', () {
      final e = LeaderboardEntry.fromFirestore('docABC', {
        'uid': 'realUid',
        'displayName': 'Alice',
        'score': 1000,
        'maxLevel': 7,
        'mergeCount': 50,
        'timestamp': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });
      expect(e.uid, 'realUid');
      expect(e.docId, 'docABC');
    });

    test('falls back to docId when uid is missing', () {
      final e = LeaderboardEntry.fromFirestore('player_42', {
        'displayName': 'Bob',
        'score': 500,
        'maxLevel': 3,
        'mergeCount': 10,
      });
      expect(e.uid, 'player_42');
    });

    test('falls back to docId when uid is empty string', () {
      final e = LeaderboardEntry.fromFirestore('player_99', {
        'uid': '',
        'displayName': 'Eve',
        'score': 0,
        'maxLevel': 1,
        'mergeCount': 0,
      });
      expect(e.uid, 'player_99');
    });

    test('defaults missing numeric fields to safe values', () {
      final e = LeaderboardEntry.fromFirestore('x', const {});
      expect(e.displayName, '');
      expect(e.score, 0);
      expect(e.maxLevel, 1);
      expect(e.mergeCount, 0);
      expect(e.uid, 'x');
    });

    test('toFirestore round-trip preserves fields', () {
      final original = LeaderboardEntry(
        uid: 'u1',
        displayName: 'Carol',
        photoUrl: 'https://example.com/a.png',
        avatarId: 'cat',
        score: 1234,
        maxLevel: 8,
        mergeCount: 77,
        timestamp: DateTime.utc(2026, 5, 11, 12, 0),
      );
      final restored = LeaderboardEntry.fromFirestore('u1', original.toFirestore());
      expect(restored.uid, 'u1');
      expect(restored.displayName, 'Carol');
      expect(restored.photoUrl, 'https://example.com/a.png');
      expect(restored.avatarId, 'cat');
      expect(restored.score, 1234);
      expect(restored.maxLevel, 8);
      expect(restored.mergeCount, 77);
      expect(restored.timestamp.toUtc(), original.timestamp);
    });

    test('falls back to DateTime.now when timestamp is missing', () {
      final before = DateTime.now();
      final e = LeaderboardEntry.fromFirestore('x', const {});
      final after = DateTime.now();
      expect(e.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(e.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });
}

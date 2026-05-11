import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/config/challenge_config.dart';

void main() {
  group('ChallengeTargets.target', () {
    test('returns matrix value for known type+difficulty', () {
      expect(ChallengeTargets.target('fusions', 'easy'), 10);
      expect(ChallengeTargets.target('fusions', 'medium'), 25);
      expect(ChallengeTargets.target('fusions', 'hard'), 50);
      expect(ChallengeTargets.target('score', 'hard'), 6000);
    });

    test('returns 1 (default) for unknown type', () {
      expect(ChallengeTargets.target('does_not_exist', 'easy'), 1);
    });

    test('returns 1 (default) for unknown difficulty', () {
      expect(ChallengeTargets.target('fusions', 'impossible'), 1);
    });

    test('every entry exposes the three difficulty levels', () {
      for (final entry in ChallengeTargets.targets.entries) {
        expect(entry.value.keys.toSet(), {'easy', 'medium', 'hard'},
            reason: '${entry.key} must declare easy/medium/hard');
      }
    });

    test('targets are monotonically increasing easy < medium < hard', () {
      for (final entry in ChallengeTargets.targets.entries) {
        final e = entry.value['easy']!;
        final m = entry.value['medium']!;
        final h = entry.value['hard']!;
        expect(e <= m, true, reason: '${entry.key}: easy <= medium');
        expect(m <= h, true, reason: '${entry.key}: medium <= hard');
      }
    });
  });

  group('ChallengeRewards', () {
    test('xp rewards declared for every difficulty', () {
      expect(ChallengeRewards.xp.keys.toSet(), {'easy', 'medium', 'hard'});
    });

    test('joker rewards declared for every difficulty', () {
      expect(ChallengeRewards.joker.keys.toSet(), {'easy', 'medium', 'hard'});
    });
  });

  group('ChallengeBands', () {
    test('thresholds are ordered easy < medium', () {
      expect(ChallengeBands.easyMaxLevel, lessThan(ChallengeBands.mediumMaxLevel));
    });
  });
}

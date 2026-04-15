import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/services/integrity_guard.dart';

void main() {
  group('IntegrityGuard', () {
    test('wrap + unwrap round-trip returns original data', () {
      const data = '{"bomb":3,"wildcard":1}';
      final wrapped = IntegrityGuard.wrap(data);
      final result = IntegrityGuard.unwrap(wrapped);
      expect(result, data);
    });

    test('unwrap returns null on tampered data', () {
      const data = '{"bomb":3,"wildcard":1}';
      final wrapped = IntegrityGuard.wrap(data);
      // Modify the data portion
      final tampered = wrapped.replaceFirst('"bomb":3', '"bomb":999');
      final result = IntegrityGuard.unwrap(tampered);
      expect(result, isNull);
    });

    test('unwrap returns null on corrupted signature', () {
      const data = 'some data';
      final wrapped = IntegrityGuard.wrap(data);
      // Corrupt the trailing signature
      final corrupted = '${wrapped.substring(0, wrapped.length - 3)}xyz';
      final result = IntegrityGuard.unwrap(corrupted);
      expect(result, isNull);
    });

    test('unwrap returns null on empty string', () {
      expect(IntegrityGuard.unwrap(''), isNull);
    });

    test('unwrap returns null on string without separator', () {
      expect(IntegrityGuard.unwrap('noseparator'), isNull);
    });

    test('sign is deterministic', () {
      const data = 'test-data';
      final sig1 = IntegrityGuard.sign(data);
      final sig2 = IntegrityGuard.sign(data);
      expect(sig1, sig2);
    });

    test('different data produces different signatures', () {
      expect(IntegrityGuard.sign('a'), isNot(IntegrityGuard.sign('b')));
    });

    test('wrap preserves data with pipe characters', () {
      const data = 'a|b|c';
      final wrapped = IntegrityGuard.wrap(data);
      final result = IntegrityGuard.unwrap(wrapped);
      expect(result, data);
    });
  });
}

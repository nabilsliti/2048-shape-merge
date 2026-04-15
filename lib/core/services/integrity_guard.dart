import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Client-side HMAC integrity check for SharedPreferences data.
///
/// NOT a replacement for server-side validation — a determined attacker
/// can reverse-engineer the key. This raises the bar enough to block
/// the vast majority of casual cheaters (XML editors, preference managers).
abstract final class IntegrityGuard {
  // Obfuscated key parts — reassembled at runtime.
  static final _key = utf8.encode(
    String.fromCharCodes([0x73, 0x68, 0x61, 0x70, 0x65]) + // "shape"
    String.fromCharCodes([0x6D, 0x65, 0x72, 0x67, 0x65]) + // "merge"
    String.fromCharCodes([0x32, 0x30, 0x34, 0x38]),         // "2048"
  );

  /// Produces a lightweight hash for [data]. Not cryptographically secure,
  /// but sufficient to detect hand-edited SharedPreferences values.
  static String sign(String data) {
    var hash = 0x811c9dc5; // FNV-1a offset basis
    final bytes = utf8.encode(data);
    for (var i = 0; i < bytes.length; i++) {
      hash ^= bytes[i];
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    // Mix in the key
    for (var i = 0; i < _key.length; i++) {
      hash ^= _key[i];
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Returns the data with its signature appended (separated by `|`).
  static String wrap(String data) => '$data|${sign(data)}';

  /// Unwraps and verifies. Returns the original data if valid, null if tampered.
  static String? unwrap(String? wrapped) {
    if (wrapped == null) return null;
    final sep = wrapped.lastIndexOf('|');
    if (sep < 0) return null;
    final data = wrapped.substring(0, sep);
    final sig = wrapped.substring(sep + 1);
    if (sig != sign(data)) {
      debugPrint('[IntegrityGuard] Tampered data detected — resetting');
      return null;
    }
    return data;
  }
}

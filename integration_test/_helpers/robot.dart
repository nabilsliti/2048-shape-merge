// High-level robot actions used by the integration test suite.
//
// Centralises the verbs (`tapNavTab`, `tapButton3D`, `toggleSwitch`, …) so
// the main suite stays readable. Anchors come from the real widget tree.
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shape_merge/core/theme/button_3d.dart';
import 'package:shape_merge/core/widgets/google_sign_in_button.dart';

/// Emit a robot step trace. Visible on host stdout via `--reporter expanded`
/// AND on-device via `adb logcat | grep ROBOT`.
void robotLog(String message) {
  // ignore: avoid_print
  debugPrint('[ROBOT] $message');
  developer.log(message, name: 'ROBOT');
}

class Robot {
  Robot(this.tester);
  final WidgetTester tester;

  // ─────────────────────────────────────────────────────────────────────────
  // Synchronisation primitives
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> waitFor(Finder finder,
      {Duration timeout = const Duration(seconds: 15)}) async {
    robotLog('waitFor $finder (timeout ${timeout.inSeconds}s)');
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        robotLog('  ✓ found $finder');
        return;
      }
    }
    robotLog('  ✖ timeout waiting for $finder');
    expect(finder, findsAtLeastNWidgets(1),
        reason: 'Timed out waiting for $finder after ${timeout.inSeconds}s');
  }

  Future<void> waitForGone(Finder finder,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isEmpty) return;
    }
  }

  Future<void> waitForHome() async {
    robotLog('waitForHome — splash → hub');
    await waitFor(find.byType(Scaffold));
    // Splash animation + first router transition + first frame of hub.
    await tester.pump(const Duration(seconds: 3));
    robotLog('  ✓ home reached');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Finders
  // ─────────────────────────────────────────────────────────────────────────

  Finder textContaining(String pattern) {
    return find.byWidgetPredicate((w) {
      if (w is Text && w.data != null) {
        return w.data!.toLowerCase().contains(pattern.toLowerCase());
      }
      return false;
    });
  }

  /// Bottom-nav tab by asset filename: `shop.webp`, `podium.webp`,
  /// `play.webp`, `profil.webp`, `settings.webp`.
  Finder navTabFinder(String assetFilename) {
    return find.byWidgetPredicate((w) {
      if (w is! Image) return false;
      final p = w.image;
      if (p is AssetImage) return p.assetName.endsWith(assetFilename);
      return false;
    });
  }

  Finder button3DWithLabel(String labelPattern) {
    return find.ancestor(
      of: textContaining(labelPattern),
      matching: find.byType(Button3D),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> tapNavTab(String assetFilename) async {
    robotLog('tapNavTab($assetFilename)');
    final f = navTabFinder(assetFilename);
    await waitFor(f);
    await tester.tap(f.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> tapButton3D(String labelPattern) async {
    robotLog('tapButton3D($labelPattern)');
    final f = button3DWithLabel(labelPattern);
    await waitFor(f);
    await tester.tap(f.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Tap the i-th `Switch` (0=sound, 1=music, 2=vibration in Settings).
  Future<bool> toggleSwitch(int index) async {
    robotLog('toggleSwitch(index=$index)');
    final f = find.byType(Switch);
    await waitFor(f);
    final all = f.evaluate().toList();
    if (index >= all.length) {
      fail('Expected at least ${index + 1} Switch widgets, '
          'found ${all.length}.');
    }
    final before = (all[index].widget as Switch).value;
    robotLog('  switch[$index] before=$before');
    await tester.tap(f.at(index));
    await tester.pump(const Duration(milliseconds: 400));
    return before;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Predicates
  // ─────────────────────────────────────────────────────────────────────────

  bool hasGoogleSignInButton() =>
      find.byType(GoogleSignInButton).evaluate().isNotEmpty;

  // ─────────────────────────────────────────────────────────────────────────
  // Provider access
  // ─────────────────────────────────────────────────────────────────────────

  /// Read the live [ProviderContainer] backing the running app. Lets a
  /// scenario manipulate state directly when going through the UI would be
  /// flaky or impossible (ads, daily challenges, etc.).
  ProviderContainer container() {
    final element = tester.element(find.byType(Scaffold).first);
    return ProviderScope.containerOf(element);
  }
}

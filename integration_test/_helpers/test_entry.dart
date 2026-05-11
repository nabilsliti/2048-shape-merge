// Test entry point that wires Firebase emulators BEFORE booting the app.
//
// Hermetic environment: emulator-only Auth/Firestore/Functions so:
//   • we never pollute prod with test users/scores;
//   • Cloud Function calls work offline;
//   • tests can `signInAnonymously()` without OAuth.
//
// Required adb reverse setup before running (handled by tool/robot.sh):
//   adb reverse tcp:9099 tcp:9099   # auth
//   adb reverse tcp:8080 tcp:8080   # firestore
//   adb reverse tcp:5001 tcp:5001   # functions
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shape_merge/app.dart';
import 'package:shape_merge/core/config/flavor_config.dart';
import 'package:shape_merge/core/services/audio_service.dart';
import 'package:shape_merge/firebase_options.dart';
import 'package:shape_merge/screens/game/game_screen.dart';

bool _emulatorsWired = false;

Future<void> wireEmulators() async {
  if (_emulatorsWired) return;
  // Host resolution:
  //   • Android emulator → `10.0.2.2` works out of the box.
  //   • Physical device  → must use the host machine's LAN IP, because the
  //     firebase_auth Android plugin **unconditionally** remaps `localhost`
  //     AND `127.0.0.1` to `10.0.2.2` (which is unreachable on a physical
  //     device), bypassing any `adb reverse` we set up.
  // `tool/robot.sh` injects the host's LAN IP via --dart-define when a
  // wireless/physical device is detected; default falls back to `10.0.2.2`
  // for the Android emulator case.
  const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(region: 'europe-west1')
      .useFunctionsEmulator(host, 5001);
  _emulatorsWired = true;
}

/// Boot the app inside the test harness. Idempotent — safe to call across
/// scenarios within the same isolate.
Future<Widget> bootTestApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initialize(FlavorType.dev);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await wireEmulators();

  // Reset auth state so each scenario starts from a known guest baseline.
  await FirebaseAuth.instance.signOut();

  // Pre-mark the tutorial as seen — otherwise the in-game CoachOverlay
  // blocks every interaction on the game screen.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tutorial_seen', true);
  GameScreen.tutorialSeen = true;

  unawaited(AudioService.instance.init());

  return const ProviderScope(child: ShapeMergeApp());
}

# Refactoring Plan — 2048 Shape Merge

> Full code review, refactoring & cleanup checklist.
> Priority: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

---

## Phase 1 — Architecture & Code Quality

### 1.1 `GameShape` — Mutable state in Riverpod (🔴)
> `x` and `y` are mutable fields mutated directly in `moveDraggedShape()` → Riverpod doesn't detect changes.

- [ ] Make `x` and `y` `final` in `GameShape`
- [ ] Update `GameEngine.moveDraggedShape()` to use `copyWith()` instead of direct mutation
- [ ] Verify all direct assignments to `shape.x` / `shape.y` are replaced
- [ ] Run `flutter analyze` — 0 errors
- [ ] Run `flutter test` — all game logic tests pass

**Files:** `lib/core/models/game_shape.dart`, `lib/game/logic/game_engine.dart`

---

### 1.2 `AudioService` singleton vs Riverpod (🟠)
> Singleton pattern bypasses Riverpod, making testing impossible.

- [ ] Remove `AudioService._()` private constructor and `static final instance`
- [ ] Create a proper `Provider<AudioService>` (or reuse existing `audioProvider`)
- [ ] Replace all `AudioService.instance.*` calls in `GameBoard`, `GameScreen`, `ShopScreen` with `ref.read(audioProvider)`
- [ ] Verify sound still plays on merge, bomb, spawn, etc.

**Files:** `lib/core/services/audio_service.dart`, `lib/providers/audio_provider.dart`, `lib/screens/game/widgets/game_board.dart`, `lib/screens/game/game_screen.dart`

---

### 1.3 `AdsService` — Double init (🟡)
> `MobileAds.instance.initialize()` called both in `main.dart` and `AdsService.init()`.

- [ ] Remove `MobileAds.instance.initialize()` from `main.dart`
- [ ] Keep init in `AdsService.init()` only, called via provider
- [ ] Verify ads still load correctly

**Files:** `lib/main.dart`, `lib/core/services/ads_service.dart`

---

### 1.4 `FlavorConfig` missing in `main.dart` (🔴)
> `main.dart` never calls `FlavorConfig.initialize()` → crash if accessed.

- [ ] Add `FlavorConfig.initialize(FlavorType.dev)` in `main.dart` (same as `main_dev.dart`)
- [ ] Or make `main.dart` delegate to `main_dev.dart`

**Files:** `lib/main.dart`

---

### 1.5 `debugPrint` in production (🟠)
> 19 occurrences. `_debugFirestore()` does a full Firestore collection read.

- [ ] Delete `_debugFirestore()` function from `leaderboard_screen.dart`
- [ ] Remove the call to `_debugFirestore()` in the `entries.isEmpty` branch
- [ ] Wrap remaining `debugPrint` calls with `if (kDebugMode)` or remove unnecessary ones
- [ ] Audit list: `firestore_service.dart`, `iap_service.dart`, `iap_provider.dart`, `game_screen.dart`, `shop_screen.dart`, `ad_banner_widget.dart`

**Files:** `lib/screens/leaderboard/leaderboard_screen.dart` + 5 others

---

### 1.6 `SharedPreferences` direct access in screens (🟡)
> `GameScreen` bypasses `LocalStorageService`.

- [ ] Add `tutorialSeen` getter/setter to `LocalStorageService`
- [ ] Replace `SharedPreferences.getInstance()` calls in `GameScreen` with `ref.read(localStorageProvider)`
- [ ] Verify tutorial shown/hidden correctly

**Files:** `lib/screens/game/game_screen.dart`, `lib/core/services/local_storage_service.dart`

---

## Phase 2 — Firebase & Firestore

### 2.1 `firebase_options.dart` — placeholder TODO (🔴)
> `apiKey: 'TODO'` → app crashes on startup without FlutterFire CLI.

- [ ] Run `flutterfire configure` to generate real `firebase_options.dart`
- [ ] Or document the procedure in README for contributors
- [ ] Verify app boots without crash

**Files:** `lib/firebase_options.dart`

---

### 2.2 Firestore Rules — Security holes (🔴)
> Players profile readable by any authenticated user. No `score > 0` validation.

- [ ] Change `players/{userId}` read rule from `isAuth()` to `isOwner(userId)`
- [ ] Add field validation: `request.resource.data.score is int && request.resource.data.score > 0`
- [ ] Decide: keep or remove `allow delete` on leaderboard (remove if not intended)
- [ ] Add type validation for all required fields (displayName is string, score is int, etc.)
- [ ] Deploy rules: `firebase deploy --only firestore:rules`
- [ ] Test rules with Firebase emulator

**Files:** `firestore.rules`

---

### 2.3 `weekKey` calculation — Bug (🔴)
> Uses `now.day ~/ 7` (day of month) instead of ISO week number.

- [ ] Create ISO week number helper function
- [ ] Replace `'${now.year}-W${(now.day ~/ 7) + 1}'` with proper ISO week
- [ ] Verify weekly leaderboard groups entries correctly
- [ ] Backfill or reset existing entries if needed

**Files:** `lib/screens/game/game_screen.dart`

---

### 2.4 Score submission — Double submit (🟠)
> Submitted both in real-time (`listenManual`) AND at game over.

- [ ] Remove real-time `listenManual` score submission
- [ ] Keep only game over submission (single source of truth)
- [ ] Or: keep real-time but remove game over submit + add deduplication
- [ ] Verify score appears in leaderboard after game over

**Files:** `lib/screens/game/game_screen.dart`

---

### 2.5 Offline handling (🟡)
> Firestore errors silently swallowed.

- [ ] Enable Firestore persistence explicitly: `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)`
- [ ] Add user feedback when offline (snackbar or banner)
- [ ] Add retry logic or queue for score submission failures

**Files:** `lib/core/services/firestore_service.dart`, `lib/main.dart`

---

## Phase 3 — Internationalization (i18n)

### 3.1 Hardcoded strings in code (🟠)
> Shop, leaderboard, tutorial contain French strings.

- [ ] Extract from `shop_screen.dart`: `'Pack Étoile'`, `'Pack Comète'`, `'Pack Diamant'`, `'STARTER'`, `'POPULAIRE'`, `'BEST VALUE'`, `'🎁 PACKS JOKERS'`, `'🎬 JOKER GRATUIT'`, `'ZÉRO PUB'`
- [ ] Extract from `leaderboard_screen.dart`: `'No scores yet'`
- [ ] Extract from `tutorial_overlay.dart`: `'OBJECTIF'`, `'CONTRÔLES'`, `'ASTUCES'`, all instruction text
- [ ] Add corresponding keys to `app_en.arb` and `app_fr.arb`
- [ ] Run `flutter gen-l10n` and verify no missing keys
- [ ] Visually verify both EN and FR on every screen

**Files:** `lib/screens/shop/shop_screen.dart`, `lib/screens/leaderboard/leaderboard_screen.dart`, `lib/screens/game/overlays/tutorial_overlay.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

---

### 3.2 ARB keys out of sync with code (🟡)
> Pack names changed (`pack_star` vs `packSmall`) but ARB not updated.

- [ ] Audit all ARB keys vs actual usage with `grep`
- [ ] Remove unused ARB keys
- [ ] Add missing ARB keys for new UI elements
- [ ] Run `flutter gen-l10n` — 0 unused/missing warnings

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

---

## Phase 4 — Theme & UI Consistency

### 4.1 `withOpacity()` deprecated → `withValues(alpha:)` (🟡)
> Mix of old and new API.

- [ ] Replace `.withOpacity(x)` with `.withValues(alpha: x)` in `main_hub_screen.dart`
- [ ] Replace in `score_popup.dart`
- [ ] Replace in `glass_card.dart`
- [ ] Search for any remaining `withOpacity` calls and migrate

**Files:** `lib/screens/hub/main_hub_screen.dart`, `lib/screens/game/widgets/score_popup.dart`, `lib/core/widgets/glass_card.dart`

---

### 4.2 `google_fonts` — Runtime network fetch (🟠)
> Fonts downloaded at runtime on first display.

- [ ] Download Fredoka and Nunito font files
- [ ] Add them to `assets/fonts/` and declare in `pubspec.yaml`
- [ ] Set `GoogleFonts.config.allowRuntimeFetching = false` in `main.dart`
- [ ] Verify fonts render correctly offline

**Files:** `lib/main.dart`, `pubspec.yaml`, `assets/fonts/`

---

## Phase 5 — Android Build & APK Size

### 5.1 `proguard-rules.pro` missing (🔴 Blocker)
> Referenced in `build.gradle.kts` but file doesn't exist → release build fails.

- [ ] Create `android/app/proguard-rules.pro` with Firebase + AdMob + Flutter rules
- [ ] Test release build: `flutter build apk --release --flavor prod`
- [ ] Verify Firebase, Crashlytics, and AdMob work in release APK

**Files:** `android/app/proguard-rules.pro`

---

### 5.2 APK size optimization (🟡)
- [ ] Build with `--split-per-abi` and measure per-ABI size
- [ ] Check sound assets: verify sizes (placeholders vs real files)
- [ ] Consider `--obfuscate --split-debug-info=build/symbols` for further shrink
- [ ] Measure final APK: target < 25 MB per ABI

---

### 5.3 Flavor `applicationId` — Invalid underscore (🔴)
> `com.crestbit.shapemerge2048_dev` is invalid on Google Play.

- [ ] Change dev flavor `applicationId` to `com.crestbit.shapemerge2048.dev`
- [ ] Change staging flavor `applicationId` to `com.crestbit.shapemerge2048.staging`
- [ ] Uninstall old dev/staging builds before testing (different package)

**Files:** `android/app/build.gradle.kts`

---

### 5.4 `google-services.json` per flavor (🟠)
> Single file shared across all flavors.

- [ ] Create Firebase projects for dev and staging (or use single project with multiple apps)
- [ ] Place `google-services.json` in `android/app/src/dev/`, `android/app/src/staging/`, `android/app/src/prod/`
- [ ] Verify each flavor connects to correct Firebase project

**Files:** `android/app/src/{dev,staging,prod}/google-services.json`

---

### 5.5 Android 15 readiness (🟡)
- [ ] Verify `flutter.targetSdkVersion` resolves to 35
- [ ] Test edge-to-edge rendering
- [ ] Verify no deprecated API warnings in logcat

---

## Phase 6 — Tests

### 6.1 Missing test coverage (🟠)
> Only 3 test files. No service/provider/widget tests.

- [ ] Create `test/services/local_storage_service_test.dart`
- [ ] Create `test/providers/game_state_provider_test.dart`
- [ ] Add edge case tests to `game_engine_test.dart`: board full+pairs, wildcard merge, spawn after merge
- [ ] Add edge case tests to `joker_handler_test.dart`: bomb with 0 matches, reducer on level 1
- [ ] Create basic widget test for `ShapeWidget` rendering

---

### 6.2 Integration test (🟢)
- [ ] Create `integration_test/app_test.dart` — smoke test: launch → home → play → merge → game over
- [ ] Verify integration test passes on emulator

---

## Phase 7 — Security

### 7.1 Firestore anti-cheat (🟠)
> Client sends arbitrary scores. Rules only cap at 999999.

- [ ] Create Cloud Function `validateScore` triggered on leaderboard write
- [ ] Validate: score within plausible range, rate limit per user, server timestamp
- [ ] Deploy function: `firebase deploy --only functions`

---

### 7.2 IAP server-side validation (🟠)
> Purchases delivered client-side without receipt verification.

- [ ] Create Cloud Function `verifyPurchase` for Google Play receipt validation
- [ ] Call function after `PurchaseStatus.purchased` before delivering jokers
- [ ] Handle verification failure gracefully (retry or refund)

---

### 7.3 Ad unit IDs management (🟡)
> Production AdMob ID hardcoded. Test IDs only in `kDebugMode`.

- [ ] Move production ad unit IDs to flavor-specific config or environment variable
- [ ] Verify test IDs used in dev, real IDs only in prod

**Files:** `lib/core/widgets/ad_banner_widget.dart`, `lib/core/services/ads_service.dart`

---

## Phase 8 — Cleanup & Best Practices

### 8.1 Dead code removal (🟡)
- [ ] Delete `_debugFirestore()` from `leaderboard_screen.dart`
- [ ] Delete `_GlassMenuButton` from `home_screen.dart` (unused vestige)
- [ ] Run `flutter analyze` — check for unused imports
- [ ] Remove unused imports in `leaderboard_screen.dart` (`dart:math`, `cloud_firestore` direct import)

**Files:** `lib/screens/leaderboard/leaderboard_screen.dart`, `lib/screens/home/home_screen.dart`

---

### 8.2 Navigation consistency (🟡)
> Buttons use `context.go('/home')` instead of `context.pop()`.

- [ ] Audit all "back" buttons: shop, leaderboard, settings
- [ ] Replace `context.go('/home')` with `context.pop()` where appropriate
- [ ] Verify back navigation works correctly from each screen
- [ ] Verify `MainHubScreen` tab navigation is consistent with GoRouter routes

**Files:** `lib/screens/shop/shop_screen.dart`, `lib/screens/leaderboard/leaderboard_screen.dart`, `lib/screens/settings/settings_screen.dart`

---

### 8.3 Lint rules — Strengthen (🟢)
- [ ] Add to `analysis_options.yaml`:
  - `prefer_const_constructors_in_immutables`
  - `avoid_unnecessary_containers`
  - `sized_box_for_whitespace`
  - `use_build_context_synchronously`
- [ ] Run `flutter analyze`, fix new warnings

**Files:** `analysis_options.yaml`

---

## Phase 9 — GPU Performance & Rendering

### 9.1 `BackdropFilter` in `GlassCard` (🔴)
> `ImageFilter.blur` is extremely expensive on low-end devices. No `RepaintBoundary` anywhere.

- [ ] Wrap `GlassCard` in `RepaintBoundary`
- [ ] Or replace `BackdropFilter` with simple semi-transparent `Container` (same visual on dark backgrounds, 10x cheaper)
- [ ] Measure FPS before/after with Flutter DevTools

**Files:** `lib/core/widgets/glass_card.dart`

---

### 9.2 `TextPainter` in `paint()` loop (🟠)
> `ReducerPainter` creates `TextPainter(...).layout()` every frame.

- [ ] Cache `TextPainter` as instance variable in painter
- [ ] Or move text rendering to a `Text` widget overlaid on `CustomPaint`

**Files:** `lib/core/widgets/joker_icons.dart`

---

### 9.3 CustomPainters recreated every `build()` (🟠)
> `HudBar` creates `_StarPainter()`, `_RingPainter()`, `_BoltPainter()` on each rebuild.

- [ ] Make painters `const` or cache as final fields
- [ ] Implement proper `shouldRepaint()` comparison in `_ShapePainter`

**Files:** `lib/screens/game/widgets/hud_bar.dart`, `lib/screens/game/widgets/shape_widget.dart`

---

### 9.4 Disable animations for depleted jokers (🟡)
> Pulse animation runs even when `count <= 0`.

- [ ] Conditionally start/stop `_pulseCtrl` based on `widget.count > 0`
- [ ] In `didUpdateWidget`, stop animation if count drops to 0

**Files:** `lib/screens/game/widgets/joker_bar.dart`

---

### 9.5 Add `RepaintBoundary` across the app (🟠)
> 0 occurrences in the entire project. Every repaint cascades through the full tree.

- [ ] Add `RepaintBoundary` around `HudBar`
- [ ] Add `RepaintBoundary` around `JokerBar`
- [ ] Add `RepaintBoundary` around `GameBoard`
- [ ] Add `RepaintBoundary` around each `MergeEffect`
- [ ] Measure FPS improvement on drag interactions

---

### 9.6 `GameBoard` — Excessive rebuilds during drag (🔴)
> `setState()` called on every `onPanUpdate` frame → all `ShapeWidget`s recreated.

- [ ] Extract drag position to `ValueNotifier<Offset>` instead of `setState`
- [ ] Use `ValueListenableBuilder` for the dragged shape only
- [ ] Non-dragged shapes should not rebuild during drag
- [ ] Measure: should reduce per-drag rebuilds from N shapes to 1

**Files:** `lib/screens/game/widgets/game_board.dart`

---

## Phase 10 — Accessibility (a11y)

### 10.1 Add `Semantics` across the app (🟠)
> Zero `Semantics` widgets. TalkBack/VoiceOver completely unusable.

- [ ] Add `Semantics(button: true, label: ...)` on all interactive buttons
- [ ] Add `Semantics` on score display, merge count, capacity bar
- [ ] Add `Semantics` on joker buttons with count: `"Bomb joker, 3 available"`
- [ ] Add `Semantics(header: true)` on screen titles
- [ ] Test with Android TalkBack

---

### 10.2 Color-only indicators — Colorblind support (🟡)
> `CapacityBar` and `HudBar` use green/orange/red without text fallback.

- [ ] Add text label or icon alongside `CapacityBar` color (e.g., "⚠" icon when near full)
- [ ] Ensure all status indicators have non-color differentiation

**Files:** `lib/screens/game/widgets/capacity_bar.dart`, `lib/screens/game/widgets/hud_bar.dart`

---

## Phase 11 — Android Configuration

### 11.1 `AD_ID` permission (🔴)
> Required since Android 13 for AdMob. Missing → advertising ID null → revenue loss.

- [ ] Add `<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>` to `android/app/src/main/AndroidManifest.xml`
- [ ] Verify in logcat that ad ID is populated

**Files:** `android/app/src/main/AndroidManifest.xml`

---

### 11.2 `INTERNET` permission in main manifest (🟡)
- [ ] Add `<uses-permission android:name="android.permission.INTERNET"/>` to `main/AndroidManifest.xml`

**Files:** `android/app/src/main/AndroidManifest.xml`

---

### 11.3 Backup & data extraction rules (🟡)
> Missing for Android 12+. Play Console will warn.

- [ ] Create `android/app/src/main/res/xml/data_extraction_rules.xml`
- [ ] Create `android/app/src/main/res/xml/backup_rules.xml`
- [ ] Add `android:dataExtractionRules` and `android:fullBackupContent` to manifest `<application>`

**Files:** `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/`

---

### 11.4 Flavor-specific manifests & resources (🟡)
- [ ] Create `android/app/src/dev/` directory
- [ ] Create `android/app/src/staging/` directory
- [ ] Create `android/app/src/prod/` directory
- [ ] Move `google-services.json` to each flavor directory

---

## Phase 12 — iOS Configuration

### 12.1 App Tracking Transparency (ATT) (🔴)
> Required for personalized AdMob ads on iOS 14.5+.

- [ ] Add `NSUserTrackingUsageDescription` key to `Info.plist`
- [ ] Add `SKAdNetworkItems` for Google (list from Google AdMob docs)
- [ ] Implement ATT permission request in `AdsService` before loading ads on iOS

**Files:** `ios/Runner/Info.plist`

---

### 12.2 Fix `UISupportedInterfaceOrientations` (🟡)
> Plist allows Landscape but code locks Portrait.

- [ ] Remove `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` from `Info.plist`
- [ ] Keep only `UIInterfaceOrientationPortrait`

**Files:** `ios/Runner/Info.plist`

---

### 12.3 iOS minimum deployment target (🟡)
- [ ] Uncomment and set `platform :ios, '15.0'` in `Podfile`
- [ ] Run `cd ios && pod install`

**Files:** `ios/Podfile`

---

### 12.4 iOS flavors/schemes (🟢)
- [ ] Create Xcode schemes for dev, staging, prod
- [ ] Configure bundle identifiers per scheme
- [ ] Add `GoogleService-Info.plist` per scheme

---

## Phase 13 — Memory & Lifecycle

### 13.1 `HomeScreen` animation running when not visible (🟡)
> 60-second `AnimationController.repeat()` runs even in background tab.

- [ ] Use `TickerMode` or `VisibilityDetector` to pause animation when off-screen
- [ ] Or dispose and re-create when tab switches

**Files:** `lib/screens/home/home_screen.dart`

---

### 13.2 `AudioService` — Single `AudioPlayer` (🟠)
> Second sound cancels first if played in quick succession.

- [ ] Replace single `AudioPlayer` with a pool (3-4 players rotating)
- [ ] Or use `AudioPool` from audioplayers package
- [ ] Verify rapid merge + spawn sounds both play

**Files:** `lib/core/services/audio_service.dart`

---

### 13.3 `AdsService` — No lifecycle management (🟡)
> Banner/rewarded ads consume resources when app is backgrounded.

- [ ] Listen to `AppLifecycleState` via `WidgetsBindingObserver`
- [ ] Pause/dispose ads on `paused`, reload on `resumed`

**Files:** `lib/core/services/ads_service.dart`

---

## Phase 14 — Miscellaneous

### 14.1 `main_dev.dart` — Missing Crashlytics handler (🟡)
- [ ] Add `FlutterError.onError` and `PlatformDispatcher.instance.onError` to `main_dev.dart` (same as `main_prod.dart`)
- [ ] Or create a shared `initApp()` function called by all entry points

**Files:** `lib/main_dev.dart`, `lib/main_staging.dart`

---

### 14.2 Custom `ErrorWidget.builder` (🟡)
> Red Screen of Death shown to users on render error in release.

- [ ] Set `ErrorWidget.builder` in `main.dart` to show a user-friendly error screen
- [ ] Include "restart" button

**Files:** `lib/main.dart`

---

### 14.3 GoRouter `errorBuilder` (🟡)
> No 404 page for unknown routes.

- [ ] Add `errorBuilder` to `GoRouter` that redirects to home or shows error page

**Files:** `lib/app.dart`

---

### 14.4 Firestore write rate limiting (🟡)
> Score submitted on every bestScore change during gameplay.

- [ ] Debounce score submission (max 1 write per 30 seconds)
- [ ] Or submit only at game over

**Files:** `lib/screens/game/game_screen.dart`

---

### 14.5 `tutorial_overlay.dart` — Hardcoded French strings (🟠)
> `'OBJECTIF'`, `'CONTRÔLES'`, `'ASTUCES'` etc. not in ARB files.

- [ ] Extract all strings to ARB files
- [ ] Add EN and FR translations
- [ ] Replace hardcoded strings with `AppLocalizations.of(context)!.key`

**Files:** `lib/screens/game/overlays/tutorial_overlay.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

---

## Verification Checklist

- [ ] `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings
- [ ] `flutter test` → all pass (existing + new)
- [ ] `flutter build apk --release --split-per-abi --flavor prod` → success
- [ ] `proguard-rules.pro` doesn't break Firebase/Ads in release APK
- [ ] Full flow test: splash → home → play → merge → joker → game over → leaderboard → shop → settings
- [ ] i18n: switch device to FR, verify all screens (no hardcoded EN/FR visible)
- [ ] i18n: switch device to EN, verify all screens
- [ ] Firestore rules: test with `firebase emulators:start` — players read/write, leaderboard constraints
- [ ] FPS measurement: drag shapes with Flutter DevTools Performance overlay → target 60fps
- [ ] APK size: measure per-ABI, target < 25 MB
- [ ] TalkBack: navigate full app with screen reader

---

## Priority Order (suggested execution)

| Order | Phase | Items | Effort |
|-------|-------|-------|--------|
| 1 | **5.1** | Create `proguard-rules.pro` | 15 min |
| 2 | **1.4** | Fix `FlavorConfig` in `main.dart` | 5 min |
| 3 | **5.3** | Fix flavor `applicationId` underscores | 5 min |
| 4 | **2.3** | Fix `weekKey` ISO week bug | 15 min |
| 5 | **11.1** | Add `AD_ID` permission | 5 min |
| 6 | **2.2** | Harden Firestore rules | 30 min |
| 7 | **1.1** | Make `GameShape` immutable | 45 min |
| 8 | **9.6** | Fix `GameBoard` drag rebuilds | 1h |
| 9 | **9.1** | Fix `BackdropFilter` / add `RepaintBoundary` | 30 min |
| 10 | **3.1 + 14.5** | Extract all hardcoded strings to ARB | 1h |
| 11 | **1.5** | Clean `debugPrint` + dead code | 30 min |
| 12 | **12.1** | iOS ATT + SKAdNetwork | 30 min |
| 13 | **1.2** | Refactor `AudioService` singleton | 45 min |
| 14 | **13.2** | AudioPlayer pool | 30 min |
| 15 | **9.2–9.5** | Painters + RepaintBoundary fixes | 1h |
| 16 | **4.2** | Bundle Google Fonts locally | 30 min |
| 17 | **2.4** | Fix score submission dedup | 20 min |
| 18 | **6.1** | Add missing tests | 2h |
| 19 | **10.1** | Add Semantics (accessibility) | 1h30 |
| 20 | **14.2–14.3** | ErrorWidget + GoRouter error | 20 min |
| 21 | **Remaining** | All 🟢 items | 2h |

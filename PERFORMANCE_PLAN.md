# Performance Plan — 2048 Shape Merge

Audit thorough effectué (18 issues : 5 CRITICAL / 5 HIGH / 5 MEDIUM / 3 LOW). Plan en 6 phases du quick-win au refactor structurel.

## TL;DR
4 grands axes de jank/gaspillage :
1. `setState` chains 60fps sur badges animés
2. `ref.watch(gameStateProvider)` partout → rebuilds en cascade
3. Startup bloqué par preload + audio synchrone + Google Sign-In paresseux
4. Allocations GC dans le moteur de jeu sur chaque merge

---

## Gains estimés

| Métrique | Avant | Après | Gain |
|---|---|---|---|
| **Cold start** | ~3.0s | ~2.0s | **−33 %** |
| **Frames > 16ms (jank) / minute gameplay** | 30-50 | 0-5 | **−90 %** |
| **GC events / minute** | 8-12 | 1-2 | **−85 %** |
| **Heap peak** | ~180 MB | ~140 MB | **−22 %** |
| **Rebuilds par changement de score** | 15-20 widgets | 2-3 widgets | **−85 %** |
| **Délai tap "Sign in" → fenêtre Google** | 600ms-1s | 50-100ms | **−85 %** |

---

## Phase 1 — Quick Wins (provider granularity + ads)

| # | Fichier | Problème | Fix | Effort | Gain |
|---|---|---|---|---|---|
| 1 | `lib/screens/hub/main_hub_screen.dart:36-39` | `loadRewardedAd()` à chaque `build()` | Déplacer dans `initState` + `addPostFrameCallback` | 10 min | Spam ad API |
| 2 | `lib/screens/shop/shop_screen.dart:96-99` | `ref.watch(gameStateProvider)` watch tout | `.select((s) => s.jokerInventory)` | 15 min | Rebuilds −30 à −50 % |
| 3 | `lib/screens/hub/widgets/level_badge.dart:18-38` | Watch 3 AsyncValue entiers | `.select((async) => async.valueOrNull)` | 15 min | Rebuilds −40 % |
| 4 | `lib/screens/game/widgets/game_board.dart:60-62` | Watch tout gameState pour 32 shapes | `.select((s) => s.shapes)` | 15 min | Drag plus fluide |

**Visuel** : Hub/Shop ouverture instantanée, plus de micro-stutter quand le score change en arrière-plan, GameBoard drag fluide.

---

## Phase 2 — Animations isolées

| # | Fichier | Problème | Fix | Effort | Gain |
|---|---|---|---|---|---|
| 5 | `lib/screens/hub/widgets/animated_xp_badge.dart:41-62` | 5× `addListener(setState)` | `AnimatedBuilder` par animation + `RepaintBoundary` | 30 min | Frame time −60 à −80 % |
| 6 | `lib/screens/home/widgets/home_widgets.dart:134-206` | `AnimatedBuilder` dans `setState` parent | Extraire en widget séparé | 30 min | Plus de blocage scroll |
| 7 | `lib/screens/hub/main_hub_screen.dart:70-90` | Fonds animés sans isolation | `RepaintBoundary` autour des orbes | 15 min | Repaints isolés |

**Visuel** : Animation XP badge fluide (vs ~200ms freeze actuel au level-up), pop-in stars/coins sans saccade, animations qui ne bloquent plus les taps.

---

## Phase 3 — Startup

| # | Fichier | Problème | Fix | Effort | Gain |
|---|---|---|---|---|---|
| 8 | `lib/main_dev.dart:30`, `lib/main_prod.dart:33` | `await GameScreen.preload()` bloque `runApp` | Post-frame callback | 1-2h | −200 à −300 ms |
| 9 | `lib/core/services/audio_service.dart:119-140` | Charge tous les SFX synchrones | Charger sons critiques + reste en arrière-plan | 1-2h | −100 à −300 ms |
| 10 | `lib/core/services/auth_service.dart` | `GoogleSignIn` paresseux : init native au 1er tap | `warmUp()` via `signInSilently(suppressErrors: true)` lancé non-await au boot | 20 min | Tap → fenêtre Google **−500 ms à −900 ms** |
| 11 | `lib/app.dart` | Pas de précachage images | `precacheImage` pour `trophy.png`, `calendar.webp`, formes | 20 min | Smooth UI load |
| 12 | google_fonts runtime | Fetch au runtime → délai 1er render texte | `GoogleFonts.pendingFonts(['Fredoka', 'Nunito'])` au boot | 15 min | Texte instantané |

**Visuel** : Splash → Hub plus rapide, premier tap "Play" répond immédiatement, **fenêtre de choix Google quasi-instantanée**.

### Détail Phase 3.10 — Google Sign-In warm-up

**Pourquoi c'est lent aujourd'hui** : `GoogleSignIn.signIn()` paie au 1er appel :
1. Enregistrement platform channel (~50-100 ms)
2. Init Google Play Services (~200-400 ms)
3. Fetch token serveur (`serverClientId`)
4. Lancement Activity native (~200 ms)

→ **600 ms à 1 s** avant que la fenêtre apparaisse.

**Fix** : appeler `signInSilently(suppressErrors: true)` au boot, en parallèle d'AudioService/RemoteConfig. N'affiche aucune UI, force juste l'init native pendant le splash.

```dart
// auth_service.dart
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '...',
    scopes: ['email'],
  );

  Future<void> warmUp() async {
    try {
      await _googleSignIn.signInSilently(suppressErrors: true);
    } catch (_) {}
  }
}

// main_dev.dart / main_prod.dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
unawaited(AuthService.instance.warmUp());   // ← parallèle, non bloquant
unawaited(RemoteConfigService.instance.init());

// auth_providers.dart
final authServiceProvider = Provider<AuthService>((_) => AuthService.instance);
```

---

## Phase 4 — Hot path moteur

| # | Fichier | Problème | Fix | Effort | Gain |
|---|---|---|---|---|---|
| 13 | `lib/game/logic/game_engine.dart:48,58,108` | 3-4 `List.from()`/`.toList()` par merge | Buffer réutilisable + `List.unmodifiable` | 2-3h | GC events −70 à −90 % |
| 14 | `lib/game/logic/spawn_manager.dart:40-75` | Chaînes `.where().toList()` O(n²) | Single-pass + `Map<String,int>` partner counter | 2h | Allocations −80 % |

**Visuel** : Pendant un combo rapide (3-4 merges/sec), micro-hiccup GC actuel toutes les ~1s **disparaît totalement**. Sound timing du merge plus précis (GC retardait le son de 30-50 ms).

---

## Phase 5 — Architecture providers

| # | Action | Effort | Impact |
|---|---|---|---|
| 15 | Découper `gameStateProvider` en sous-providers : `shapesProvider`, `scoreProvider`, `jokerInventoryProvider`, `comboProvider` | 2-3h | Effet cumulatif Phase 1 sur toute l'app |
| 16 | Pass `const` systématique sur `lib/screens/` (50+ widgets candidats) | 1h | Widget tree mémoire −15 à −25 % |

**Visuel** : Transitions GoRouter, ouverture modals (NoEnergy, level-up, game-over) instantanées.

---

## Validation

```
□ flutter run --profile + DevTools Timeline : aucune frame > 16 ms en gameplay
□ DevTools Memory : 0 GC event / min en gameplay normal, heap < 150 MB
□ Cold start chrono < 2s
□ Tap "Sign in" → fenêtre Google < 200 ms
□ Compteur rebuilds via debugRepaintRainbowEnabled validé
□ dart analyze zéro erreur après chaque phase
□ Aucune régression visuelle vs feat/new-design
```

### Markers profilage à ajouter

```dart
Timeline.instantSync('Merge.Start');
final result = GameEngine.attemptMerge(...);
Timeline.instantSync('Merge.End');
```

---

## Ordre recommandé

**Option A (recommandée)** : Phase 1 + 2 + 3.10 (Google warm-up) **en parallèle** — impact visible immédiat, 0 dépendance. Puis Phase 3 reste, puis Phase 4, puis Phase 5.

**Option B** : strictement séquentiel — plus sûr si on veut bisect des régressions.

**1 PR par phase** sur `feat/new-design` pour pouvoir reverter en cas de régression.

---

## Hors scope

- Conversion en isolate (overkill pour la taille du game state)
- Refonte rendu sans `Stack`
- Migration vers Flame
- Remplacement flutter_soloud (le seul vrai problème est la stratégie de preload)

---

**Branch** : `feat/new-design`
**Severity** : 5 CRITICAL · 5 HIGH · 5 MEDIUM · 3 LOW · +1 Google Sign-In warm-up

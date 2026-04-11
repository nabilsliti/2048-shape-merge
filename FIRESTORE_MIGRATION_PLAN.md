# Plan de migration & refactoring complet : 2048 Shape Merge

## Objectif
Chaque compte Google a ses propres données. Le localStorage ne sert plus que pour :
- Les préférences device (son, onboarding, nudges)
- Le mode guest (données temporaires avant connexion)

Au login, on charge **tout** depuis Firestore. Au switch de compte, aucune donnée de l'ancien compte ne fuit.

---

## Étape 1 — Ajouter les champs manquants au Player Firestore

Le modèle `Player` et Firestore manquent :
- `jokerInventory` (bomb, wildcard, reducer, radar, evolution, megaBomb)
- `noAdsPurchased`
- `rewardClaimedDate`

### Checklist
- [ ] 1.1 Ajouter `noAdsPurchased` et `rewardClaimedDate` au modèle `Player`
- [ ] 1.2 Mettre à jour `Player.fromMap()` et `Player.toMap()` pour ces champs
- [ ] 1.3 Ajouter `jokerInventory` à `Player.fromMap()` / `Player.toMap()`
- [ ] 1.4 Ajouter `FirestoreService.updateJokerInventory(uid, JokerInventory)`
- [ ] 1.5 Ajouter `FirestoreService.updateRewardClaimedDate(uid, String)`
- [ ] 1.6 Ajouter `FirestoreService.updateNoAdsPurchased(uid, bool)`
- [ ] 1.7 `dart analyze` — 0 erreurs

---

## Étape 2 — Modifier `playerProvider` : Firestore = source unique

Actuellement `playerProvider` fait un merge max(local, Firestore). Il faut :
- Connecté : charger depuis Firestore uniquement
- 1er login : migrer les données locales → Firestore (une seule fois)
- Après : ne plus toucher à localStorage pour les données du compte

### Checklist
- [ ] 2.1 Supprimer la logique de merge bidirectionnelle dans `playerProvider`
- [ ] 2.2 1er login (player == null) : créer Player avec données locales + jokers locaux
- [ ] 2.3 Login existant : charger Player tel quel depuis Firestore, **sans** merge local
- [ ] 2.4 Supprimer les écritures localStorage (setBestScore, setPlayerLevel, etc.) du `playerProvider`
- [ ] 2.5 `dart analyze` — 0 erreurs

---

## Étape 3 — Modifier `gameStateProvider` : jokers depuis Player (connecté)

Actuellement les jokers sont toujours lus/écrits en localStorage. Il faut :
- Connecté : charger depuis `Player.jokerInventory`, sauvegarder en Firestore
- Guest : garder localStorage

### Checklist
- [ ] 3.1 `SplashScreen._initAndNavigate()` : si connecté, charger jokers depuis Player Firestore
- [ ] 3.2 `GameStateNotifier.addJokers()` / `useJoker()` : persister en Firestore si connecté
- [ ] 3.3 `GameStateNotifier.saveJokerInventory()` : écrire Firestore (connecté) ou localStorage (guest)
- [ ] 3.4 `game_screen.dart` : ne plus écrire jokers en localStorage si connecté
- [ ] 3.5 `dart analyze` — 0 erreurs

---

## Étape 4 — Modifier `streakProvider/Service` : rewardClaimedDate en Firestore

`rewardClaimedDate` est uniquement en localStorage. Multi-compte = partage du flag.

### Checklist
- [ ] 4.1 `checkAndUpdateSigned()` : lire `player.rewardClaimedDate` au lieu de `storage.rewardClaimedDate`
- [ ] 4.2 `claimStreakReward()` : écrire `rewardClaimedDate` en Firestore (connecté) ou localStorage (guest)
- [ ] 4.3 Supprimer la copie locale streak (`_saveToStorage`) quand connecté
- [ ] 4.4 `dart analyze` — 0 erreurs

---

## Étape 5 — Modifier `progressionProvider/Service` : XP uniquement Firestore

Actuellement `addXPSigned()` écrit en Firestore **ET** en localStorage. Doublon.

### Checklist
- [ ] 5.1 `ProgressionService.addXPSigned()` : ne plus écrire en localStorage
- [ ] 5.2 `ProgressionService.addXPGuest()` : garde localStorage (inchangé)
- [ ] 5.3 `ProgressionProvider.addXP()` : lire level/XP depuis Player (connecté) au lieu de localStorage
- [ ] 5.4 `level_badge.dart` et `main_hub_screen.dart` : lire depuis `playerProvider` (connecté) — déjà le cas avec fallback localStorage
- [ ] 5.5 `dart analyze` — 0 erreurs

---

## Étape 6 — Modifier `dailyChallengeProvider` : Firestore uniquement (connecté)

Actuellement la sauvegarde locale `setDailyChallengesJson()` est faite même en connecté.

### Checklist
- [ ] 6.1 `DailyChallengeNotifier.checkRenewal()` : connecté = Firestore seul, guest = localStorage seul
- [ ] 6.2 `ChallengeService._persistState()` : ne plus écrire localStorage si connecté
- [ ] 6.3 `dart analyze` — 0 erreurs

---

## Étape 7 — Nettoyage au sign-out / switch de compte

Quand l'utilisateur se déconnecte, les données en mémoire (providers) doivent être reset pour ne pas fuiter vers un autre compte.

### Checklist
- [ ] 7.1 Au sign-out : invalider `playerProvider`, `streakProvider`, `dailyChallengeProvider`, `progressionProvider`
- [ ] 7.2 `gameStateProvider` : reset les jokers en mémoire au sign-out
- [ ] 7.3 Ne **PAS** effacer les données localStorage au sign-out (elles servent au mode guest)
- [ ] 7.4 Vérifier que `authStateProvider` listener dans `app.dart` gère le sign-out (prevUser != null && nextUser == null)
- [ ] 7.5 `dart analyze` — 0 erreurs

---

## Étape 8 — Migration des utilisateurs existants (1er lancement post-update)

Les joueurs qui upgraderont l'app ont des jokers en localStorage mais pas en Firestore.

### Checklist
- [ ] 8.1 Au 1er login post-update : si `Player.jokerInventory` est vide (tous à 0) et localStorage a des jokers, migrer
- [ ] 8.2 Idem pour `noAdsPurchased` : si local = true et Firestore = false, migrer
- [ ] 8.3 Idem pour `rewardClaimedDate` : copier si existe en local et pas en Firestore
- [ ] 8.4 Marquer la migration faite (ex: `migrationV2Done` en localStorage) pour ne pas la refaire
- [ ] 8.5 `dart analyze` — 0 erreurs

---

## Étape 9 — Nettoyage final

### Checklist
- [ ] 9.1 Supprimer de `LocalStorageService` les champs qui ne sont plus lus en mode connecté (streak, XP, etc.) — **non**, les garder pour le mode guest
- [ ] 9.2 Supprimer le code de merge dans `migrateGuestToFirestore()` streak (déjà fait)
- [ ] 9.3 `dart analyze` sur tout le projet — 0 erreurs / 0 warnings
- [ ] 9.4 Test manuel : guest → jouer → se connecter → vérifier données → se déconnecter → reconnecter autre compte → vérifier indépendance
- [ ] 9.5 Test manuel : kill app → relancer → vérifier que données persistent depuis Firestore

---

## Résumé des fichiers impactés

| Fichier | Modification |
|---------|-------------|
| `lib/core/models/player.dart` | Ajouter jokerInventory, noAdsPurchased, rewardClaimedDate |
| `lib/core/services/firestore_service.dart` | Nouvelles méthodes update |
| `lib/providers/player_provider.dart` | Supprimer merge bidirectionnel |
| `lib/providers/game_state_provider.dart` | Jokers depuis Player si connecté |
| `lib/providers/streak_provider.dart` | rewardClaimedDate Firestore |
| `lib/core/services/streak_service.dart` | Supprimer _saveToStorage si connecté |
| `lib/providers/progression_provider.dart` | XP Firestore-only si connecté |
| `lib/core/services/progression_service.dart` | Supprimer écriture localStorage si connecté |
| `lib/providers/daily_challenge_provider.dart` | Firestore-only si connecté |
| `lib/core/services/challenge_service.dart` | Supprimer écriture localStorage si connecté |
| `lib/core/services/iap_service.dart` | Sauvegarder noAdsPurchased en Firestore |
| `lib/screens/splash/splash_screen.dart` | Init jokers depuis Player |
| `lib/screens/game/game_screen.dart` | Sauvegarder bestScore Firestore-only |
| `lib/screens/hub/main_hub_screen.dart` | Lire depuis Player (connecté) |
| `lib/app.dart` | Gérer sign-out : reset providers |

---

## Étape 10 — Correction des bugs architecturaux (hors migration)

Bugs et code smells identifiés lors de l'audit global.

### 10A — Race condition bestScore sync (`app.dart` L126-137)
- `getLeaderboardScore().then(...)` sans `.catchError()` → exception non gérée
- Chaîne de `.then()` sans `await` → écritures concurrentes multiples
- [ ] 10A.1 Réécrire en `async/await` avec un seul point de décision
- [ ] 10A.2 Ajouter `catchError` ou `try/catch`

### 10B — Timer leak dans `GameStateNotifier` (`game_state_provider.dart`)
- `_radarTimer` jamais annulé → memory leak si radar activé plusieurs fois
- [ ] 10B.1 Annuler `_radarTimer?.cancel()` avant d'en créer un nouveau
- [ ] 10B.2 Ajouter `dispose()` au StateNotifier qui cancel le timer

### 10C — `JokerInventory.addAll()` n'ajoute qu'à 3 types sur 6
- `bomb`, `wildcard`, `reducer` → OK
- `radar`, `evolution`, `megaBomb` → **ignorés**
- [ ] 10C.1 Corriger `addAll()` pour inclure les 6 types

### 10D — Duplicate score submission (`game_screen.dart`)
- Sign-in depuis GameOver overlay → `_submitScore` mais PAS `_updatePlayerStats` ni `syncGameResult`
- [ ] 10D.1 Extraire `_onGameEnd()` partagée entre les 2 chemins

### 10E — Listener dupliqué via `didChangeDependencies`
- `ref.listenManual` dans `didChangeDependencies()` → enregistre un nouveau listener à chaque appel
- [ ] 10E.1 Déplacer dans `initState()` avec `addPostFrameCallback`

### 10F — Calcul de semaine ISO incorrect (`game_screen.dart`)
- Calcul manuel du numéro de semaine → off-by-one aux limites d'année
- [ ] 10F.1 Utiliser `intl` DateFormat ou calcul ISO 8601 correct

### 10G — `mounted` checks manquants après `await`
- `game_screen.dart`, `profile_dialog.dart` : accès `ref` / `setState` après `await` sans vérifier `mounted`
- [ ] 10G.1 Ajouter `if (!mounted) return;` après chaque `await` dans les callbacks

### 10H — Test ad ID en production iOS
- `ad_banner_widget.dart` : `ca-app-pub-3940256099942544/2934735716` → ID de test Google, pas de revenus iOS
- [ ] 10H.1 Remplacer par le vrai ID AdMob iOS

### 10I — Notifications hardcodées en français
- `notification_service.dart` : `_channelName = 'Série de jeu'` → pas localisé
- [ ] 10I.1 Passer des strings localisées au scheduling

### 10J — Export inutile dans `game_state_provider.dart`
- `export 'package:shape_merge/providers/local_storage_provider.dart';` → fuite d'import
- [ ] 10J.1 Supprimer l'export, corriger les imports cassés

### Checklist globale
- [ ] 10.final `dart analyze` sur tout le projet — 0 erreurs / 0 warnings

---

## Étape 11 — Bugs critiques game engine & UI

### 11A — Mutation directe de GameShape au lieu de copyWith (`game_engine.dart` L146-147)
- `s.x = newX; s.y = newY;` → casse l'immutabilité du state
- [ ] 11A.1 Utiliser `s.copyWith(x: newX, y: newY)` dans `moveDraggedShape()`

### 11B — AnimationController listeners jamais retirés (`game_board.dart` L221-248)
- `addListener()` / `addStatusListener()` sans `removeListener()` → fuite mémoire
- Les 2 controllers (`_snapBackCtrl`, `_flyToCtrl`) ont le même pattern dupliqué
- [ ] 11B.1 Retirer les listeners avant `dispose()` du controller
- [ ] 11B.2 Extraire une méthode `_setupAnimController()` commune

### 11C — `setState()` sans check `mounted` dans les status listeners (`game_board.dart` L229)
- Animation complète après dispose → crash "setState() called after dispose()"
- [ ] 11C.1 Ajouter `if (!mounted) return;` dans chaque `addStatusListener`

### 11D — `setBoardSize()` appelé à chaque `build()` (`game_board.dart` L57)
- Inside `LayoutBuilder` → re-exécuté à chaque rebuild même si taille identique
- [ ] 11D.1 Mémoriser la taille et ne notifier que si elle change

### 11E — Liste mutable `_effects` dans game_screen (`game_screen.dart` L9)
- `final List<Widget> _effects = []` muté directement via `setState`
- [ ] 11E.1 Convertir en pattern immutable ou déplacer dans le provider

---

## Étape 12 — Performance : Paint objects & allocations par frame

### 12A — Paint objects recréés à chaque frame (`joker_icons.dart` — tous les painters)
- `Paint()..color = ...` créé inline dans `paint()` → GC pression
- `RadialGradient().createShader()` recalculé chaque frame
- `TextPainter` recréé chaque frame dans `ReducerPainter`
- Star path calculé chaque frame dans `WildcardPainter`
- [ ] 12A.1 Cacher les `Paint` en champs `static final` ou `late final`
- [ ] 12A.2 Pré-calculer le star Path et le cacher
- [ ] 12A.3 Cacher le TextPainter dans ReducerPainter

### 12B — ~150 lignes de classes wrapper const dupliquées (`joker_icons.dart` L413-500)
- 10+ classes `_XxxPainterConst` identiques, juste pour wraper un painter en `const`
- [ ] 12B.1 Factoriser avec une classe générique `_ConstPainterDelegate<T>`

### 12C — `Color.withValues()` appelé chaque frame dans AnimatedBuilder (`joker_bar.dart`)
- Crée de nouveaux objets Color à chaque tick d'animation
- [ ] 12C.1 Pré-calculer les couleurs disabled/active/inactive

### 12D — Animation home_screen tourne même en background
- `_bgAnim.repeat()` continue quand l'app est en arrière-plan
- [ ] 12D.1 Stop/resume dans `didChangeAppLifecycleState`

---

## Étape 13 — Code dupliqué & complexité

### 13A — Filtre partenaire dupliqué 3× dans `spawn_manager.dart` (L39-67)
- Même filtre `type == type && color == color && level == level` répété 3 fois
- [ ] 13A.1 Extraire `_findPartners(GameShape, List<GameShape>)` helper

### 13B — Logique identique `processGameEnd` / `addBonusXP` dans `progression_provider.dart`
- ~30 lignes copiées-collées pour auth check + signed/guest dispatch
- [ ] 13B.1 Extraire `_addXP(int xp, {String? uid, Player? player})` méthode interne

### 13C — Ternaires imbriqués 4 niveaux (`spawn_manager.dart` L22-33)
- `mergeRate > 0.7 ? 0.50 : mergeRate > 0.5 ? 0.60 : ...`
- [ ] 13C.1 Extraire en méthode nommée `_adaptiveChance(double mergeRate)`

### 13D — Nesting 5+ niveaux dans `game_screen.dart` `didChangeDependencies`
- Callback → async → await → if → await → if → setState
- [ ] 13D.1 Extraire `_initGame()` et `_setupBestScoreListener()`

### 13E — Build tree 6+ niveaux de profondeur (`game_screen.dart` L151+)
- Scaffold → Stack → SafeArea → Column → Padding → ClipRRect → Stack
- [ ] 13E.1 Extraire `_buildHudBar()`, `_buildGameBoard()`, `_buildJokerBar()`

---

## Étape 14 — Error handling manquant

### 14A — Futures non protégées dans `game_screen.dart` (L138-148)
- `syncGameResult()`, `processGameEnd()` sans try/catch → erreurs silencieuses
- [ ] 14A.1 Wrapper dans try/catch avec debugPrint

### 14B — Futures non protégées dans `daily_challenge_provider.dart` (L55-59)
- `await _ref.read(playerProvider.future)` peut throw
- [ ] 14B.1 Ajouter try/catch autour du bloc

### 14C — Futures non protégées dans `progression_provider.dart` (L62-113)
- `addXPSigned()` peut throw si Firestore échoue
- [ ] 14C.1 Ajouter try/catch, logger l'erreur

### 14D — `Player.fromFirestore` cast unsafe (`player.dart`)
- `data['jokerInventory'] as Map<String, Object?>?` → crashe si c'est un autre type
- [ ] 14D.1 Vérifier `is Map` avant le cast

### 14E — `.then()` sans `.catchError()` dans `app.dart` (L126)
- `getLeaderboardScore().then(...)` — exception non gérée
- [ ] 14E.1 Ajouter `.catchError()` ou réécrire en async/await (voir 10A)

---

## Étape 15 — Centaines de magic numbers dans les painters

### 15A — `joker_icons.dart` : ~200+ valeurs hardcodées
- Positions : `0.48`, `0.58`, `0.34`, `0.22`, `0.46`, etc.
- Tailles : `1.5`, `4.0`, `3.5`, `5`, `3`, etc.
- Couleurs inline au lieu de `AppTheme`
- Gradients : `Alignment(-0.3, -0.3)` répété 15+ fois
- [ ] 15A.1 Extraire les constantes de position/taille dans le painter
- [ ] 15A.2 Extraire `_highlightAlignment = Alignment(-0.3, -0.3)` partagé

### 15B — `game_board.dart` : durées d'animation hardcodées
- `Duration(milliseconds: 250)` snap-back, `Duration(milliseconds: 180)` fly-to
- Scale factors : `0.4`, `0.15`
- [ ] 15B.1 Extraire en constantes `_snapDuration`, `_flyDuration`

---

## Étape 16 — Nettoyage divers

### 16A — TODO/FIXME à résoudre
- `notification_service.dart` : `TODO(l10n)` x2 — strings non localisées
- `ad_banner_widget.dart` : `TODO: replace with real iOS ID`
- `game_screen.dart` : commentaires "Bug B5 fix", "Bug B2 fix" — à nettoyer

### 16B — `addAll()` incomplet dans `JokerInventory`
- N'ajoute qu'aux 3 premiers types, ignore radar/evolution/megaBomb
- (Même item que 10C, rappel ici pour la checklist)

### 16C — Switch non exhaustif sur reward types (`daily_challenge_provider.dart` L84-89)
- `case JokerReward` / `case XpReward` — pas de `default` → si nouveau type = plus de warning
- [ ] 16C.1 Pas de action car sealed class couvre déjà tous les cas (vérifier que c'est sealed)

---

## Étape 17 — Fonctionnalités non implémentées / stubs

### 17A — 🔴 Config Firebase iOS = placeholders (`firebase_options.dart` L27-29)
- `apiKey`, `appId`, `messagingSenderId` = `'TODO'`
- L'app crashe au lancement sur iOS (Firebase, Auth, Firestore, Analytics, Crashlytics tout cassé)
- [ ] 17A.1 Lancer `flutterfire configure` pour générer les vrais credentials iOS

### 17B — 🔴 Background music = méthode vide (`audio_service.dart` L104)
- `playMusic()` → `return;` avec commentaire "No background.mp3 yet"
- Le toggle musique existe dans les Settings mais ne fait rien
- [ ] 17B Soit ajouter un fichier `assets/sounds/background.mp3` et implémenter

### 17C — 🔴 Ad Unit IDs iOS = IDs de test (`ads_service.dart` L19,30 + `ad_banner_widget.dart` L48)
- Banner : `ca-app-pub-3940256099942544/2934735716` (test Google)
- Rewarded : `ca-app-pub-3940256099942544/1712485313` (test Google)
- Aucun revenu pub sur iOS
- [ ] 17C.1 Remplacer par les vrais IDs AdMob iOS (créer les ad units dans la console)

### 17D — 🟡 Rewarded Ad callback vide (`shop_screen.dart` L332)
- `showRewardedAd(onRewarded: () {})` → callback vide, aucun joker donné après la pub
- L'utilisateur regarde une pub et ne reçoit rien → feature cassée
- [ ] 17D.1 Implémenter le reward : ajouter le joker dans `onRewarded`

### 17E — 🟡 Leaderboard = seulement hebdomadaire
- Pas de filtre "all-time" ni "mensuel" ni "amis"
- Pas de pagination (seulement ~50 entries)
- [ ] 17E.1 Ajouter filtre all-time/mensuel (si souhaité)
- [ ] 17E.2 Ajouter pagination/infinite scroll

### 17F — 🟡 Dépendance `audioplayers` potentiellement inutile
- `flutter_soloud` est le moteur audio principal
- `audioplayers` importé dans pubspec.yaml mais peut-être pas utilisé
- [ ] 17F.1 Vérifier si `audioplayers` est réellement utilisé, sinon le retirer

---

## Données qui restent en localStorage (préférences device)
- `soundEnabled`
- `onboardingDone`
- `nudgeStreak3Shown`, `nudgeStreak7Shown`, `nudgeLevel5Shown`, `nudgeObjectives3DaysShown`
- `guestName`, `guestAvatar`
- Toutes les données guest (bestScore, jokers, XP, streak, challenges) pour le mode non-connecté

---

# PARTIE 2 — Performance, Code Quality & Game Feel

---

## Étape 18 — Performance critique : Paint objects recréés par frame

### Impact mesuré
- **10 500 allocations Paint/sec** sur un board plein (7 paints × 25 shapes × 60 fps)
- Chaque `RadialGradient.createShader()` recompile le shader
- Chaque `MaskFilter.blur()` réalloue le filtre
- **GC pauses** possibles → frame drops visibles pendant le drag

### 18A — Cacher les Paint dans ShapePainter (`shape_widget.dart`)
- 7 Paint objects recréés dans `paint()` à chaque frame
- `glowPaint`, `fillPaint`, `rainbowPaint`, `borderPaint`, `highlightPaint`, ring paints
- [ ] 18A.1 Convertir en champs `late final` initialisés dans le constructeur
- [ ] 18A.2 Ne recalculer le shader que si `size` ou `color` change (shouldRepaint)
- [ ] 18A.3 Cacher `MaskFilter.blur()` en `static const`

### 18B — Cacher les Paint dans les Joker painters (`joker_icons.dart`)
- ~200 `Paint()..color = ...` inline dans les méthodes `paint()`
- Gradients recréés par frame, star Path recalculé, TextPainter recréé
- [ ] 18B.1 Pré-calculer les Paint en champs du painter (déjà dans étape 12A)
- [ ] 18B.2 Cacher le star Path de WildcardPainter
- [ ] 18B.3 Cacher le TextPainter de ReducerPainter

### 18C — RepaintBoundary manquant sur le game board (`game_board.dart`)
- Le drag déclenche `setState` → **tout le board repaint** (25 shapes au lieu d'1)
- [ ] 18C.1 Wrapper les non-dragged shapes dans `RepaintBoundary`
- [ ] 18C.2 Ou isoler le shape dragué du Stack principal

### 18D — `setBoardSize()` appelé à chaque `build()` inutilement
- [ ] 18D.1 Mémoriser la taille, ne notifier que si elle change (déjà dans 11D)

---

## Étape 19 — Latence spawn : O(n³) position finding

### Impact mesuré
- Phase 1 : 100 tentatives × O(n) overlap checks = O(100n)
- Phase 2 : 16×16 grid × O(n) distance checks = O(256n)
- **Total sur 25 shapes : 8 544 calculs de distance** → 50-200ms freeze possible

### 19A — Optimiser `spawn_manager.dart`
- [ ] 19A.1 Réduire le grid à 8×8 au lieu de 16×16 (diminue par 4 la phase 2)
- [ ] 19A.2 Early exit dès qu'une position acceptable est trouvée en phase 2
- [ ] 19A.3 Cacher les positions occupées dans un spatial hash simple (cellules de grille)
- [ ] 19A.4 Ne pas recalculer `shapeSize()` pour chaque shape dans la boucle interne

---

## Étape 20 — Fichiers trop gros : découper

| Fichier | Lignes | Problème | Action |
|---------|--------|----------|--------|
| `shop_screen.dart` | **2040** | 15+ classes dans 1 fichier, 10+ build() de 60+ lignes | Découper en widgets |
| `home_screen.dart` | **1092** | Painters + widgets + animations mélangés | Extraire painters |
| `joker_icons.dart` | **1080** | 10 painters + 10 wrappers const dupl. (~150 lignes de wrappers) | Factoriser wrappers |
| `main_hub_screen.dart` | **677** | TopHud + background + logic mélangés | Extraire widgets |
| `app_theme.dart` | **616** | OK pour un theme, mais Button3D est un widget, pas un theme | Extraire `Button3D` |
| `streak_popup.dart` | **572** | Long mais cohérent | OK |

### 20A — Découper `shop_screen.dart` (2040 lignes → ~6 fichiers)
- [ ] 20A.1 Extraire `shop_joker_card.dart` 
- [ ] 20A.2 Extraire `shop_iap_card.dart`
- [ ] 20A.3 Extraire `shop_rewarded_ad.dart`
- [ ] 20A.4 Extraire `shop_painters.dart` (2 CustomPainters)
- [ ] 20A.5 Extraire `joker_choice_dialog.dart`

### 20B — Découper `home_screen.dart` (1092 lignes → ~3 fichiers)
- [ ] 20B.1 Extraire les painters dans un fichier séparé
- [ ] 20B.2 Extraire `_PlayButton` widget

### 20C — Factoriser wrappers const dans `joker_icons.dart` (~150 lignes → ~10)
- [ ] 20C.1 Remplacer les 10 classes `_XxxPainterConst` par un pattern générique

---

## Étape 21 — Code dupliqué à factoriser

### 21A — `canMerge` dupliqué entre `GameShape` et `MergeDetector`
- `GameShape.canMergeWith()` et `MergeDetector.canMerge()` = même logique (+check id)
- [ ] 21A.1 Supprimer `MergeDetector.canMerge()`, utiliser `a.canMergeWith(b)` partout (ajouter check id)

### 21B — Filtre partenaire dupliqué 4× (`spawn_manager.dart` + `joker_handler.dart`)
- `type == type && color == color && level == level` copié 4 fois
- [ ] 21B.1 Utiliser `GameShape.canMergeWith()` ou extraire `_isPartner(a, b)` helper

### 21C — Pattern auth+dispatch dupliqué dans `progression_provider.dart`
- `processGameEnd()` et `addBonusXP()` : ~30 lignes identiques
- [ ] 21C.1 Extraire `_addXP(int amount)` méthode interne

### 21D — Pattern const painter wrapper dupliqué 10× (`joker_icons.dart`)
- [ ] 21D.1 (Même que 20C)

---

## Étape 22 — Game State : immutabilité cassée

### 22A — `GameShape.x` et `GameShape.y` sont mutables
- `double x;` et `double y;` au lieu de `final`
- `game_engine.dart` L146 fait `s.x = newX;` → mutation directe
- [ ] 22A.1 Rendre `x` et `y` `final`
- [ ] 22A.2 Utiliser `copyWith(x: newX, y: newY)` dans `moveDraggedShape()`
- [ ] 22A.3 Vérifier tous les appelants de `.x =` / `.y =`

### 22B — `GameShape.level` est mutable
- `int level;` au lieu de `final`
- [ ] 22B.1 Rendre `level` `final`, utiliser `copyWith(level: ...)` partout

---

## Étape 23 — UX/UI : manque de "juice" pour un jeu premium

### Ce qui est excellent (garder) ✅
- Spawn entrance avec elasticOut bounce + particles
- Merge effect avec ring + 12 particles burst
- Score popup avec ShaderMask gradient
- Haptic feedback progressif par combo
- Float animation (sine wave ±3px)
- Shape 3D effect (radial gradient + specular highlight)

### Ce qui manque pour un vrai jeu premium ❌
- [ ] 23A — **Screen shake au merge** : 2-3 frames, 5-10px, diminution rapide
- [ ] 23B — **Transition de scale au drag** : easing 100ms de 1.0→1.18 au lieu d'instantané
- [ ] 23C — **Résultat du merge grandit** : scale 1.5→1.0 depuis le point de merge au lieu de pop
- [ ] 23D — **Stagger organisé au spawn** : 25ms par shape au lieu de random 0-150ms
- [ ] 23E — **Float commence plus tôt** : démarre à 50% de l'entrée au lieu d'après
- [ ] 23F — **Snap-back avec rebond** : overshoot léger au lieu de easeOut linéaire
- [ ] 23G — (Optionnel) Shadow trail pendant le drag
- [ ] 23H — (Optionnel) Micro-shake quand le board est ≥85% plein

---

## Étape 24 — Architecture : responsabilités mélangées

### 24A — `app.dart` 157 lignes avec 7 responsabilités différentes
- Notifications, Player sync, BestScore sync, Streak, Daily challenges, Leaderboard, Lifecycle
- [ ] 24A.1 Extraire un `SyncCoordinator` pour gérer la réconciliation de données
- [ ] 24A.2 Déplacer la logique notification dans le listener approprié

### 24B — `Button3D` vit dans `app_theme.dart` au lieu d'être un widget
- [ ] 24B.1 Déplacer dans `lib/core/widgets/button_3d.dart`

### 24C — `game_state_provider.dart` exporte `local_storage_provider`
- `export 'package:shape_merge/providers/local_storage_provider.dart';` → fuite
- [ ] 24C.1 Supprimer l'export (même que 10J)

---

## Étape 25 — Issues trouvées dans les fichiers restants (audit final)

### 25A — `retention_ui.dart` : 200+ lignes de badge dupliquées
- `xpBadge()`, `streakBadge()`, `levelBadge()` = structure identique × 3 (L83-259)
- Même Container/BoxDecoration/Row avec juste couleurs/icônes différentes
- [ ] 25A.1 Extraire `_baseBadge({gradient, icon, label, ...})` helper
- [ ] 25A.2 Les 3 badges appellent le helper avec leurs paramètres spécifiques

### 25B — `leaderboard_screen.dart` : header dupliqué + dead code + `buildCard()` 178 lignes
- Header Stack (Button3D + title) copié 2 fois (L59-83 et L141-167)
- `_debugFirestore()` (L18-28) = code debug en production
- `buildCard()` = 178 lignes → extraire en widget séparé
- [ ] 25B.1 Extraire header commun → helper widget
- [ ] 25B.2 Supprimer `_debugFirestore()` ou le garder derrière `kDebugMode`
- [ ] 25B.3 Extraire `buildCard()` en `_LeaderboardCard` widget

### 25C — `daily_challenge_card.dart` : `mounted` manquant + switch dupliqué
- `Future.delayed(900ms, () { widget.onCollect() })` sans check `mounted` (L138-143)
- Pattern `switch (challenge.reward)` répété 3 fois (L225, L237, L283)
- `_buildRewardAnimation()` = 79 lignes
- [ ] 25C.1 Ajouter `if (!mounted) return;` dans les callbacks `Future.delayed`
- [ ] 25C.2 Extraire helper `_rewardIcon(ChallengeReward)` pour le switch dupliqué

### 25D — Ad unit IDs dupliqués entre `ads_service.dart` et `ad_banner_widget.dart`
- Même getter `_adUnitId` / `_bannerAdUnitId` copié dans 2 fichiers
- Risque : changer un ID dans un fichier mais pas l'autre
- [ ] 25D.1 Centraliser les IDs dans `ads_service.dart`, `ad_banner_widget` lit depuis `AdsService`

### 25E — `ad_banner_widget.dart` L65 : `AdSize.getAnchoredAdaptiveBannerAdSize()` sans try/catch
- Peut throw sur certains appareils → crash silencieux
- [ ] 25E.1 Wrapper dans try/catch

### 25F — `gradient_button.dart` : `depthColors` recalculé par frame + hauteur 54 répétée 4×
- `gradient.map((c) => c.withOpacity(0.5)).toList()` dans le build d'AnimatedBuilder
- Hauteur `54` hardcodée aux lignes 83, 87, 97, 107
- [ ] 25F.1 Cacher `depthColors` en champ, recalculer uniquement si `gradient` change
- [ ] 25F.2 Extraire `_surfaceHeight` constant

### 25G — `animated_background.dart` : 30+ magic numbers + Paint par frame
- 20-150 Paint objects recréés par frame selon le mode (lite/full)
- ~30 magic numbers (star count, radius, opacity, grid count, etc.)
- [ ] 25G.1 Cacher les Paint objects en champs
- [ ] 25G.2 Extraire les constantes de configuration en named constants

### 25H — `hud_bar.dart` : 3 painters avec magic numbers + star path recalculé par frame
- `_StarPainter`, `_RingPainter`, `_BoltPainter` — chacun avec coefficients hardcodés
- `_starPath()` recalculé à chaque render
- [ ] 25H.1 Cacher le Path en champ
- [ ] 25H.2 Extraire constantes coefficients (`0.14`, `0.12`, `0.35`, etc.)

### 25I — `pause_overlay.dart` : boutons dupliqués
- Resume et Quit = même structure SizedBox → Button3D → Row (L61-90)
- [ ] 25I.1 Extraire `_buildActionButton({color, icon, label, onPressed})`

### 25J — `ads_service.dart` L78 : `loadRewardedAd()` après dispose peut fuiter
- `onAdFailedToShowFullScreenContent` → `ad.dispose()` puis `loadRewardedAd()`
- Si `AdsService` est détruit entre-temps, la future est orpheline
- [ ] 25J.1 Ajouter un guard `_disposed` flag

---

## Résumé par priorité d'implémentation

### 🔴 P0 — Impact utilisateur immédiat
| # | Quoi | Impact |
|---|------|--------|
| 18A | Cacher Paint objects dans ShapePainter | Frame drops pendant drag |
| 19A | Optimiser spawn position finding | 50-200ms freeze au spawn |
| 22A | Rendre GameShape immutable | Bugs state subtils |
| 17D | Rewarded ad callback vide | Feature cassée visible |
| 10C | `addAll()` ignore 3 jokers sur 6 | Joueurs perdent des jokers IAP |
| 25C.1 | `mounted` check dans daily_challenge_card | Crash après dispose |

### 🟡 P1 — Qualité code & performance
| # | Quoi | Impact |
|---|------|--------|
| 18C | RepaintBoundary sur game board | Rebuilds inutiles pendant drag |
| 20A | Découper shop_screen.dart (2040 lignes) | Maintenabilité |
| 21A-C | Éliminer code dupliqué (canMerge 2×, filtres 4×, progression 2×) | Bugs divergence |
| 11B-C | Fix animation controller leaks | Memory leak progressif |
| 23A-F | Ajouter le juice manquant | Feel premium |
| 25A | Factoriser 200 lignes de badges dupliqués | DRY |
| 25D | Centraliser les ad unit IDs | Risque de divergence |
| 25F-G | Cacher Paint + depthColors dans gradient_button et animated_bg | Perf |

### 🟢 P2 — Nettoyage & polish
| # | Quoi | Impact |
|---|------|--------|
| 20B-C | Découper home_screen, joker_icons | Lisibilité |
| 24A-C | Séparer responsabilités app.dart | Architecture |
| 25B | Nettoyer leaderboard_screen (dead code, header dupl., buildCard 178L) | Code quality |
| 25H-I | Magic numbers hud_bar + boutons pause dupliqués | Maintenabilité |
| 15A-B | Extraire magic numbers painters | Maintenabilité |
| 16A | Résoudre les TODO | Dettes techniques |

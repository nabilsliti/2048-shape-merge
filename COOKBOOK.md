# COOKBOOK — Prompts de refactoring 2048 Shape Merge

> Chaque prompt ci-dessous est conçu pour être copié-collé tel quel dans Copilot.
> Cocher `[x]` chaque prompt une fois exécuté et validé (`dart analyze` = 0 erreurs).

---

## Étape 1 — Ajouter les champs manquants au Player Firestore

- [ ] **Prompt 1.1–1.7**
```
Dans le projet 2048-shape-merge, ajoute les champs manquants au modèle Player Firestore :

1. Ajouter `noAdsPurchased` (bool, default false) et `rewardClaimedDate` (String?) au modèle `Player` dans `lib/core/models/player.dart`
2. Mettre à jour `Player.fromMap()` et `Player.toMap()` pour ces 2 champs
3. Ajouter `jokerInventory` à `Player.fromMap()` / `Player.toMap()` (Map<String, int> avec les 6 types : bomb, wildcard, reducer, radar, evolution, megaBomb)
4. Ajouter dans `FirestoreService` :
   - `updateJokerInventory(String uid, JokerInventory inventory)`
   - `updateRewardClaimedDate(String uid, String date)`
   - `updateNoAdsPurchased(String uid, bool value)`
5. Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 2 — Modifier `playerProvider` : Firestore = source unique

- [ ] **Prompt 2.1–2.5**
```
Dans 2048-shape-merge, modifie `lib/providers/player_provider.dart` pour que Firestore soit la source unique de données quand l'utilisateur est connecté :

1. Supprimer la logique de merge bidirectionnelle (max local vs Firestore)
2. 1er login (player == null en Firestore) : créer le Player avec les données locales + jokers locaux, puis sauvegarder en Firestore
3. Login existant (player != null en Firestore) : charger le Player tel quel depuis Firestore, SANS merge avec localStorage
4. Supprimer les écritures localStorage (setBestScore, setPlayerLevel, etc.) qui étaient faites en parallèle
5. Le mode guest (non connecté) continue d'utiliser localStorage normalement

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 3 — Modifier `gameStateProvider` : jokers depuis Player (connecté)

- [ ] **Prompt 3.1–3.5**
```
Dans 2048-shape-merge, modifie la gestion des jokers pour utiliser Firestore quand connecté :

1. Dans `SplashScreen._initAndNavigate()` : si l'utilisateur est connecté, charger les jokers depuis `Player.jokerInventory` en Firestore (pas localStorage)
2. Dans `GameStateNotifier.addJokers()` / `useJoker()` : persister en Firestore si connecté, en localStorage si guest
3. Créer ou modifier `GameStateNotifier.saveJokerInventory()` pour dispatcher vers Firestore (connecté) ou localStorage (guest)
4. Dans `game_screen.dart` : ne plus écrire les jokers en localStorage si l'utilisateur est connecté
5. Le mode guest continue d'utiliser localStorage pour les jokers

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 4 — Modifier `streakProvider/Service` : rewardClaimedDate en Firestore

- [ ] **Prompt 4.1–4.4**
```
Dans 2048-shape-merge, migre `rewardClaimedDate` vers Firestore quand connecté :

1. Dans `checkAndUpdateSigned()` : lire `player.rewardClaimedDate` au lieu de `storage.rewardClaimedDate`
2. Dans `claimStreakReward()` : écrire `rewardClaimedDate` en Firestore (connecté) ou localStorage (guest)
3. Supprimer l'appel à `_saveToStorage()` pour les données streak quand l'utilisateur est connecté (on garde uniquement Firestore)
4. Le mode guest continue avec localStorage

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 5 — Modifier `progressionProvider/Service` : XP uniquement Firestore

- [ ] **Prompt 5.1–5.5**
```
Dans 2048-shape-merge, supprime les écritures localStorage doublons pour la progression XP quand connecté :

1. `ProgressionService.addXPSigned()` : ne plus écrire en localStorage (seulement Firestore)
2. `ProgressionService.addXPGuest()` : inchangé (garde localStorage)
3. `ProgressionProvider.addXP()` : lire level/XP depuis le Player Firestore (connecté) au lieu de localStorage
4. Vérifier que `level_badge.dart` et `main_hub_screen.dart` lisent déjà depuis `playerProvider` quand connecté
5. Le mode guest continue avec localStorage

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 6 — Modifier `dailyChallengeProvider` : Firestore uniquement (connecté)

- [ ] **Prompt 6.1–6.3**
```
Dans 2048-shape-merge, supprime les écritures localStorage doublons pour les daily challenges quand connecté :

1. `DailyChallengeNotifier.checkRenewal()` : connecté = lire/écrire Firestore seul, guest = localStorage seul
2. `ChallengeService._persistState()` : ne plus écrire en localStorage si connecté
3. Le mode guest continue avec localStorage

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 7 — Nettoyage au sign-out / switch de compte

- [ ] **Prompt 7.1–7.5**
```
Dans 2048-shape-merge, assure que le sign-out/switch de compte ne fuit aucune donnée :

1. Au sign-out : invalider (ref.invalidate) les providers `playerProvider`, `streakProvider`, `dailyChallengeProvider`, `progressionProvider`
2. `gameStateProvider` : reset les jokers en mémoire au sign-out
3. Ne PAS effacer les données localStorage au sign-out (elles servent au mode guest)
4. Vérifier que le listener `authStateProvider` dans `app.dart` gère correctement le sign-out (prevUser != null && nextUser == null → reset)
5. Tester : connecter compte A → déconnecter → connecter compte B → les données de A ne doivent pas apparaître

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 8 — Migration des utilisateurs existants (1er lancement post-update)

- [ ] **Prompt 8.1–8.5**
```
Dans 2048-shape-merge, gère la migration one-shot pour les utilisateurs existants qui ont des données en localStorage mais pas encore en Firestore :

1. Au 1er login post-update : si `Player.jokerInventory` est vide (tous à 0) ET localStorage a des jokers → migrer les jokers vers Firestore
2. Idem pour `noAdsPurchased` : si local = true et Firestore = false → migrer
3. Idem pour `rewardClaimedDate` : copier si existe en local et pas en Firestore
4. Marquer la migration faite avec un flag `migrationV2Done` en localStorage pour ne pas la refaire
5. Cette logique de migration doit être dans le flux de login du `playerProvider`, après le chargement Firestore

Lancer `dart analyze` — 0 erreurs obligatoire.
```

---

## Étape 9 — Nettoyage final migration

- [ ] **Prompt 9.1–9.5**
```
Dans 2048-shape-merge, nettoyage final de la migration Firestore :

1. Vérifier que LocalStorageService garde les champs guest (bestScore, jokers, XP, streak, challenges) — NE PAS les supprimer
2. Supprimer tout code de merge bidirectionnel restant qui n'a plus de raison d'être
3. Lancer `dart analyze` sur tout le projet — 0 erreurs / 0 warnings
4. Test manuel : guest → jouer → se connecter → vérifier données migrées → se déconnecter → reconnecter autre compte → vérifier indépendance des données
5. Test manuel : kill app → relancer → vérifier que les données persistent depuis Firestore (pas de regression)
```

---

## Étape 10 — Correction des bugs architecturaux

- [ ] **Prompt 10A — Race condition bestScore sync**
```
Dans 2048-shape-merge, corrige `app.dart` lignes ~126-137 :

1. Réécrire la chaîne `.then()` de `getLeaderboardScore()` en `async/await` propre avec un seul point de décision
2. Ajouter `try/catch` autour de l'appel
3. `dart analyze` — 0 erreurs
```

- [ ] **Prompt 10B — Timer leak radar**
```
Dans 2048-shape-merge, corrige le leak du timer radar dans `game_state_provider.dart` :

1. Annuler `_radarTimer?.cancel()` AVANT d'en créer un nouveau
2. Ajouter un `dispose()` au StateNotifier qui cancel le timer
3. `dart analyze` — 0 erreurs
```

- [ ] **Prompt 10C — addAll() incomplet**
```
Dans 2048-shape-merge, corrige `JokerInventory.addAll()` qui n'ajoute que 3 types sur 6 :

Actuellement `addAll()` traite bomb, wildcard, reducer mais IGNORE radar, evolution, megaBomb.
Corrige pour inclure les 6 types de jokers.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10D — Duplicate score submission**
```
Dans 2048-shape-merge, corrige la double soumission de score dans `game_screen.dart` :

Quand l'utilisateur se connecte depuis le GameOver overlay, `_submitScore` est appelé mais PAS `_updatePlayerStats` ni `syncGameResult`. Extraire une méthode `_onGameEnd()` partagée entre les 2 chemins (game over normal et sign-in post game over).

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10E — Listener dupliqué via didChangeDependencies**
```
Dans 2048-shape-merge, corrige le listener dupliqué dans `game_screen.dart` :

`ref.listenManual()` est appelé dans `didChangeDependencies()` → enregistre un nouveau listener à chaque rebuild. Déplacer dans `initState()` avec `WidgetsBinding.instance.addPostFrameCallback`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10F — Calcul semaine ISO incorrect**
```
Dans 2048-shape-merge, corrige le calcul de numéro de semaine dans `game_screen.dart` :

Le calcul manuel actuel a un off-by-one aux limites d'année. Utiliser le calcul ISO 8601 correct : `(dayOfYear - date.weekday + 10) ~/ 7`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10G — mounted checks manquants après await**
```
Dans 2048-shape-merge, ajoute les checks `mounted` manquants :

Dans `game_screen.dart` et `profile_dialog.dart` : après chaque `await` dans un callback widget, ajouter `if (!mounted) return;` avant d'accéder à `ref`, `context`, ou `setState`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10H — Test ad ID en production iOS**
```
Dans 2048-shape-merge, remplace l'ID de test AdMob iOS dans `ad_banner_widget.dart` :

L'ID actuel `ca-app-pub-3940256099942544/2934735716` est un ID de test Google. Remplace par le vrai ID AdMob iOS (à créer dans la console AdMob si pas encore fait). En attendant, ajoute un TODO explicite avec un guard `kDebugMode` pour utiliser l'ID de test uniquement en debug.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10I — Notifications hardcodées en français**
```
Dans 2048-shape-merge, localise les strings de notification dans `notification_service.dart` :

`_channelName = 'Série de jeu'` est hardcodé en français. Passer les strings via les paramètres de la méthode de scheduling ou depuis l10n.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 10J — Export inutile**
```
Dans 2048-shape-merge, supprime l'export parasite dans `game_state_provider.dart` :

Supprimer `export 'package:shape_merge/providers/local_storage_provider.dart';`
Corriger tous les fichiers qui importaient `local_storage_provider` via `game_state_provider`.

`dart analyze` — 0 erreurs
```

---

## Étape 11 — Bugs critiques game engine & UI

- [ ] **Prompt 11A — Mutation directe GameShape**
```
Dans 2048-shape-merge, corrige la mutation directe dans `game_engine.dart` :

`moveDraggedShape()` fait `s.x = newX; s.y = newY;` au lieu d'utiliser copyWith. Remplace par `s.copyWith(x: newX, y: newY)` et met à jour la liste des shapes avec le nouveau shape immutable.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 11B–11C — AnimationController leaks + mounted check**
```
Dans 2048-shape-merge, corrige les leaks dans `game_board.dart` :

1. Les listeners ajoutés via `addListener()` / `addStatusListener()` sur `_snapBackCtrl` et `_flyToCtrl` ne sont jamais retirés → fuite mémoire. Retirer les listeners dans `dispose()`.
2. Les 2 controllers ont le même pattern dupliqué → extraire `_setupAnimController()` commune.
3. Dans les `addStatusListener` callbacks, ajouter `if (!mounted) return;` avant tout `setState`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 11D — setBoardSize appelé à chaque build**
```
Dans 2048-shape-merge, corrige `game_board.dart` :

`setBoardSize()` est appelé dans le `LayoutBuilder` à chaque `build()` même si la taille est identique. Mémoriser la taille précédente et ne notifier que si elle change réellement.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 11E — Liste mutable _effects**
```
Dans 2048-shape-merge, corrige la liste mutable `_effects` dans `game_screen.dart` :

`final List<Widget> _effects = []` est mutée directement via `setState`. Convertir en pattern immutable (recréer la liste à chaque ajout/suppression) ou déplacer dans le provider.

`dart analyze` — 0 erreurs
```

---

## Étape 12 — Performance : Paint objects & allocations par frame

- [ ] **Prompt 12A — Paint objects joker_icons.dart**
```
Dans 2048-shape-merge, optimise les painters de `joker_icons.dart` :

1. Cacher les `Paint` objects en champs `late final` ou `static final` au lieu de les recréer dans `paint()` à chaque frame
2. Pré-calculer le star Path de `WildcardPainter` et le cacher en champ
3. Cacher le `TextPainter` de `ReducerPainter`
4. Ne plus appeler `RadialGradient().createShader()` à chaque frame — cacher le shader et ne le recalculer que si la taille change (dans `shouldRepaint`)

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 12B — Wrappers const dupliqués**
```
Dans 2048-shape-merge, factorise les ~150 lignes de classes wrapper const dans `joker_icons.dart` :

Les 10+ classes `_XxxPainterConst` sont identiques (juste un painter différent). Remplacer par une classe générique `_ConstPainterDelegate<T>` ou un pattern factory.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 12C — Color.withValues par frame**
```
Dans 2048-shape-merge, optimise `joker_bar.dart` :

`Color.withValues()` est appelé à chaque tick d'animation dans un `AnimatedBuilder`. Pré-calculer les couleurs disabled/active/inactive une seule fois et les cacher.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 12D — Animation background en arrière-plan**
```
Dans 2048-shape-merge, corrige `home_screen.dart` :

`_bgAnim.repeat()` continue de tourner quand l'app est en arrière-plan → consommation batterie inutile. Ajouter `WidgetsBindingObserver` et stop/resume l'animation dans `didChangeAppLifecycleState`.

`dart analyze` — 0 erreurs
```

---

## Étape 13 — Code dupliqué & complexité

- [ ] **Prompt 13A — Filtre partenaire dupliqué**
```
Dans 2048-shape-merge, factorise le filtre partenaire répété 3× dans `spawn_manager.dart` :

Le filtre `type == type && color == color && level == level` est copié 3 fois (L39-67). Extraire un helper `_findPartners(GameShape target, List<GameShape> shapes)`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 13B — Pattern auth+dispatch dupliqué progression**
```
Dans 2048-shape-merge, factorise le pattern dupliqué dans `progression_provider.dart` :

`processGameEnd()` et `addBonusXP()` contiennent ~30 lignes identiques de auth check + signed/guest dispatch. Extraire `_addXP(int amount)` méthode interne.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 13C — Ternaires imbriqués 4 niveaux**
```
Dans 2048-shape-merge, simplifie les ternaires dans `spawn_manager.dart` L22-33 :

`mergeRate > 0.7 ? 0.50 : mergeRate > 0.5 ? 0.60 : ...` sur 4 niveaux. Extraire en méthode nommée `_adaptiveChance(double mergeRate)` avec des if/else clairs.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 13D–13E — Nesting game_screen.dart**
```
Dans 2048-shape-merge, réduis le nesting dans `game_screen.dart` :

1. Le callback `didChangeDependencies` a 5+ niveaux (callback → async → await → if → await → if → setState). Extraire `_initGame()` et `_setupBestScoreListener()`.
2. Le build tree a 6+ niveaux (Scaffold → Stack → SafeArea → Column → Padding → ClipRRect → Stack). Extraire `_buildHudBar()`, `_buildGameBoard()`, `_buildJokerBar()`.

`dart analyze` — 0 erreurs
```

---

## Étape 14 — Error handling manquant

- [ ] **Prompt 14A–14E — try/catch manquants**
```
Dans 2048-shape-merge, ajoute le error handling manquant :

1. `game_screen.dart` L138-148 : wrapper `syncGameResult()`, `processGameEnd()` dans try/catch avec debugPrint
2. `daily_challenge_provider.dart` L55-59 : wrapper `await _ref.read(playerProvider.future)` dans try/catch
3. `progression_provider.dart` L62-113 : wrapper `addXPSigned()` dans try/catch, logger l'erreur
4. `player.dart` `Player.fromFirestore` : vérifier `data['jokerInventory'] is Map` avant le cast
5. `app.dart` L126 : ajouter `.catchError()` ou réécrire `getLeaderboardScore().then(...)` en async/await (lié à 10A)

`dart analyze` — 0 erreurs
```

---

## Étape 15 — Magic numbers dans les painters

- [ ] **Prompt 15A–15B — Extraire constantes painters**
```
Dans 2048-shape-merge, extrais les magic numbers des painters :

1. `joker_icons.dart` : extraire les ~200 valeurs hardcodées (0.48, 0.58, 0.34, etc.) en constantes nommées dans chaque painter. Extraire `_highlightAlignment = Alignment(-0.3, -0.3)` en constante partagée.
2. `game_board.dart` : extraire les durées d'animation (`Duration(milliseconds: 250)` snap-back, `Duration(milliseconds: 180)` fly-to) et les scale factors (`0.4`, `0.15`) en constantes nommées.

`dart analyze` — 0 erreurs
```

---

## Étape 16 — Nettoyage TODO/FIXME

- [ ] **Prompt 16A — Résoudre les TODO**
```
Dans 2048-shape-merge, traite les TODO/FIXME ouverts :

1. `notification_service.dart` : résoudre les 2 `TODO(l10n)` en passant les strings localisées
2. `ad_banner_widget.dart` : résoudre `TODO: replace with real iOS ID` (lié à 10H)
3. `game_screen.dart` : nettoyer les commentaires debug ("Bug B5 fix", "Bug B2 fix")
4. Vérifier que le switch de `daily_challenge_provider.dart` L84-89 est exhaustif (sealed class) — si oui, rien à faire

`dart analyze` — 0 erreurs
```

---

## Étape 17 — Fonctionnalités non implémentées / stubs

- [ ] **Prompt 17A — Firebase iOS config**
```
Dans 2048-shape-merge, génère les vrais credentials Firebase iOS :

`firebase_options.dart` L27-29 contient `apiKey`, `appId`, `messagingSenderId` = `'TODO'`.
Lancer `flutterfire configure` pour générer les vrais credentials iOS.
```

- [ ] **Prompt 17B — Background music**
```
Dans 2048-shape-merge, implémente la musique de fond :

`playMusic()` dans `audio_service.dart` retourne immédiatement avec le commentaire "No background.mp3 yet". Soit ajouter un fichier audio et implémenter, soit supprimer le toggle musique des Settings pour ne pas tromper l'utilisateur.
```

- [ ] **Prompt 17C — Ad unit IDs iOS**
```
Dans 2048-shape-merge, configure les vrais IDs AdMob iOS :

Les IDs dans `ads_service.dart` et `ad_banner_widget.dart` sont les IDs de test Google (ca-app-pub-3940256099942544/...). Créer les ad units dans la console AdMob et remplacer. Garder les IDs de test derrière `kDebugMode`.
```

- [ ] **Prompt 17D — Rewarded ad callback vide**
```
Dans 2048-shape-merge, implémente le reward de la pub vidéo dans `shop_screen.dart` :

`showRewardedAd(onRewarded: () {})` a un callback vide — l'utilisateur regarde une pub et ne reçoit rien. Implémenter : dans `onRewarded`, ajouter le joker sélectionné à l'inventaire via `gameStateProvider`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 17E — Leaderboard filtres**
```
Dans 2048-shape-merge, ajoute des filtres au leaderboard (optionnel) :

Actuellement le leaderboard n'affiche que le classement hebdomadaire, pas de filtre all-time ni mensuel, et pas de pagination. Ajouter un toggle hebdomadaire/all-time et une pagination/infinite scroll si besoin.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 17F — Dépendance audioplayers inutile**
```
Dans 2048-shape-merge, vérifie si la dépendance `audioplayers` est encore utilisée :

`flutter_soloud` est le moteur audio principal. Chercher si `audioplayers` est importé quelque part. Si non, le retirer de `pubspec.yaml`.

`dart analyze` — 0 erreurs
```

---

## Étape 18 — Performance critique : Paint objects

- [ ] **Prompt 18A — Cacher Paint dans ShapePainter**
```
Dans 2048-shape-merge, optimise `shape_widget.dart` (ShapePainter) :

Les 7 Paint objects (glowPaint, fillPaint, rainbowPaint, borderPaint, highlightPaint, ring paints) sont recréés dans `paint()` à chaque frame → 10 500 allocations/sec sur un board plein.

1. Convertir en champs `late final` initialisés dans le constructeur
2. Ne recalculer le shader que si `size` ou `color` change (via `shouldRepaint`)
3. Cacher `MaskFilter.blur()` en `static const`

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 18B — Cacher Paint dans JokerPainters**
```
Dans 2048-shape-merge, optimise les joker painters dans `joker_icons.dart` :

~200 `Paint()..color = ...` inline dans les méthodes `paint()`. Gradients recréés par frame, star Path recalculé, TextPainter recréé.

1. Pré-calculer les Paint en champs du painter
2. Cacher le star Path de WildcardPainter
3. Cacher le TextPainter de ReducerPainter

(Complète le travail de 12A si pas déjà fait)

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 18C — RepaintBoundary sur le game board**
```
Dans 2048-shape-merge, ajoute un RepaintBoundary dans `game_board.dart` :

Le drag déclenche `setState` → tout le board repaint (25 shapes au lieu d'1). Wrapper les non-dragged shapes dans `RepaintBoundary` ou isoler le shape dragué du Stack principal.

`dart analyze` — 0 erreurs
```

---

## Étape 19 — Latence spawn : O(n³) → O(n)

- [ ] **Prompt 19A — Optimiser spawn_manager.dart**
```
Dans 2048-shape-merge, optimise `_findFreePosition()` dans `spawn_manager.dart` :

La phase 2 (grid scan) fait 16×16 grid × N shapes = potentiellement 8 544 calculs de distance → 50-200ms freeze.

1. Réduire le grid à 8×8 au lieu de 16×16 (81 points au lieu de 289)
2. Early exit dès qu'une position sans chevauchement est trouvée en phase 2 (closestDist > 0 → return immédiatement)
3. Pré-calculer `shapeSize(shape.level)` pour chaque shape UNE seule fois avant les boucles, dans un Map/List. Actuellement `shapeSize()` est appelé pour chaque shape × chaque point de grille.
4. (Optionnel) Cacher les positions occupées dans un spatial hash simple (diviser le board en cellules)

`dart analyze` — 0 erreurs
```

---

## Étape 20 — Fichiers trop gros : découper

- [ ] **Prompt 20A — Découper shop_screen.dart**
```
Dans 2048-shape-merge, découpe `shop_screen.dart` (2040 lignes → ~6 fichiers) :

1. Extraire `shop_joker_card.dart` (widget carte joker)
2. Extraire `shop_iap_card.dart` (widget carte achat in-app)
3. Extraire `shop_rewarded_ad.dart` (widget section pub récompensée)
4. Extraire `shop_painters.dart` (les 2 CustomPainters)
5. Extraire `joker_choice_dialog.dart` (dialog de choix de joker)

Mettre les fichiers extraits dans `lib/screens/shop/widgets/`.
Mettre à jour tous les imports.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 20B — Découper home_screen.dart**
```
Dans 2048-shape-merge, découpe `home_screen.dart` (1092 lignes → ~3 fichiers) :

1. Extraire les painters dans `lib/screens/home/home_painters.dart`
2. Extraire `_PlayButton` widget dans `lib/screens/home/widgets/play_button.dart`

Mettre à jour tous les imports.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 20C — Factoriser wrappers joker_icons.dart**
```
Dans 2048-shape-merge, factorise les ~150 lignes de wrappers const dans `joker_icons.dart` :

Les 10+ classes `_XxxPainterConst` sont identiques. Remplacer par un pattern générique (classe paramétrée ou factory).

`dart analyze` — 0 erreurs
```

---

## Étape 21 — Code dupliqué à factoriser

- [ ] **Prompt 21A — canMerge dupliqué**
```
Dans 2048-shape-merge, supprime la duplication de canMerge :

`GameShape.canMergeWith()` et `MergeDetector.canMerge()` font la même chose (+check id dans l'un). Supprimer `MergeDetector.canMerge()` et utiliser `a.canMergeWith(b)` partout. Ajouter le check `a.id != b.id` dans `canMergeWith()` si pas déjà présent.

Grep tous les appelants de `MergeDetector.canMerge` et les migrer.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 21B — Filtre partenaire dupliqué 4×**
```
Dans 2048-shape-merge, factorise le filtre partenaire dupliqué dans `spawn_manager.dart` et `joker_handler.dart` :

Le pattern `type == type && color == color && level == level` est copié 4 fois à travers ces 2 fichiers. Utiliser `GameShape.canMergeWith()` ou extraire un helper `_isPartner(a, b)` partagé.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 21C — Pattern auth+dispatch progression**
```
Dans 2048-shape-merge, factorise le pattern auth+dispatch dans `progression_provider.dart` :

`processGameEnd()` et `addBonusXP()` ont ~30 lignes identiques. Extraire `_addXP(int amount)` méthode interne.

(Même que 13B — exécuter celui qui n'a pas encore été fait)

`dart analyze` — 0 erreurs
```

---

## Étape 22 — GameShape immutabilité

- [ ] **Prompt 22A–22B — Rendre GameShape immutable**
```
Dans 2048-shape-merge, rends `GameShape` pleinement immutable :

1. Rendre `x`, `y` et `level` `final` dans `game_shape.dart`
2. Dans `game_engine.dart` `moveDraggedShape()` : remplacer `s.x = newX; s.y = newY;` par `s.copyWith(x: newX, y: newY)` et mettre à jour la liste des shapes
3. Grep tout le projet pour `.x =`, `.y =`, `.level =` sur GameShape et corriger chaque mutation avec copyWith

`dart analyze` — 0 erreurs
```

---

## Étape 23 — UX/UI : juice premium

- [ ] **Prompt 23A — Screen shake au merge**
```
Dans 2048-shape-merge, ajoute un screen shake au merge dans `game_board.dart` :

2-3 frames, 5-10px d'amplitude, diminution rapide. Se déclenche à chaque merge réussi. Utiliser un Transform avec un AnimationController de ~100ms.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 23B — Transition scale au drag**
```
Dans 2048-shape-merge, ajoute une transition de scale au drag :

Au lieu du scale instantané quand on commence à drag une shape, faire un easing 100ms de 1.0→1.18 avec un AnimationController.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 23C — Résultat merge grandit**
```
Dans 2048-shape-merge, améliore l'animation post-merge :

La shape résultante doit faire un scale 1.5→1.0 depuis le point de merge au lieu d'un simple pop. Utiliser un AnimationController de ~200ms avec elasticOut.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 23D — Stagger organisé au spawn**
```
Dans 2048-shape-merge, organise le stagger au spawn initial :

Au lieu d'un délai random 0-150ms, utiliser un stagger organisé de 25ms entre chaque shape (shape 1 = 0ms, shape 2 = 25ms, shape 3 = 50ms, etc.).

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 23E — Float commence plus tôt**
```
Dans 2048-shape-merge, fais démarrer l'animation de float (sine wave ±3px) plus tôt :

Actuellement le float commence après que l'animation d'entrée est terminée. Le faire commencer à 50% de l'entrée pour un enchaînement plus fluide.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 23F — Snap-back avec rebond**
```
Dans 2048-shape-merge, ajoute un léger rebond au snap-back dans `game_board.dart` :

Quand un drag est relâché sans merge, la shape retourne à sa position avec un easeOut linéaire. Ajouter un léger overshoot (elasticOut ou custom curve) pour un feel plus satisfaisant.

`dart analyze` — 0 erreurs
```

---

## Étape 24 — Architecture : responsabilités mélangées

- [ ] **Prompt 24A — Extraire SyncCoordinator de app.dart**
```
Dans 2048-shape-merge, sépare les responsabilités de `app.dart` (157 lignes, 7 responsabilités) :

Extraire un `SyncCoordinator` (ou `AppLifecycleCoordinator`) dans `lib/core/services/sync_coordinator.dart` qui gère : Player sync, BestScore sync, Streak check, Daily challenges check, Leaderboard update. `app.dart` ne garde que le MaterialApp + GoRouter + le listener auth.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 24B — Déplacer Button3D**
```
Dans 2048-shape-merge, déplace `Button3D` de `app_theme.dart` vers `lib/core/widgets/button_3d.dart` :

C'est un widget, pas une config de thème. Mettre à jour tous les imports (grep `Button3D`).

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 24C — Supprimer l'export parasite**
```
Dans 2048-shape-merge, supprime l'export `local_storage_provider` dans `game_state_provider.dart` :

(Même que 10J — exécuter celui qui n'a pas encore été fait)

`dart analyze` — 0 erreurs
```

---

## Étape 25 — Issues trouvées dans l'audit final

- [ ] **Prompt 25A — Factoriser les badges dans retention_ui.dart**
```
Dans 2048-shape-merge, factorise les 200+ lignes de badges dupliqués dans `retention_ui.dart` :

`xpBadge()`, `streakBadge()`, `levelBadge()` = structure identique × 3 (Container/BoxDecoration/Row avec juste couleurs/icônes différentes). Extraire `_baseBadge({required List<Color> gradient, required IconData icon, required String label, ...})` et les 3 fonctions l'appellent.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25B — Nettoyer leaderboard_screen.dart**
```
Dans 2048-shape-merge, nettoie `leaderboard_screen.dart` :

1. Header Stack (Button3D + title) copié 2 fois (L59-83 et L141-167) → extraire `_buildHeader()` ou un widget commun
2. `_debugFirestore()` (L18-28) = code debug en production → supprimer ou garder derrière `kDebugMode`
3. `buildCard()` = 178 lignes → extraire en widget `_LeaderboardCard`

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25C — mounted manquant + switch dupliqué dans daily_challenge_card.dart**
```
Dans 2048-shape-merge, corrige `daily_challenge_card.dart` :

1. `Future.delayed(900ms, () { widget.onCollect() })` sans check `mounted` (L138-143) → ajouter `if (!mounted) return;`
2. Pattern `switch (challenge.reward)` répété 3 fois → extraire `_rewardIcon(ChallengeReward)` helper

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25D — Centraliser les ad unit IDs**
```
Dans 2048-shape-merge, centralise les ad unit IDs :

Les même IDs AdMob sont dupliqués dans `ads_service.dart` et `ad_banner_widget.dart`. Centraliser dans `ads_service.dart` (getters statiques) et `ad_banner_widget.dart` lit depuis `AdsService`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25E — try/catch sur getAnchoredAdaptiveBannerAdSize**
```
Dans 2048-shape-merge, ajoute un try/catch dans `ad_banner_widget.dart` L65 :

`AdSize.getAnchoredAdaptiveBannerAdSize()` peut throw sur certains appareils. Wrapper dans try/catch et retourner un fallback (`AdSize.banner`) en cas d'erreur.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25F — Optimiser gradient_button.dart**
```
Dans 2048-shape-merge, optimise `gradient_button.dart` :

1. `depthColors` (gradient.map(...).toList()) est recalculé par frame dans l'AnimatedBuilder → cacher en champ, recalculer uniquement si `gradient` change
2. La hauteur `54` est hardcodée 4 fois → extraire en constante `_surfaceHeight`

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25G — Optimiser animated_background.dart**
```
Dans 2048-shape-merge, optimise `animated_background.dart` :

1. 20-150 Paint objects recréés par frame selon le mode → cacher les Paint en champs
2. ~30 magic numbers (star count, radius, opacity, grid count, etc.) → extraire en named constants

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25H — Optimiser hud_bar.dart painters**
```
Dans 2048-shape-merge, optimise les painters dans `hud_bar.dart` :

1. `_StarPainter`, `_RingPainter`, `_BoltPainter` contiennent des magic numbers hardcodés (0.14, 0.12, 0.35, etc.) → extraire en constantes
2. `_starPath()` est recalculé à chaque render → cacher le Path en champ

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25I — Factoriser boutons pause_overlay.dart**
```
Dans 2048-shape-merge, factorise les boutons dupliqués dans `pause_overlay.dart` :

Resume et Quit = même structure `SizedBox → Button3D → Row` (L61-90). Extraire `_buildActionButton({required Color color, required IconData icon, required String label, required VoidCallback onPressed})`.

`dart analyze` — 0 erreurs
```

- [ ] **Prompt 25J — Guard dispose dans ads_service.dart**
```
Dans 2048-shape-merge, ajoute un guard dispose dans `ads_service.dart` :

Dans `onAdFailedToShowFullScreenContent`, `ad.dispose()` suivi de `loadRewardedAd()`. Si `AdsService` est détruit entre-temps, la future est orpheline. Ajouter un flag `_disposed` et vérifier avant `loadRewardedAd()`.

`dart analyze` — 0 erreurs
```

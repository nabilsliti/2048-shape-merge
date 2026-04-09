# Plan de Rétention & Monétisation Joueur — 2048 Shape Merge

## Objectif

Augmenter la rétention D1/D7/D30 via une couche de progression méta externe au gameplay, sans modifier la mécanique de base. Maximiser la conversion et les revenus via des triggers comportementaux au bon moment.

---

## Stratégie de monétisation comportementale (Jokers)

### Principe fondamental
Le joueur doit penser **"sans joker c'est plus dur"** — jamais **"sans payer c'est impossible"**.  
Les niveaux doivent être faisables sans joker, mais les jokers les rendent significativement plus fluides.

### Boucle de progression

```
Début de vie du joueur :
  1. Joker gratuits offerts (streak J1→J3, objectifs faciles)
  2. Le joueur découvre leur valeur en situation facile
  3. La difficulté augmente progressivement (spawn adaptatif P4)
  4. Les jokers se font plus rares
  5. Le joueur ressent un "léger blocage" (pas frustrant)
     → Pub pour joker gratuit   ← monétisation douce
     → Pack de jokers           ← monétisation payante
  6. Il débloque, continue, progresse
  7. Le cycle recommence avec moins de jokers offerts gratuitement
```

### Moments clés pour proposer un joker (Timing = clé)

**⚡ AVANT la défaite — impact maximum**

Déclencher quand : aucun mouvement valide détecté, le plateau est bloqué.

```
┌──────────────────────────────────────┐
│  😱  Plus aucun mouvement possible   │
│                                      │
│  Utiliser un joker pour continuer ?  │
│                                      │
│  [🎬 Regarder une pub]  [💣 Bombe]   │
│  [✕ Terminer la partie]              │
└──────────────────────────────────────┘
```

- Proposer en premier la pub (frictionless) puis l'achat
- Bouton "Terminer" toujours visible — jamais bloquer le joueur
- Délai de 1.5s avant affichage (laisser le joueur "réaliser" la situation)

**😤 APRÈS la défaite — frustration convertible**

Déclencher dans `GameOverOverlay` si : `score >= bestScore * 0.85` (à 15% du record).

```
┌──────────────────────────────────────┐
│  Tu étais proche de battre ton       │
│  record ! 🔥                         │
│                                      │
│  Score : 8 450  |  Record : 10 000   │
│  ████████████░░  85%                 │
│                                      │
│  [🎬 Joker gratuit]  [💰 Acheter]    │
│  [↩ Rejouer sans joker]              │
└──────────────────────────────────────┘
```

**🎯 Quand le joueur n'a plus de joker**

Badge dans `JokerBar` qui pulse quand `totalJokers == 0` + message discret.

```
Joker bar vide → légère animation pulse orange
"Recharge tes jokers 👜" — bannière 3s puis disparaît
```

**🏁 À 1 mouvement de battre son record**

Déclencher si : `score > bestScore - scoreForMerge(topLevel)`.

```
"Tu es à 1 fusion de battre ton record ! 🎯
Utilise un joker pour ne pas rater ça !"
[💣 Utiliser Bombe]  [🔴 Prendre le risque]
```

### Architecture — fichiers à créer / modifier

**Détection "plateau bloqué" (avant défaite) :**
- `lib/game/logic/game_engine.dart` — `isGameOver()` existe déjà → aussi `isAlmostOver()` (1 seul move possible)
- `lib/screens/game/game_screen.dart` — observer `gameActive` + `isAlmostOver` → afficher `JokerRescueOverlay`
- `lib/screens/game/overlays/joker_rescue_overlay.dart` (nouveau)

**Détection "proche du record" (après défaite) :**
- `lib/screens/game/overlays/game_over_overlay.dart` — ajouter param `isNearRecord: bool` + `percentOfRecord: double`
- `lib/screens/game/game_screen.dart` — calculer `score / bestScore` avant d'afficher l'overlay

**Joker bar vide :**
- `lib/screens/game/widgets/joker_bar.dart` — pulse animation quand `totalJokers == 0`

**Message "à 1 fusion du record" :**
- `lib/screens/game/game_screen.dart` — `ref.listenManual` sur le score, déclencher si score franchit le seuil

### Design des overlays (cohérent avec la charte premium)

- Fond : `BackdropFilter blur(20)` + `Colors.black.withOpacity(0.75)`
- Container : border gold `withOpacity(0.3)`, `BoxShadow` gold glow, radius 24
- CTA principal : `Button3D.green` (regarder pub) ou `Button3D.orange` (acheter)
- CTA secondaire : texte simple blanc54 (rejeter)
- Animation entrée : `SlideTransition` depuis le bas + `FadeTransition` (200ms)

### Règles anti-abus

- **Max 1 "rescue overlay" par partie** — stocker `_rescueShown` flag dans `GameScreen`
- **Max 1 proposition d'achat par session** — flag dans `LocalStorageService`
- **Jamais de popup si le joueur vient d'utiliser un joker** (délai 30s minimum)
- **Le bouton "Non merci" toujours présent et aussi visible** que le CTA principal

### Intégration avec la boucle de rétention

- Les récompenses de **streak** et **objectifs** livrent des jokers gratuits → le joueur valorise les jokers
- La **difficulté adaptative** (P4) peut légèrement augmenter si le joueur a beaucoup de jokers → crée le besoin
- Le streak de connexion J5 donne un joker Radar (premium) → le joueur découvre sa puissance → en veut plus

### Firebase Analytics — events monétisation

À ajouter dans `AnalyticsService` :

| Event | Paramètres |
|-------|-----------|
| `rescue_overlay_shown` | `{trigger: 'blocked'/'near_record'/'no_jokers', score, best_score}` |
| `rescue_overlay_accepted` | `{method: 'ad'/'purchase', joker_type}` |
| `rescue_overlay_rejected` | `{trigger}` |
| `near_record_shown` | `{percent_of_record, score_gap}` |

---

## Charte design — Composants premium & luxe

Tous les nouveaux composants de rétention suivent un langage visuel **sombre, premium, glassmorphism** — cohérent avec le jeu existant.

### Palette dédiée rétention
| Rôle | Couleur | Usage |
|------|---------|-------|
| Streak (or chaud) | `Color(0xFFFFD60A)` | Badge streak, séparateurs premium |
| Niveau (cyan) | `Color(0xFF00d4ff)` | Badge niveau, barre XP |
| Objectifs (vert émeraude) | `Color(0xFF00E676)` | Complétion, checkmarks |
| Danger / expiration | `Color(0xFFFF5252)` | Streak en danger, objectif expiré |
| Fond glassmorphism | `Color(0xFF1A1A2E)` | Fond des cartes retention |

### Conventions composants

**Badges (TopHud)** — style pill compact :
- Fond : couleur principale `withOpacity(0.12)`
- Border : couleur principale `withOpacity(0.4)`, épaisseur 1px, radius 20
- Icône : 14-16px, couleur principale
- Texte : blanc bold 14px + label secondaire blanc54 10px
- Tappable avec `InkWell` + `BorderRadius` correspondant

**Cartes hub** — style glassmorphism :
- Fond : `Color(0xFF1A1A2E)` avec `BoxShadow` glow de la couleur thématique
- Border : `Colors.white.withOpacity(0.08)`, radius 16
- Header : icône couleur thématique + titre blanc bold `GoogleFonts.fredoka`
- Padding interne : `EdgeInsets.all(14)`
- Pas de `Card` Flutter natif — tout `Container` custom

**Barres de progression** :
- `LinearProgressIndicator` enveloppé dans `ClipRRect(radius: 4)`
- Fond : `Colors.white.withOpacity(0.06)`
- Couleur active : gradient via `ShaderMask` si possible, sinon couleur pleine
- Hauteur : 5px (fine et élégante)

**Popups / overlays** :
- `BackdropFilter` avec `ImageFilter.blur(sigmaX:20, sigmaY:20)`
- Fond : `Colors.black.withOpacity(0.6)`
- Contenu : `Container` avec border glow + `BoxShadow` coloré
- Entrée : animation `SlideTransition` + `FadeTransition` depuis le bas

**Animations** :
- Scale pulse sur débloquage : `ScaleTransition` 0.8 → 1.0 avec `ElasticOut`
- Shimmer sur récompense à collecter : `AnimatedBuilder` avec gradient en mouvement
- Confettis si level-up ou streak record : `package:confetti` (à ajouter)

### Icônes — règles de choix
| Feature | Icône Material | Couleur |
|---------|---------------|---------|
| Streak | `Icons.calendar_month_rounded` | Gold `0xFFFFD60A` |
| Niveau joueur | `Icons.workspace_premium_rounded` | Cyan `0xFF00d4ff` |
| Objectifs / missions | `Icons.flag_rounded` | Vert `0xFF00E676` |
| Fusion (objectif) | `Icons.merge_type_rounded` | Blanc |
| Score (objectif) | `Icons.emoji_events_rounded` | Gold |
| Parties jouées | `Icons.sports_esports_rounded` | Blanc |
| XP gagné | `Icons.auto_awesome_rounded` | Cyan |
| Récompense à collecter | `Icons.card_giftcard_rounded` | Gold avec shimmer |
| Level-up | `Icons.arrow_upward_rounded` | Cyan avec glow |

---

## Gestion mode Guest (invité)

### Stratégie : Hybride (Approche 3 — style Clash Royale / Stumble Guys)

Les features de rétention sont **entièrement disponibles en mode guest** (sans friction), avec une conversion naturelle vers un compte Google quand le joueur est suffisamment investi.

### Règle de stockage

| Joueur | Streak | Objectifs | Niveau/XP |
|--------|--------|-----------|-----------|
| Guest | SharedPreferences | SharedPreferences | SharedPreferences |
| Connecté | Firestore | Firestore | Firestore |

### Nudges de conversion (non intrusifs)

| Déclencheur | Message | Fréquence |
|-------------|---------|-----------|
| Streak ≥ 3 jours | Bannière discrète en bas du popup streak : "Sauvegarde ton streak avec Google →" | 1 fois |
| Streak ≥ 7 jours | Popup centré : "🔥 7 jours ! Ne perds pas ta série — connecte-toi pour la sauvegarder" | 1 fois |
| Niveau ≥ 5 | Nudge dans le badge niveau : "Connecte-toi pour sauvegarder ton niveau" | 1 fois |
| Objectifs complétés 3 jours de suite | Popup : "Tu es régulier ! Connecte-toi pour ne pas perdre ta progression" | 1 fois |

**Règles importantes :**
- Chaque nudge ne s'affiche **qu'une seule fois** (flag dans SharedPreferences)
- Jamais de blocage — le joueur peut toujours fermer et continuer à jouer
- Le bouton "Plus tard" est aussi visible que "Se connecter"

### Migration Guest → Compte

Quand un guest se connecte avec Google :
1. Lire les données locales (streak, objectifs, niveau, XP)
2. Comparer avec les données Firestore existantes (si compte déjà utilisé sur un autre appareil)
3. Garder le **maximum** (ex : streak local = 5 jours, Firestore = 2 jours → garder 5)
4. Écrire les données migrées dans Firestore
5. Effacer les données locales

```dart
// dans streak_service.dart
Future<void> migrateGuestToAccount(String uid, LocalStorageService local) async {
  final localStreak = local.currentStreak;
  final firestoreStreak = await getStreak(uid);
  final merged = max(localStreak, firestoreStreak.currentStreak);
  await saveStreak(uid, merged);
  await local.clearStreakData();
}
```

### Fichiers impactés
- `lib/core/services/streak_service.dart` — dual mode local/Firestore
- `lib/core/services/challenge_service.dart` — dual mode local/Firestore
- `lib/core/services/progression_service.dart` — dual mode local/Firestore
- `lib/core/services/local_storage_service.dart` — ajout des clés streak/objectifs/niveau
- `lib/screens/hub/widgets/streak_popup.dart` — nudge de connexion conditionnel

---

### Fichier à créer : `lib/core/constants/retention_ui.dart`
Centraliser toutes les couleurs, icônes et helpers des composants rétention — même principe que `joker_ui.dart`.

```dart
class RetentionUI {
  static const streakColor = Color(0xFFFFD60A);
  static const levelColor  = Color(0xFF00d4ff);
  static const goalColor   = Color(0xFF00E676);
  static const dangerColor = Color(0xFFFF5252);
  static const cardBg      = Color(0xFF1A1A2E);

  static Widget pillBadge({required IconData icon, required Color color, required String text, String? sub}) { ... }
  static BoxDecoration glassCard({required Color glow}) { ... }
  static Widget progressBar({required double value, required Color color}) { ... }
}
```

---

## Prérequis techniques (à faire en premier)

### 1. Firestore rules — mettre à jour `firestore.rules`

Les règles actuelles couvrent `players/{userId}` mais **pas les sous-collections**. `dailyChallenges`, `streak` et `progression` sont des sous-documents — sans cette règle les écritures échoueront silencieusement.

```javascript
// Ajouter dans firestore.rules :
match /players/{userId} {
  allow read: if isAuth();
  allow create, update, delete: if isOwner(userId);

  // ← NOUVEAU : couvre tous les sous-documents
  match /{subcollection=**} {
    allow read, write: if isOwner(userId);
  }
}
```

### 2. `pubspec.yaml` — nouvelles dépendances

```yaml
dependencies:
  confetti: ^0.8.0                        # NE PAS AJOUTER — système de particules déjà présent dans GameOverOverlay._buildParticles()
  flutter_local_notifications: ^18.0.0   # notifs locales streak (P5)
  timezone: ^0.9.0                        # REQUIS par flutter_local_notifications pour les notifs planifiées à heure locale
  # flutter_animate: ^4.5.2 — DÉJÀ PRÉSENT dans pubspec, utiliser pour les animations retention
```

**Note importante** : `flutter_animate` est **déjà dans le projet**. L'utiliser pour les animations des composants rétention (shimmer, pulse, slide) à la place des `AnimationController` custom — réduit le boilerplate significativement.

### 3. Traductions — `lib/l10n/app_fr.arb` et `app_en.arb`

Clés à ajouter avec **format pluriel Flutter obligatoire** (`{n, plural, ...}` sinon "1 jours" s'affiche) :

| Clé ARB | FR | EN |
|---------|-----|-----|
| `streakDays` | `{n, plural, =1{1 jour} other{{n} jours}}` | `{n, plural, =1{1 day} other{{n} days}}` |
| `streakPopupTitle` | `Connexion du jour !` | `Daily login!` |
| `streakBroken` | `Série interrompue` | `Streak lost` |
| `streakSaveNudge` | `Sauvegarde ton streak avec Google →` | `Save your streak with Google →` |
| `streakToday` | `Déjà joué aujourd'hui ✓` | `Already played today ✓` |
| `dailyObjectivesTitle` | `OBJECTIFS DU JOUR` | `DAILY GOALS` |
| `objectiveFusions` | `{n, plural, =1{Réaliser 1 fusion} other{Réaliser {n} fusions}}` | `{n, plural, =1{Make 1 merge} other{Make {n} merges}}` |
| `objectiveScore` | `Atteindre un score de {n}` | `Reach a score of {n}` |
| `objectiveParties` | `{n, plural, =1{Jouer 1 partie} other{Jouer {n} parties}}` | `{n, plural, =1{Play 1 game} other{Play {n} games}}` |
| `objectiveFormeMax` | `Atteindre la forme rang {n}` | `Reach shape rank {n}` |
| `objectiveBonusAll` | `Bonus tout compléter` | `Complete all bonus` |
| `objectiveCompleted` | `Objectif complété !` | `Objective completed!` |
| `collectReward` | `Collecter` | `Collect` |
| `rewardReceived` | `Récompense reçue !` | `Reward received!` |
| `levelBadge` | `Nv` | `Lv` |
| `levelUp` | `NIVEAU {n} !` | `LEVEL {n}!` |
| `xpGained` | `+{n} XP` | `+{n} XP` |
| `xpToNextLevel` | `{n} XP avant le niveau {lv}` | `{n} XP to level {lv}` |
| `connectToSave` | `Connecte-toi pour sauvegarder` | `Sign in to save progress` |
| `later` | `Plus tard` | `Later` |
| `deleteAccount` | `Supprimer mon compte` | `Delete my account` |
| `deleteAccountConfirm` | `Supprimer définitivement ?` | `Delete permanently?` |

**Note** : `signInToSave` existe déjà dans les ARB — les nudges streak utilisent `streakSaveNudge` pour ne pas créer de conflit.

### 4. Firebase Analytics — events à tracker

**Important** : `AnalyticsService` existe dans `lib/core/services/analytics_service.dart` mais n'est branché sur **aucun Provider Riverpod** — il n'est jamais instancié ni utilisé dans l'app. Créer un `analyticsServiceProvider` est la première étape.

```dart
// À ajouter dans analytics_service.dart ou un nouveau analytics_provider.dart
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
```

Nouveaux events à ajouter dans `AnalyticsService` (pas créer un nouveau service) :

| Event | Paramètres | Déclenché dans |
|-------|-----------|----------------|
| `session_start` | `{hour, day_of_week}` | `splash_screen.dart` |
| `app_opened_from_notification` | `{notif_type}` | `notification_service.dart` |
| `streak_updated` | `{current_streak, longest_streak}` | `streak_service.dart` |
| `streak_broken` | `{lost_streak}` | `streak_service.dart` |
| `objective_completed` | `{objective_type, objective_id}` | `challenge_service.dart` |
| `all_objectives_completed` | `{day, bonus_jokers}` | `challenge_service.dart` |
| `reward_collected` | `{reward_type, amount}` | `streak_service.dart` / `challenge_service.dart` |
| `level_up` | `{new_level, xp_total}` | `progression_service.dart` |
| `nudge_shown` | `{nudge_id}` | `streak_popup.dart` |
| `nudge_converted` | `{nudge_id, streak, level}` | `auth_providers.dart` |

### 5. Gestion hors-ligne (offline)

Firestore Flutter a un cache local automatique — les features fonctionnent sans réseau :
- **Lecture** : Firestore retourne les données cachées si offline
- **Écriture** : Firestore met en queue les écritures et les rejoue quand le réseau revient
- **Cas à gérer explicitement** : si le joueur ouvre l'app offline et que la date a changé → générer les objectifs localement, écrire dans Firestore quand reconnecté
- Pas de code spécial nécessaire pour P1/P2 grâce au offline-first de Firestore Flutter

### 6. Fuseau horaire (timezone) — streak edge case

La comparaison de dates pour le streak doit utiliser la **timezone locale du joueur**, pas UTC :

```dart
// ✅ Correct — timezone locale
final today = DateTime.now();
final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

// ❌ Incorrect — UTC, décale pour les joueurs non-UTC
final todayStr = DateTime.now().toUtc().toIso8601String().substring(0, 10);
```

Conséquence : un joueur à Paris qui joue à 23h30 puis à 00h30 compte bien comme 2 jours consécutifs.

### 7. Livraison des récompenses → `GameStateNotifier.addJokers()`

Quand une récompense de streak ou d'objectif donne des jokers, elle doit passer par le mécanisme existant `GameStateNotifier.addJokers(JokerType, amount)` — qui sauvegarde automatiquement via `_saveJokers()`.

```dart
// dans streak_service.dart — après collecte récompense
ref.read(gameStateProvider.notifier).addJokers(JokerType.bomb, 1);

// dans challenge_service.dart — après collecte objectif complété
ref.read(gameStateProvider.notifier).addJokers(rewardType, 1);
```

**Ne pas créer un autre mécanisme** — `addJokers` gère déjà la persistance locale et Firebase.

### 8. Écran Game Over — enrichissement

L'`GameOverOverlay` existant affiche score + mergeCount. Il faut ajouter après chaque partie :
- XP gagné : `+{n} XP` en cyan avec animation slide-up (P3)
- Objectifs progressés : mini-résumé `2/3 objectifs` (P2)
- Fichier à modifier : `lib/screens/game/overlays/game_over_overlay.dart`
- `GameOverOverlay` reçoit deux nouveaux paramètres : `xpGained`, `challengesSummary`

### 9. Lifecycle app — détection retour au premier plan

`app.dart` a déjà un `WidgetsBindingObserver`. Le hook `AppLifecycleState.resumed` existe mais ne fait que reprendre la musique. Il faut **y brancher** la vérification du streak et des objectifs :

```dart
// dans app.dart — case AppLifecycleState.resumed:
case AppLifecycleState.resumed:
  AudioService.instance.resumeMusic();
  ref.read(streakProvider.notifier).checkAndUpdate();     // ← nouveau
  ref.read(dailyChallengeProvider.notifier).checkRenewal(); // ← nouveau
```

Fichier à modifier : `lib/app.dart`

### 10. `AnalyticsService` — nouveaux events à centraliser

Le projet a déjà `lib/core/services/analytics_service.dart` avec `logGameOver`, `logMerge`, etc. Les nouveaux events de rétention doivent être ajoutés dans **ce même fichier** (pas créer un service séparé) :

```dart
Future<void> logStreakUpdated(int streak, bool isRecord) => ...
Future<void> logChallengCompleted(String type) => ...
Future<void> logLevelUp(int level) => ...
Future<void> logGuestNudgeShown(String trigger) => ...
Future<void> logGuestConverted(int streak, int level) => ...
```

Fichier à modifier : `lib/core/services/analytics_service.dart`

### 11. Suppression de compte (GDPR)

Si le joueur supprime son compte, les **sous-collections** Firestore ne sont pas supprimées automatiquement avec le document parent. Il faut supprimer explicitement `streak`, `dailyChallenges`, `progression` lors de la suppression de compte.

Fichier à vérifier/modifier : là où la suppression de compte est gérée (à identifier dans le codebase).

### 12. Compteurs de partie — reset au démarrage

`game_state_provider.dart` devra tracker `nbFusions`, `nbParties`, `scoreSession` pour les objectifs. Ces compteurs sont **par session** (remis à 0 au début de chaque partie), différents du `bestScore` qui est cumulatif. À documenter explicitement dans le code avec un commentaire pour éviter la confusion.

---

## Bugs existants à corriger avant d'implémenter la rétention

Ces bugs sont dans le code actuel et **bloqueront les features de rétention** s'ils ne sont pas corrigés d'abord.

### B1. `playerProvider` ne sauvegarde jamais le document Firestore au premier lancement

```dart
// lib/providers/player_provider.dart — PROBLÈME
return Player(uid: user.uid, displayName: ..., photoUrl: ...);
// ↑ Crée le Player en mémoire mais ne l'écrit JAMAIS dans Firestore
```

Si on tente d'écrire dans `/players/{uid}/streak` alors que le document parent n'existe pas → erreur Firestore.  
**Fix** : appeler `firestoreService.savePlayer(player)` lors de la création du Player (premier lancement).

### B2. `gamesPlayed` et `totalMerges` dans `Player` jamais incrémentés

Ces deux champs existent dans le modèle `Player` et dans Firestore mais rien dans le code ne les met à jour. Les objectifs "jouer N parties" et "réaliser N fusions" dépendent d'eux.  
**Fix** : dans `GameScreen`, là où `!gameState.gameActive && !_scoreSubmitted`, incrémenter les deux compteurs via Firestore.

### B3. `localStorageProvider` défini dans `game_state_provider.dart`

```dart
// lib/providers/game_state_provider.dart — COUPLAGE PROBLÉMATIQUE
final localStorageProvider = FutureProvider<LocalStorageService>((ref) async { ... });
```

Tous les nouveaux services de rétention ont besoin de `LocalStorageService`. En le laissant dans `game_state_provider.dart`, chaque nouveau service devra importer ce fichier — couplage fort non souhaitable.  
**Fix** : extraire dans `lib/providers/local_storage_provider.dart` avant d'implémenter quoi que ce soit.

### B4. `AnalyticsService` jamais instancié dans l'app

`AnalyticsService` est défini mais il n'existe aucun Provider Riverpod pour l'injecter. Le tracking actuel ne fonctionne pas (zéro event envoyé).  
**Fix** : créer `final analyticsServiceProvider = Provider<AnalyticsService>((_) => AnalyticsService());` dans `analytics_service.dart`.

### B5. Bug `weekKey` pour les défis hebdomadaires futurs

```dart
// lib/screens/game/game_screen.dart — CALCUL FAUX
final weekKey = '${now.year}-W${(now.day ~/ 7) + 1}';
// ↑ now.day = jour du MOIS (1-31), donne des semaines complètement fausses
```

**Fix** : utiliser `package:intl` (déjà présent) : `DateFormat('w').format(now)` pour la semaine ISO.

### B6. `GameScreen` accède aux SharedPreferences directement (bypass `LocalStorageService`)

```dart
// lib/screens/game/game_screen.dart
final prefs = await SharedPreferences.getInstance();  // ← bypass du service
```

Les flags de nudge rétention ne doivent **pas** suivre ce pattern.  
**Fix** : toujours passer par `LocalStorageService` pour la cohérence.

---

## Décisions d'architecture à trancher avant de coder

### D1. Où stocker streak / niveau / XP dans Firestore ?

**Décision** : intégrer dans le document `Player` existant (pas de sous-documents séparés pour ces champs).

Raison : `FirestoreService.savePlayer()` utilise `merge: true` → backward-compatible, pas de migration destructive. Champs absents → `?? 0`.

```dart
// Player.toFirestore() — ajouter :
'currentStreak': currentStreak,
'longestStreak': longestStreak,
'level': level,
'currentXP': currentXP,
'totalXP': totalXP,
'unlockedRewards': unlockedRewards,
```

**Objectifs quotidiens** → sous-document `/players/{uid}/dailyChallenges` (structure complexe, différente chaque jour).

### D2. Couleur fond des cartes rétention

- `AppTheme.panelBg = Color(0xFF1e1b4b)` (violet foncé — existant)
- `RetentionUI.cardBg = Color(0xFF1A1A2E)` (quasi-noir — plan rétention)

**Décision** : utiliser `Color(0xFF1A1A2E)` pour les cartes rétention pour les distinguer visuellement des panneaux de jeu existants.

### D3. Récompenses jokers — utiliser `addJokers()` existant

`GameStateNotifier.addJokers(JokerType, amount)` existe déjà et gère la persistance automatiquement. **Ne pas créer un autre mécanisme**. Pour les jokers premium dans les récompenses, utiliser `add(type, amount)` et non `addAll()` (qui ne touche pas radar/evolution/megaBomb).

### D4. Animations — utiliser `flutter_animate` (déjà dans pubspec)

`flutter_animate ^4.5.2` est déjà une dépendance. L'utiliser pour les animations rétention (shimmer, pulse, slide, fade) au lieu de créer des `AnimationController` custom. **Ne pas ajouter `package:confetti`** — `GameOverOverlay` a déjà son propre système de particules (`_buildParticles()`).

### D5. Migration guest → compte — où brancher le listener

Le `StreamProvider<User?>` de `authStateProvider` émet quand le statut d'auth change. Personne ne l'écoute pour déclencher la migration. Ajouter un `ref.listen(authStateProvider, ...)` dans `SplashScreen._initAndNavigate()` ou dans un provider haut niveau dédié `migration_provider.dart`.

### D6. Validation Firestore rules pour les nouvelles données

Ajouter une validation stricte dans les règles pour les champs streak/niveau :

```javascript
match /players/{userId} {
  allow update: if isOwner(userId)
    && (!request.resource.data.keys().hasAny(['currentStreak']) ||
        request.resource.data.currentStreak is int &&
        request.resource.data.currentStreak >= 0 &&
        request.resource.data.currentStreak <= 999);
}
```

---

## Features prioritaires

| # | Feature | Impact | Effort | Priorité |
|---|---------|--------|--------|----------|
| 1 | Streak de connexion | 🔴 Très élevé | Faible | P1 |
| 2 | Objectifs quotidiens | 🔴 Très élevé | Moyen | P2 |
| 3 | XP + Niveau joueur | 🟠 Élevé | Moyen | P3 |
| 4 | Spawn adaptatif | 🟠 Élevé | Faible | P4 |
| 5 | Notifications push | 🟠 Élevé | Faible | P5 |
| 6 | Leaderboard + Saisons | 🟡 Moyen | Élevé | P6 |
| 7 | Événements limités | 🟡 Moyen | Élevé | P7 |
| 8 | Historique / Graphes | 🟢 Faible | Faible | P8 |

---

## P1 — Streak de connexion

### Concept
L'utilisateur reçoit une récompense chaque jour consécutif de connexion. Briser le streak crée une frustration volontaire qui pousse au retour.

### Modèle de données (Firestore)
```
players/{uid}/streak:
  currentStreak: int       // jours consécutifs
  longestStreak: int       // record personnel
  lastLoginDate: Timestamp // pour calculer la continuité
  nextReward: int          // index dans la liste des récompenses
```

### Cycle de récompenses (7 jours)
| Jour | Récompense |
|------|------------|
| J1   | +1 Bombe |
| J2   | +1 Wildcard |
| J3   | +1 Réducteur |
| J4   | +2 Bombes |
| J5   | +1 Radar (premium) |
| J6   | +2 Wildcards |
| J7   | +1 Méga Bombe (premium) |

Cycle relancé à partir de J1 après J7.

### UI

**Badge streak — placement dans `_TopHud`**

Position : Row du TopHud, entre le bouton `⚙️` et le Spacer.

```
[⚙️]   [📅 7]  ·········  [Lv12] [👤]
```

Design premium (pas de flamme — déjà utilisée pour la Méga Bombe joker) :
- Icône : `Icons.calendar_month_rounded` en gold `Color(0xFFFFD60A)`
- Fond : gold `withOpacity(0.12)`, border gold `withOpacity(0.4)`, `BorderRadius.circular(20)`
- Texte : compteur blanc bold + unité "j" grise

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFFFFD60A).withOpacity(0.12),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0xFFFFD60A).withOpacity(0.4), width: 1),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.calendar_month_rounded, color: Color(0xFFFFD60A), size: 16),
      SizedBox(width: 5),
      Text('7', style: bold white 14),
      Text(' j', style: white54 11),
    ],
  ),
)
```

- Tappable → ouvre popup avec calendrier 7 jours + récompenses
- Popup d'accueil au premier lancement du jour avec animation de récompense
- Si streak cassé : message de reprise sans punir (reset à J1)

### Fichiers à créer / modifier
- `lib/core/constants/retention_ui.dart` (nouveau — créer en premier)
- `lib/core/models/player_streak.dart` (nouveau)
- `lib/providers/streak_provider.dart` (nouveau, Riverpod)
- `lib/core/services/streak_service.dart` (nouveau, dual mode local/Firestore)
- `lib/screens/hub/main_hub_screen.dart` (badge streak dans `_TopHud`)
- `lib/screens/hub/widgets/streak_popup.dart` (nouveau, popup accueil + nudge guest)
- `lib/core/services/local_storage_service.dart` (ajout clés streak guest)
- `lib/l10n/app_fr.arb` + `app_en.arb` (clés streak)
- `firestore.rules` (sous-collections)
- `pubspec.yaml` (confetti)

---

## P2 — Objectifs quotidiens

### Concept
3 objectifs renouvelés chaque jour à minuit. Compléter un objectif donne des jokers. Compléter les 3 donne un bonus supplémentaire.

### Types d'objectifs
| ID | Description | Cible exemple |
|----|-------------|---------------|
| `fusions` | Réaliser N fusions | 10 / 20 / 50 |
| `score` | Atteindre un score de N | 500 / 1000 / 5000 |
| `forme_max` | Atteindre la forme de rang N | 5 / 8 / 12 |
| `jokers_uses` | Utiliser N jokers | 2 / 5 |
| `parties` | Jouer N parties | 1 / 2 / 3 |
| `sans_joker` | Atteindre score N sans joker | 300 / 800 |

### Renouvellement automatique

Les objectifs se régénèrent **chaque jour sans aucune intervention manuelle** — ni push en base, ni Cloud Function, ni cron job.

**Principe : le client écrit ses propres objectifs dans son propre document Firestore.**

Chaque joueur possède un document `players/{uid}/dailyChallenges` qu'il crée et met à jour lui-même. Tu n'as jamais à toucher à cette collection.

```
Firestore
└── players/
    └── {uid}/              ← document du joueur (existant)
        └── dailyChallenges ← sous-document géré entièrement par l'app
              date: "2026-04-07"
              challenges: [...]
```

```
Au lancement de l'app (ou retour en foreground) :
  1. L'app lit players/{uid}/dailyChallenges.date
     (depuis le cache Firestore local — pas forcément un appel réseau)
  2. Compare avec aujourd'hui (format "YYYY-MM-DD", timezone locale)
  3. Si date ≠ aujourd'hui (ou document inexistant) :
       → L'app génère elle-même 3 objectifs
       → L'app s'écrit ses propres objectifs dans players/{uid}/dailyChallenges
       → Affiche popup "Nouveaux objectifs disponibles !"
  4. Si date == aujourd'hui :
       → Charge l'état existant (déjà en cache)
```

**Génération 100% côté client** (pas de Cloud Function, pas de cron job) :
- `ChallengeService.generateForToday(playerLevel)` — appelé par `daily_challenge_provider.dart`
- Seed déterministe `"${uid}_${dateString}"` → même résultat sur plusieurs appareils du même compte
- Pondération selon le niveau : niveau < 5 → faciles, 5-20 → moyens, > 20 → difficiles

**Tracking en temps réel** (pendant la partie) :
- `game_state_provider.dart` incrémente les compteurs locaux (`nbFusions`, `score`, `nbParties`)
- À la fin de chaque partie → `ChallengeService.syncProgress(counters)` compare avec les targets et marque `completed = true` si atteint
- Pas de sync Firestore pendant la partie — seulement en fin de partie pour éviter les écritures excessives

### Modèle de données (Firestore)
```
players/{uid}/dailyChallenges:
  date: String             // "2026-04-07" — clé de renouvellement
  challenges: [
    { id, type, target, current, completed, reward, difficulty }
  ]
  allCompleted: bool
  bonusCollected: bool
```

### Récompenses
- Objectif simple : +1 joker classique aléatoire
- Objectif difficile : +1 joker premium aléatoire
- Bonus tout compléter : +3 jokers au choix

### UI

**Carte objectifs — placement dans `HomeScreenContent`**

Position : entre `_BestScoreDisplay` et le bouton PLAY, pleine largeur.

Design :
- Fond : `Color(0xFF1A1A2E)` avec border `Colors.white.withOpacity(0.08)`, `BorderRadius.circular(16)`
- Header : icône `Icons.flag_rounded` cyan (`Color(0xFF00d4ff)`) + texte "OBJECTIFS DU JOUR" + sous-texte date
- 3 lignes d'objectifs, chacune avec :
  - Icône spécifique à l'objectif (ex: `merge_type_rounded`, `emoji_events_rounded`)
  - Texte description + barre de progression fine (`LinearProgressIndicator`)
  - Icône ✓ `check_circle_rounded` vert quand complété, sinon récompense à collecter
- Footer : bonus "Tout compléter" avec état `allCompleted ? Collecte ! : X/3`
- Tappable sur chaque ligne complétée → animation collecte joker

```
┌─────────────────────────────────┐
│ 🏁 OBJECTIFS DU JOUR   7 avr.  │
├─────────────────────────────────┤
│ ⚡ 10 fusions    ████████░░  ✓  │
│ 🏆 Score 1000   ██████░░░░  🎁  │
│ 🎮 2 parties    ██░░░░░░░░      │
├─────────────────────────────────┤
│ Bonus tout compléter : 2/3      │
└─────────────────────────────────┘
```

### Fichiers à créer / modifier
- `lib/core/models/daily_challenge.dart` (nouveau)
- `lib/providers/daily_challenge_provider.dart` (nouveau)
- `lib/core/services/challenge_service.dart` (nouveau, dual mode local/Firestore + générateur)
- `lib/screens/hub/widgets/daily_challenge_card.dart` (nouveau)
- `lib/screens/hub/main_hub_screen.dart` (intégration carte dans `HomeScreenContent`)
- `lib/providers/game_state_provider.dart` (tracking `nbFusions`, `score`, `nbParties`)
- `lib/screens/game/game_screen.dart` (appel `syncProgress` en fin de partie)
- `lib/core/services/local_storage_service.dart` (ajout clés objectifs guest)
- `lib/l10n/app_fr.arb` + `app_en.arb` (clés objectifs)

---

## P3 — XP + Niveau joueur

### Concept
Chaque partie rapporte de l'XP. Le niveau monte globalement, indépendamment du jeu. Les premiers niveaux montent vite (accroche), le late game est lent (rétention longue durée).

### Formule XP par partie
```
xp = floor(score / 500)          // base score
   + (nbFusions × 1)             // récompense les combos
   + (rangeFormeMax × 3)         // récompense la progression
   + (5 si objectif complété)    // bonus objectif quotidien
   + (streakBonus)               // +10% si streak ≥ 7 jours
```

### Courbe de progression
```
xpRequis(niveau N) = 100 × N^1.4
```

| Niveau | XP cumulés | XP palier | ~Temps (3 parties/jour) |
|--------|------------|-----------|------------------------|
| 1→5    | 500        | ~100      | 1 semaine              |
| 5→15   | 5 000      | ~500      | 1 mois                 |
| 15→30  | 25 000     | ~1 500    | 3 mois                 |
| 30→50  | 100 000    | ~3 500    | 1 an+                  |

**Max : niveau 50**

### Récompenses par palier
| Niveau | Récompense |
|--------|------------|
| 5      | +1 Bombe offerte au démarrage de partie |
| 10     | Fond de plateau alternatif |
| 15     | +1 Wildcard offerte au démarrage |
| 20     | Joker Radar débloqué gratuitement 1×/jour |
| 30     | Badge "Expert" |
| 50     | Titre "Maître des Formes" + cosmétique exclusif |

### Modèle de données (Firestore)
```
players/{uid}/progression:
  level: int
  currentXP: int
  totalXP: int
  unlockedRewards: List<String>
```

### UI

**Badge niveau — placement dans `_TopHud`**

Position : Row du TopHud, entre le Spacer et le bouton `👤` (avatar).

```
[⚙️]   [📅 7]  ·········  [Lv 12] [👤]
```

Design premium :
- Icône : `Icons.workspace_premium_rounded` en `Color(0xFF00d4ff)` (cyan)
- Fond : cyan `withOpacity(0.12)`, border cyan `withOpacity(0.4)`, `BorderRadius.circular(20)`
- Texte : "Lv" blanc54 10px + numéro blanc bold 14px

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFF00d4ff).withOpacity(0.12),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0xFF00d4ff).withOpacity(0.4), width: 1),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.workspace_premium_rounded, color: Color(0xFF00d4ff), size: 14),
      SizedBox(width: 4),
      Text('Lv', style: white54 10),
      SizedBox(width: 2),
      Text('12', style: bold white 14),
    ],
  ),
)
```

**Barre XP — sous le TopHud**

- Fine barre de 3px pleine largeur, juste sous le HUD
- Couleur qui évolue avec le niveau : bleu (1-10) → violet (11-25) → gold (26-50)
- Animée (`AnimatedFractionallySizedBox`) à chaque gain d'XP

**Animation Level-up**

- Overlay centré (Stack dans `MainHubScreen`) affiché 2s après une partie
- `workspace_premium_rounded` cyan agrandi avec animation scale + glow
- Texte "NIVEAU 13 !" + récompense débloquée si palier atteint

### Fichiers à créer / modifier
- `lib/core/models/player_progression.dart` (nouveau)
- `lib/providers/progression_provider.dart` (nouveau)
- `lib/core/services/progression_service.dart` (nouveau, dual mode local/Firestore)
- `lib/screens/hub/widgets/level_badge.dart` (nouveau, badge pill cyan)
- `lib/screens/hub/widgets/xp_bar.dart` (nouveau, barre 3px sous TopHud)
- `lib/screens/hub/widgets/level_up_overlay.dart` (nouveau, animation confettis)
- `lib/screens/game/game_screen.dart` (calcul XP + appel `progressionService` en fin de partie)
- `lib/core/services/local_storage_service.dart` (ajout clés niveau/XP guest)
- `lib/l10n/app_fr.arb` + `app_en.arb` (clés niveau/XP)
- `pubspec.yaml` (confetti — si pas déjà ajouté via P1)

---

## P4 — Spawn adaptatif (difficulté dynamique)

### Concept
Le `SpawnManager` ajuste le pourcentage de smart spawn selon le taux de fusion récent du joueur. Si le joueur fusionne beaucoup → le jeu se complique légèrement (moins de smart spawn). Si le joueur est bloqué → le jeu s'adapte (plus de smart spawn).

### Logique
```dart
// Stocker les 20 dernières tentatives de drag
recentAttempts: List<bool>   // true = fusionné, false = raté

recentMergeRate = recentAttempts.where(true).length / recentAttempts.length

// Mapping → smartChance
if (recentMergeRate > 0.7) smartChance = 0.50   // joueur trop fort → plus difficile
if (recentMergeRate > 0.5) smartChance = 0.60
if (recentMergeRate > 0.3) smartChance = 0.70   // zone cible (actuel)
else                        smartChance = 0.80   // joueur en difficulté → aide
```

### Fichiers à modifier
- `lib/game/logic/spawn_manager.dart` (smartChance dynamique)
- `lib/providers/game_state_provider.dart` (tracking recentAttempts)
- `lib/game/logic/game_engine.dart` (passer le rate au SpawnManager)

---

## P5 — Notifications push

### Concept
Rappels légers pour maintenir l'habitude quotidienne.

### Messages
| Déclencheur | Exemple |
|-------------|---------|
| Streak en danger (23h sans connexion) | "🔥 Ton streak de 7 jours est en danger !" |
| Objectifs quotidiens disponibles | "🎯 Tes objectifs du jour t'attendent !" |
| Niveau proche | "⬆️ Plus que 50 XP pour le niveau 12 !" |

### Stack
- Firebase Cloud Messaging (FCM) — déjà dans le projet
- `flutter_local_notifications` pour les notifs locales (streak)

### Fichiers à créer / modifier
- `lib/core/services/notification_service.dart` (nouveau)
- `lib/providers/streak_provider.dart` (planifier notif au login)

---

## Layout global du hub avec toutes les features

```
┌─────────────────────────────────────────┐
│ [⚙️]  [📅 7]  ·········  [Lv 12] [👤]  │  ← _TopHud
│ ═══════════════════════cyan══════════════│  ← Barre XP 3px
│                                         │
│         SHAPE MERGE 2048                │  ← _FloatingTitle
│                                         │
│  ┌───────────────────────────────────┐  │
│  │      🏆  12 450  (meilleur)       │  │  ← _BestScoreDisplay
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🏁 OBJECTIFS DU JOUR    7 avr.   │  │  ← DailyChallengeCard (nouveau)
│  │ ⚡ 10 fusions   ████████░░  ✓    │  │
│  │ 🏆 Score 1000   ██████░░░░  🎁   │  │
│  │ 🎮 2 parties    ██░░░░░░░░        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🚀  JOUER                      │    │  ← Button PLAY
│  └─────────────────────────────────┘    │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │  🛍️  SHOP    │  │ 🏆 CLASSEMENT│    │  ← Row existante
│  └──────────────┘  └──────────────┘    │
│                                         │
│  [  AdBanner  ]                         │
└─────────────────────────────────────────┘

Overlays (Stack z-order par-dessus tout) :
  - StreakPopup      → popup centré au 1er lancement du jour
  - LevelUpOverlay   → 2s après la fin d'une partie si level up
```

---

## Ordre d'implémentation recommandé

**IMPORTANT** : respecter cet ordre — les étapes suivantes dépendent des précédentes.

```
── Phase 0 : Fondations (OBLIGATOIRE avant tout) ─────────────────────
  0a. Extraire localStorageProvider → lib/providers/local_storage_provider.dart
  0b. Créer analyticsServiceProvider dans analytics_service.dart
  0c. Mettre à jour firestore.rules (sous-collections + validation)
  0d. Corriger le bug B1 : sauvegarder Player au premier lancement
  0e. Corriger le bug B2 : incrémenter gamesPlayed + totalMerges en fin de partie
  0f. Étendre LocalStorageService (clés streak / level / xp / nudge flags)
  0g. Étendre Player model (streak / level / xp / unlockedRewards)
  0h. Créer retention_ui.dart
  0i. Ajouter pubspec deps (flutter_local_notifications, timezone)
  0j. Corriger le bug B5 : weekKey → DateFormat ISO

── Sprint 1 : Streak + Spawn adaptatif ───────────────────────────────
  1a. Créer player_streak.dart (model)
  1b. Créer streak_service.dart (dual mode guest/connecté)
  1c. Créer streak_provider.dart
  1d. Brancher streak dans SplashScreen._initAndNavigate()
  1e. Brancher streak dans app.dart AppLifecycleState.resumed
  1f. Créer streak_popup.dart (popup J1→J7 + nudge guest)
  1g. Ajouter badge streak dans _TopHud (main_hub_screen.dart)
  1h. Brancher migration guest→compte sur authStateProvider
  1i. Spawn adaptatif (spawn_manager.dart + game_state_provider.dart)
  1j. Ajouter clés ARB streak + régénérer l10n

── Sprint 2 : Objectifs quotidiens ───────────────────────────────────
  2a. Créer daily_challenge.dart (model)
  2b. Créer challenge_service.dart (générateur dual mode)
  2c. Créer daily_challenge_provider.dart
  2d. Brancher tracking (nbFusions, score session, nbParties) dans game_state_provider.dart
  2e. Appeler syncProgress() dans GameScreen en fin de partie
  2f. Créer daily_challenge_card.dart
  2g. Intégrer la carte dans HomeScreenContent (home_screen.dart)
  2h. Ajouter clés ARB objectifs + régénérer l10n

── Sprint 3 : XP + Niveau joueur ─────────────────────────────────────
  3a. Créer player_progression.dart (model — peut être intégré dans Player)
  3b. Créer progression_service.dart (dual mode)
  3c. Créer progression_provider.dart
  3d. Calculer XP en fin de partie dans GameScreen
  3e. Créer level_badge.dart (widget pill cyan TopHud)
  3f. Créer xp_bar.dart (barre 3px sous TopHud)
  3g. Créer level_up_overlay.dart (animation flutter_animate)
  3h. Enrichir GameOverOverlay (XP gagné + résumé objectifs)
  3i. Ajouter clés ARB niveau/XP + régénérer l10n

── Sprint 4 : Notifications push ─────────────────────────────────────
  4a. Créer notification_service.dart
  4b. Planifier notif streak au login
  4c. Handler deep link depuis notif (main.dart)

── Sprint 5 : GDPR + nettoyage ──────────────────────────────────────
  5a. Ajouter deleteAccount() — supprime sous-collections + Auth user
  5b. Ajouter clearAllData() dans LocalStorageService
  5c. Ajouter clés ARB deleteAccount + régénérer l10n
```

---

## Métriques à suivre

| Métrique | Baseline à mesurer | Cible |
|----------|-------------------|-------|
| D1 rétention | ? | > 40% |
| D7 rétention | ? | > 20% |
| D30 rétention | ? | > 10% |
| Sessions/jour/user | ? | > 2 |
| Durée session moyenne | ? | > 5 min |

Suivre via Firebase Analytics (events déjà configurés dans le projet).

# Prompt Claude Opus — 2048 Shape Merge (Flutter/Firebase)

> **Instruction** : Crée un projet Flutter complet pour un jeu mobile appelé **2048 Shape Merge**.
> Le jeu est basé sur le prototype HTML ci-dessous. Tu dois produire **tout le code source**,
> fichier par fichier, prêt à compiler.

---

## 📎 Prototype HTML de référence

Le fichier `shape-merge.html` (fourni en pièce jointe) contient la mécanique complète du jeu :
- Plateau avec des formes (cercle, carré, étoile, hexagone) de 4 couleurs
- Drag & drop pour fusionner deux formes identiques (même type + même couleur + même niveau)
- Niveaux : 2 → 4 → 8 → 16 → 32 → 64 → 128 → 256 (MAX_LEVEL = 8)
- Score = 2^niveau × 10 points par fusion
- Capacité max : 30 formes sur le plateau
- Game over quand plateau plein ET aucune paire fusionnable
- Spawn intelligent : 70% de chance de copier une forme existante
- Animations : spawn pop-in, merge shrink, burst radial, score float-up

**Reproduis fidèlement toute cette mécanique en Flutter.**

---

## 🏗️ Architecture & Conventions

Suis **exactement** les conventions du projet `shape-rush` dans le même workspace :

### Structure des dossiers

```
2048-shape-merge/
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── flutter_launcher_icons.yaml
├── flutter_native_splash.yaml
├── android/
│   ├── app/
│   │   └── build.gradle.kts        # 3 flavors: dev, staging, prod
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── assets/
│   ├── icon/                        # App icon
│   └── sounds/
│       ├── merge.wav
│       ├── bomb.wav
│       ├── wildcard.wav
│       ├── reducer.wav
│       ├── game_over.wav
│       ├── level_up.wav
│       ├── spawn.wav
│       └── button_tap.wav
├── lib/
│   ├── main.dart                    # Entry point dev (default)
│   ├── main_dev.dart
│   ├── main_staging.dart
│   ├── main_prod.dart
│   ├── app.dart                     # GoRouter + MaterialApp.router
│   ├── firebase_options.dart        # Placeholder (FlutterFire CLI)
│   ├── core/
│   │   ├── config/
│   │   │   └── flavor_config.dart   # FlavorType enum + FlavorConfig singleton
│   │   ├── constants/
│   │   │   ├── game_constants.dart  # MAX_LEVEL, MAX_SHAPES, SNAP_R, etc.
│   │   │   ├── shape_types.dart     # ShapeType enum
│   │   │   └── joker_types.dart     # JokerType enum + config
│   │   ├── models/
│   │   │   ├── game_shape.dart      # id, x, y, type, color, level
│   │   │   ├── player.dart          # uid, displayName, bestScore, jokerInventory
│   │   │   ├── joker_inventory.dart # bomb, wildcard, reducer counts
│   │   │   └── leaderboard_entry.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart           # Google Sign-In + Firebase Auth
│   │   │   ├── firestore_service.dart      # Leaderboard CRUD
│   │   │   ├── audio_service.dart          # Sound effects on/off
│   │   │   ├── analytics_service.dart      # Firebase Analytics events
│   │   │   ├── ads_service.dart            # Banner + Rewarded ads
│   │   │   ├── iap_service.dart            # In-App Purchases (joker packs)
│   │   │   ├── local_storage_service.dart  # SharedPreferences (best score, onboarding done, sound pref, joker stock)
│   │   │   └── crashlytics_service.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Material 3, dark theme spatial/gaming
│   │   └── widgets/
│   │       ├── animated_counter.dart
│   │       ├── glass_card.dart      # Glassmorphism card widget
│   │       └── gradient_button.dart
│   ├── providers/
│   │   ├── auth_providers.dart
│   │   ├── game_state_provider.dart    # Core game state (shapes list, score, merges, jokers, gameActive)
│   │   ├── leaderboard_provider.dart
│   │   ├── audio_provider.dart
│   │   ├── ads_provider.dart
│   │   ├── iap_provider.dart
│   │   └── settings_provider.dart      # Sound on/off, onboarding done
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart       # PageView avec 2 pages
│   │   │   ├── rules_page.dart              # Page 1 : règles du jeu
│   │   │   └── jokers_page.dart             # Page 2 : explication jokers + bouton "Jouer"
│   │   ├── home/
│   │   │   ├── home_screen.dart             # Menu principal
│   │   │   └── widgets/
│   │   │       ├── play_button.dart
│   │   │       ├── best_score_card.dart
│   │   │       ├── menu_item_button.dart
│   │   │       └── animated_background.dart # Fond animé avec formes flottantes
│   │   ├── game/
│   │   │   ├── game_screen.dart             # Le plateau de jeu
│   │   │   ├── widgets/
│   │   │   │   ├── game_board.dart          # Zone principale drag & drop
│   │   │   │   ├── shape_widget.dart        # Widget d'une forme (rendu 3D)
│   │   │   │   ├── hud_bar.dart             # Score, meilleur, formes, fusions
│   │   │   │   ├── capacity_bar.dart        # Barre de capacité
│   │   │   │   ├── joker_bar.dart           # Barre des 3 jokers en bas
│   │   │   │   ├── merge_effect.dart        # Animation 3D explosion de fusion
│   │   │   │   └── score_popup.dart         # "+80" flottant
│   │   │   └── overlays/
│   │   │       ├── game_over_overlay.dart   # Score + stats + sign-in Google (si pas connecté) + rejouer
│   │   │       └── pause_overlay.dart
│   │   ├── leaderboard/
│   │   │   ├── leaderboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── leaderboard_tile.dart
│   │   │       └── podium_widget.dart       # Top 3 avec podium animé
│   │   ├── shop/
│   │   │   ├── shop_screen.dart             # Acheter des jokers
│   │   │   └── widgets/
│   │   │       ├── joker_pack_card.dart     # Small (5) / Medium (15) / Large (40)
│   │   │       └── watch_ad_button.dart     # Regarder une pub → +1 joker
│   │   └── settings/
│   │       └── settings_screen.dart         # Son on/off, sign-out, about
│   ├── l10n/
│   │   ├── app_en.arb
│   │   └── app_fr.arb
│   └── game/
│       ├── logic/
│       │   ├── game_engine.dart         # Toute la logique : spawn, merge, collision, game over check
│       │   ├── merge_detector.dart      # canMerge, findBestTarget, hasPairs
│       │   ├── spawn_manager.dart       # Smart spawn (70% mirror), findFreePos
│       │   └── joker_handler.dart       # Logique des 3 jokers
│       └── models/
│           └── game_state.dart          # Immutable state class (shapes, score, merges, jokerUses, gameActive)
├── test/
│   ├── game/
│   │   ├── game_engine_test.dart
│   │   ├── merge_detector_test.dart
│   │   └── joker_handler_test.dart
│   └── services/
│       └── local_storage_service_test.dart
└── integration_test/
    └── app_test.dart
```

### Stack technique

```yaml
# pubspec.yaml dependencies
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Navigation
  go_router: ^14.8.1

  # Firebase
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  firebase_analytics: ^11.4.4
  firebase_crashlytics: ^4.3.3

  # Auth
  google_sign_in: ^6.2.2

  # UI
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.2

  # Audio
  audioplayers: ^6.1.0

  # Ads
  google_mobile_ads: ^5.3.0

  # IAP
  in_app_purchase: ^3.2.0

  # Storage
  shared_preferences: ^2.5.3

  # Misc
  uuid: ^4.5.1
  vector_math: ^2.1.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.15
  mocktail: ^1.0.4
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.5
```

### Patterns obligatoires

- **Riverpod** pour tout le state management (providers dans `providers/`)
- **GoRouter** pour la navigation (routes dans `app.dart`)
- **Services** : classes dédiées qui encapsulent Firebase, audio, ads, IAP
- **Pas de JSDoc / pas de commentaires descriptifs** — noms explicites uniquement
- **Comments en anglais** pour expliquer le "why", pas le "what"
- **Flavors** : dev / staging / prod (comme shape-rush)
- **Entry points** : `main.dart` (dev), `main_dev.dart`, `main_staging.dart`, `main_prod.dart`
- **Initialisation** : `WidgetsFlutterBinding.ensureInitialized()` → lock portrait → Firebase.initializeApp → audio init → Crashlytics → `ProviderScope(child: App())`

---

## 🎮 Mécanique de jeu détaillée

### Règles fondamentales (reproduire le HTML)

| Paramètre | Valeur |
|---|---|
| Formes | circle, square, star, hexagon |
| Couleurs | blue (#4fc3f7), green (#69f0ae), purple (#ce93d8), gold (#ffd54f) |
| MAX_LEVEL | 8 (valeurs: 2, 4, 8, 16, 32, 64, 128, 256) |
| MAX_SHAPES | 30 (game over threshold) |
| START_SHAPES | 10 (formes initiales, en paires garanties) |
| SPAWN_PER_MOVE | 1 (après chaque drag) |
| SNAP_R | 60px (rayon de détection de merge) |
| Taille forme | `min(38 + level × 8, 86)` pixels |
| Score par merge | `2^newLevel × 10` |

### Fusion

- Deux formes fusionnent si : **même type + même couleur + même niveau**
- Le joueur **drag** une forme sur une autre compatible
- Si merge réussi → la forme résultante apparaît au milieu avec level+1
- Si pas de merge → la forme **snap-back** à sa position d'origine
- Après chaque drag (avec ou sans merge) → spawn 1 nouvelle forme

### Spawn intelligent

- 70% de chance de copier type+couleur d'une forme existante
- 55% de chance (dans ces 70%) de copier aussi le level → crée des paires immédiates
- 30% complètement aléatoire
- Position : chercher jusqu'à 40 positions aléatoires sans overlap

### Game Over

- Plateau plein (30) ET aucune paire fusionnable → **Game Over**
- Plateau plein MAIS paires existantes → toast "⚠️ Fusionne vite !" et on continue
- Plus de paires MAIS place → spawn automatique jusqu'à créer une paire

### Victoire

- Si le plateau est vide (toutes les formes fusionnées) → message victoire spécial

---

## 🃏 Système de Jokers

### Les 3 jokers

| Joker | Icône | Effet | Activation |
|-------|-------|-------|------------|
| **Bombe** | 💣 | Détruit toutes les formes identiques (même couleur + même type, **tous niveaux**) | Tap joker → tap sur une forme cible → toutes les formes de même type+couleur explosent |
| **Wildcard** | 🌀 | Forme arc-en-ciel qui merge avec n'importe quelle forme du même niveau | Tap joker → une forme spéciale arc-en-ciel apparaît → drag sur n'importe quelle forme de même niveau → merge garanti |
| **Réducteur** | ⬇️ | Baisse le niveau d'une forme de 1 (level 1 → disparaît) | Tap joker → tap sur une forme → son niveau baisse de 1 |

### Règles jokers

- **3 utilisations de chaque** en début de première partie
- Les jokers NE se rechargent PAS automatiquement entre les parties
- Utiliser un joker **ne spawne PAS** de nouvelle forme (avantage gratuit)
- Les jokers restants persistent entre les parties (stockés localement + dans Firestore si connecté)
- Le compteur d'utilisations restantes s'affiche sur chaque joker dans la barre

### Recharge des jokers

1. **Gratuit** : Regarder une pub rewarded → +1 joker au choix du joueur (dialog de sélection)
2. **Achat intégré** (IAP) :
   - **Pack Small** : 5 de chaque joker (15 total) → 1,99€
   - **Pack Medium** : 15 de chaque joker (45 total) → 4,99€
   - **Pack Large** : 40 de chaque joker (120 total) → 9,99€

---

## 📱 Écrans & Flow utilisateur

### 1. Splash Screen
- Logo du jeu avec animation d'apparition
- Vérification Firebase + chargement des données locales
- Redirect vers Onboarding (première fois) ou Home

### 2. Onboarding (première fois uniquement)
- **Page 1 — Règles du jeu** :
  - Explication visuelle : "Fais glisser des formes identiques pour les fusionner"
  - Montre les 4 types de formes et les valeurs (2 → 4 → 8 → ... → 256)
  - "Le plateau peut contenir max 30 formes"
  - Indicateur de page (dots) + bouton "Suivant"
- **Page 2 — Les Jokers** :
  - Présentation des 3 jokers avec icônes et description
  - "Tu commences avec 3 de chaque !"
  - Bouton **"🎮 Jouer"** qui lance la première partie

### 3. Home Screen (menu principal)
- **Fond animé** : formes géométriques flottantes semi-transparentes (parallax subtil)
- **Titre** "SHAPE MERGE" en police Orbitron (ou équivalent Google Fonts)
- **Meilleur score** affiché dans un card glassmorphism
- **Boutons** :
  - 🎮 **Jouer** (gros bouton central animé, gradient bleu)
  - 🏆 **Classement** (leaderboard)
  - 🃏 **Boutique** (acheter des jokers)
  - ⚙️ **Paramètres** (son, compte, about)
- **Icône son** 🔊/🔇 en haut à droite (toggle rapide)
- Le joueur doit sentir qu'il est dans un **vrai univers de jeu** (ambiance spatiale, néons, profondeur)

### 4. Game Screen
- **HUD en haut** : Score | Meilleur | Formes | Fusions (comme le HTML)
- **Barre de capacité** sous le HUD (couleur dynamique: vert → orange → rouge)
- **Plateau de jeu** : fond sombre avec léger effet étoilé
- **Barre de jokers en bas** : 3 boutons (💣🌀⬇️) avec compteur restant, au-dessus de la pub
- **Banner publicitaire** tout en bas (AdMob banner, ne gêne pas le gameplay)
- **Bouton pause** en haut à gauche

### 5. Game Over Overlay
- Card glassmorphism central
- 💀 "Game Over" (ou 🏆 si victoire)
- Score final (gros chiffre doré animé)
- Stats : nombre de fusions, niveau max atteint
- **Si pas connecté** : bouton "🔗 Se connecter avec Google" pour sauvegarder le score
- **Si connecté** : score automatiquement envoyé au leaderboard + rang affiché
- Bouton "▶ Rejouer"
- Bouton "🏠 Menu"

### 6. Leaderboard Screen
- **Podium animé** pour le top 3 (or, argent, bronze)
- Liste scrollable des joueurs (photo, nom, score, rang)
- Le joueur connecté est mis en surbrillance
- Pull-to-refresh
- Tabs : "Tous les temps" / "Cette semaine" (optionnel si simple)

### 7. Shop Screen
- 3 cards pour les packs de jokers (Small, Medium, Large)
- Chaque card montre le contenu et le prix
- Bouton "Regarder une pub" → sélection du joker à recharger
- Stock actuel de jokers affiché en haut

### 8. Settings Screen
- Toggle son 🔊/🔇
- Compte Google (connecté/déconnecté)
- Bouton déconnexion
- Version de l'app
- Lien politique de confidentialité

---

## 🎨 Design & Thème

### Palette (reprendre le HTML)

```dart
static const background = Color(0xFF0A0A1A);
static const panel = Color(0xFF12122A);
static const border = Color(0xFF2A2A5A);
static const blue = Color(0xFF4FC3F7);
static const green = Color(0xFF69F0AE);
static const purple = Color(0xFFCE93D8);
static const gold = Color(0xFFFFD54F);
static const red = Color(0xFFEF5350);
static const text = Color(0xFFE8EAF6);
static const muted = Color(0xFF7986CB);
```

### Ambiance

- Thème sombre futuriste / spatial
- Background avec subtils points lumineux (étoiles)
- Cards en glassmorphism (semi-transparent + blur)
- Gradients sur les boutons
- Polices : **Orbitron** pour les titres/scores, **Exo 2** pour le texte
- Ombres néon sur les éléments interactifs

---

## ✨ Animations & Effets 3D

### Formes sur le plateau

- Chaque forme a un **rendu 3D** : ombrage, reflet, profondeur (utiliser `Transform` avec perspective)
- Les formes ont un léger **idle float** (oscillation verticale subtile, 2-3px)
- Quand on sélectionne une forme : **scale 1.18** + glow + ombre portée amplifiée
- Les formes compatibles **pulsent** (match-hint) quand on drag une forme

### Animation de merge

1. Les deux formes **se rétractent** vers le point central (0.22s ease-in)
2. **Explosion de particules** radiales (burst) avec la couleur de la forme
3. La nouvelle forme **pop-in** avec un effet 3D de rotation (spawn depuis scale 0 avec légère rotation 3D)
4. **Score popup** "+80" flotte vers le haut et disparaît
5. **Screen shake** très subtil (1-2px, 100ms)
6. **Son de merge** joué

### Animation de spawn

- Nouvelle forme : apparition avec **scale 0 → 1** + légère rotation
- **Beacon** circulaire qui pulse à la position de spawn

### Animation de joker

- **Bombe** : toutes les formes ciblées explosent simultanément avec particules rouges/oranges + screen shake
- **Wildcard** : forme arc-en-ciel avec gradient animé qui tourne
- **Réducteur** : la forme ciblée **shrink** puis **re-pop** à la taille inférieure (ou disparaît si level 1)

### Game Over

- Les formes restantes **tremblent** puis **tombent** une par une (gravity effect)
- Le score final **count-up** de 0 au score réel

---

## 🔊 Audio

- **merge.wav** : son satisfaisant de fusion (clochette/chime)
- **bomb.wav** : explosion sourde
- **wildcard.wav** : son magique/arcane
- **reducer.wav** : son de compression/shrink
- **game_over.wav** : son dramatique court
- **level_up.wav** : quand une forme atteint un nouveau record de niveau
- **spawn.wav** : petit pop subtil
- **button_tap.wav** : clic UI

Le son est **activable/désactivable** globalement. L'état persiste dans SharedPreferences.

> Note : place des fichiers `.wav` vides (1-byte placeholder) dans `assets/sounds/` pour la compilation.
> Les vrais sons seront ajoutés manuellement ensuite.

---

## 🌐 Internationalisation

- 2 langues : **anglais** (défaut) + **français**
- Détection automatique de la langue système
- Toutes les strings UI dans les fichiers ARB
- Utiliser le pattern `AppLocalizations.of(context)!.key`

### Clés ARB à créer (minimum)

```json
{
  "appTitle": "Shape Merge",
  "play": "Play",
  "leaderboard": "Leaderboard",
  "shop": "Shop",
  "settings": "Settings",
  "bestScore": "Best Score",
  "score": "Score",
  "shapes": "Shapes",
  "merges": "Merges",
  "capacity": "Board Capacity",
  "gameOver": "Game Over",
  "victory": "Victory",
  "boardFull": "Board full and no possible merge!",
  "noPairs": "No possible merge!",
  "boardFullWarning": "Board full — merge fast!",
  "noPairsNewShapes": "No pairs — new shapes added!",
  "replay": "Play Again",
  "menu": "Menu",
  "signInGoogle": "Sign in with Google",
  "signInToSave": "Sign in to save your score and see the leaderboard",
  "signOut": "Sign Out",
  "soundOn": "Sound On",
  "soundOff": "Sound Off",
  "jokerBomb": "Bomb",
  "jokerBombDesc": "Destroys all shapes of the same type and color",
  "jokerWildcard": "Wildcard",
  "jokerWildcardDesc": "Merges with any shape of the same level",
  "jokerReducer": "Reducer",
  "jokerReducerDesc": "Reduces a shape's level by 1",
  "onboardingTitle1": "How to Play",
  "onboardingDesc1": "Drag identical shapes to merge them and score points!",
  "onboardingTitle2": "Your Jokers",
  "onboardingDesc2": "You start with 3 of each joker. Use them wisely!",
  "startPlaying": "Start Playing",
  "next": "Next",
  "packSmall": "Small Pack",
  "packMedium": "Medium Pack",
  "packLarge": "Large Pack",
  "watchAd": "Watch an Ad",
  "watchAdReward": "Watch an ad to get +1 joker of your choice",
  "chooseJoker": "Choose a joker to recharge",
  "rank": "Rank",
  "allTime": "All Time",
  "thisWeek": "This Week",
  "maxLevel": "Max Level",
  "fusionsCount": "{count} merges",
  "version": "Version",
  "privacyPolicy": "Privacy Policy",
  "connected": "Connected",
  "notConnected": "Not Connected",
  "pause": "Pause",
  "resume": "Resume",
  "quit": "Quit"
}
```

---

## 🔥 Firebase & Backend

### Firestore Structure

```
leaderboard/
  {odcId}/
    uid: string
    displayName: string
    photoUrl: string?
    score: int
    maxLevel: int
    mergeCount: int
    timestamp: Timestamp
    weekKey: string          // "2026-W14" pour le classement hebdo

players/
  {uid}/
    displayName: string
    photoUrl: string?
    bestScore: int
    totalMerges: int
    gamesPlayed: int
    jokerInventory:
      bomb: int
      wildcard: int
      reducer: int
    createdAt: Timestamp
    lastPlayedAt: Timestamp
```

### Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{docId} {
      allow read: if true;
      allow create, update: if request.auth != null
        && request.resource.data.uid == request.auth.uid;
      allow delete: if false;
    }
    match /players/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Firestore Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "leaderboard",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "score", "order": "DESCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "leaderboard",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "weekKey", "order": "ASCENDING" },
        { "fieldPath": "score", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 📢 Publicité

- **Banner AdMob** en bas de l'écran de jeu (sous la barre de jokers)
- Hauteur standard (50px), ne pousse pas le contenu
- Le plateau de jeu est au-dessus, le joueur n'est **jamais gêné**
- **Rewarded Ad** pour recharger 1 joker au choix
- Utiliser des test ad unit IDs en dev

---

## 🛒 In-App Purchases

- 3 produits consommables :
  - `joker_pack_small` → 5 de chaque joker → 1.99€
  - `joker_pack_medium` → 15 de chaque joker → 4.99€
  - `joker_pack_large` → 40 de chaque joker → 9.99€
- Après achat → créditer les jokers dans le state local + Firestore
- Gérer les pending purchases au démarrage

---

## 🧪 Tests

Crée des tests unitaires pour :
- `game_engine.dart` : merge logic, spawn, game over detection
- `merge_detector.dart` : canMerge, hasPairs, countPairs
- `joker_handler.dart` : bomb effect, wildcard merge, reducer effect

---

## ⚙️ Build Configuration

### Android (`android/app/build.gradle.kts`)

- **applicationId** : `com.crestbit.shape_merge`
- **3 flavors** (dimension: "environment") :
  - `dev` → suffix `.dev`, app name "Shape Merge Dev"
  - `staging` → suffix `.staging`, app name "Shape Merge Staging"
  - `prod` → no suffix, app name "Shape Merge"
- **minSdk** : 24
- **targetSdk** : 35
- **Java** : JVM 11
- **Signing** : `key.properties` file pour release

---

## 📝 Résumé des priorités

1. **Jeu fonctionnel** avec toute la mécanique du prototype HTML
2. **Animations 3D** impressionnantes sur les merges et les interactions
3. **Jokers** avec le flow d'activation exact décrit
4. **Onboarding** 2 pages unique au premier lancement
5. **Sign-in Google** proposé au premier game over
6. **Leaderboard Firebase** temps réel
7. **Son** toggle avec persistance
8. **Internationalisation** FR/EN détection auto système
9. **Banner pub** non-intrusive + rewarded pour jokers
10. **IAP** packs de jokers
11. **Tests unitaires** de la logique de jeu

---

## ⚠️ Contraintes

- **PAS** de `any` type (Dart est déjà typé, mais attention aux `dynamic`)
- **PAS** de commentaires descriptifs — noms auto-explicatifs
- **PAS** d'over-engineering — code simple et direct
- **PAS** de packages inutiles — seulement ceux listés
- Les fichiers audio sont des **placeholders** (fichiers vides ou 1 byte)
- Le `firebase_options.dart` est un **placeholder** (sera régénéré par FlutterFire CLI)
- Commits en anglais, comments en anglais, UI strings dans ARB uniquement

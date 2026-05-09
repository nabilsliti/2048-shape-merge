# 🎮 Audit Complet — Shape Merge 2048 (Game Engine & Stratégie)

> Date : 2025-04-16 | Branche : `feat/new-design`
> Scope : Gameplay, Rétention, Monétisation, UX, Technique, Sécurité

---

## 📊 SCORECARD GLOBAL

| Catégorie | Score | Verdict |
|-----------|-------|---------|
| **Game Engine** | 9/10 | Excellent — pur Dart, difficulté adaptative, bien tuné |
| **Rétention** | 8/10 | Streak + challenges + XP solides. Streak ne nécessite pas de jouer |
| **Monétisation** | 5/10 | Callback pub vide, pas d'interstitiels, catalogue IAP limité |
| **UX/Feedback** | 8/10 | Animations riches, haptics, tuto. Audio manque de variété |

---

## 📋 TABLEAU RÉCAPITULATIF — TOUS LES POINTS À FAIRE

| # | Priorité | Catégorie | Action | Fichier(s) | Effort | Statut |
|---|----------|-----------|--------|-----------|--------|--------|
| 1 | **P0** | 🔴 Bug | Remplacer iOS ad unit IDs test | `ad_units.dart` | 5 min | 📋 todo |
| 2 | ✅ | 💀 Game Over | Implémenter revive via pub | `game_over_overlay.dart`, `game_state_provider.dart` | 2-3h | ✅ |
| 3 | ✅ | 💰 Monétisation | Ajouter interstitiels entre parties (chaque 3ème GO) | `ads_service.dart`, `game_screen.dart` | 1-2h | ✅ |
| 4 | ✅ | 📊 Analytics | Ajouter events critiques (session, ads, funnel, tuto) | `analytics_service.dart` + callers | 2h | ✅ |
| 5 | ✅ | 📊 Analytics | Appeler `logLevelReached` dans progression | `progression_provider.dart` | 10 min | ✅ |
| 6 | ✅ | 🧠 Audio | Sons distincts par joker (6 sons) | `audio_catalog.dart` + assets | 2h | ✅ |
| 8 | ✅ | 🎁 Jokers | Réduire jokers de départ (22 → 12) | `game_tuning.dart` | 10 min | ✅ |
| 9 | ✅ | 🎮 Engine | Fix `findMatchingShapes` radar ignore level | `merge_detector.dart` | 30 min | ✅ |
| 10 | ✅ | 🏆 Progression | Récompenses level-up (jokers par palier) | `game_tuning.dart`, `progression_provider.dart`, `level_up_overlay.dart` | 3h | ✅ |
| 11 | ✅ | 💰 Monétisation | Catalogue IAP : packRescue + packBoost | `shop_catalog.dart`, `shop_screen.dart` | 3h | ✅ |
| 12 | ✅ | 🧠 Audio | Son game over dramatique dédié | `audio_catalog.dart` + assets | 30 min | ✅ |
| 13 | ✅ | 🧠 Audio | Son tap bouton distinct du merge | `audio_catalog.dart` + assets | 15 min | ✅ |
| 14 | **P2** | 🔁 Rétention | Missions hebdomadaires + récompenses premium | Nouveau provider | 4-6h | ❌ |
| 15 | **P2** | 💰 Monétisation | Battle Pass mensuel (€2.99/mois) | Nouveau système | 8-12h | 📋 todo |
| 16 | **P2** | 🏆 Progression | Thèmes visuels débloquables par niveau | `core/theme/` | 6-8h | ❌ |
| 17 | **P2** | 🎮 Gameplay | Mode Quick Play (chrono 3 min) | Nouveau mode | 4h | ❌ |
| 18 | ✅ | ⚙️ Performance | Optimiser board rebuilds (ValueNotifier) | `game_board.dart` | 3h | ✅ |
| 19 | ✅ | ⚙️ Performance | Cache `_BoardBackgroundPainter` (50 étoiles) | `game_board.dart` | 30 min | ✅ |
| 20 | ✅ | ⚙️ Performance | Limiter `_effects` list à 8 max | `game_screen.dart` | 30 min | ✅ |
| 21 | ✅ | 🔒 Sécurité | Cloud Function validation score + IAP receipt (Android) | `functions/index.js` | 4h | ✅ |
| 21b | **P2** | 🔒 Sécurité | Vérification IAP iOS (App Store Server API) | `functions/index.js` | 1-2h | ❌ |
| 23 | **P2** | 🔁 Rétention | Événements temporaires saisonniers | Nouveau système | 8-12h | ❌ |
| 26 | **P2** | 📊 Analytics | Events P1 (combo, challenge progress, streak milestone…) | `analytics_service.dart` + callers | 2h | ❌ |
| 27 | ✅ | 🎮 Engine | `copyWith(lastMergedShapeId)` nullable wrapper | `game_state.dart` | 30 min | ✅ |
| 28 | ✅ | 🔒 Sécurité | Utiliser `serverTimestamp()` pour streak dates — CF `claimDailyStreakReward` déployée, `lastClaimAt` autoritaire serveur, anti-cheat horloge | `functions/index.js`, `streak_service.dart`, `player.dart`, `streak_provider.dart` | 2h | ✅ |
| 29 | ✅ | 🔴 Bug | Callback pub vide → JokerChoiceDialog | `main_hub_screen.dart` | — | ✅ `796f868` |
| 30 | ✅ | 🔴 Bug | XP donné au quit (processGameEnd appelé au quit) | `game_screen.dart` | 30 min | ✅ |
| 31 | ✅ | 🔴 Bug | XP gonflé : completedObjectives = total jour, pas delta | `game_screen.dart`, `progression_provider.dart` | 30 min | ✅ |
| 32 | ✅ | 🔴 Bug | Objectif `parties` compte le quit comme partie jouée | `game_screen.dart` | 30 min | ✅ |
| 33 | ✅ | 🎯 Objectifs | Nouvel objectif `shapesDestroyed` (détruire X formes avec bombes) → pousse 💣Bomb/💥MegaBomb | `game_state_provider.dart`, `challenge_service.dart`, `challenge_config.dart` | 1h | ✅ |
| 34 | ✅ | 🎯 Objectifs | Nouvel objectif `wildcardMerges` (faire X fusions avec wildcard) → pousse 🃏Wildcard | `game_engine.dart`, `challenge_service.dart`, `challenge_config.dart` | 1h | ✅ |
| 35 | ✅ | 🎯 Objectifs | Nouvel objectif `highLevelMerges` (créer X formes niveau ≥ 6) → pousse ⬆️Evolution/🃏Wildcard | `game_engine.dart`, `challenge_service.dart`, `challenge_config.dart` | 1h | ✅ |
| 36 | ✅ | 🎯 Objectifs | Nouvel objectif `boardClears` (vider le board X fois) → pousse 💥MegaBomb | `game_engine.dart`, `challenge_service.dart`, `challenge_config.dart` | 1h | ✅ |
| 37 | ✅ | 🎯 Objectifs | Nouvel objectif `maxCombo` (atteindre combo-chain de X) → pousse 🔍Radar | `game_engine.dart`, `challenge_service.dart`, `challenge_config.dart` | 1h | ✅ |
| 38 | ✅ | 📱 Android | Permission `AD_ID` ajoutée (Android 13+) → AdMob peut générer un ID publicitaire | `AndroidManifest.xml` | 5 min | ✅ |
| 39 | ⏭️ | 📱 Android | Flavor underscore : non-applicable — seul le flavor `prod` (sans underscore) va sur Play Store ; `_dev` / `_staging` sont internes | `android/app/build.gradle.kts` | — | ⏭️ |
| 40 | **P0** | 📱 iOS | App Tracking Transparency (ATT) + SKAdNetwork manquants — bloquant pour pubs personnalisées iOS 14.5+ | `ios/Runner/Info.plist`, `ads_service.dart` | 30 min | ❌ |
| 41 | ⏭️ | ⚙️ Performance | Non-applicable — vérification : aucun `BackdropFilter` réel dans le code, le "glass" est juste un `BoxDecoration` (couleur + glow), donc zéro coût GPU | `retention_ui.dart` | — | ⏭️ |
| 42 | **P2** | ♿ Accessibilité | 0 widget `Semantics` → TalkBack/VoiceOver inutilisable | Plusieurs écrans | 1h30 | ❌ |
| 43 | ✅ | 🧹 Tech debt | `AudioService` extrait en `abstract class` + impl `_SoLoudAudioService` ; `audioServiceProvider` Riverpod ; `setForTesting`/`resetForTesting` pour mocks ; providers (audio/iap/daily_challenge) migrés vers `ref.read(audioServiceProvider)` | `audio_service.dart`, `audio_provider.dart`, `iap_provider.dart`, `daily_challenge_provider.dart` | 45 min | ✅ |
| 44 | ✅ | ⚙️ Performance | `HomeScreen._bgAnim` pause auto via `WidgetsBindingObserver` (app pause) + `currentBranchIndexProvider` (tab switch) → zéro CPU quand pas visible | `home_screen.dart`, `ad_banner_widget.dart`, `nav_provider.dart` (nouveau) | 30 min | ✅ |
| 45 | ⏭️ | 🔴 Bug | Sign-out efface progression guest — **intentionnel** : profil vierge voulu en mode guest | `app.dart` | — | ⏭️ |
| 46 | ✅ | 🔴 Bug | Race condition splash + auth listener (double init) | `splash_screen.dart`, `app.dart` | 30 min | ✅ |
| 47 | **P2** | 🔒 Sécurité | `IntegrityGuard` HMAC sur bestScore/level/XP/stats en localStorage (anti-cheat guest) | `local_storage_service.dart` | 1h | ❌ |
| 48 | ✅ | 🎨 UX | Overlay plein écran (spinner + texte localisé) pendant le merge guest→signed (replay achats + fetch player + merge jokers/XP/score). Bloque l'input pour éviter les "sauts" de jokers visibles. | `app.dart`, `account_sync_provider.dart`, `account_sync_overlay.dart`, `app_*.arb` | 30 min | ✅ |
| 49 | **P2** | 🔁 Rétention | Streak Freeze (protection 1 jour manqué — pub ou IAP) | `streak_service.dart`, UI | 3-4h | ❌ |
| 50 | **P2** | 🔁 Rétention | Streak Recovery via pub récompensée (rattraper 1 jour) | `streak_service.dart`, `ads_service.dart`, UI | 2-3h | ❌ |
| 51 | **P2** | 🔁 Rétention | Notifications streak personnalisées (heure du dernier play) | `notification_service.dart` | 1h | ❌ |
| 52 | **LOW** | 🔁 Rétention | Partage social du streak (capture + share intent) | UI + share_plus | 2h | ❌ |
| 53 | ✅ | ⚙️ Performance | Cache `Paint` dans painters chauds 60FPS : `_RadiationPainter`, `_ConfettiPainter` (HUD), `_ConfettiRainPainter` (game over) — économie ~30 allocations/frame pendant confetti | `joker_orb.dart`, `hud_painters.dart`, `game_over_overlay.dart` | 1h | ✅ |
| 54 | ✅ | 🌐 i18n | Notifications streak l10n via `AppLocalizations` (clés `notifStreakTitle`/`notifStreakBody`/`notifStreakBodyWithDays`/`notifChannelName`/`notifChannelDesc`) ; FR/EN gérés | `notification_service.dart`, `game_screen.dart`, `app_*.arb` | 30 min | ✅ |

**Résumé** : 2 P0 · 9 P2 · 0 LOW · 33 DONE | Supprimés : #7, #22, #24, #25, #39, #41, #45 (non-applicables ou retirés) | Déplacé : #15 → todo
**Objectifs** : 5 existants + 5 nouveaux = 10 types → 120 combinaisons | Couverture jokers : 💣Bomb, 💥MegaBomb, 🃏Wildcard, ⬆️Evolution, 🔍Radar, ⬇️Reducer
| **Architecture** | 9/10 | Séparation propre, dual-mode (guest/signed), état immutable |
| **Performance** | 9/10 | Drag isolé via ValueNotifier, painter caché, effets cappés |
| **Analytics** | 4/10 | Événements basiques seulement. Manque session, funnel, pub |
| **Sécurité** | 7/10 | Bonnes rules Firestore. Modèle client-trust acceptable |

---

## 🔴 BUGS CRITIQUES TROUVÉS

### BUG #1 — Callback pub vide (CRITIQUE / P0)

**Fichier** : `lib/screens/hub/main_hub_screen.dart`

**Problème** : ~~`_watchAdFromHub` appelait `showRewardedAd(onRewarded: () {})` — callback vide.~~ **CORRIGÉ** — Utilise maintenant `JokerChoiceDialog.show(context)` après visionnage.

**Impact** : Revenus publicitaires perdus, frustration joueur (regarde une pub pour rien).

**Statut** : ✅ Corrigé dans commit `796f868`.

---

### BUG #2 — iOS Ad Unit IDs = Test IDs (CRITIQUE / P0)

**Fichier** : `lib/core/constants/ad_units.dart` lignes 14 et 23

**Problème** : iOS utilise les IDs de test Google en production.
```dart
// TODO: replace with real iOS ID
static const iosBanner = 'ca-app-pub-3940256099942544/2435281174';
// TODO: replace with real iOS ID  
static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
```

**Impact** : $0 de revenus publicitaires sur iOS. Violation possible des policies Google.

**Solution** : Remplacer par les vrais IDs AdMob iOS avant soumission App Store.

**Priorité** : P0

---

### BUG #3 — `logLevelReached()` jamais appelé (HAUT / P1)

**Fichier** : `lib/core/services/analytics_service.dart`

**Problème** : L'événement `level_reached` est défini mais jamais déclenché nulle part dans le code.

**Impact** : Aucune donnée sur la progression des joueurs par niveau.

**Solution** : Appeler `logLevelReached(level)` dans `ProgressionService` lors d'un level-up.

**Priorité** : P1

---

### BUG #4 — XP donné au quit (CRITIQUE / P0)

**Fichiers** : `lib/screens/game/game_screen.dart`, `lib/providers/progression_provider.dart`

**Problème** : `processGameEnd` est appelé à la fois au game over (ligne ~242) ET au quit via pause (ligne ~384). Le joueur reçoit de l'XP simplement en lançant une partie et en quittant.

**Impact** : Exploit XP — le joueur peut farm de l'XP en boucle sans jouer.

**Solution** : Ne pas appeler `processGameEnd` au quit, ou passer un flag `isQuit: true` qui donne 0 XP.

**Priorité** : P0

---

### BUG #5 — XP gonflé par objectifs déjà complétés (HAUT / P1)

**Fichier** : `lib/providers/progression_provider.dart`

**Problème** : La formule XP utilise `challengeState?.completedCount` qui est le **total du jour** (pas le delta de cette partie). Si 2 objectifs sont complétés à la partie 1, chaque partie suivante gagne +10 XP bonus (`completedObjectives × 5`) même sans compléter de nouvel objectif.

**Impact** : Inflation XP progressive au fil de la journée.

**Solution** : Sauvegarder `completedCount` avant `syncGameResult`, puis utiliser `newCount - oldCount` comme delta pour le calcul XP.

**Priorité** : P1

---

### BUG #6 — Objectif `parties` compte le quit (HAUT / P1)

**Fichiers** : `lib/core/services/challenge_service.dart`, `lib/providers/daily_challenge_provider.dart`

**Problème** : `syncGameResult` est appelé au quit → `applyGameResult` fait `current + 1` pour le type `parties`. Quitter sans jouer valide l'objectif "Jouer X parties".

**Impact** : Le joueur peut compléter l'objectif `parties` en faisant quit/relance.

**Solution** : Ne pas appeler `syncGameResult` au quit, ou ignorer le type `parties` quand `isQuit = true`.

**Priorité** : P1

---

## 1. 🎮 GAME ENGINE — Core Gameplay

### Architecture moteur

| Composant | Fichier | Rôle |
|-----------|---------|------|
| `GameEngine` | `lib/game/logic/game_engine.dart` | Orchestration : merge, spawn, game over |
| `MergeDetector` | `lib/game/logic/merge_detector.dart` | Détection paires + cible snap |
| `SpawnManager` | `lib/game/logic/spawn_manager.dart` | Spawn adaptatif + placement |
| `GameState` | `lib/game/models/game_state.dart` | État immutable + `copyWith` |
| `GameTuning` | `lib/core/config/game_tuning.dart` | Toutes les constantes centralisées |

### Mécaniques fondamentales

- **Board** : Canvas libre (drag & drop), pas une grille. Max 32 formes.
- **Merge** : Même `type` + même `color` + même `level` → `level + 1`. Wildcard = merge n'importe quel même niveau.
- **Scoring** : `2^newLevel × 10` points. Combos : `+0.5×` par chain (cap ×5.0).
- **Game Over** : Board plein (32) ET aucune paire mergeable.

### 🟢 Points forts

- **Difficulté adaptative** très bien calibrée :
  - Smart spawn 60% base → ajusté par merge rate (fenêtre glissante 20 coups)
  - Mode débutant (<20 merges) : duplique les paires existantes pour enseigner
  - Rescue system : force-spawn si 0 paires et board non plein
  - Board pressure : ≥25 formes → smart spawn capé à 50%
- **Constantes centralisées** dans `game_tuning.dart` — modifiable sans toucher la logique
- **Engine pur Dart** — zéro dépendance Flutter, testable unitairement

### 🟠 Problèmes identifiés

#### 1. `findMatchingShapes` ignore le level (MEDIUM)

**Fichier** : `lib/game/logic/merge_detector.dart`

`findMatchingShapes` matche type+color sans vérifier le level. Utilisé par le Radar joker → pourrait afficher des paires non mergeables.

**Solution** : Ajouter le check `level` ou créer `findMergeableShapes` distinct.

#### 2. `copyWith(lastMergedShapeId)` ne peut pas être reset à null (LOW) — ✅ FAIT

**Fichier** : `lib/game/models/game_state.dart`

~~`null` dans `copyWith` signifie "garder l'existant", donc impossible de reset `lastMergedShapeId`.~~

**Solution implémentée** : Sentinel `_unset` dans `copyWith` permet de distinguer "non fourni" de "explicitement null". `game_engine.dart` reset maintenant `lastMergedShapeId: null` sur fail-merge.

#### 3. Pas de cap sur le level des formes (LOW)

Les formes peuvent monter infiniment en level. Taille cappée à 82px, donc pas de problème visuel, mais le scoring `2^level × 10` pourrait exploser en théorie.

---

## 2. 🔁 BOUCLE DE RÉTENTION

### Systèmes en place

| Système | État | Évaluation |
|---------|------|-----------|
| Daily Streak | ✅ Complet | 8/10 — cycle 7j, scaling ×3, rotation premium |
| Daily Challenges | ✅ Complet | 8/10 — 3 objectifs/jour, difficulté adaptative |
| XP/Progression | ✅ Complet | 7/10 — level cap 50, curve `100 × n^1.4` |
| Leaderboard | ✅ Complet | 7/10 — scoreboard public, rate-limited |
| Tutorial | ✅ Complet | 9/10 — 11 étapes interactives |

### 🟠 Améliorations proposées

#### Streak sans jouer = problème (P1)

**Problème** : Le streak est basé sur la date de connexion, pas sur le gameplay. Un joueur peut ouvrir l'app, collecter la récompense, fermer — sans jamais jouer.

**Impact** : Les récompenses streak sont données "gratuitement", diminuant leur valeur perçue et la rétention active.

**Solution** : Exiger au moins 1 partie terminée pour valider le jour de streak. Modifier `StreakService._compute()` pour vérifier un flag `playedToday`.

#### XP trop généreuse en early game (P2)

**Problème** : Level 1 = 100 XP. Un score de 5000 + 50 merges + maxLevel 5 = 75 XP minimum. Le joueur monte très vite les premiers niveaux.

**Impact** : La progression semble rapide puis ralentit brutalement (level 20 = 4,600 XP). Rupture de rythme.

**Solution** : Augmenter le XP de base pour level 1-5 (ex: `150 × n^1.3`) pour lisser la courbe.

#### Pas de "missions hebdomadaires" (P2)

**Problème** : Seuls les objectifs journaliers existent. Pas d'engagement moyen-terme.

**Solution** : Ajouter des missions hebdomadaires (ex: "Atteins 50 000 points cumulés", "Fais 200 fusions") avec récompenses premium.

---

## 3. 🧠 ADDICTIVITÉ & FEEDBACK

### 🟢 Points forts

- **Merge effect** : 12 particules + anneau d'expansion, 600ms, couleur assortie
- **Score popup** : Animation float-up 1200ms, elastic scale. Labels combo : "COMBO ×2" → "LEGENDARY ×9"
- **Joker effects** : CustomPaint unique par type (600-950ms), feel premium
- **New record** : Étoiles rebondissantes + glow doré + confetti plein écran
- **Haptics progressifs** : Light (drag) → Medium (merge) → Heavy (combo ×3+). Togglable.

### 🟠 Améliorations

#### Audio : tous les jokers = même son (P1)

**Fichier** : `lib/core/config/audio_catalog.dart`

**Problème** : Les 6 types de jokers jouent tous `level_up.wav`. Le son game over = `merge_abort.wav`. Le son de tap bouton = `merge.mp3`.

**Impact** : Feedback audio pauvre. Le joueur ne peut pas distinguer les jokers à l'oreille. Game over non impactant.

**Solution** :
- Créer des sons distincts : `bomb_explode.mp3`, `wildcard_spawn.mp3`, `radar_scan.mp3`, `evolution_upgrade.mp3`, `megabomb_blast.mp3`
- Son game over dramatique dédié
- Son tap bouton distinct du merge

**Priorité** : P1

#### Pas de son distinct pour les high combos (P2)

Le combo ×3+ joue `level_up` au lieu de `merge`. C'est bien mais insuffisant — un combo ×5 devrait avoir un son plus impactant qu'un ×3.

**Solution** : Sons escaladant par palier de combo (×3, ×5, ×7+).

---

## 4. 🏆 PROGRESSION & NIVEAUX

### Système actuel

| Paramètre | Valeur |
|-----------|--------|
| Level max | 50 |
| XP curve | `floor(100 × level^1.4)` |
| XP sources | score/500 + merges×1 + maxLevel×3 + objectifs×5 |
| Streak bonus | ≥7 jours → ×1.1 |
| Level-up overlay | Auto-dismiss, animation dédiée |

### 🟠 Propositions

#### Récompenses par palier de niveau (P1)

**Problème** : Le level-up ne donne aucune récompense tangible. C'est juste un chiffre qui monte.

**Solution** : Récompenses par palier :
- Level 5 : 1 Radar gratuit
- Level 10 : Débloquer un thème visuel
- Level 15 : 1 Evolution gratuit
- Level 25 : Titre spécial dans leaderboard
- Level 50 : Badge "Master" + récompense exclusive

#### Pas d'unlockables (P2)

**Problème** : Rien à débloquer en progressant. Pas de thèmes, avatars, ou effets visuels.

**Solution** : Système de thèmes visuels (formes néon, rétro, nature) débloqués par niveau. Architecture modulaire dans `core/theme/`.

---

## 5. 🎁 JOKERS / POWER-UPS

### Inventaire

| Joker | Effet | Stock départ | Premium |
|-------|-------|-------------|---------|
| Bomb | Supprime forme + toutes matching (type+color) | 5 | Non |
| Wildcard | Spawn forme qui merge avec tout même-niveau | 5 | Non |
| Reducer | Réduit level -1 (level 1 = détruit) | 5 | Non |
| Radar | Surligne paires mergeables 5s | 3 | Oui |
| Evolution | Upgrade level+1 sans merge | 2 | Oui |
| MegaBomb | Supprime toutes les formes du même level | 2 | Oui |

### Suggestion Engine

Cascade de priorité intelligente :
1. **Critique** (≥90% plein, ≤2 paires) : MegaBomb → Bomb → Reducer
2. **Haut** (≥75% plein) : MegaBomb → Bomb → Wildcard → Reducer
3. **Moyen/struggling** (merge rate <30%) : Radar → Wildcard
4. **Moyen/cluster** (≥60% plein, ≥4 même-level) : MegaBomb
5. **Bas/lonely** (forme isolée haut-level) : Evolution → Reducer

Cooldown 8 coups entre suggestions. Gate ≥50% board fill.

### 🟠 Problèmes

#### 22 jokers gratuits au départ = trop généreux (P1)

**Problème** : 5+5+5+3+2+2 = 22 jokers. Un nouveau joueur n'a jamais besoin d'en acheter pendant longtemps.

**Impact** : Monétisation retardée. Le joueur s'habitue à avoir des jokers gratuits.

**Solution** : Réduire à 3+3+3+1+1+1 = 12 total. Ou : donner les basiques (B/W/R) mais pas les premium au départ.

#### Pas de "recharge gratuite" incitant le jeu (P2)

**Problème** : Les jokers se gagnent uniquement via streak, challenges, ou achat.

**Solution** : Donner 1 joker gratuit (aléatoire basique) pour chaque partie complétée. Incite à jouer plus.

---

## 6. 💀 GAME OVER & REVIVE

### Système actuel

- **Game Over** : Board plein + 0 paires. Confetti si new record.
- **Score count-up** : Animation du score, badge trophy/skull.
- **Revive** : Non implémenté.

### 🔴 Propositions critiques

#### Pas de système de revive (P0)

**Problème** : Le game over est final. Aucune seconde chance. C'est LE moment où un joueur accepterait de regarder une pub.

**Impact** : Perte massive de revenus publicitaires. Frustration joueur → désinstallation.

**Solution** :
```
Game Over → "Seconde chance ?" → [Regarder une pub] / [Abandonner]
Effets du revive : supprime 5 formes aléatoires de bas level
Limité à 1 revive par partie
```

**Priorité** : P0

---

## 7. 💰 MONÉTISATION

### État actuel

| Type | Implémentation | Revenus estimés |
|------|---------------|----------------|
| Banner ads | Code présent, pas affiché dans le game/hub ? | Faibles |
| Rewarded ads | Hub button → JokerChoiceDialog | Modérés |
| IAP Packs | 3 packs (€1.99/€4.99/€9.99) + No-ads | Limités |
| Interstitiels | **Absent** | $0 |

### 🔴 Problèmes critiques

#### Pas d'interstitiels entre parties (P0)

**Problème** : Zéro interstitiel. Après un game over, le joueur retourne au hub sans pub. C'est le placement #1 en revenus pour les jeux casual.

**Solution** :
- Afficher un interstitiel après chaque 3ème game over
- Respecter le `noAdsPurchased` flag
- Fréquence configurable dans `game_tuning.dart`

#### Catalogue IAP trop limité (P1)

**Problème** : 3 packs consommables + 1 non-consommable. Pas d'abonnement, pas de battle pass.

**Solution** :
- **Battle Pass mensuel** (€2.99/mois) : missions exclusives, récompenses de jokers doublées, thème premium
- **Pack "Revive ×10"** (€0.99) : 10 revives stockables
- **Pack hebdomadaire "Boost"** (€0.49) : 3 jokers + 1 radar

#### Pas de vérification côté serveur des achats (P1)

**Problème** : `iap_service.dart` — pas de receipt validation via Cloud Function. Les achats sont trustés côté client.

**Solution** : Cloud Function qui valide le receipt Apple/Google avant de créditer les jokers.

---

## 8. ⚙️ PERFORMANCE

### Analyse

| Zone | FPS attendu | Risque |
|------|------------|--------|
| Hub (3 painters animés) | 60fps | Faible — `RepaintBoundary` partout |
| Game board (32 formes) | 60fps | ✅ Résolu — drag isolé via `ValueNotifier` |
| Merge effects (10+ simultanés) | 50-60fps | ✅ Résolu — cap à 8 effets concurrents |
| Game over confetti | 60fps | Faible — animation simple |

### ✅ Optimisations réalisées

#### Board rebuilds complets (P2) — ✅ FAIT

**Fichier** : `lib/screens/game/widgets/game_board.dart`

~~Chaque `setState` reconstruit tout le `Stack` de 32 formes.~~

**Solution implémentée** : `_dragOffset` converti en `ValueNotifier<Offset?>`. Chaque forme est wrappée dans un `ValueListenableBuilder` qui rebuild uniquement son `Positioned` quand la valeur change. `onPanUpdate` met à jour le notifier sans `setState` → seul le `Positioned` de la forme draguée se reconstruit à 60fps. Le subtree coûteux (`GestureDetector` + `ShapeWidget`) est préservé via `child:`.

#### `_BoardBackgroundPainter` recalcule 50 étoiles chaque frame (P2) — ✅ FAIT

~~Génère 50 étoiles avec `Random(42)` à chaque paint.~~

**Solution implémentée** : Cache `static final List<_Star> _stars` généré une seule fois. Painter rendu `const`. Ajout d'un `RepaintBoundary` autour du `Stack` de formes pour isoler les couches GPU.

#### `_effects` list sans limite (LOW) — ✅ FAIT

~~Pendant des combos rapides, 10+ effets visuels simultanés.~~

**Solution implémentée** : Constante `_maxConcurrentEffects = 8` ; éviction FIFO du plus ancien dans `_addMergeEffect` et `_addJokerEffect`.

---

## 9. 📊 ANALYTICS — Événements manquants

### Actuellement tracké

| Événement | Paramètres |
|-----------|-----------|
| `game_start` | aucun |
| `game_over` | score, max_level, merge_count, shapes_on_board |
| `joker_used` | type |
| `level_reached` | ~~level~~ (défini mais jamais appelé!) |
| `challenge_completed` | challenge_id |
| `iap_attempt` | product_id |
| `iap_success` | product_id |
| `streak_day` | streak_count |

### 🔴 Événements manquants critiques (P0)

| Événement | Pourquoi |
|-----------|---------|
| `session_duration` | Mesurer l'engagement. KPI #1 |
| `ad_watched` / `ad_failed` | Mesurer les revenus pub |
| `first_merge` | Funnel onboarding |
| `first_joker_used` | Funnel onboarding |
| `tutorial_step_completed(step)` | Détecter abandon tuto |
| `tutorial_skipped` | Taux de skip |
| `streak_lost` | Mesurer la rétention |
| `revive_watched` (quand implémenté) | Conversion pub |

### 🟠 Événements manquants importants (P1)

| Événement | Pourquoi |
|-----------|---------|
| `combo_achieved(multiplier)` | Tuning difficulté |
| `daily_challenge_progress(done/total)` | Engagement challenges |
| `streak_milestone(day)` | Rétention long-terme |
| `iap_revenue(product, price, currency)` | Attribution revenus |
| `board_state_on_gameover(level_distribution)` | Tuning spawn |
| `joker_suggestion_shown(type)` | Efficacité suggestions |
| `joker_suggestion_followed(type)` | Conversion suggestions |

---

## 10. 🔒 SÉCURITÉ & ANTI-CHEAT

### Firestore Rules — Bonnes

- **Players** : Read/write owner-only
- **Leaderboard** : Public read. Write : auth + uid match + score 0-999,999 + displayName ≤50 chars + rate limit 1 write/5s
- **Daily challenges** : Owner-only subcollection

### 🟠 Faiblesses

| Risque | Sévérité | Mitigation |
|--------|---------|-----------|
| Score client-side | Moyen | Cap 999,999 + rate limit |
| Jokers client-side | Moyen | Pas de compétition directe |
| Pas de receipt validation IAP | Haut | Ajouter Cloud Function |
| Streak manipulable (date device) | Bas | Utiliser `FieldValue.serverTimestamp()` |

### Solution long-terme (P2)

Cloud Function `validateScore(uid, score, mergeCount, gameDuration)` :
- Vérifier plausibilité : score / mergeCount ratio raisonnable
- Vérifier durée : minimum 30s pour >1000 points
- Rate limit : max 1 score/minute

---

## 11. 🛑 MODE RED TEAM — Pourquoi je désinstalle ?

### Motifs de désinstallation probables

| # | Raison | Sévérité | Solution |
|---|--------|---------|---------|
| 1 | **Game over brutal sans seconde chance** | 🔴 | Système de revive via pub |
| 2 | **Rien de nouveau après quelques jours** | 🔴 | Événements temporaires, missions hebdo |
| 3 | **Le jeu ressemble à tous les autres 2048** | 🟠 | Modes de jeu spéciaux (chrono, endless) |
| 4 | **Pas de raison de progresser** | 🟠 | Débloquables (thèmes, effets) |
| 5 | **Sessions trop longues ou trop courtes** | 🟠 | Mode 3 minutes "Quick Play" |
| 6 | **Notifications agaçantes** | 🟢 | Supprimé ✅ |
| 7 | **Pubs intrusives** | 🟢 | Que des rewarded — bien |

### Moments de rage quit

1. **Board plein, 0 paires, 0 jokers** → Aucune issue possible. Mettre le revive ici.
2. **Forme high-level isolée sans paire** → Le suggestion engine propose Evolution/Reducer, c'est bien.
3. **Combo interrompu par un mauvais spawn** → Frustrant mais acceptable (adaptive spawn aide).

---

## 12. 🎯 PLAN D'ACTION PRIORISÉ

### P0 — CRITIQUES (faire immédiatement)

| # | Action | Fichier(s) | Effort |
|---|--------|-----------|--------|
| 1 | Remplacer iOS ad unit IDs test | `ad_units.dart` | 5 min |
| 2 | Implémenter revive via pub au game over | `game_over_overlay.dart`, `game_state_provider.dart` | 2-3h |
| 3 | Ajouter interstitiels entre parties | `ads_service.dart`, `game_screen.dart` | 1-2h |
| 4 | Ajouter analytics critiques (session, ads, funnel) | `analytics_service.dart` + callers | 2h |

### P1 — IMPORTANTS (cette semaine)

| # | Action | Fichier(s) | Effort |
|---|--------|-----------|--------|
| 5 | Appeler `logLevelReached` dans progression | `progression_service.dart` | 10 min |
| 6 | Sons distincts par joker | `audio_catalog.dart` + assets | 2h |
| 7 | Streak = exiger 1 partie jouée | `streak_service.dart` | 1h |
| 8 | Réduire jokers de départ (22→12) | `game_tuning.dart` | 10 min |
| 9 | Fix `findMatchingShapes` radar level check | `merge_detector.dart` | 30 min |
| 10 | Récompenses de level-up tangibles | `progression_service.dart` | 2h |

### P2 — AMÉLIORATIONS (ce mois)

| # | Action | Effort |
|---|--------|--------|
| 11 | Missions hebdomadaires | 4-6h |
| 12 | Battle Pass mensuel | 8-12h |
| 13 | Système de thèmes visuels débloquables | 6-8h |
| 14 | Mode Quick Play (chrono 3 min) | 4h |
| 15 | Optimisation board rebuilds | 3h |
| 16 | Cloud Function validation score + IAP receipt | 4h |
| 17 | Sons escaladant par combo | 1h |
| 18 | Événements temporaires saisonniers | 8-12h |

---

## 📊 KPIs À SUIVRE

| KPI | Cible | Comment mesurer |
|-----|-------|----------------|
| Rétention J1 | >40% | Firebase Analytics cohort |
| Rétention J7 | >15% | Firebase Analytics cohort |
| Durée session moyenne | 5-8 min | `session_duration` event |
| Parties/session | 2-3 | `game_start` / sessions |
| Taux complétion tuto | >80% | `tutorial_step_completed` funnel |
| Revive conversion | >30% | `revive_watched` / `game_over` |
| Streak J7+ | >20% joueurs | `streak_day(≥7)` / DAU |
| ARPDAU | >€0.03 | Revenus / DAU |
| Crash rate | <1% | Firebase Crashlytics |

---

## 📁 FICHIERS CLÉS AUDITÉS

| Fichier | Verdict |
|---------|---------|
| `lib/game/logic/game_engine.dart` | ✅ Excellent |
| `lib/game/logic/spawn_manager.dart` | ✅ Très bon (adaptive difficulty) |
| `lib/game/logic/merge_detector.dart` | ⚠️ `findMatchingShapes` ignore level |
| `lib/game/logic/joker_suggestion_engine.dart` | ✅ Excellent |
| `lib/core/config/game_tuning.dart` | ✅ Parfait — tout centralisé |
| `lib/game/models/game_state.dart` | ⚠️ Minor `copyWith` null issue |
| `lib/core/services/streak_service.dart` | ⚠️ Pas de retry Firestore |
| `lib/core/services/iap_service.dart` | ⚠️ Pas de receipt validation |
| `lib/core/services/ads_service.dart` | ⚠️ Pas de no-ads gate interne |
| `lib/core/services/analytics_service.dart` | 🔴 Événements critiques manquants |
| `lib/core/config/audio_catalog.dart` | ⚠️ Même son pour tous les jokers |
| `lib/core/constants/ad_units.dart` | 🔴 iOS = test IDs |
| `lib/screens/game/widgets/game_board.dart` | ⚠️ Full rebuild par setState |
| `lib/screens/game/overlays/game_over_overlay.dart` | ⚠️ Pas de revive |
| `lib/screens/game/widgets/coach_overlay.dart` | ✅ Tuto interactif 11 étapes |

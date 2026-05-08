# Audit — Gestion d'État Multi-Mode (Firebase vs Guest)

## Contexte

Jeu mobile 2048-shape-merge avec deux modes :
- **Guest** : données stockées en SharedPreferences (local)
- **Connecté** : données stockées dans Firestore (Firebase Auth)

---

## 🔴 CRITIQUE

### C1 — Sign-out perd TOUTE la progression guest

**Problème**
À la déconnexion, `app.dart` écrase l'état avec `bestScore: 0, jokers: JokerInventory.initial()`.
Le localStorage a DÉJÀ été vidé au moment du sign-in (`_resetLocalToDefaults`).
Résultat : le joueur voit un profil vierge.

`syncToLocalOnSignOut()` existe dans `streak_service.dart` mais **n'est jamais appelée**.

**Impact utilisateur**
Joueur connecté → se déconnecte → perd visibilité de son best score, XP, level, streak, jokers en mode guest. Il pense avoir tout perdu.

**Impact technique**
- `bestScore`, `level`, `XP`, `streak`, `gamesPlayed`, `totalMerges` → tous à zéro
- Jokers → remis aux valeurs initiales
- Seul `noAdsPurchased` survit (pas reset)

**Solution**
Avant de passer en guest, copier les données Firestore vers localStorage :

```dart
// app.dart — dans le bloc sign-out
} else {
  final player = prev?.valueOrNull != null
      ? await ref.read(firestoreServiceProvider).getPlayer(prevUser!.uid)
      : null;
  if (player != null) {
    await storage.setBestScore(player.bestScore);
    await storage.saveJokerInventory(player.jokerInventory);
    await storage.setPlayerLevel(player.level);
    await storage.setCurrentXP(player.currentXP);
    await storage.setTotalXP(player.totalXP);
    await streakService.syncToLocalOnSignOut(player: player, storage: storage);
  }
  notifier.clearSignedIn();
  notifier.loadSavedState(
    bestScore: player?.bestScore ?? 0,
    jokers: player?.jokerInventory ?? const JokerInventory.initial(),
  );
}
```

**Priorité** P0

---

### C2 — Sign-in ne merge pas bestScore, XP, level, streak, stats

**Problème**
Le `mergeMax` ne couvre que les **jokers**. Tous les autres champs sont écrasés par Firestore sans fusion :

| Champ | Merge ? |
|---|---|
| jokers | ✅ `mergeMax` |
| bestScore | ❌ Firestore écrase |
| level / XP | ❌ Firestore écrase |
| streak | ✅ via `migrateAndRefresh` |
| gamesPlayed / totalMerges | ❌ Firestore écrase |

**Impact utilisateur**
Guest joue 50 parties, atteint bestScore 8000, level 5 → se connecte sur un compte neuf → bestScore=0, level=1.

**Impact technique**
`app.dart` : `loadSavedState(bestScore: player.bestScore, jokers: merged)` ignore le bestScore local.

**Solution**
```dart
final localBest = notifier.bestScore;
final serverBest = player?.bestScore ?? 0;
final mergedBest = math.max(localBest, serverBest);

final localLevel = storage.playerLevel;
final serverLevel = player?.level ?? 1;
// ... same max pattern for level, XP, gamesPlayed, totalMerges
```

**Priorité** P0

---

### C3 — Double init — splash + auth listener race condition

**Problème**
`splash_screen.dart` appelle `setSignedIn()` + `loadSavedState()`. Quelques ms plus tard, le listener dans `app.dart` se déclenche et refait la même chose + déclenche `playerProvider.future`.

**Impact utilisateur**
Jokers chargés 2 fois, potentiel flash UI. Pas de corruption mais du gaspillage réseau (2 lectures Firestore).

**Impact technique**
Race : si splash charge les jokers locaux, puis l'auth listener charge les jokers Firestore, le `mergeMax` dans l'auth listener voit les jokers locaux déjà écrasés par ceux du splash.

**Solution**
Splash ne fait que l'init storage + animations. Tout le chargement d'état est délégué au listener de `app.dart` uniquement.

**Priorité** P1

---

## 🟠 IMPORTANT

### I1 — `_withRetry` manquant sur 5 méthodes Firestore

**Problème**
Dans `firestore_service.dart`, ces méthodes n'ont **pas** de `_withRetry` :

| Méthode | Retry ? |
|---|---|
| `savePlayer()` | ❌ |
| `updateXP()` | ❌ |
| `updateStreak()` | ❌ |
| `updateRewardClaimedDate()` | ❌ |
| `updateNoAdsPurchased()` | ❌ |
| `updateProfile()` | ❌ |
| `saveDailyChallenges()` | ❌ |
| `incrementPlayerStats()` | ✅ |
| `updateBestScore()` | ✅ |
| `updateJokerInventory()` | ✅ |

**Impact utilisateur**
XP, streak, no-ads — un timeout réseau = perte silencieuse.

**Priorité** P1

---

### I2 — Pas de queue offline pour les écritures Firestore

**Problème**
Toutes les écritures Firestore sont des appels directs. Si le réseau tombe en pleine partie, les sauvegardes de score, XP, jokers sont perdues.

Firestore SDK a un cache offline natif qui buffer les écritures — MAIS le `_withRetry` catch les erreurs et les ignore après 3 tentatives. Si l'erreur est un timeout, l'écriture en cache peut être annulée par le catch.

**Solution**
Laisser Firestore SDK gérer l'offline nativement. Ne pas catch + swallow mais simplement await et laisser le SDK faire.

**Priorité** P1

---

### I3 — Anti-cheat faible en mode guest

**Problème**
Les jokers locaux utilisent un `IntegrityGuard` (HMAC) — bien. MAIS :
- `bestScore` → simple `int` en SharedPreferences → modifiable
- `playerLevel`, `currentXP`, `totalXP` → simples ints → modifiables
- `gamesPlayed`, `totalMerges` → simples ints → modifiables

**Red Team**
Un joueur peut éditer ses SharedPreferences (appareil rooté) avant de se connecter. Le `mergeMax` prendra le score gonflé et le poussera vers Firestore.

**Solution**
Appliquer `IntegrityGuard` à tous les champs numériques critiques, ou valider côté serveur (Cloud Function `submitScore` fait déjà un clamp à 999999).

**Priorité** P2

---

## 🟢 AMÉLIORATION

### A1 — `noAdsPurchased` persiste après sign-out

**Problème**
`_resetLocalToDefaults()` ne reset pas `noAdsPurchased`. Si un joueur A achète no-ads, se déconnecte, le joueur B en guest voit aussi no-ads sur le même appareil.

Probablement intentionnel (achat lié à l'appareil), mais à documenter.

**Priorité** P2

---

### A2 — Pas de feedback UX pendant la sync

**Problème**
Le passage guest → connecté charge les données Firestore en background (`.then()`). Pas de spinner. Si Firestore est lent (2-3s), le joueur voit brièvement ses jokers guest puis un "saut" vers les jokers serveur.

**Priorité** P2

---

## Architecture Cible

```
┌─────────────────────────────────────────────┐
│               Source de Vérité               │
│                                              │
│  Connecté  → Firestore (serveur fait loi)    │
│  Guest     → SharedPreferences (local)       │
│                                              │
│  Sign-in   → mergeMax sur TOUS les champs    │
│              puis push merged → Firestore    │
│              puis reset localStorage         │
│                                              │
│  Sign-out  → copier Firestore → localStorage │
│              puis passer en mode guest       │
└─────────────────────────────────────────────┘
```

---

## Tableau des données par champ

| Champ | Guest | Connecté | Sign-In Merge | Sign-Out |
|---|---|---|---|---|
| bestScore | localStorage | Firestore + leaderboard | max(local, server) | server→local |
| jokerInventory | localStorage (HMAC) | Firestore | mergeMax | server→local |
| level/currentXP/totalXP | localStorage | Firestore | max | server→local |
| streak | localStorage | Firestore | migrateAndRefresh | syncToLocalOnSignOut |
| gamesPlayed/totalMerges | localStorage | Firestore (increment) | max(local, server) | server→local |
| dailyChallenges | localStorage JSON | Firestore subcollection | regenerated | cleared |
| noAdsPurchased | localStorage | Firestore | OR (true if either) | NOT reset |
| gameCheckpoint | localStorage only | localStorage only | cleared | cleared |

---

## Plan d'action

| # | Item | Priorité | Fichiers | Statut |
|---|---|---|---|---|
| C1 | Sync server→local au sign-out | P0 | `app.dart` | ⏭️ Intentionnel (profil vierge voulu) |
| C2 | Merge bestScore/XP/level/stats au sign-in | P0 | `app.dart` | ✅ Done |
| C3 | Supprimer double init splash vs auth | P1 | `splash_screen.dart`, `app.dart` | ✅ Done |
| I1 | Ajouter `_withRetry` aux méthodes Firestore | P1 | `firestore_service.dart` | ✅ Done |
| I2 | Revoir stratégie offline Firestore | P1 | `firestore_service.dart` | ✅ OK (SDK gère nativement) |
| I3 | IntegrityGuard sur bestScore/XP | P2 | `local_storage_service.dart` | ⏳ Backlog |
| A1 | Documenter comportement noAds | P2 | — | ⏳ Backlog |
| A2 | Spinner/feedback pendant sync | P2 | `app.dart`, UI | ⏳ Backlog |

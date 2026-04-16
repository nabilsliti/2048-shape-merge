# Audit Streak — Plan d'implémentation complet

> Date : 15 avril 2026
> Référence : Candy Crush, Duolingo, Clash Royale, Monopoly GO
> Statut : VALIDÉ — prêt à implémenter

---

## Économie validée

### Jokers existants

| Type | Catégorie | Départ | Pack Star (1,99€) | Pack Comet (4,99€) | Pack Diamond (9,99€) |
|------|-----------|--------|--------------------|--------------------|----------------------|
| 💣 Bomb | Classique | 5 | ~2 | ~5 | ~13 |
| 🃏 Wildcard | Classique | 5 | ~2 | ~5 | ~13 |
| 📉 Reducer | Classique | 5 | ~1 | ~5 | ~14 |
| 🎯 Radar | **Premium** | 3 | 1 | 3 | 8 |
| ✨ Evolution | **Premium** | 2 | 0 | 2 | 5 |
| 💣 MegaBomb | **Premium** | 2 | 0 | 2 | 5 |

### Cycle hebdomadaire streak (classiques uniquement, scaling par semaine)

| Jour | S1 | S2 | S3+ (cap) |
|------|----|----|-----------|
| J1 | 💣 Bomb ×1 | ×2 | ×3 |
| J2 | 📉 Reducer ×1 | ×2 | ×3 |
| J3 | 🃏 Wildcard ×1 | ×2 | ×3 |
| J4 | 💣 Bomb ×2 | ×3 | ×4 |
| J5 | 🃏 Wildcard ×2 | ×3 | ×4 |
| J6 | 📉 Reducer ×2 | ×3 | ×4 |
| **J7** | **🎯 Radar ×1** | **✨ Evolution ×1** | **💣 MegaBomb ×1** |

Règles :
- J1→J6 : classiques uniquement, scaling ×1/×2/×3 (cap semaine 3+)
- J7 : **1 seul premium**, rotation Radar → Evolution → MegaBomb par semaine
- Premium J7 : **toujours ×1, jamais de scaling** (échantillon, pas stock)

### Milestones (bonus EN PLUS du reward quotidien)

| Palier | Bonus | Fréquence réelle |
|--------|-------|------------------|
| **J14** | ✨ Evolution ×1 | 1× en 2 semaines |
| **J30** | 💣 MegaBomb ×1 + 🃏 Wildcard ×3 | 1× par mois |
| **J100** | 💣 MegaBomb ×1 + ✨ Evolution ×1 + 🎯 Radar ×1 | Quasi personne |

### Impact économique (30 jours de streak parfait)

- ~20 classiques (via scaling)
- ~4 premium (J7×4 + milestone J14 + J30)
- Équivalent < 1 pack Comet (4,99€)
- ✅ Ne cannibalise PAS les IAP

---

## P0 — Critique

### 1. Bouton Collect absent quand le streak est cassé

**Problème** : Quand `streakReset = true`, l'overlay affiche un bandeau d'alerte
mais PAS la grille de jours ni le bouton "Collecter". Or `_compute()` produit un
`reward = rewardForIndex(0)` (1 bomb) même en reset → la récompense J1 existe
mais est impossible à collecter.

**Fichier** : `lib/screens/hub/widgets/streak_popup.dart`

**Cause** : Le `if (!result.streakReset)` exclut `_buildWeekRow` et `_buildButton`
quand le streak est cassé.

**Fix** :
- Toujours afficher `_buildWeekRow(todaySlot)` et `_buildButton` (grille + bouton)
- En mode reset, la grille affiche seulement J1 coché (les 6 autres verrouillés)
- Le bandeau reset reste visible AU-DESSUS de la grille comme info contextuelle
- Le joueur clique "Collecter" pour récupérer sa récompense J1 de redémarrage

**Résultat attendu** :
```
┌────────────────────────────┐
│    🔥 Jour 1               │
│  Ton streak s'est interrompu│
│                             │
│  ⚠️ Streak perdu            │
│  Reviens chaque jour pour...│
│                             │
│  [J1✓] [J2🔒] ... [J7🔒]  │
│                             │
│  [ Collecter 💣 +1 ]       │
└────────────────────────────┘
```

---

### 2. Après J7 : numéro de semaine + progression des récompenses

**Problème** : Le cycle fait `% 7` silencieusement. Le joueur ne sait pas qu'il
recommence une nouvelle semaine. Pas de sentiment de progression après J7.

**Fichiers** :
- `lib/core/models/player_streak.dart` — ajouter `weekNumber` getter + rewards scaling
- `lib/screens/hub/widgets/streak_popup.dart` — afficher "Semaine N"
- `lib/core/services/streak_service.dart` — pas de changement logique (le cycle roule déjà)

**Fix** :

a) **Ajouter un getter `weekNumber`** dans `PlayerStreak` :
```dart
int get weekNumber => ((currentStreak - 1) ~/ rewardCycleLength) + 1;
```

b) **Faire monter les récompenses par semaine** via un multiplicateur :
```dart
static (JokerType, int) rewardForStreak(int currentStreak) {
  final weekMultiplier = ((currentStreak - 1) ~/ rewardCycleLength) + 1;
  final dayIndex = (currentStreak - 1) % rewardCycleLength;
  final (type, baseAmount) = _baseRewards[dayIndex];
  // Semaine 1 = ×1, Semaine 2 = ×1, J7 slots = ×2, etc.
  // Plafonner à ×3 pour ne pas casser l'économie
  final multiplier = weekMultiplier.clamp(1, 3);
  return (type, baseAmount * multiplier);
}
```

c) **Afficher "Semaine N"** dans le header de l'overlay :
```
🔥 Jour 15 — Semaine 3
Connexion du jour validée !
```

d) **Afficher le nom du jour actuel** dans la grille : "L, M, M, J, V, S, D"
au lieu de "J1, J2, J3..." (slot index → jour de la semaine correspondant basé
sur le jour de début du cycle, ou simplement les jours de la semaine actuelle).

**Alternative simplifiée** : garder "J1...J7" mais ajouter "Semaine N" dans le header.
Plus simple et moins confus si le cycle ne s'aligne pas sur lundi.

---

## P1 — Important

### 3. Milestones à J7, J14, J30, J100

**Problème** : Rien de spécial ne se passe aux paliers. Le joueur n'a aucune
raison de viser J30 plutôt que J8.

**Fichiers** :
- `lib/core/models/player_streak.dart` — ajouter table de milestones
- `lib/core/services/streak_service.dart` — détecter les milestones dans `_compute()`
- `lib/screens/hub/widgets/streak_popup.dart` — afficher le milestone bonus

**Fix** :

a) **Table de milestones** dans `PlayerStreak` :
```dart
static const Map<int, (JokerType, int)> milestoneRewards = {
  7:   (JokerType.megaBomb, 1),
  14:  (JokerType.megaBomb, 2),
  30:  (JokerType.megaBomb, 3),
  60:  (JokerType.megaBomb, 4),
  100: (JokerType.megaBomb, 5),
};

static (JokerType, int)? milestoneFor(int streak) => milestoneRewards[streak];
```

b) **Ajouter `milestoneReward`** dans `StreakCheckResult` :
```dart
final (JokerType, int)? milestoneReward; // bonus en plus du reward quotidien
```

c) **Détecter dans `_compute()`** :
```dart
final milestone = PlayerStreak.milestoneFor(newStreak);
```

d) **UI** : Si milestone != null, afficher un bandeau doré spécial :
```
🏆 Milestone J30 !  +3 💣 MEGA
```
Le bouton collect donne reward quotidien + milestone bonus en une seule action.

---

### 4. Signed→Guest : sync inverse du streak

**Problème** : Quand le joueur se déconnecte, le streak Firestore n'est PAS copié
vers localStorage. Le joueur retrouve un vieux streak local (potentiellement
inférieur ou incohérent).

**Fichier** : `lib/core/services/streak_service.dart`

**Fix** : Ajouter une méthode `syncToLocalOnSignOut()` :
```dart
Future<void> syncToLocalOnSignOut({
  required Player player,
  required LocalStorageService storage,
}) async {
  final streak = PlayerStreak(
    currentStreak: player.currentStreak,
    longestStreak: player.longestStreak,
    lastLoginDate: player.lastLoginDate,
    nextRewardIndex: player.nextRewardIndex,
  );
  await _saveToStorage(streak, storage);
  // Also sync rewardClaimedDate
  if (player.rewardClaimedDate != null) {
    await storage.setRewardClaimedDate(player.rewardClaimedDate!);
  }
}
```

**Appeler depuis** `app.dart` dans le bloc `else` (Going to guest mode) :
```dart
// Sync streak from Firestore → localStorage before going guest
if (prevUser != null) {
  final player = await ref.read(playerProvider.future); // still has old data
  if (player != null) {
    final storage = await ref.read(localStorageProvider.future);
    await const StreakService().syncToLocalOnSignOut(player: player, storage: storage);
  }
}
```

---

### 5. Badge "0🔥" quand aucun streak

**Problème** : `StreakFlameButton` affiche "0🔥" si le joueur n'a jamais joué.

**Fichier** : `lib/screens/hub/widgets/streak_flame_button.dart`

**Fix** : Afficher "1🔥" minimum, ou masquer le badge entièrement si count == 0 :
```dart
if (widget.streakCount > 0)
  // ... badge avec '${widget.streakCount}🔥'
```

**Choix recommandé** : Masquer le badge si 0 (plus clean), afficher dès 1.

---

### 6. Afficher `longestStreak` dans le profil

**Problème** : `longestStreak` est persisté (Firestore + localStorage) mais
jamais affiché.

**Fichiers** :
- `lib/screens/profile/profile_screen.dart` — ajouter un widget stat
- Utiliser `player?.longestStreak ?? localStorage?.longestStreak ?? 0`

**UI** : Dans la section stats du profil :
```
🔥 Meilleure série : 42 jours
```

---

## P2 — Améliorations (optionnelles, fort impact rétention)

### 7. Streak Freeze (protection)

**Concept** : Le joueur peut acheter un "bouclier" qui protège son streak si
il manque UN jour. Maximum 1 freeze actif à la fois.

**Modèle de données** :
```dart
// Dans PlayerStreak ou Player :
final int streakFreezeCount;    // Nombre de freezes disponibles
final String? freezeUsedDate;   // Date où un freeze a été auto-consommé
```

**Logique dans `_compute()`** :
```dart
if (current.lastLoginDate != yesterday && current.lastLoginDate != today) {
  // Streak cassé... mais si freeze disponible ?
  if (current.streakFreezeCount > 0) {
    // Auto-consume freeze : streak maintenu, pas de reset
    newStreak = current.currentStreak + 1;
    freezeConsumed = true;
  } else {
    // Reset normal
    newStreak = 1;
    reset = true;
  }
}
```

**Obtention du freeze** :
- Achat en shop avec gems (ex: 50 gems = 1 freeze)
- Récompense milestone J30
- Récompense pub (voir point 8)

**UI** : Icône bouclier dans l'overlay + dans le profil.

---

### 8. Streak Recovery via pub

**Concept** : Quand le streak est cassé, proposer : "Regarde une pub pour
récupérer ton streak !" (une seule chance, dans les 24h suivantes).

**Condition** : Seulement si le streak perdu était ≥ 3 jours (sinon pas
d'intérêt émotionnel).

**Modèle** :
```dart
final bool recoveryAvailable; // true si on vient de reset un streak ≥ 3
```

**UI dans le popup reset** :
```
⚠️ Streak perdu (était 15 jours)
[ 🎬 Regarder une pub pour récupérer ] ← rewarded ad
          ou
[ Recommencer à J1 ]
```

**Après la pub** : remettre le streak à la valeur précédente.

---

### 9. Notification personnalisée

**Problème** : Le texte notif est générique "Votre série est en danger !".

**Fix dans** `notification_service.dart` :
```dart
// Lire le streak actuel avant de schedule
final streak = storage.currentStreak;
final title = streak > 7
    ? 'Votre série de $streak jours est en danger !'
    : 'Votre série est en danger !';
```

**Fichier** : `lib/core/services/notification_service.dart` + `notification_config.dart`

---

### 10. Partage social

**Concept** : Bouton "Partager" dans l'overlay quand streak ≥ 7.

**UI** :
```
🔥 Jour 30 — Semaine 5
[ Collecter ] [ 📤 Partager ]
```

**Implémentation** : `Share.share('J'ai un streak de 30 jours sur Shape Merge ! 🔥')`
via le package `share_plus`.

---

## Récapitulatif par fichier

| Fichier | Changements |
|---|---|
| `lib/core/models/player_streak.dart` | + `weekNumber` getter, + milestones table, + `rewardForStreak()` avec scaling, + `streakFreezeCount` (P2) |
| `lib/core/services/streak_service.dart` | + `syncToLocalOnSignOut()`, + milestone detection dans `_compute()`, + freeze logic (P2) |
| `lib/providers/streak_provider.dart` | + appel milestone reward, + freeze claim |
| `lib/screens/hub/widgets/streak_popup.dart` | + afficher grille+bouton même en reset, + "Semaine N" header, + milestone banner, + recovery ad (P2) |
| `lib/screens/hub/widgets/streak_flame_button.dart` | + masquer badge si 0 |
| `lib/screens/hub/main_hub_screen.dart` | aucun changement |
| `lib/screens/profile/profile_screen.dart` | + afficher longestStreak |
| `lib/app.dart` | + appel `syncToLocalOnSignOut()` au sign-out |
| `lib/core/services/notification_service.dart` | + texte personnalisé avec streak count |
| `lib/l10n/app_fr.arb` + `app_en.arb` | + clés : streakWeek, streakMilestone, streakFreeze, streakRecovery |
| `test/services/streak_service_test.dart` | + tests milestones, freeze, sync inverse, scaling rewards |

## Ordre d'implémentation recommandé

1. Fix **bouton collect en mode reset** (P0, 5 min)
2. Fix **badge 0🔥** (P1, 2 min)
3. Fix **signed→guest sync** (P1, 15 min)
4. Ajouter **weekNumber + header "Semaine N"** (P0, 20 min)
5. Ajouter **scaling rewards par semaine** (P0, 15 min)
6. Ajouter **milestones J7/J14/J30** (P1, 30 min)
7. Afficher **longestStreak dans profil** (P1, 10 min)
8. **Notification personnalisée** (P2, 10 min)
9. **Streak freeze** (P2, 1-2h)
10. **Streak recovery via pub** (P2, 1-2h)
11. **Partage social** (P2, 30 min)

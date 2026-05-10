const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { google } = require("googleapis");
const { logger } = require("firebase-functions");

// Runtime: Node.js 22
initializeApp();
const db = getFirestore();

// ── Pack catalog (must mirror shop_catalog.dart) ──────────────
const PACK_CONTENTS = {
  pack_star:    { bomb: 5, wildcard: 5, reducer: 5, radar: 2, evolution: 0, megaBomb: 0 },
  pack_comet:   { bomb: 10, wildcard: 10, reducer: 10, radar: 4, evolution: 3, megaBomb: 2 },
  pack_diamond: { bomb: 20, wildcard: 20, reducer: 20, radar: 8, evolution: 6, megaBomb: 5 },
  pack_rescue:  { bomb: 6, wildcard: 6, reducer: 6, radar: 0, evolution: 0, megaBomb: 3 },
  pack_boost:   { bomb: 12, wildcard: 12, reducer: 12, radar: 6, evolution: 4, megaBomb: 3 },
  no_ads:       { bomb: 10, wildcard: 10, reducer: 10, radar: 3, evolution: 2, megaBomb: 2 },
  pack_emoji:   { bomb: 0, wildcard: 0, reducer: 0, radar: 0, evolution: 0, megaBomb: 0 },
};

const MAX_PER_JOKER = 99;
const PACKAGE_NAME = "com.crestbit.shapemerge2048";

// ── Google Play verification ─────────────────────────────────
const PLAY_KEY_PATH = "./play-verify-key.json";

async function verifyGooglePlay(productId, purchaseToken) {
  const auth = new google.auth.GoogleAuth({
    keyFile: PLAY_KEY_PATH,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const androidPublisher = google.androidpublisher({ version: "v3", auth: client });

  const res = await androidPublisher.purchases.products.get({
    packageName: PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });

  // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending
  if (res.data.purchaseState !== 0) {
    throw new HttpsError("failed-precondition", "Purchase not completed");
  }

  return {
    orderId: res.data.orderId,
    purchaseTime: res.data.purchaseTimeMillis,
  };
}

// ── Credit jokers atomically ─────────────────────────────────
async function creditJokers(uid, productId) {
  const pack = PACK_CONTENTS[productId];
  if (!pack) {
    throw new HttpsError("invalid-argument", `Unknown product: ${productId}`);
  }

  const playerRef = db.collection("players").doc(uid);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(playerRef);
    const current = doc.exists ? (doc.data().jokerInventory || {}) : {};

    const updated = {};
    for (const [type, amount] of Object.entries(pack)) {
      const cur = typeof current[type] === "number" ? current[type] : 0;
      updated[type] = amount > 0 ? Math.min(cur + amount, MAX_PER_JOKER) : cur;
    }

    tx.set(playerRef, { jokerInventory: updated }, { merge: true });
  });
}

// ── Record processed purchase (idempotency) ──────────────────
async function isAlreadyProcessed(uid, orderId) {
  const ref = db.collection("players").doc(uid)
    .collection("purchases").doc(orderId);
  const doc = await ref.get();
  return doc.exists;
}

async function recordPurchase(uid, orderId, productId) {
  const ref = db.collection("players").doc(uid)
    .collection("purchases").doc(orderId);
  await ref.set({
    productId,
    processedAt: FieldValue.serverTimestamp(),
  });
}

// ── Main Cloud Function ──────────────────────────────────────
exports.verifyPurchase = onCall(
  { region: "europe-west1", maxInstances: 10 },
  async (request) => {
    // Must be authenticated
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { productId, purchaseToken, platform } = request.data;

    if (!productId || !purchaseToken) {
      throw new HttpsError("invalid-argument", "Missing productId or purchaseToken");
    }

    if (!PACK_CONTENTS[productId]) {
      throw new HttpsError("invalid-argument", `Unknown product: ${productId}`);
    }

    // ── Verify with store ──
    let orderId;

    if (platform === "android") {
      const result = await verifyGooglePlay(productId, purchaseToken);
      orderId = result.orderId;
    } else if (platform === "ios") {
      // TODO: Add Apple App Store Server API verification
      // For now, accept iOS purchases (add verification when iOS is live)
      orderId = `ios_${purchaseToken.substring(0, 32)}`;
    } else {
      throw new HttpsError("invalid-argument", "Invalid platform");
    }

    // ── Idempotency check ──
    if (await isAlreadyProcessed(uid, orderId)) {
      return { status: "already_processed", orderId };
    }

    // ── Credit jokers and record ──
    await creditJokers(uid, productId);

    // Handle no-ads flag
    if (productId === "no_ads") {
      await db.collection("players").doc(uid).set(
        { noAdsPurchased: true },
        { merge: true },
      );
    }

    // Handle emoji pack flag
    if (productId === "pack_emoji") {
      await db.collection("players").doc(uid).set(
        { emojiPackPurchased: true },
        { merge: true },
      );
    }

    await recordPurchase(uid, orderId, productId);

    return { status: "ok", orderId };
  },
);

// ══════════════════════════════════════════════════════════════
// Score submission — server-side validation
// ══════════════════════════════════════════════════════════════

// Scoring formula mirrors game_tuning.dart:
//   pointsPerMerge = (1 << newLevel) * 10
//   comboMultiplier = min(1 + combo * 0.5, 5.0)
//   max single merge = (1 << 20) * 10 * 5 ≈ 52M (theoretical, level 20 with max combo)
// Realistic cap: average points per merge (considering early merges are tiny)
const MAX_AVG_POINTS_PER_MERGE = 20000;
const MAX_SCORE = 999999;
const MAX_MERGE_COUNT = 50000;
const MAX_LEVEL = 30;

function validateScoreConsistency(score, mergeCount, maxLevel) {
  if (typeof score !== "number" || score < 0 || score > MAX_SCORE) {
    return "Invalid score";
  }
  if (typeof mergeCount !== "number" || mergeCount < 0 || mergeCount > MAX_MERGE_COUNT) {
    return "Invalid mergeCount";
  }
  if (typeof maxLevel !== "number" || maxLevel < 1 || maxLevel > MAX_LEVEL) {
    return "Invalid maxLevel";
  }
  // Score / merge consistency: can't have huge score with very few merges
  if (mergeCount > 0 && score > mergeCount * MAX_AVG_POINTS_PER_MERGE) {
    return `Score ${score} too high for ${mergeCount} merges`;
  }
  // maxLevel / merge consistency: reaching level N requires at least N-1 merges
  if (maxLevel > mergeCount + 1) {
    return `maxLevel ${maxLevel} impossible with ${mergeCount} merges`;
  }
  return null; // Valid
}

exports.submitScore = onCall(
  { region: "europe-west1", maxInstances: 20 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { score, mergeCount, maxLevel, displayName, photoUrl, avatarId } = request.data;

    // ── Validate inputs ──
    const error = validateScoreConsistency(score, mergeCount, maxLevel);
    if (error) {
      logger.warn(`Score rejected for ${uid}: ${error}`);
      throw new HttpsError("invalid-argument", error);
    }

    if (typeof displayName !== "string" || displayName.length > 50) {
      throw new HttpsError("invalid-argument", "Invalid displayName");
    }

    // ── Rate limit: max 1 submit per 5 seconds ──
    const docRef = db.collection("leaderboard").doc(uid);

    await db.runTransaction(async (tx) => {
      const doc = await tx.get(docRef);
      const existing = doc.data();

      if (existing?.timestamp) {
        const lastTime = existing.timestamp.toDate().getTime();
        const now = Date.now();
        if (now - lastTime < 5000) {
          throw new HttpsError("resource-exhausted", "Too frequent");
        }
      }

      const existingScore = (existing?.score ?? 0);
      if (doc.exists && existingScore >= score) {
        // Not a new best — skip
        return;
      }

      const entry = {
        score,
        mergeCount,
        maxLevel,
        displayName: displayName.substring(0, 50),
        timestamp: FieldValue.serverTimestamp(),
      };
      if (photoUrl) entry.photoUrl = photoUrl;
      if (avatarId) entry.avatarId = avatarId;

      tx.set(docRef, entry);
      logger.info(`Score accepted for ${uid}: ${score} (merges: ${mergeCount}, maxLevel: ${maxLevel})`);
    });

    // Also update player bestScore
    await db.collection("players").doc(uid).set(
      { bestScore: score },
      { merge: true },
    );

    return { status: "ok" };
  },
);

// ══════════════════════════════════════════════════════════════
// Daily Challenge — server-side reward claim
// ══════════════════════════════════════════════════════════════

// Challenge reward catalog (mirrors challenge_config.dart)
const CHALLENGE_XP = { easy: 15, medium: 30, hard: 50 };
const CHALLENGE_JOKER = { easy: "bomb", medium: "wildcard", hard: "reducer" };
const BONUS_JOKERS = ["bomb", "wildcard", "reducer"]; // 3/3 bonus

// XP leveling formula: floor(100 × level^1.4), mirrors game_tuning.dart
const XP_MAX_LEVEL = 50;
function xpForLevel(level) {
  return Math.min(Math.max(Math.floor(100 * Math.pow(level, 1.4)), 100), 999999);
}

function todayKey() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * claimChallengeReward — validates and distributes a single challenge reward.
 *
 * data: { challengeId: string }  OR  { bonus: true }
 *
 * For a single challenge:
 *   - Verifies challenge doc date = server today
 *   - Verifies challenge exists, completed, not yet collected
 *   - Re-derives reward from (difficulty, seed) to prevent client forgery
 *   - Credits joker or XP atomically
 *   - Marks rewardCollected in the doc
 *
 * For the 3/3 bonus:
 *   - Verifies all 3 completed + bonusCollected == false
 *   - Credits 1 bomb + 1 wildcard + 1 reducer
 *   - Marks bonusCollected = true
 */
exports.claimChallengeReward = onCall(
  { region: "europe-west1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { challengeId, bonus } = request.data;

    const playerRef = db.collection("players").doc(uid);
    const challengeRef = playerRef.collection("data").doc("dailyChallenges");

    const result = await db.runTransaction(async (tx) => {
      const challengeDoc = await tx.get(challengeRef);
      if (!challengeDoc.exists) {
        throw new HttpsError("not-found", "No daily challenges found");
      }

      const data = challengeDoc.data();
      const serverToday = todayKey();

      // Date must match server today — blocks clock manipulation
      if (data.date !== serverToday) {
        throw new HttpsError(
          "failed-precondition",
          `Challenge date ${data.date} does not match server date ${serverToday}`,
        );
      }

      const challenges = data.challenges || [];

      if (bonus === true) {
        // ── Bonus claim (3/3) ──
        if (data.bonusCollected === true) {
          return { status: "already_collected" };
        }

        const allCompleted = challenges.length > 0 &&
          challenges.every((c) => c.completed === true);
        if (!allCompleted) {
          throw new HttpsError("failed-precondition", "Not all challenges completed");
        }

        // Credit bonus jokers
        const playerDoc = await tx.get(playerRef);
        const inventory = playerDoc.exists
          ? (playerDoc.data().jokerInventory || {})
          : {};

        const updatedInventory = { ...inventory };
        for (const jokerType of BONUS_JOKERS) {
          const cur = typeof updatedInventory[jokerType] === "number"
            ? updatedInventory[jokerType] : 0;
          updatedInventory[jokerType] = Math.min(cur + 1, MAX_PER_JOKER);
        }

        tx.update(playerRef, { jokerInventory: updatedInventory });
        tx.update(challengeRef, { bonusCollected: true });

        return { status: "ok", rewardType: "bonus" };
      }

      // ── Single challenge claim ──
      if (typeof challengeId !== "string" || challengeId.length === 0) {
        throw new HttpsError("invalid-argument", "Missing challengeId");
      }

      const idx = challenges.findIndex((c) => c.id === challengeId);
      if (idx === -1) {
        throw new HttpsError("not-found", `Challenge ${challengeId} not found`);
      }

      const challenge = challenges[idx];

      if (challenge.rewardCollected === true) {
        return { status: "already_collected" };
      }

      if (challenge.completed !== true) {
        throw new HttpsError("failed-precondition", "Challenge not completed");
      }

      // Re-derive reward from difficulty (server-authoritative)
      const diff = challenge.difficulty;
      const rewardData = challenge.reward || {};

      // Read the player doc for atomic inventory/XP update
      const playerDoc = await tx.get(playerRef);
      const playerData = playerDoc.exists ? playerDoc.data() : {};

      let rewardType;
      let rewardDetail;

      if (rewardData.kind === "xp") {
        // XP reward — validate against config
        const xpAmount = CHALLENGE_XP[diff] || 15;
        const currentLevel = typeof playerData.level === "number" ? playerData.level : 1;
        const currentXP = typeof playerData.currentXP === "number" ? playerData.currentXP : 0;
        const currentTotalXP = typeof playerData.totalXP === "number" ? playerData.totalXP : 0;

        let level = currentLevel;
        let xp = currentXP + xpAmount;
        const totalXP = currentTotalXP + xpAmount;

        // Level-up loop (mirrors progression_service.dart)
        while (level < XP_MAX_LEVEL) {
          const needed = xpForLevel(level);
          if (xp < needed) break;
          xp -= needed;
          level++;
        }

        tx.set(playerRef, { level, currentXP: xp, totalXP }, { merge: true });
        rewardType = "xp";
        rewardDetail = { xp: xpAmount, newLevel: level };
      } else {
        // Joker reward — validate against config
        const jokerType = CHALLENGE_JOKER[diff] || "bomb";
        const inventory = playerData.jokerInventory || {};
        const cur = typeof inventory[jokerType] === "number" ? inventory[jokerType] : 0;
        const updatedInventory = {
          ...inventory,
          [jokerType]: Math.min(cur + 1, MAX_PER_JOKER),
        };
        tx.update(playerRef, { jokerInventory: updatedInventory });
        rewardType = "joker";
        rewardDetail = { joker: jokerType };
      }

      // Mark reward as collected in the challenges array
      challenges[idx] = { ...challenge, rewardCollected: true };
      tx.update(challengeRef, { challenges });

      logger.info(`Challenge reward claimed for ${uid}: ${rewardType}`, rewardDetail);
      return { status: "ok", rewardType, ...rewardDetail };
    });

    return result;
  },
);

// ══════════════════════════════════════════════════════════════
// Player profile → Leaderboard mirror
// ──────────────────────────────────────────────────────────────
// When a player's displayName or avatarId changes, propagate to
// their leaderboard entry (if it exists) so the leaderboard view
// shows up-to-date avatar/name without waiting for a new score.
// ══════════════════════════════════════════════════════════════
exports.onPlayerProfileUpdate = onDocumentUpdated(
  { document: "players/{uid}", region: "europe-west1" },
  async (event) => {
    const before = event.data?.before.data() || {};
    const after = event.data?.after.data() || {};

    const nameChanged = before.displayName !== after.displayName;
    const avatarChanged = before.avatarId !== after.avatarId;
    if (!nameChanged && !avatarChanged) return;

    const uid = event.params.uid;
    const leaderboardRef = db.collection("leaderboard").doc(uid);
    const doc = await leaderboardRef.get();
    if (!doc.exists) return;

    const update = {};
    if (nameChanged && typeof after.displayName === "string") {
      update.displayName = after.displayName.substring(0, 50);
    }
    if (avatarChanged) {
      if (after.avatarId) {
        update.avatarId = after.avatarId;
      } else {
        update.avatarId = FieldValue.delete();
      }
    }

    if (Object.keys(update).length === 0) return;

    await leaderboardRef.update(update);
    logger.info(`Mirrored profile update to leaderboard for ${uid}`, update);
  },
);

// ══════════════════════════════════════════════════════════════
// Daily Streak — server-authoritative claim with serverTimestamp
// ──────────────────────────────────────────────────────────────
// Anti-cheat: client cannot manipulate device clock to claim
// rewards twice or maintain a streak fraudulently. All date math
// uses Firestore server time (Timestamp.now()).
//
// On call:
//   1. Read player doc inside transaction
//   2. Determine "today" / "yesterday" UTC keys from server now
//   3. Compare with stored `lastClaimAt` (Timestamp) — fallback to
//      legacy `rewardClaimedDate` (String) for migration
//   4. If already claimed today → throw `already_claimed`
//   5. Compute new streak: yesterday => +1, else reset to 1
//   6. Re-derive reward server-side (mirror of player_streak.dart)
//   7. Atomically: update streak fields + jokerInventory / XP
//   8. Set `lastClaimAt = serverTimestamp()` (source of truth)
//
// Returns: { currentStreak, longestStreak, reward, milestone }
// ══════════════════════════════════════════════════════════════

const STREAK_CYCLE = 7;
// Mirror of player_streak.dart `_baseRewards` (J1..J6).
// J7 uses premium rotation computed below.
const STREAK_BASE_REWARDS = [
  { kind: "xp",    xp: 15 },                    // J1
  { kind: "joker", type: "bomb",     amount: 1 }, // J2
  { kind: "xp",    xp: 20 },                    // J3
  { kind: "joker", type: "wildcard", amount: 1 }, // J4
  { kind: "xp",    xp: 25 },                    // J5
  { kind: "joker", type: "reducer",  amount: 1 }, // J6
  // J7 placeholder — replaced by premium rotation
];
const STREAK_J7_ROTATION = ["radar", "evolution", "megaBomb"];

const STREAK_MILESTONES = {
  14:  [{ type: "evolution", amount: 1 }],
  30:  [{ type: "megaBomb",  amount: 1 }, { type: "wildcard", amount: 1 }],
  100: [{ type: "megaBomb",  amount: 1 }, { type: "evolution", amount: 1 }, { type: "radar", amount: 1 }],
};

function streakRewardFor(streak) {
  if (streak <= 0) return { kind: "xp", xp: 15 };
  const dayIndex = (streak - 1) % STREAK_CYCLE;
  const weekNum = Math.floor((streak - 1) / STREAK_CYCLE) + 1;
  if (dayIndex === 6) {
    const premium = STREAK_J7_ROTATION[(weekNum - 1) % STREAK_J7_ROTATION.length];
    return { kind: "joker", type: premium, amount: 1 };
  }
  return STREAK_BASE_REWARDS[dayIndex];
}

/** Returns "YYYY-MM-DD" in UTC for a given Date. */
function utcDayKey(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

exports.claimDailyStreakReward = onCall(
  { region: "europe-west1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }
    const uid = request.auth.uid;
    const playerRef = db.collection("players").doc(uid);

    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(playerRef);
      const data = snap.exists ? snap.data() : {};

      // ── Server time is the only trusted clock ──
      const now = new Date();
      const todayKey = utcDayKey(now);
      const yesterdayKey = utcDayKey(new Date(now.getTime() - 86400000));

      // Determine last claim day key.
      let lastKey = null;
      if (data.lastClaimAt && typeof data.lastClaimAt.toDate === "function") {
        lastKey = utcDayKey(data.lastClaimAt.toDate());
      } else if (typeof data.rewardClaimedDate === "string") {
        // Legacy fallback — accept the stored String key as-is.
        lastKey = data.rewardClaimedDate;
      }

      if (lastKey === todayKey) {
        throw new HttpsError("already-exists", "Reward already claimed today");
      }

      const prevStreak = typeof data.currentStreak === "number" ? data.currentStreak : 0;
      const prevLongest = typeof data.longestStreak === "number" ? data.longestStreak : 0;

      // Yesterday claim continues the streak; anything else resets to 1.
      const newStreak = lastKey === yesterdayKey ? prevStreak + 1 : 1;
      const newLongest = Math.max(prevLongest, newStreak);
      const newIndex = ((newStreak - 1) % STREAK_CYCLE + STREAK_CYCLE) % STREAK_CYCLE;

      const reward = streakRewardFor(newStreak);
      const milestone = STREAK_MILESTONES[newStreak] || null;

      // Build inventory + XP updates (atomic).
      const inventory = data.jokerInventory ? { ...data.jokerInventory } : {};
      let level = typeof data.level === "number" ? data.level : 1;
      let currentXP = typeof data.currentXP === "number" ? data.currentXP : 0;
      let totalXP = typeof data.totalXP === "number" ? data.totalXP : 0;

      const addJoker = (type, amount) => {
        const cur = typeof inventory[type] === "number" ? inventory[type] : 0;
        inventory[type] = Math.min(cur + amount, MAX_PER_JOKER);
      };

      if (reward.kind === "joker") {
        addJoker(reward.type, reward.amount);
      } else if (reward.kind === "xp") {
        totalXP += reward.xp;
        currentXP += reward.xp;
        // Level-up loop (mirror of progression_service)
        while (level < XP_MAX_LEVEL && currentXP >= xpForLevel(level)) {
          currentXP -= xpForLevel(level);
          level += 1;
        }
        if (level >= XP_MAX_LEVEL) currentXP = 0;
      }

      if (milestone) {
        for (const bonus of milestone) {
          addJoker(bonus.type, bonus.amount);
        }
      }

      tx.set(
        playerRef,
        {
          currentStreak: newStreak,
          longestStreak: newLongest,
          nextRewardIndex: newIndex,
          lastClaimAt: FieldValue.serverTimestamp(),
          // Keep legacy fields in sync for backward-compat readers.
          lastLoginDate: todayKey,
          rewardClaimedDate: todayKey,
          jokerInventory: inventory,
          level,
          currentXP,
          totalXP,
        },
        { merge: true },
      );

      return {
        currentStreak: newStreak,
        longestStreak: newLongest,
        nextRewardIndex: newIndex,
        reward,
        milestone,
      };
    });

    logger.info(`Streak claimed for ${uid}: day ${result.currentStreak}`);
    return result;
  },
);

const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const REGION = "us-central1";

const openaiApiKeySecret = defineSecret("OPENAI_API_KEY");
const usdaApiKeySecret = defineSecret("USDA_API_KEY");

const algoliaAppIdSecret = defineSecret("ALGOLIA_APP_ID");
const algoliaAdminApiKeySecret = defineSecret("ALGOLIA_ADMIN_API_KEY");
const algoliaIndexNameSecret = defineSecret("ALGOLIA_INDEX_NAME");
const searchBackfillAdminKeySecret = defineSecret("SEARCH_BACKFILL_ADMIN_KEY");

const aiSecurity = require("./aiSecurity");
const { withAppCheck } = require("./appCheckEnforcement");
const appStoreVerification = require("./appStoreVerification");

const XP = Object.freeze({
  RECIPE_PUBLISHED: 20,
  MAIN_PHOTO_ADDED: 5,
  STEP_PHOTOS_ADDED: 0,
  VIDEO_ADDED: 0,
  FULL_RECIPE_COMPLETED: 0,
  NUTRITION_INFO_ADDED: 0,
  RECIPE_COOKED_BY_OTHER_USER: 0,
  LIKE_RECEIVED: 1,
  COMMENT_RECEIVED: 4,
  SAVE_RECEIVED: 3,
  FOLLOWER_GAINED: 10,
  RECIPE_SAVED: 0,
  COMMENT_WRITTEN: 2,
  USER_FOLLOWED: 1,
  FIRST_RECIPE_PUBLISHED: 0,
  FIRST_LIKE_RECEIVED: 0,
  FIRST_COMMENT_RECEIVED: 0,
  FIRST_FOLLOWER_GAINED: 0,
  TEN_LIKES_RECEIVED: 0,
  FIFTY_LIKES_RECEIVED: 0,
  ONE_HUNDRED_LIKES_RECEIVED: 0,
  FIVE_RECIPES_PUBLISHED: 0,
  TEN_RECIPES_PUBLISHED: 0,
  TEN_FOLLOWERS_GAINED: 0,
  ONE_HUNDRED_FOLLOWERS_GAINED: 0,
});

// Daily anti-farm caps (XP per actor -> receiver -> eventType per UTC day).
// This throttle is independent from revoke flows, so repeated toggle actions
// cannot bypass it within the same day.
const DAILY_ACTOR_RECEIVER_XP_CAP = Object.freeze({
  LIKE_RECEIVED: 10,
  SAVE_RECEIVED: 15,
  COMMENT_RECEIVED: 12,
  FOLLOWER_GAINED: 10,
});

function roundToNearestFive(value) {
  return Math.round(value / 5) * 5;
}

function xpToNextLevel(level) {
  const L = Math.max(1, level);
  return roundToNearestFive(25 + 10 * L + 5 * Math.pow(L, 1.5));
}

function totalXPRequiredForLevel(level) {
  if (level <= 1) return 0;
  let total = 0;
  for (let l = 1; l < level; l += 1) {
    total += xpToNextLevel(l);
  }
  return total;
}

function levelFromXP(totalXP) {
  const safeXP = Math.max(0, totalXP);
  let level = 1;
  while (safeXP >= totalXPRequiredForLevel(level + 1)) {
    level += 1;
  }
  return level;
}

function getLevelTitle(level) {
  const lv = Math.max(1, level);
  if (lv <= 5) return "Kitchen Newbie";
  if (lv <= 10) return "Home Cook";
  if (lv <= 15) return "Recipe Explorer";
  if (lv <= 20) return "Skilled Cook";
  if (lv <= 30) return "Rising Chef";
  if (lv <= 40) return "Master Chef";
  if (lv <= 50) return "Culinary Star";
  return "Legendary Chef";
}

function eventRef(eventId) {
  return db.collection("xpEvents").doc(eventId);
}

function progressRef(userId) {
  return db.collection("userProgress").doc(userId);
}

function throttleRef(eventType, actorUserId, receiverUserId, dayKey) {
  return db.collection("xpAwardThrottle").doc(`${eventType}:${actorUserId}:${receiverUserId}:${dayKey}`);
}

async function awardXP({ eventId, receiverUserId, actorUserId, eventType, targetId, xpAmount, metadata = null }) {
  if (!receiverUserId || !actorUserId || !targetId || !eventId) return false;
  if (xpAmount <= 0) return false;
  const cap = DAILY_ACTOR_RECEIVER_XP_CAP[eventType];
  const dayKey = new Date().toISOString().slice(0, 10); // UTC day

  await db.runTransaction(async (tx) => {
    const evt = await tx.get(eventRef(eventId));
    if (evt.exists) return;
    
    let finalAwardXP = xpAmount;
    if (typeof cap === "number" && cap > 0) {
      const tRef = throttleRef(eventType, actorUserId, receiverUserId, dayKey);
      const tSnap = await tx.get(tRef);
      const usedToday = Number(tSnap.data()?.awardedXP || 0);
      finalAwardXP = Math.max(0, Math.min(xpAmount, cap - usedToday));
      if (finalAwardXP <= 0) {
        logger.info("XP award skipped by anti-farm daily cap.", {
          eventType,
          actorUserId,
          receiverUserId,
          dayKey,
          cap,
          requestedXP: xpAmount,
          usedToday,
        });
        return;
      }
      tx.set(tRef, {
        eventType,
        actorUserId,
        receiverUserId,
        dayKey,
        awardedXP: usedToday + finalAwardXP,
        createdAt: tSnap.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const pRef = progressRef(receiverUserId);
    const pSnap = await tx.get(pRef);
    const current = pSnap.exists ? pSnap.data() : null;
    const prevXP = Number(current?.totalXP || 0);
    const nextXP = prevXP + finalAwardXP;
    const nextLevel = levelFromXP(nextXP);
    const nextTitle = getLevelTitle(nextLevel);

    tx.set(eventRef(eventId), {
      eventId,
      receiverUserId,
      actorUserId,
      eventType,
      targetId,
      xpAmount: finalAwardXP,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata,
    }, { merge: false });

    tx.set(pRef, {
      userId: receiverUserId,
      totalXP: nextXP,
      currentLevel: nextLevel,
      currentTitle: nextTitle,
      createdAt: current?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return true;
}

async function revokeXP({ eventId, receiverUserId, xpAmount }) {
  if (!eventId || !receiverUserId || xpAmount <= 0) return false;

  await db.runTransaction(async (tx) => {
    const evtRef = eventRef(eventId);
    const evt = await tx.get(evtRef);
    if (!evt.exists) return;

    const pRef = progressRef(receiverUserId);
    const pSnap = await tx.get(pRef);
    const current = pSnap.exists ? pSnap.data() : {};
    const eventData = evt.data() || {};
    // Revoke the exact amount that was originally awarded for this event.
    const awardedXP = Number(eventData.xpAmount || xpAmount);
    const prevXP = Number(current.totalXP || 0);
    const nextXP = Math.max(0, prevXP - awardedXP);
    const nextLevel = levelFromXP(nextXP);
    const nextTitle = getLevelTitle(nextLevel);

    tx.delete(evtRef);
    tx.set(pRef, {
      userId: receiverUserId,
      totalXP: nextXP,
      currentLevel: nextLevel,
      currentTitle: nextTitle,
      createdAt: current.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return true;
}

async function maybeAwardMilestonesForLikes(receiverUserId, likesCount) {
  if (likesCount >= 1) {
    await awardXP({
      eventId: `MILESTONE:FIRST_LIKE_RECEIVED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIRST_LIKE_RECEIVED",
      targetId: receiverUserId,
      xpAmount: XP.FIRST_LIKE_RECEIVED,
    });
  }
  if (likesCount >= 10) {
    await awardXP({
      eventId: `MILESTONE:TEN_LIKES_RECEIVED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "TEN_LIKES_RECEIVED",
      targetId: receiverUserId,
      xpAmount: XP.TEN_LIKES_RECEIVED,
    });
  }
  if (likesCount >= 50) {
    await awardXP({
      eventId: `MILESTONE:FIFTY_LIKES_RECEIVED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIFTY_LIKES_RECEIVED",
      targetId: receiverUserId,
      xpAmount: XP.FIFTY_LIKES_RECEIVED,
    });
  }
  if (likesCount >= 100) {
    await awardXP({
      eventId: `MILESTONE:ONE_HUNDRED_LIKES_RECEIVED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "ONE_HUNDRED_LIKES_RECEIVED",
      targetId: receiverUserId,
      xpAmount: XP.ONE_HUNDRED_LIKES_RECEIVED,
    });
  }
}

async function maybeAwardMilestonesForFollowers(receiverUserId, followerCount) {
  if (followerCount >= 1) {
    await awardXP({
      eventId: `MILESTONE:FIRST_FOLLOWER_GAINED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIRST_FOLLOWER_GAINED",
      targetId: receiverUserId,
      xpAmount: XP.FIRST_FOLLOWER_GAINED,
    });
  }
  if (followerCount >= 10) {
    await awardXP({
      eventId: `MILESTONE:TEN_FOLLOWERS_GAINED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "TEN_FOLLOWERS_GAINED",
      targetId: receiverUserId,
      xpAmount: XP.TEN_FOLLOWERS_GAINED,
    });
  }
  if (followerCount >= 100) {
    await awardXP({
      eventId: `MILESTONE:ONE_HUNDRED_FOLLOWERS_GAINED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "ONE_HUNDRED_FOLLOWERS_GAINED",
      targetId: receiverUserId,
      xpAmount: XP.ONE_HUNDRED_FOLLOWERS_GAINED,
    });
  }
}

async function maybeAwardMilestonesForRecipes(receiverUserId, recipeCount) {
  if (recipeCount >= 1) {
    await awardXP({
      eventId: `MILESTONE:FIRST_RECIPE_PUBLISHED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIRST_RECIPE_PUBLISHED",
      targetId: receiverUserId,
      xpAmount: XP.FIRST_RECIPE_PUBLISHED,
    });
  }
  if (recipeCount >= 5) {
    await awardXP({
      eventId: `MILESTONE:FIVE_RECIPES_PUBLISHED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIVE_RECIPES_PUBLISHED",
      targetId: receiverUserId,
      xpAmount: XP.FIVE_RECIPES_PUBLISHED,
    });
  }
  if (recipeCount >= 10) {
    await awardXP({
      eventId: `MILESTONE:TEN_RECIPES_PUBLISHED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "TEN_RECIPES_PUBLISHED",
      targetId: receiverUserId,
      xpAmount: XP.TEN_RECIPES_PUBLISHED,
    });
  }
}

function buildApnProvider() {
  const key = process.env.APN_KEY;
  const keyId = process.env.APN_KEY_ID;
  const teamId = process.env.APN_TEAM_ID;
  const topic = process.env.APN_TOPIC;

  if (!key || !keyId || !teamId || !topic) {
    logger.warn("APNs env vars missing; push notification skipped.");
    return null;
  }

  const apn = require("apn");
  return {
    provider: new apn.Provider({
      token: {
        key: key.replace(/\\n/g, "\n"),
        keyId,
        teamId,
      },
      production: process.env.APN_PRODUCTION === "true",
    }),
    topic,
  };
}

function getAlgoliaConfig() {
  const appId = process.env.ALGOLIA_APP_ID;
  const adminApiKey = process.env.ALGOLIA_ADMIN_API_KEY;
  const indexName = process.env.ALGOLIA_INDEX_NAME || "recipes";
  if (!appId || !adminApiKey || !indexName) {
    return null;
  }
  return {
    appId,
    adminApiKey,
    indexName,
    endpoint: `https://${appId}.algolia.net/1/indexes/${indexName}`,
  };
}

function toEpochSeconds(value) {
  if (!value) return 0;
  if (typeof value === "number") return Math.floor(value);
  if (value.toDate && typeof value.toDate === "function") {
    return Math.floor(value.toDate().getTime() / 1000);
  }
  if (value._seconds) return Number(value._seconds) || 0;
  return 0;
}

function normalizeText(value) {
  if (typeof value !== "string") return "";
  return value.trim();
}

function buildRecipeSearchObject(recipeId, data) {
  const ingredients = Array.isArray(data.ingredients)
    ? data.ingredients
      .map((item) => normalizeText(item?.name))
      .filter((name) => name.length > 0)
    : [];

  return {
    objectID: recipeId,
    id: recipeId,
    title: normalizeText(data.title),
    titleEnglish: normalizeText(data.titleEnglish),
    titleLocal: normalizeText(data.titleLocal),
    titleOriginal: normalizeText(data.titleOriginal),
    description: normalizeText(data.description),
    cuisine: normalizeText(data.cuisine),
    cuisineEnglish: normalizeText(data.cuisineEnglish),
    authorID: normalizeText(data.authorID),
    authorName: normalizeText(data.authorName),
    authorUsername: normalizeText(data.authorUsername),
    ingredients,
    searchKeywords: Array.isArray(data.searchKeywords) ? data.searchKeywords : [],
    isPrivate: Boolean(data.isPrivate),
    sharedWith: Array.isArray(data.sharedWith) ? data.sharedWith : [],
    isHidden: Boolean(data.isHidden),
    reportCount: Number(data.reportCount || 0),
    createdAtSec: toEpochSeconds(data.createdAt),
    updatedAtSec: toEpochSeconds(data.updatedAt),
  };
}

async function algoliaSaveObject(searchObject) {
  const config = getAlgoliaConfig();
  if (!config) {
    logger.warn("Algolia env vars missing; recipe index sync skipped.");
    return;
  }

  const response = await fetch(`${config.endpoint}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Algolia-Application-Id": config.appId,
      "X-Algolia-API-Key": config.adminApiKey,
    },
    body: JSON.stringify(searchObject),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Algolia saveObject failed (${response.status}): ${body}`);
  }
}

async function algoliaDeleteObject(recipeId) {
  const config = getAlgoliaConfig();
  if (!config) {
    logger.warn("Algolia env vars missing; recipe index delete skipped.");
    return;
  }

  const response = await fetch(`${config.endpoint}/${recipeId}`, {
    method: "DELETE",
    headers: {
      "X-Algolia-Application-Id": config.appId,
      "X-Algolia-API-Key": config.adminApiKey,
    },
  });

  if (!response.ok && response.status !== 404) {
    const body = await response.text();
    throw new Error(`Algolia deleteObject failed (${response.status}): ${body}`);
  }
}

exports.onRecipeChangeProposalCreated = onDocumentCreated(
  {
    document: "recipeChangeProposals/{proposalId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) {
      logger.warn("No payload found in proposal create event.");
      return;
    }

    const proposalId = event.params.proposalId;
    const recipeAuthorID = data.recipeAuthorID;
    const proposerName = data.displayName || "Someone";
    const targetKind = data.targetKind || "recipe";
    const proposerID = data.userID;

    if (!recipeAuthorID || recipeAuthorID === proposerID) {
      logger.info("Skipping notification; invalid author/proposer relation.", {
        proposalId,
      });
      return;
    }

    const apnConfig = buildApnProvider();
    if (!apnConfig) return;

    const apn = require("apn");

    const devicesSnapshot = await db
      .collection("users")
      .doc(recipeAuthorID)
      .collection("devices")
      .where("platform", "==", "ios")
      .where("notificationsEnabled", "==", true)
      .get();

    if (devicesSnapshot.empty) {
      logger.info("No active iOS devices for recipe author.", {
        recipeAuthorID,
        proposalId,
      });
      return;
    }

    const tokens = devicesSnapshot.docs
      .map((doc) => ({ id: doc.id, token: doc.get("pushToken") }))
      .filter((entry) => typeof entry.token === "string" && entry.token.length > 0);

    if (tokens.length === 0) {
      logger.info("No APNs tokens available for recipe author.", {
        recipeAuthorID,
        proposalId,
      });
      return;
    }

    const note = new apn.Notification();
    note.topic = apnConfig.topic;
    note.pushType = "alert";
    note.sound = "default";
    note.alert = {
      title: "New recipe update recommendation",
      body: `${proposerName} suggested a change to your ${targetKind}.`,
    };
    note.payload = {
      type: "recipeChangeProposal",
      proposalId,
      recipeId: data.recipeID || "",
      targetKind,
      targetIndex: data.targetIndex ?? null,
    };

    const result = await apnConfig.provider.send(
      note,
      tokens.map((entry) => entry.token)
    );

    logger.info("APNs send complete.", {
      proposalId,
      sent: result.sent.length,
      failed: result.failed.length,
    });

    // Remove invalid tokens (professional hygiene).
    const badTokens = new Set(
      result.failed
        .map((f) => f.device)
        .filter((deviceToken) => typeof deviceToken === "string")
    );

    if (badTokens.size > 0) {
      const batch = db.batch();
      tokens.forEach((entry) => {
        if (badTokens.has(entry.token)) {
          const ref = db
            .collection("users")
            .doc(recipeAuthorID)
            .collection("devices")
            .doc(entry.id);
          batch.delete(ref);
        }
      });
      await batch.commit();
      logger.info("Removed invalid device tokens.", {
        recipeAuthorID,
        removedCount: badTokens.size,
      });
    }
  }
);

exports.onFavoriteCreatedAwardXP = onDocumentCreated(
  {
    document: "favorites/{favoriteId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const actorUserId = data.userID;
    const recipeId = data.recipeID;
    if (!actorUserId || !recipeId) return;

    let receiverUserId = data.recipeAuthorID;
    if (!receiverUserId) {
      const recipeDoc = await db.collection("recipes").doc(recipeId).get();
      receiverUserId = recipeDoc.data()?.authorID;
    }
    if (!receiverUserId || receiverUserId === actorUserId) return;

    await awardXP({
      eventId: `LIKE_RECEIVED:${actorUserId}:${recipeId}`,
      receiverUserId,
      actorUserId,
      eventType: "LIKE_RECEIVED",
      targetId: recipeId,
      xpAmount: XP.LIKE_RECEIVED,
    });
    await awardXP({
      eventId: `SAVE_RECEIVED:${actorUserId}:${recipeId}`,
      receiverUserId,
      actorUserId,
      eventType: "SAVE_RECEIVED",
      targetId: recipeId,
      xpAmount: XP.SAVE_RECEIVED,
    });
    await awardXP({
      eventId: `RECIPE_SAVED:${actorUserId}:${recipeId}`,
      receiverUserId: actorUserId,
      actorUserId,
      eventType: "RECIPE_SAVED",
      targetId: recipeId,
      xpAmount: XP.RECIPE_SAVED,
    });

    const userDoc = await db.collection("users").doc(receiverUserId).get();
    const likesCount = Number(userDoc.data()?.likesCount || 0);
    await maybeAwardMilestonesForLikes(receiverUserId, likesCount);
  }
);

exports.onFavoriteDeletedRevokeXP = onDocumentDeleted(
  {
    document: "favorites/{favoriteId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const actorUserId = data.userID;
    const recipeId = data.recipeID;
    if (!actorUserId || !recipeId) return;

    let receiverUserId = data.recipeAuthorID;
    if (!receiverUserId) {
      const recipeDoc = await db.collection("recipes").doc(recipeId).get();
      receiverUserId = recipeDoc.data()?.authorID;
    }
    if (!receiverUserId) return;

    await revokeXP({
      eventId: `LIKE_RECEIVED:${actorUserId}:${recipeId}`,
      receiverUserId,
      xpAmount: XP.LIKE_RECEIVED,
    });
    await revokeXP({
      eventId: `SAVE_RECEIVED:${actorUserId}:${recipeId}`,
      receiverUserId,
      xpAmount: XP.SAVE_RECEIVED,
    });
    await revokeXP({
      eventId: `RECIPE_SAVED:${actorUserId}:${recipeId}`,
      receiverUserId: actorUserId,
      xpAmount: XP.RECIPE_SAVED,
    });
  }
);

exports.onFollowCreatedAwardXP = onDocumentCreated(
  {
    document: "follows/{followId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const actorUserId = data.followerID;
    const receiverUserId = data.followingID;
    if (!actorUserId || !receiverUserId || actorUserId === receiverUserId) return;

    await awardXP({
      eventId: `FOLLOWER_GAINED:${actorUserId}:${receiverUserId}`,
      receiverUserId,
      actorUserId,
      eventType: "FOLLOWER_GAINED",
      targetId: receiverUserId,
      xpAmount: XP.FOLLOWER_GAINED,
    });
    await awardXP({
      eventId: `USER_FOLLOWED:${actorUserId}:${receiverUserId}`,
      receiverUserId: actorUserId,
      actorUserId,
      eventType: "USER_FOLLOWED",
      targetId: receiverUserId,
      xpAmount: XP.USER_FOLLOWED,
    });

    const userDoc = await db.collection("users").doc(receiverUserId).get();
    const followerCount = Number(userDoc.data()?.followerCount || 0);
    await maybeAwardMilestonesForFollowers(receiverUserId, followerCount);
  }
);

exports.onFollowDeletedRevokeXP = onDocumentDeleted(
  {
    document: "follows/{followId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const actorUserId = data.followerID;
    const receiverUserId = data.followingID;
    if (!actorUserId || !receiverUserId) return;

    await revokeXP({
      eventId: `FOLLOWER_GAINED:${actorUserId}:${receiverUserId}`,
      receiverUserId,
      xpAmount: XP.FOLLOWER_GAINED,
    });
    await revokeXP({
      eventId: `USER_FOLLOWED:${actorUserId}:${receiverUserId}`,
      receiverUserId: actorUserId,
      xpAmount: XP.USER_FOLLOWED,
    });
  }
);

exports.onRecipeCommentCreatedAwardXP = onDocumentCreated(
  {
    document: "recipeComments/{commentId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const actorUserId = data.userID;
    const recipeId = data.recipeID;
    const content = (data.content || "").trim();
    if (!actorUserId || !recipeId || content.length < 20) return;

    const recipeDoc = await db.collection("recipes").doc(recipeId).get();
    const receiverUserId = recipeDoc.data()?.authorID;
    if (!receiverUserId || receiverUserId === actorUserId) return;

    await awardXP({
      eventId: `COMMENT_RECEIVED:${actorUserId}:${recipeId}`,
      receiverUserId,
      actorUserId,
      eventType: "COMMENT_RECEIVED",
      targetId: recipeId,
      xpAmount: XP.COMMENT_RECEIVED,
    });
    await awardXP({
      eventId: `COMMENT_WRITTEN:${actorUserId}:${recipeId}`,
      receiverUserId: actorUserId,
      actorUserId,
      eventType: "COMMENT_WRITTEN",
      targetId: recipeId,
      xpAmount: XP.COMMENT_WRITTEN,
    });
    await awardXP({
      eventId: `MILESTONE:FIRST_COMMENT_RECEIVED:${receiverUserId}`,
      receiverUserId,
      actorUserId: "system",
      eventType: "FIRST_COMMENT_RECEIVED",
      targetId: receiverUserId,
      xpAmount: XP.FIRST_COMMENT_RECEIVED,
    });
  }
);

exports.onRecipeCreatedAwardXP = onDocumentCreated(
  {
    document: "recipes/{recipeId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const recipeId = event.params.recipeId;
    const userId = data.authorID;
    if (!userId || !recipeId) return;

    await awardXP({
      eventId: `RECIPE_PUBLISHED:${userId}:${recipeId}`,
      receiverUserId: userId,
      actorUserId: userId,
      eventType: "RECIPE_PUBLISHED",
      targetId: recipeId,
      xpAmount: XP.RECIPE_PUBLISHED,
    });

    const imageURLs = Array.isArray(data.imageURLs) ? data.imageURLs : [];
    if (imageURLs.length > 0 || data.imageURL) {
      await awardXP({
        eventId: `MAIN_PHOTO_ADDED:${userId}:${recipeId}`,
        receiverUserId: userId,
        actorUserId: userId,
        eventType: "MAIN_PHOTO_ADDED",
        targetId: recipeId,
        xpAmount: XP.MAIN_PHOTO_ADDED,
      });
    }

    // Intentionally no publish-time XP for step photos, video, full-recipe, or nutrition.
    // These bonuses are currently not applicable to Misoto XP progression.

    const userDoc = await db.collection("users").doc(userId).get();
    const recipeCount = Number(userDoc.data()?.recipeCount || 0);
    await maybeAwardMilestonesForRecipes(userId, recipeCount);
  }
);

exports.onRecipeDeletedRevokeXP = onDocumentDeleted(
  {
    document: "recipes/{recipeId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const recipeId = event.params.recipeId;
    const userId = data.authorID;
    if (!userId || !recipeId) return;

    await revokeXP({
      eventId: `RECIPE_PUBLISHED:${userId}:${recipeId}`,
      receiverUserId: userId,
      xpAmount: XP.RECIPE_PUBLISHED,
    });
    await revokeXP({
      eventId: `MAIN_PHOTO_ADDED:${userId}:${recipeId}`,
      receiverUserId: userId,
      xpAmount: XP.MAIN_PHOTO_ADDED,
    });
  }
);

exports.onRecipeWriteSyncAlgolia = onDocumentWritten(
  {
    document: "recipes/{recipeId}",
    region: REGION,
    retry: true,
    secrets: [algoliaAppIdSecret, algoliaAdminApiKeySecret, algoliaIndexNameSecret],
  },
  async (event) => {
    const recipeId = event.params.recipeId;
    if (!recipeId) return;

    const afterData = event.data?.after?.data();
    if (!afterData) {
      await algoliaDeleteObject(recipeId);
      logger.info("Deleted recipe from Algolia index.", { recipeId });
      return;
    }

    const searchObject = buildRecipeSearchObject(recipeId, afterData);
    await algoliaSaveObject(searchObject);
    logger.info("Synced recipe to Algolia index.", {
      recipeId,
      indexName: process.env.ALGOLIA_INDEX_NAME || "recipes",
    });
  }
);

exports.backfillRecipesToAlgolia = onRequest(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [
      algoliaAppIdSecret,
      algoliaAdminApiKeySecret,
      algoliaIndexNameSecret,
      searchBackfillAdminKeySecret,
    ],
  },
  async (req, res) => {
    const configuredAdminKey = process.env.SEARCH_BACKFILL_ADMIN_KEY;
    const providedKey = req.get("x-admin-key");
    if (!configuredAdminKey || providedKey !== configuredAdminKey) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const limit = 200;
    let lastDoc = null;
    let synced = 0;

    while (true) {
      let query = db.collection("recipes")
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(limit);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      for (const doc of snapshot.docs) {
        const searchObject = buildRecipeSearchObject(doc.id, doc.data() || {});
        await algoliaSaveObject(searchObject);
        synced += 1;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.docs.length < limit) break;
    }

    res.json({
      success: true,
      synced,
      indexName: process.env.ALGOLIA_INDEX_NAME || "recipes",
    });
  }
);

// --- Authenticated HTTPS proxies (secrets never ship in the iOS client) ---

exports.openaiChatCompletions = onCall(
  withAppCheck({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [openaiApiKeySecret],
  }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const usageType = request.data?.usageType;
    if (typeof usageType !== "string" || (usageType !== "description" && usageType !== "imageExtraction")) {
      throw new HttpsError(
        "invalid-argument",
        "usageType must be \"description\" or \"imageExtraction\"."
      );
    }
    const openaiRequest = request.data?.openaiRequest;
    let sanitizedRequest;
    try {
      sanitizedRequest = aiSecurity.sanitizeOpenAIRequest(openaiRequest);
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      throw new HttpsError("invalid-argument", "openaiRequest object required.");
    }

    await aiSecurity.assertAIQuotaAndIncrement(uid, usageType);

    let payloadStr;
    try {
      payloadStr = JSON.stringify(sanitizedRequest);
    } catch (e) {
      throw new HttpsError("invalid-argument", "openaiRequest must be JSON-serializable.");
    }
    if (payloadStr.length > 9 * 1024 * 1024) {
      throw new HttpsError("invalid-argument", "Request too large.");
    }
    const apiKey = openaiApiKeySecret.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "OPENAI_API_KEY secret is not configured.");
    }
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: payloadStr,
    });
    const body = await r.text();
    return { status: r.status, body };
  }
);

const IMAGE_EDIT_BASE_PROMPT = `You are a professional food-photography retoucher. Return ONE polished version of this dish photo, ready for a cookbook, recipe app, or social-media grid. No text, borders, watermarks, or extra graphics—only the enhanced photograph.

1. Framing
• Center the main bowl/plate with even breathing room.
• Zoom out slightly so the dish sits a little farther from the camera, with more space around the plate or bowl—avoid tight close-up framing.
• Default output: square (1:1). Keep the whole dish visible; no awkward crop.
• Unless instructed otherwise, use 1:1 for Misoto recipe cards.

2. Lighting & Color
• Brighten exposure and set a clean, neutral white balance (remove yellow/blue cast).
• Boost contrast moderately so highlights pop and shadows deepen.
• Gently enrich key food colors (greens, reds, yolks, sauces) while staying natural.

3. Texture & Clarity
• Sharpen the food itself—sauces glossy, grains distinct, herbs crisp.
• Preserve soft depth-of-field so background props remain subtle.

4. Background & Distractions
• Remove or blur UI elements, on-screen text, harsh reflections, crumbs, or stains.
• Keep backdrop minimal: light marble, warm wood, or neutral slate—whichever suits the dish best.

5. Authenticity
• Do not distort portion sizes or ingredient shapes.
• Keep existing garnishes; add gentle steam only if it looks realistic.

6. Deliverable
• Output only the final enhanced food photograph—realistic photography, not illustration.`;

const IMAGE_EDIT_PRESET_APPEND = Object.freeze({
  recipeApp: "Style override: clean recipe-app grid look; neutral bright backdrop (light marble or soft white); minimal props.",
  modernPatisserie: "Style override: modern patisserie; smooth bakery polish; refined plating; light marble or studio white background.",
  rusticComfort: "Style override: rustic comfort cookbook; warm wood or homestyle surface; cozy natural light.",
  minimalist: "Style override: minimalist Scandinavian; very clean white or pale marble; extremely uncluttered.",
  celebration: "Style override: celebration-friendly; keep festive elements tidy and photo-ready.",
  premiumDessert: "Style override: premium dessert book; glossy patisserie finish; elegant highlights.",
  familyCookbook: "Style override: family cookbook warmth; authentic home-baked feel; approachable not overly styled.",
  foodBlog: "Style override: modern food blog; slightly editorial color pop; appetizing and realistic.",
});

function buildImageEditPrompt(presetId) {
  const append = IMAGE_EDIT_PRESET_APPEND[presetId] || IMAGE_EDIT_PRESET_APPEND.recipeApp;
  return `${IMAGE_EDIT_BASE_PROMPT}\n\n${append}`;
}

exports.openaiImageEdit = onCall(
  withAppCheck({
    region: REGION,
    timeoutSeconds: 180,
    memory: "1GiB",
    secrets: [openaiApiKeySecret],
  }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    await aiSecurity.assertAIQuotaAndIncrement(request.auth.uid, "imageEdit");

    const imageBase64 = request.data?.imageBase64;
    const presetId = request.data?.presetId;
    const mimeTypeRaw = request.data?.mimeType;
    if (!imageBase64 || typeof imageBase64 !== "string") {
      throw new HttpsError("invalid-argument", "imageBase64 string required.");
    }
    if (!presetId || typeof presetId !== "string" || !IMAGE_EDIT_PRESET_APPEND[presetId]) {
      throw new HttpsError("invalid-argument", "Unknown or missing presetId.");
    }
    const mimeType = mimeTypeRaw === "image/png" ? "image/png" : "image/jpeg";
    const fileName = mimeType === "image/png" ? "image.png" : "image.jpg";
    // Callable request limit is ~10 MB JSON; base64 expands ~4/3 vs raw bytes.
    if (imageBase64.length > 9 * 1024 * 1024) {
      throw new HttpsError(
        "invalid-argument",
        "Image payload too large. Use a smaller photo or try again after updating the app."
      );
    }

    let imageBuffer;
    try {
      imageBuffer = Buffer.from(imageBase64, "base64");
    } catch (e) {
      throw new HttpsError("invalid-argument", "imageBase64 must be valid base64.");
    }
    if (!imageBuffer.length) {
      throw new HttpsError("invalid-argument", "Empty image data.");
    }
    const maxDecodedBytes = 6 * 1024 * 1024;
    if (imageBuffer.length > maxDecodedBytes) {
      throw new HttpsError(
        "invalid-argument",
        "Image file too large after upload. The app should compress automatically—please update and retry."
      );
    }

    const apiKey = openaiApiKeySecret.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "OPENAI_API_KEY secret is not configured.");
    }

    const prompt = buildImageEditPrompt(presetId);
    const form = new FormData();
    const blob = new Blob([imageBuffer], { type: mimeType });
    form.append("image", blob, fileName);
    form.append("prompt", prompt);
    form.append("model", "gpt-image-1");
    form.append("size", "1024x1024");
    form.append("n", "1");

    logger.info("openaiImageEdit", { uid: request.auth.uid, presetId, bytes: imageBuffer.length });

    const r = await fetch("https://api.openai.com/v1/images/edits", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}` },
      body: form,
    });
    const body = await r.text();
    return { status: r.status, body };
  }
);

exports.syncPremiumSubscription = onCall(
  withAppCheck({
    region: REGION,
    secrets: appStoreVerification.APP_STORE_SECRETS,
  }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    return aiSecurity.syncPremiumSubscriptionFromClient(request.auth.uid, request.data || {});
  }
);

exports.ensureSubscriptionRecord = onCall(
  withAppCheck({ region: REGION }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    await aiSecurity.ensureFreeSubscriptionRecord(request.auth.uid);
    const hasPremium = await aiSecurity.isPremiumUser(request.auth.uid);
    return { hasPremium };
  }
);

exports.usdaFoodsSearchProxy = onCall(
  withAppCheck({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [usdaApiKeySecret],
  }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    await aiSecurity.assertRateLimit(request.auth.uid);

    const query = request.data?.query;
    const dataTypes = request.data?.dataTypes;
    const pageSize = Math.min(Math.max(Number(request.data?.pageSize) || 10, 1), 50);
    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new HttpsError("invalid-argument", "query required.");
    }
    if (query.length > 200) {
      throw new HttpsError("invalid-argument", "query too long.");
    }
    const apiKey = usdaApiKeySecret.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "USDA_API_KEY secret is not configured.");
    }
    const encoded = encodeURIComponent(query);
    let url = `https://api.nal.usda.gov/fdc/v1/foods/search?query=${encoded}&pageSize=${pageSize}&api_key=${encodeURIComponent(apiKey)}`;
    if (dataTypes && typeof dataTypes === "string") {
      url += `&dataType=${encodeURIComponent(dataTypes)}`;
    }
    const r = await fetch(url);
    const body = await r.text();
    return { status: r.status, body };
  }
);

exports.algoliaRecipeSearchProxy = onCall(
  withAppCheck({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [algoliaAppIdSecret, algoliaAdminApiKeySecret, algoliaIndexNameSecret],
  }),
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    await aiSecurity.assertRateLimit(request.auth.uid);

    const query = request.data?.query;
    const limit = Math.min(Math.max(Number(request.data?.limit) || 20, 1), 100);
    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new HttpsError("invalid-argument", "query required.");
    }
    if (query.length > 200) {
      throw new HttpsError("invalid-argument", "query too long.");
    }
    const appId = algoliaAppIdSecret.value();
    const adminKey = algoliaAdminApiKeySecret.value();
    const indexName = (algoliaIndexNameSecret.value() || "recipes").trim();
    const pathIndex = encodeURIComponent(indexName);
    const url = `https://${appId}-dsn.algolia.net/1/indexes/${pathIndex}/query`;
    const r = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Algolia-Application-Id": appId,
        "X-Algolia-API-Key": adminKey,
      },
      body: JSON.stringify({
        query: query.trim(),
        hitsPerPage: limit,
        attributesToRetrieve: ["objectID", "id"],
        typoTolerance: true,
        removeStopWords: true,
        advancedSyntax: true,
      }),
    });
    const body = await r.text();
    return { status: r.status, body };
  }
);

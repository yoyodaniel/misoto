/**
 * Server-side AI quotas, rate limits, and OpenAI request sanitization.
 * Client-side checks are UX only; enforcement happens here.
 */

const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const FREE_TIER_LIMITS = Object.freeze({
  aiDescription: 3,
  aiImageExtraction: 5,
  aiImageEdit: 3,
});

const ALLOWED_CHAT_MODELS = new Set([
  "gpt-4o-mini",
  "gpt-4o",
  "gpt-4.1-mini",
  "gpt-4.1",
  "gpt-3.5-turbo",
]);

const ALLOWED_USAGE_TYPES = new Set(["description", "imageExtraction", "imageEdit"]);

const PREMIUM_PRODUCT_IDS = new Set([
  "com.misoto.premium.monthly",
  "com.misoto.premium.yearly",
]);

const MAX_REQUESTS_PER_MINUTE = 12;

function monthKeyUtc() {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

function usageFieldForType(usageType) {
  switch (usageType) {
    case "description":
      return "aiDescriptionCount";
    case "imageExtraction":
      return "aiImageExtractionCount";
    case "imageEdit":
      return "aiImageEditCount";
    default:
      return null;
  }
}

function limitForUsageType(usageType) {
  switch (usageType) {
    case "description":
      return FREE_TIER_LIMITS.aiDescription;
    case "imageExtraction":
      return FREE_TIER_LIMITS.aiImageExtraction;
    case "imageEdit":
      return FREE_TIER_LIMITS.aiImageEdit;
    default:
      return 0;
  }
}

async function isPremiumUser(uid) {
  const snap = await admin.firestore().collection("subscriptions").doc(uid).get();
  if (!snap.exists) {
    return false;
  }
  const data = snap.data() || {};
  if (data.tier !== "premium" || data.isActive === false) {
    return false;
  }
  const expiresAt = data.expiresAt?.toDate?.();
  if (!expiresAt) {
    return false;
  }
  return expiresAt > new Date();
}

async function assertRateLimit(uid) {
  const minute = Math.floor(Date.now() / 60000);
  const ref = admin.firestore().collection("aiRateLimits").doc(uid);

  await admin.firestore().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const data = doc.data() || {};
    if (data.minute === minute && (data.count || 0) >= MAX_REQUESTS_PER_MINUTE) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many AI requests. Please wait a moment and try again."
      );
    }
    const nextCount = data.minute === minute ? (data.count || 0) + 1 : 1;
    tx.set(
      ref,
      {
        minute,
        count: nextCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

/**
 * Atomically checks free-tier quota and increments usage before calling OpenAI.
 */
async function assertAIQuotaAndIncrement(uid, usageType) {
  if (!ALLOWED_USAGE_TYPES.has(usageType)) {
    throw new HttpsError("invalid-argument", "Invalid usageType.");
  }

  await assertRateLimit(uid);

  if (await isPremiumUser(uid)) {
    return;
  }

  const field = usageFieldForType(usageType);
  const limit = limitForUsageType(usageType);
  const month = monthKeyUtc();
  const userRef = admin.firestore().collection("users").doc(uid);

  await admin.firestore().runTransaction(async (tx) => {
    const doc = await tx.get(userRef);
    const usage = doc.data()?.usage || {};
    const bucket = usage[field] || {};
    const count = Number(bucket[month] || 0);
    if (count >= limit) {
      const message =
        usageType === "imageEdit"
          ? "You have reached your free tier limit for AI photo enhancements this month."
          : usageType === "imageExtraction"
            ? "You have reached your free tier limit for AI image extractions this month."
            : "You have reached your free tier limit for AI features this month.";
      throw new HttpsError("resource-exhausted", message);
    }
    tx.set(
      userRef,
      {
        [`usage.${field}.${month}`]: count + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

function sanitizeOpenAIRequest(openaiRequest) {
  if (!openaiRequest || typeof openaiRequest !== "object" || Array.isArray(openaiRequest)) {
    throw new HttpsError("invalid-argument", "openaiRequest object required.");
  }

  const model = openaiRequest.model;
  if (typeof model !== "string" || !ALLOWED_CHAT_MODELS.has(model)) {
    throw new HttpsError("invalid-argument", "Unsupported or missing model.");
  }

  if (!Array.isArray(openaiRequest.messages) || openaiRequest.messages.length === 0) {
    throw new HttpsError("invalid-argument", "messages array required.");
  }

  const sanitized = { ...openaiRequest };
  sanitized.max_tokens = Math.min(
    typeof sanitized.max_tokens === "number" ? sanitized.max_tokens : 8192,
    8192
  );
  if (typeof sanitized.temperature === "number") {
    sanitized.temperature = Math.min(Math.max(sanitized.temperature, 0), 1);
  }

  return sanitized;
}

async function writeSubscription(uid, payload) {
  const ref = admin.firestore().collection("subscriptions").doc(uid);
  await ref.set(
    {
      ...payload,
      id: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function setUserPremiumFlag(uid, isPremium) {
  await admin.firestore().collection("users").doc(uid).set(
    { premiumUser: isPremium, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );
}

const appStoreVerification = require("./appStoreVerification");

/**
 * Writes subscription state after App Store Server API verification.
 */
async function syncPremiumSubscriptionFromClient(uid, data) {
  const tier = data?.tier;
  if (tier !== "free" && tier !== "premium") {
    throw new HttpsError("invalid-argument", "Invalid tier.");
  }

  if (tier === "free") {
    await writeSubscription(uid, {
      tier: "free",
      isActive: true,
      expiresAt: admin.firestore.FieldValue.delete(),
      productID: admin.firestore.FieldValue.delete(),
      transactionID: admin.firestore.FieldValue.delete(),
    });
    await setUserPremiumFlag(uid, false);
    return { tier: "free", hasPremium: false };
  }

  const productID = data?.productID;
  const transactionID = data?.transactionID;

  if (typeof productID !== "string" || !PREMIUM_PRODUCT_IDS.has(productID)) {
    throw new HttpsError("invalid-argument", "Invalid productID.");
  }
  if (typeof transactionID !== "string" || transactionID.length < 4) {
    throw new HttpsError("invalid-argument", "Invalid transactionID.");
  }

  const verified = await appStoreVerification.verifyPremiumPurchase({
    transactionId: transactionID,
    productId: productID,
    allowedProductIds: PREMIUM_PRODUCT_IDS,
  });

  await writeSubscription(uid, {
    tier: "premium",
    isActive: true,
    expiresAt: admin.firestore.Timestamp.fromDate(verified.expiresAt),
    productID: verified.productId,
    transactionID: verified.transactionId,
    appStoreEnvironment: verified.environment,
    purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await setUserPremiumFlag(uid, true);

  return {
    tier: "premium",
    hasPremium: true,
    expiresAtMs: verified.expiresAt.getTime(),
  };
}

async function ensureFreeSubscriptionRecord(uid) {
  const ref = admin.firestore().collection("subscriptions").doc(uid);
  const snap = await ref.get();
  if (snap.exists) {
    return;
  }
  await writeSubscription(uid, {
    tier: "free",
    isActive: true,
  });
  await setUserPremiumFlag(uid, false);
}

module.exports = {
  FREE_TIER_LIMITS,
  PREMIUM_PRODUCT_IDS,
  assertAIQuotaAndIncrement,
  assertRateLimit,
  sanitizeOpenAIRequest,
  isPremiumUser,
  syncPremiumSubscriptionFromClient,
  ensureFreeSubscriptionRecord,
};

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const REGION = "us-central1";

const algoliaAppIdSecret = defineSecret("ALGOLIA_APP_ID");
const algoliaAdminApiKeySecret = defineSecret("ALGOLIA_ADMIN_API_KEY");
const algoliaIndexNameSecret = defineSecret("ALGOLIA_INDEX_NAME");
const searchBackfillAdminKeySecret = defineSecret("SEARCH_BACKFILL_ADMIN_KEY");

// MARK: - Helpers

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

// MARK: - Functions

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

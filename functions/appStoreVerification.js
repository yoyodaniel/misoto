/**
 * Verifies premium purchases via Apple's App Store Server API.
 *
 * Required secrets (Firebase Functions):
 * - APP_STORE_ISSUER_ID
 * - APP_STORE_KEY_ID
 * - APP_STORE_PRIVATE_KEY  (contents of the .p8 key, newlines allowed)
 * - APP_STORE_BUNDLE_ID    (e.g. com.miniadd.Misoto)
 * Optional:
 * - APP_STORE_ENVIRONMENT  "Production" | "Sandbox" (default Production)
 */

const { HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
} = require("@apple/app-store-server-library");
const fs = require("fs");
const path = require("path");

const appStoreIssuerIdSecret = defineSecret("APP_STORE_ISSUER_ID");
const appStoreKeyIdSecret = defineSecret("APP_STORE_KEY_ID");
const appStorePrivateKeySecret = defineSecret("APP_STORE_PRIVATE_KEY");
const appStoreBundleIdSecret = defineSecret("APP_STORE_BUNDLE_ID");
const APP_STORE_SECRETS = [
  appStoreIssuerIdSecret,
  appStoreKeyIdSecret,
  appStorePrivateKeySecret,
  appStoreBundleIdSecret,
];

let cachedVerifier = null;
let cachedClient = null;
let cachedEnvironment = null;

function readSecretValue(secretParam) {
  try {
    return secretParam.value()?.trim() || "";
  } catch {
    return "";
  }
}

function isConfigured() {
  const issuerId = readSecretValue(appStoreIssuerIdSecret);
  const keyId = readSecretValue(appStoreKeyIdSecret);
  const privateKey = readSecretValue(appStorePrivateKeySecret);
  const bundleId = readSecretValue(appStoreBundleIdSecret);
  return Boolean(issuerId && keyId && privateKey && bundleId);
}

function resolveEnvironment() {
  const raw = process.env.APP_STORE_ENVIRONMENT || "Production";
  return String(raw).toLowerCase() === "sandbox" ? Environment.SANDBOX : Environment.PRODUCTION;
}

function loadAppleRootCertificates() {
  const certsDir = path.join(__dirname, "certs", "apple");
  const files = ["AppleRootCA-G3.cer", "AppleIncRootCertificate.cer"];
  return files.map((fileName) => fs.readFileSync(path.join(certsDir, fileName)));
}

function getClient() {
  if (cachedClient) {
    return cachedClient;
  }
  const privateKey = readSecretValue(appStorePrivateKeySecret).replace(/\\n/g, "\n");
  cachedClient = new AppStoreServerAPIClient(
    privateKey,
    readSecretValue(appStoreKeyIdSecret),
    readSecretValue(appStoreIssuerIdSecret),
    readSecretValue(appStoreBundleIdSecret),
    resolveEnvironment()
  );
  cachedEnvironment = resolveEnvironment();
  return cachedClient;
}

function getVerifier() {
  if (cachedVerifier) {
    return cachedVerifier;
  }
  const bundleId = readSecretValue(appStoreBundleIdSecret);
  const environment = resolveEnvironment();
  cachedVerifier = new SignedDataVerifier(
    loadAppleRootCertificates(),
    true,
    environment,
    bundleId
  );
  cachedEnvironment = environment;
  return cachedVerifier;
}

/**
 * @param {{ transactionId: string, productId: string, allowedProductIds: Set<string> }} input
 * @returns {Promise<{ productId: string, transactionId: string, expiresAt: Date, environment: string }>}
 */
async function verifyPremiumPurchase({ transactionId, productId, allowedProductIds }) {
  if (!isConfigured()) {
    throw new HttpsError(
      "failed-precondition",
      "App Store verification is not configured on the server. Add APP_STORE_* secrets before enabling premium sync."
    );
  }

  if (!allowedProductIds.has(productId)) {
    throw new HttpsError("invalid-argument", "Invalid productID.");
  }

  const normalizedTransactionId = String(transactionId).trim();
  if (!normalizedTransactionId) {
    throw new HttpsError("invalid-argument", "Invalid transactionID.");
  }

  const client = getClient();
  const verifier = getVerifier();

  let signedTransactionInfo;
  try {
    const response = await client.getTransactionInfo(normalizedTransactionId);
    signedTransactionInfo = response?.signedTransactionInfo;
  } catch (error) {
    throw new HttpsError(
      "failed-precondition",
      "Could not verify transaction with the App Store. Check Sandbox vs Production environment."
    );
  }

  if (!signedTransactionInfo) {
    throw new HttpsError("failed-precondition", "App Store returned no transaction payload.");
  }

  let decoded;
  try {
    decoded = await verifier.verifyAndDecodeTransaction(signedTransactionInfo);
  } catch (error) {
    throw new HttpsError("permission-denied", "Transaction signature verification failed.");
  }

  const decodedProductId = decoded.productId;
  if (decodedProductId !== productId) {
    throw new HttpsError("permission-denied", "Transaction product does not match purchase.");
  }

  if (!decoded.expiresDate) {
    throw new HttpsError("failed-precondition", "Subscription transaction has no expiry date.");
  }

  const expiresAt = new Date(decoded.expiresDate);
  if (expiresAt <= new Date()) {
    throw new HttpsError("failed-precondition", "Subscription is expired.");
  }

  return {
    productId: decodedProductId,
    transactionId: String(decoded.transactionId || normalizedTransactionId),
    expiresAt,
    environment: cachedEnvironment === Environment.SANDBOX ? "Sandbox" : "Production",
  };
}

module.exports = {
  APP_STORE_SECRETS,
  isConfigured,
  verifyPremiumPurchase,
};

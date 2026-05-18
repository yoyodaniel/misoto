/**
 * App Check enforcement for client-callable HTTPS functions.
 * Set ENFORCE_APP_CHECK=false only for local emulator debugging.
 */

const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK !== "false";

function withAppCheck(options = {}) {
  if (!ENFORCE_APP_CHECK) {
    return options;
  }
  return {
    ...options,
    enforceAppCheck: true,
  };
}

module.exports = {
  withAppCheck,
  ENFORCE_APP_CHECK,
};

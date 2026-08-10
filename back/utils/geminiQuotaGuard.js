/**
 * geminiQuotaGuard.js
 * -------------------
 * Simple in-memory daily Gemini call counter.
 *
 * Free-tier hard limit (gemini-2.0-flash): 1 500 req/day.
 * We stop at 80 % (1 200 calls) to leave headroom for other endpoints
 * and avoid ever hard-failing due to a quota exhaustion.
 *
 * The counter resets automatically at the start of a new calendar day
 * (Pacific Time — Google's quota day boundary).  Using local server
 * midnight is a close-enough approximation; the 20 % safety margin
 * absorbs any small timezone drift.
 *
 * Usage:
 *   const quota = require('./geminiQuotaGuard');
 *   if (quota.isAvailable()) {
 *     quota.record();          // increment before the call
 *     // … await model.generateContent(…)
 *   } else {
 *     // go straight to local fallback
 *   }
 */

const DAILY_FREE_LIMIT  = 1_500;   // Gemini 2.0-flash free-tier RPD
const SAFETY_THRESHOLD  = 0.80;    // stop at 80 % of the limit
const SOFT_CAP          = Math.floor(DAILY_FREE_LIMIT * SAFETY_THRESHOLD); // 1 200

let _count     = 0;
let _resetDate = _todayKey();      // "YYYY-MM-DD"

/** Returns "YYYY-MM-DD" for today (local date). */
function _todayKey() {
  return new Date().toISOString().slice(0, 10);
}

/** Auto-reset the counter when the calendar day rolls over. */
function _maybeReset() {
  const today = _todayKey();
  if (today !== _resetDate) {
    _count     = 0;
    _resetDate = today;
  }
}

/** Returns true if we are still below the soft cap. */
function isAvailable() {
  _maybeReset();
  return _count < SOFT_CAP;
}

/** Increment the counter (call BEFORE the Gemini request). */
function record() {
  _maybeReset();
  _count += 1;
  if (_count === SOFT_CAP) {
    console.warn(
      `[geminiQuotaGuard] ⚠️  Daily soft cap reached (${SOFT_CAP}/${DAILY_FREE_LIMIT} calls). ` +
      `Switching all AI features to local fallback until midnight.`
    );
  }
}

/** Expose counters for monitoring / test assertions. */
function stats() {
  _maybeReset();
  return { count: _count, softCap: SOFT_CAP, hardLimit: DAILY_FREE_LIMIT, date: _resetDate };
}

module.exports = { isAvailable, record, stats };

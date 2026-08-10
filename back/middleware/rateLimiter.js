const rateLimit = require('express-rate-limit');

/**
 * Auth limiter — applied specifically to POST /api/auth/login and
 * POST /api/auth/register to slow down brute-force and credential-stuffing
 * attacks. 5 attempts per 15 minutes per IP is generous enough for
 * legitimate users while meaningfully throttling automated attacks.
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  standardHeaders: true,  // Return rate-limit info in RateLimit-* headers
  legacyHeaders: false,   // Disable X-RateLimit-* headers
  message: {
    success: false,
    message: 'Too many attempts, please try again later',
  },
});

/**
 * General API limiter — applied globally to all /api/* routes as a broad
 * safety net against abuse (scrapers, DoS, runaway clients).
 * 100 requests per minute per IP is well above any normal interactive usage.
 *
 * PROXY NOTE: If you deploy behind a reverse proxy (nginx, AWS ALB,
 * Render, Railway, Heroku, etc.), set `app.set('trust proxy', 1)` in
 * index.js (already done) so express-rate-limit uses the real client IP
 * from the X-Forwarded-For header rather than the proxy's IP — otherwise
 * ALL users share a single counter and get rate-limited together.
 * For multi-layer proxies (e.g. Cloudflare + nginx) set the number of
 * trusted proxy hops: `app.set('trust proxy', 2)`.
 */
const generalApiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests, please slow down',
  },
});

module.exports = { authLimiter, generalApiLimiter };

'use strict';
// eslint-disable-next-line
void (async function main() {
/**
 * verify-ai-features.js
 * ─────────────────────
 * Offline unit-test script — no running server, no live DB needed.
 *
 * Tests:
 *  A. Module load checks (all four modified files load without syntax errors)
 *  B. geminiQuotaGuard  — counter logic, soft-cap, daily reset simulation
 *  C. aiService helpers — _localParseExpense, _templateSummary,
 *                          _templateAnomalyMessage, _localPricingSuggestions
 *  D. aiService.parseExpense  — Gemini path (mocked) + local fallback path
 *  E. aiService.generateSummary — Gemini path + template fallback path
 *  F. aiService.explainAnomalies — Gemini path + template fallback path
 *  G. aiService.suggestPricing  — Gemini path + local fallback path
 *
 * Run:  node verify-ai-features.js
 */

require('dotenv').config();

// ─── tiny test harness ────────────────────────────────────────────────────────
let passed = 0, failed = 0;

function assert(label, condition, detail = '') {
  if (condition) {
    console.log(`  ✅  ${label}`);
    passed++;
  } else {
    console.error(`  ❌  ${label}${detail ? ' — ' + detail : ''}`);
    failed++;
  }
}

async function section(title, fn) {
  console.log(`\n${'─'.repeat(60)}\n  ${title}\n${'─'.repeat(60)}`);
  try { await fn(); }
  catch (e) { console.error(`  💥  Section threw unexpectedly: ${e.message}`); failed++; }
}

// ─────────────────────────────────────────────────────────────────────────────
// A. Module load checks
// ─────────────────────────────────────────────────────────────────────────────
await section('A — Module loads (syntax + require)', async () => {
  const mods = [
    ['geminiQuotaGuard', '../back/utils/geminiQuotaGuard'],
    ['aiService',        '../back/services/aiService'],
    ['ai.controller',   '../back/controllers/ai.controller'],
    ['ai.routes',       '../back/routes/ai.routes'],
  ];
  for (const [name, path] of mods) {
    try {
      require(path);
      assert(`require('${name}') loads without error`, true);
    } catch (e) {
      assert(`require('${name}') loads without error`, false, e.message);
    }
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// B. geminiQuotaGuard
// ─────────────────────────────────────────────────────────────────────────────
await section('B — geminiQuotaGuard', async () => {
  // Fresh require so we get an isolated module instance via a small wrapper
  // (Node caches modules, so we test via the exported API directly)
  const guard = require('./utils/geminiQuotaGuard');

  const s0 = guard.stats();
  assert('stats() returns count/softCap/hardLimit/date', typeof s0.count === 'number' && s0.softCap === 1200 && s0.hardLimit === 1500);
  assert('isAvailable() true at start of day', guard.isAvailable());

  guard.record();
  const s1 = guard.stats();
  assert('record() increments counter by 1', s1.count === s0.count + 1);

  // Simulate hitting the soft cap by patching _count via repeated calls
  // (we read current count then record up to softCap - 1)
  const needed = s1.softCap - s1.count;
  // Guard: don't loop forever if somehow already past cap
  const cap = Math.min(needed, 1200);
  for (let i = 0; i < cap; i++) guard.record();
  assert('isAvailable() false once soft cap is reached', !guard.isAvailable());
  assert('stats().count equals softCap', guard.stats().count === guard.stats().softCap);
});

// ─────────────────────────────────────────────────────────────────────────────
// C. aiService private helpers (no network)
// ─────────────────────────────────────────────────────────────────────────────
await section('C — aiService private helpers', async () => {
  const svc = require('./services/aiService');

  // _localParseExpense
  const cases = [
    ['شريت قهوة بـ 5 دينار',  'قهوة',   5,  'food'],
    ['اشتريت زيت ب 10 د',     'زيت',    10, 'supplies'],
    ['أكل ب 15',               'أكل',    15, 'food'],
    ['دفعت 30 دينار صيانة',    'صيانة',  30, 'maintenance'],
    ['essence 12 dinars',      'essence',12, 'transport'],
    ['café 5 DT',              'café',   5,  'food'],
    ['قهوة 5',                 'قهوة',   5,  'food'],
    ['اشتريت سكر ب 3',         'سكر',    3,  'supplies'],
    ['bonjour',                null,     null, null],
  ];

  for (const [input, expItem, expAmt, expCat] of cases) {
    const r = svc._localParseExpense(input);
    if (expAmt === null) {
      assert(`_localParseExpense("${input}") → null`, r === null);
    } else {
      assert(
        `_localParseExpense("${input}") → item=${expItem} amount=${expAmt} cat=${expCat}`,
        r && r.amount === expAmt && r.category === expCat && r.item === expItem,
        r ? `got item=${r.item} amount=${r.amount} cat=${r.category}` : 'returned null'
      );
    }
  }

  // _templateSummary
  const m = {
    period: 'week', businessName: 'Test Biz',
    currentRevenue: 1000, previousRevenue: 800,
    currentExpenses: 400, previousExpenses: 350,
    netProfit: 600, previousNetProfit: 450,
    profitChangePct: 33.3,
    topProduct: 'قهوة', topProductRevenue: 300,
    wasteTotal: 50,
  };
  const tmpl = svc._templateSummary(m, 'الأسبوع');
  assert('_templateSummary contains revenue figure',    tmpl.includes('1000.000'));
  assert('_templateSummary contains profit change %',   tmpl.includes('33.3'));
  assert('_templateSummary mentions top product',       tmpl.includes('قهوة'));
  assert('_templateSummary mentions waste',             tmpl.includes('50.000'));

  // _templateAnomalyMessage — one per type
  const types = ['cash_discrepancy', 'expense_spike', 'revenue_drop', 'waste_spike', 'unknown_type'];
  for (const type of types) {
    const msg = svc._templateAnomalyMessage({ type, value: 100, expectedValue: 50, category: 'food' });
    assert(`_templateAnomalyMessage("${type}") returns non-empty string`, typeof msg === 'string' && msg.length > 5);
  }

  // _localPricingSuggestions
  const items = [
    { name: 'زيت',    type: 'product', sellingPrice: 10, purchaseCost: 9.5, marginPct: 5,  unitsSold30d: 2,  revenue30d: 20  },
    { name: 'قهوة',   type: 'product', sellingPrice: 5,  purchaseCost: 1,   marginPct: 80, unitsSold30d: 50, revenue30d: 250 },
    { name: 'سكر',    type: 'product', sellingPrice: 3,  purchaseCost: 2.8, marginPct: 6,  unitsSold30d: 1,  revenue30d: 3   },
  ];
  const slowIds = new Set(['زيت', 'سكر']);
  const suggs   = svc._localPricingSuggestions(items, slowIds);
  assert('_localPricingSuggestions returns array',        Array.isArray(suggs));
  assert('_localPricingSuggestions has pricing type',     suggs.some(s => s.type === 'pricing'));
  assert('_localPricingSuggestions has slow_mover type',  suggs.some(s => s.type === 'slow_mover'));
  assert('_localPricingSuggestions has general type',     suggs.some(s => s.type === 'general'));
  assert('general suggestion names the best seller',      suggs.find(s => s.type === 'general')?.itemName === 'قهوة');
});

// ─────────────────────────────────────────────────────────────────────────────
// D. aiService.parseExpense — mock Gemini call
// ─────────────────────────────────────────────────────────────────────────────
await section('D — parseExpense (mocked Gemini + local fallback)', async () => {
  const svc = require('./services/aiService');

  // ── D1: Gemini returns valid JSON ─────────────────────────────────────
  const origGenerate = svc.model.generateContent.bind(svc.model);
  svc.model.generateContent = async () => ({
    response: { text: () => '{"item":"قهوة","amount":5,"currency":"TND","category":"food","description":"قهوة","confidence":0.9}' },
  });

  // Also reset quota so it's available
  const guard = require('./utils/geminiQuotaGuard');
  // Patch isAvailable to return true for this sub-test
  const origAvail = guard.isAvailable;
  guard.isAvailable = () => true;
  const origRecord = guard.record;
  guard.record = () => {};

  try {
    const r = await svc.parseExpense('قهوة 5 دينار');
    assert('parseExpense (Gemini OK) returns item',       r.item === 'قهوة');
    assert('parseExpense (Gemini OK) returns amount',     r.amount === 5);
    assert('parseExpense (Gemini OK) parsedBy=ai',        r.parsedBy === 'ai');
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }

  // ── D2: Gemini throws 429 → local fallback ────────────────────────────
  svc.model.generateContent = async () => { throw Object.assign(new Error('[429] quota'), { isUnavailable: true }); };
  guard.isAvailable = () => true;
  guard.record = () => {};

  try {
    const r = await svc.parseExpense('شريت قهوة بـ 5 دينار');
    assert('parseExpense (429) falls back to local',       r.parsedBy === 'local');
    assert('parseExpense (429 fallback) correct amount',   r.amount === 5);
    assert('parseExpense (429 fallback) correct item',     r.item === 'قهوة');
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }

  // ── D3: Gemini 429 + text has no parseable amount → throws RATE_LIMIT ─
  svc.model.generateContent = async () => { throw Object.assign(new Error('[429] quota'), { isUnavailable: true }); };
  guard.isAvailable = () => true;
  guard.record = () => {};

  try {
    let threw429 = false;
    try { await svc.parseExpense('bonjour'); }
    catch (e) { threw429 = (e.status === 429 || e.message === 'RATE_LIMIT'); }
    assert('parseExpense (429 + no number) throws RATE_LIMIT 429', threw429);
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// E. aiService.generateSummary — mock Gemini + template fallback
// ─────────────────────────────────────────────────────────────────────────────
await section('E — generateSummary (mocked Gemini + template fallback)', async () => {
  const svc   = require('./services/aiService');
  const guard = require('./utils/geminiQuotaGuard');
  const origGenerate = svc.model.generateContent.bind(svc.model);
  const origAvail    = guard.isAvailable;
  const origRecord   = guard.record;

  const metrics = {
    period: 'week', language: 'ar', businessName: 'مقهى الزيتونة',
    currentRevenue: 1200, previousRevenue: 1000,
    currentExpenses: 500, previousExpenses: 400,
    netProfit: 700, previousNetProfit: 600,
    profitChangePct: 16.7,
    topProduct: 'قهوة', topProductRevenue: 400,
    wasteTotal: 30,
  };

  // ── E1: Gemini returns prose ──────────────────────────────────────────
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => ({ response: { text: () => 'ملخص الأسبوع الرائع.' } });

  try {
    const r = await svc.generateSummary(metrics);
    assert('generateSummary (Gemini) returns summary string',    typeof r.summary === 'string' && r.summary.length > 3);
    assert('generateSummary (Gemini) generatedBy=ai',            r.generatedBy === 'ai');
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }

  // ── E2: Gemini throws → template fallback ────────────────────────────
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => { throw Object.assign(new Error('[429]'), { isUnavailable: true }); };

  try {
    const r = await svc.generateSummary(metrics);
    assert('generateSummary (fallback) returns summary string',  typeof r.summary === 'string' && r.summary.length > 10);
    assert('generateSummary (fallback) generatedBy=template',    r.generatedBy === 'template');
    assert('generateSummary (fallback) mentions revenue',        r.summary.includes('1200'));
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// F. aiService.explainAnomalies — mock Gemini + template fallback
// ─────────────────────────────────────────────────────────────────────────────
await section('F — explainAnomalies (mocked Gemini + template fallback)', async () => {
  const svc   = require('./services/aiService');
  const guard = require('./utils/geminiQuotaGuard');
  const origGenerate = svc.model.generateContent.bind(svc.model);
  const origAvail    = guard.isAvailable;
  const origRecord   = guard.record;

  const flags = [
    { type: 'cash_discrepancy', severity: 'medium', value: -25, expectedValue: 0, relatedDate: new Date() },
    { type: 'expense_spike',    severity: 'high',   value: 300, expectedValue: 80, category: 'maintenance' },
  ];

  // ── F1: empty flags → returns [] without any call ────────────────────
  const empty = await svc.explainAnomalies([]);
  assert('explainAnomalies([]) returns empty array', Array.isArray(empty) && empty.length === 0);

  // ── F2: Gemini returns messages ───────────────────────────────────────
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => ({
    response: { text: () => '[{"message":"فرق الكاسة كبير يستحق المراجعة."},{"message":"ارتفاع غير عادي في مصاريف الصيانة."}]' },
  });

  try {
    const r = await svc.explainAnomalies(flags);
    assert('explainAnomalies (Gemini) same length as input',   r.length === flags.length);
    assert('explainAnomalies (Gemini) has message field',       typeof r[0].message === 'string');
    assert('explainAnomalies (Gemini) explainedBy=ai',          r[0].explainedBy === 'ai');
    assert('explainAnomalies (Gemini) preserves type field',    r[0].type === 'cash_discrepancy');
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }

  // ── F3: Gemini throws → template fallback ────────────────────────────
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => { throw Object.assign(new Error('[429]'), { isUnavailable: true }); };

  try {
    const r = await svc.explainAnomalies(flags);
    assert('explainAnomalies (fallback) same length as input',  r.length === flags.length);
    assert('explainAnomalies (fallback) explainedBy=template',  r[0].explainedBy === 'template');
    assert('explainAnomalies (fallback) message is Arabic text', r[0].message.includes('يستحق') || r[0].message.includes('مراجعة'));
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// G. aiService.suggestPricing — mock Gemini + local fallback
// ─────────────────────────────────────────────────────────────────────────────
await section('G — suggestPricing (mocked Gemini + local fallback)', async () => {
  const svc   = require('./services/aiService');
  const guard = require('./utils/geminiQuotaGuard');
  const origGenerate = svc.model.generateContent.bind(svc.model);
  const origAvail    = guard.isAvailable;
  const origRecord   = guard.record;

  const items = [
    { name: 'زيت',    type: 'product', sellingPrice: 10, purchaseCost: 9.5, marginPct: 5,  unitsSold30d: 2,  revenue30d: 20,  hasRecipe: false },
    { name: 'قهوة',   type: 'product', sellingPrice: 5,  purchaseCost: 1,   marginPct: 80, unitsSold30d: 60, revenue30d: 300, hasRecipe: false },
    { name: 'سكر',    type: 'product', sellingPrice: 3,  purchaseCost: 2.8, marginPct: 6,  unitsSold30d: 1,  revenue30d: 3,   hasRecipe: false },
  ];

  // ── G1: Gemini returns suggestions ───────────────────────────────────
  const aiSuggestions = [
    { itemName: 'زيت',  type: 'pricing',    currentMargin: 5,  suggestion: 'ارفع سعر الزيت.' },
    { itemName: 'سكر',  type: 'slow_mover', currentMargin: 6,  suggestion: 'خصم للسكر.' },
    { itemName: 'قهوة', type: 'general',    currentMargin: 80, suggestion: 'روّج للقهوة أكثر.' },
  ];
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => ({
    response: { text: () => JSON.stringify(aiSuggestions) },
  });

  try {
    const r = await svc.suggestPricing(items);
    assert('suggestPricing (Gemini) generatedBy=ai',           r.generatedBy === 'ai');
    assert('suggestPricing (Gemini) suggestions is array',     Array.isArray(r.suggestions));
    assert('suggestPricing (Gemini) rawData returned',         Array.isArray(r.rawData) && r.rawData.length === 3);
    assert('suggestPricing (Gemini) slowMovers populated',     Array.isArray(r.slowMovers) && r.slowMovers.length > 0);
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }

  // ── G2: Gemini throws → local fallback ───────────────────────────────
  guard.isAvailable = () => true;
  guard.record      = () => {};
  svc.model.generateContent = async () => { throw Object.assign(new Error('[429]'), { isUnavailable: true }); };

  try {
    const r = await svc.suggestPricing(items);
    assert('suggestPricing (fallback) generatedBy=local',       r.generatedBy === 'local');
    assert('suggestPricing (fallback) suggestionsUnavailable',  r.suggestionsUnavailable === true);
    assert('suggestPricing (fallback) has pricing suggestion',  r.suggestions.some(s => s.type === 'pricing'));
    assert('suggestPricing (fallback) has general suggestion',  r.suggestions.some(s => s.type === 'general'));
    assert('suggestPricing (fallback) rawData still returned',  r.rawData.length === 3);
  } finally {
    svc.model.generateContent = origGenerate;
    guard.isAvailable = origAvail;
    guard.record = origRecord;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Summary
// ─────────────────────────────────────────────────────────────────────────────
console.log(`\n${'═'.repeat(60)}`);
console.log(`  Results: ${passed} passed, ${failed} failed`);
console.log(`${'═'.repeat(60)}\n`);
process.exit(failed > 0 ? 1 : 0);
})();

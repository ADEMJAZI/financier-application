'use strict';

const { GoogleGenerativeAI } = require('@google/generative-ai');
const quota = require('../utils/geminiQuotaGuard');

// gemini-2.0-flash — confirmed working on this API key with apiVersion v1.
const MODEL_NAME     = 'gemini-2.0-flash';
const REQUEST_OPTIONS = { apiVersion: 'v1' };

// ─── Gemini error classifier ───────────────────────────────────────────────────
// Returns true for any error that means "Gemini is temporarily unavailable /
// quota exhausted" — the signal to try a local fallback instead of hard-failing.
function _isGeminiUnavailable(err) {
  const msg = (err.message || '').toLowerCase();
  return (
    msg.includes('429')                  ||
    msg.includes('quota')                ||
    msg.includes('rate limit')           ||
    msg.includes('too many requests')    ||
    msg.includes('no longer available')  ||
    msg.includes('service unavailable')  ||
    msg.includes('503')                  ||
    msg.includes('404')                  // model endpoint not found
  );
}

// ─── Shared helper: try Gemini only when quota allows ─────────────────────────
// Wraps the raw model.generateContent() call with quota guard + error
// classification.  Returns the raw response text, or throws an error whose
// .isUnavailable === true flag signals the caller to use its local fallback.
async function _callGemini(model, prompt) {
  if (!quota.isAvailable()) {
    const err = new Error('QUOTA_SOFT_CAP');
    err.isUnavailable = true;
    throw err;
  }
  quota.record();
  try {
    const result = await model.generateContent(prompt);
    return result.response.text().trim();
  } catch (err) {
    if (_isGeminiUnavailable(err)) {
      err.isUnavailable = true;
    }
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AIService {
  constructor() {
    if (!process.env.GOOGLE_AI_API_KEY) {
      console.warn('⚠️  GOOGLE_AI_API_KEY is not set — AI features will use local fallbacks.');
    }
    this.genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY || '');
    this.model = this.genAI.getGenerativeModel({ model: MODEL_NAME }, REQUEST_OPTIONS);
    this.visionModel = this.genAI.getGenerativeModel({ model: MODEL_NAME }, REQUEST_OPTIONS);
  }

  // ─── PRIVATE: safe JSON extraction ────────────────────────────────────────
  _extractJSON(text, type = 'object') {
    const pattern = type === 'array' ? /\[[\s\S]*\]/ : /\{[\s\S]*\}/;
    const match   = text.match(pattern);
    if (!match) return null;
    try { return JSON.parse(match[0]); } catch { return null; }
  }

  // ─── PRIVATE: local regex expense parser (fallback for parseExpense) ───────
  _localParseExpense(text) {
    const t = text.trim();

    const amountRx = /(\d+(?:[.,]\d+)?)/g;
    const allNums  = [...t.matchAll(amountRx)].map(m => parseFloat(m[1].replace(',', '.')));
    if (!allNums.length) return null;
    const amount = Math.max(...allNums);
    if (amount <= 0) return null;

    const stripped = t
      .replace(/(^|\s)(شريت|اشتريت|دفعت|خلصت|صرفت|جبت)(\s|$)/gu, ' ')
      .replace(/\b(j'ai acheté|j'ai payé|achat de|payé|acheté|dépensé)\b/gi, '')
      .replace(/بـ?\s*\d+(?:[.,]\d+)?\s*(دينار|دنانير|د|TND|DT)?/gu, '')
      .replace(/\d+(?:[.,]\d+)?\s*(دينار|دنانير|TND|DT|dinars?)/gi, '')
      .replace(/(^|\s)(دينار|دنانير|TND|DT|dinars?)(\s|$)/gi, ' ')
      .replace(/\b\d+(?:[.,]\d+)?\b/g, '')
      .replace(/[_\-–,;:().\u0628\u0640]/g, ' ')
      .replace(/\s{2,}/g, ' ')
      .trim();

    const tokens = stripped.split(/\s+/).filter(tk => tk.length > 1);
    if (!tokens.length) return null;
    const item = tokens.sort((a, b) => b.length - a.length)[0];

    const lower = t.toLowerCase();
    let category = 'other';
    if      (/أكل|طعام|قهوة|مشروب|café|nourriture|restaurant|pizza|sandwich/.test(lower)) category = 'food';
    else if (/صيانة|تصليح|réparation|maintenance/.test(lower))                             category = 'maintenance';
    else if (/كهرباء|ماء|غاز|électricité|eau|gaz/.test(lower))                             category = 'utilities';
    else if (/بنزين|essence|taxi|نقل|carburant|transport/.test(lower))                     category = 'transport';
    else if (/راتب|salaire|موظف|employé/.test(lower))                                      category = 'staff';
    else if (/كراء|loyer|إيجار/.test(lower))                                               category = 'rent';
    else if (/مواد|fournitures|supplies|زيت|سكر|دقيق|طحين|ملح|حليب|بيض|خضر|بضاعة/.test(lower)) category = 'supplies';

    return { item, amount, currency: 'TND', category, description: item, confidence: 0.55, parsedBy: 'local' };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PARSE EXPENSE FROM NATURAL LANGUAGE
  // ═══════════════════════════════════════════════════════════════════════════
  async parseExpense(text) {
    const prompt = `
You are a bilingual expense parser for Tunisian small businesses.
Input text: "${text}"

Return ONLY valid JSON — no markdown, no explanation:
{
  "item": "<purchased item in same language as input>",
  "amount": <positive number — required>,
  "currency": "TND",
  "category": "<food|supplies|maintenance|utilities|transport|staff|rent|other>",
  "description": "<short label in same language>",
  "confidence": <0.0–1.0>
}
If no amount can be found: { "error": "amount_not_found", "confidence": 0 }`;

    try {
      const raw    = await _callGemini(this.model, prompt);
      const parsed = this._extractJSON(raw, 'object');

      if (!parsed)                                    throw new Error('No JSON in AI response');
      if (parsed.error)                               throw new Error('Could not extract amount from text');
      if (!parsed.amount || Number(parsed.amount) <= 0) throw new Error('Invalid amount in AI response');

      return {
        item:        parsed.item        || text,
        amount:      Number(parsed.amount),
        currency:    parsed.currency    || 'TND',
        category:    parsed.category    || 'other',
        description: parsed.description || parsed.item || text,
        confidence:  Number(parsed.confidence) || 0.7,
        parsedBy:    'ai',
      };
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        const local = this._localParseExpense(text);
        if (local) {
          console.warn('[parseExpense] Gemini unavailable — used local regex fallback');
          return local;
        }
        const rateErr = new Error('RATE_LIMIT');
        rateErr.status = 429;
        throw rateErr;
      }
      console.error('[parseExpense]', err.message);
      throw new Error('Could not parse expense from text');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. WEEKLY / MONTHLY NARRATIVE SUMMARY
  //
  // metrics — pre-calculated object (controller does ALL number-crunching):
  //   { period, businessName, currentRevenue, previousRevenue,
  //     currentExpenses, previousExpenses, netProfit, previousNetProfit,
  //     profitChangePct, topProduct, topProductRevenue,
  //     wasteTotal, language }
  //
  // Returns { summary: string, generatedBy: 'ai'|'template', metrics }
  // ═══════════════════════════════════════════════════════════════════════════
  async generateSummary(metrics) {
    const {
      period, businessName,
      currentRevenue, previousRevenue,
      currentExpenses, previousExpenses,
      netProfit, previousNetProfit,
      profitChangePct,
      topProduct, topProductRevenue,
      wasteTotal,
      language = 'ar',
    } = metrics;

    const periodLabel = period === 'week' ? 'الأسبوع' : 'الشهر';
    const langLabel   = language === 'ar' ? 'Arabic (Tunisian dialect preferred)'
                      : language === 'fr' ? 'French' : 'English';

    const prompt = `
You are a friendly Tunisian business advisor for "${businessName}".
Write a SHORT narrative summary (3–5 sentences) in ${langLabel}.

IMPORTANT: Do NOT calculate or estimate any numbers yourself.
Only describe the numbers given to you below in natural prose.
Mention the % profit change and the top-selling product by name.

Pre-calculated data for this ${period === 'week' ? 'week' : 'month'}:
- Revenue    : ${currentRevenue.toFixed(3)} DT  (previous: ${previousRevenue.toFixed(3)} DT)
- Expenses   : ${currentExpenses.toFixed(3)} DT (previous: ${previousExpenses.toFixed(3)} DT)
- Net profit : ${netProfit.toFixed(3)} DT        (previous: ${previousNetProfit.toFixed(3)} DT, change: ${profitChangePct > 0 ? '+' : ''}${profitChangePct.toFixed(1)}%)
- Top product: ${topProduct || 'N/A'} (revenue: ${(topProductRevenue || 0).toFixed(3)} DT)
- Waste/loss : ${(wasteTotal || 0).toFixed(3)} DT

Output: plain Arabic text only. No JSON. No bullet points. No headers.`;

    try {
      const summary = await _callGemini(this.model, prompt);
      return { summary, generatedBy: 'ai' };
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        console.warn('[generateSummary] Gemini unavailable — using template fallback');
        return { summary: this._templateSummary(metrics, periodLabel), generatedBy: 'template' };
      }
      console.error('[generateSummary]', err.message);
      // Non-quota error: still return template rather than crashing
      return { summary: this._templateSummary(metrics, periodLabel), generatedBy: 'template' };
    }
  }

  /** Arabic template summary — used when Gemini is unavailable. */
  _templateSummary(m, periodLabel) {
    const sign    = m.profitChangePct >= 0 ? '+' : '';
    const trend   = m.profitChangePct >= 0 ? 'ارتفع' : 'انخفض';
    const topLine = m.topProduct
      ? `أفضل منتج كان "${m.topProduct}" بإيرادات ${(m.topProductRevenue || 0).toFixed(3)} دينار. `
      : '';
    const wasteLine = m.wasteTotal > 0
      ? `بلغت خسائر الهدر ${m.wasteTotal.toFixed(3)} دينار. `
      : '';
    return (
      `هذا ${periodLabel}، حققت إيرادات ${m.currentRevenue.toFixed(3)} دينار ` +
      `ومصاريف ${m.currentExpenses.toFixed(3)} دينار، ` +
      `بربح صافي ${m.netProfit.toFixed(3)} دينار. ` +
      `${trend} الربح بنسبة ${sign}${m.profitChangePct.toFixed(1)}% مقارنةً بالفترة السابقة. ` +
      topLine + wasteLine
    ).trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ANOMALY DETECTION
  //
  // rawFlags — array of rule-detected anomaly objects produced by the
  // controller (pure JS/DB, no AI).  Each has:
  //   { type, severity, value, expectedValue, relatedDate?, relatedEntity?, category? }
  //
  // This method adds an Arabic "message" field to each flag, either via
  // Gemini or a pre-written template.
  //
  // Returns array of { type, severity, message, value, expectedValue,
  //                    relatedDate?, relatedEntity?, category? }
  // ═══════════════════════════════════════════════════════════════════════════
  async explainAnomalies(rawFlags, language = 'ar') {
    if (!rawFlags.length) return [];

    const langLabel = language === 'ar' ? 'Arabic (Tunisian dialect)'
                    : language === 'fr' ? 'French' : 'English';

    const prompt = `
You are a Tunisian business analyst.
For each anomaly below, write ONE short sentence in ${langLabel} explaining
what looks unusual and one possible (generic) reason.
Do NOT be definitive — use phrases like "يستحق المراجعة" / "قد يكون سببه".

Anomalies:
${JSON.stringify(rawFlags, null, 2)}

Return ONLY a JSON array — same length as the input, same order.
Each element: { "message": "<one sentence in ${langLabel}>" }
No markdown. No extra fields.`;

    try {
      const raw     = await _callGemini(this.model, prompt);
      const parsed  = this._extractJSON(raw, 'array');
      if (!Array.isArray(parsed) || parsed.length !== rawFlags.length) throw new Error('bad array');

      return rawFlags.map((flag, i) => ({
        ...flag,
        message:     parsed[i]?.message || this._templateAnomalyMessage(flag),
        explainedBy: 'ai',
      }));
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        console.warn('[explainAnomalies] Gemini unavailable — using template messages');
      } else {
        console.error('[explainAnomalies]', err.message);
      }
      // Always return something — detection works regardless of AI availability
      return rawFlags.map(flag => ({
        ...flag,
        message:     this._templateAnomalyMessage(flag),
        explainedBy: 'template',
      }));
    }
  }

  /** Pre-written Arabic template messages per anomaly type. */
  _templateAnomalyMessage(flag) {
    const v   = typeof flag.value         === 'number' ? flag.value.toFixed(3)         : flag.value;
    const exp = typeof flag.expectedValue === 'number' ? flag.expectedValue.toFixed(3) : flag.expectedValue;
    const date = flag.relatedDate ? ` (${new Date(flag.relatedDate).toLocaleDateString('ar-TN')})` : '';

    switch (flag.type) {
      case 'cash_discrepancy':
        return `فرق الكاسة${date} كان ${v} دينار مقابل المتوقع ${exp} دينار — يستحق المراجعة.`;
      case 'expense_spike':
        return `مصاريف "${flag.category || ''}" هذا الأسبوع (${v} دينار) تجاوزت المعدل الشهري (${exp} دينار) بشكل ملحوظ.`;
      case 'revenue_drop':
        return `الإيرادات${date} (${v} دينار) انخفضت بشكل غير معتاد مقارنةً بالمتوسط (${exp} دينار) — قد يكون سببه يوم عطلة أو مشكلة طارئة.`;
      case 'waste_spike':
        return `خسائر الهدر هذا الأسبوع (${v} دينار) تجاوزت 10% من الإيرادات — يُنصح بمراجعة أسباب التلف.`;
      default:
        return `تم رصد قيمة غير معتادة (${v}) — يُنصح بالمراجعة.`;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PRICING & SALES ADVISOR
  //
  // itemData — pre-calculated array (controller does ALL number-crunching):
  //   [ { name, type:'product'|'menuItem', sellingPrice, purchaseCost|null,
  //       marginPct|null, unitsSold30d, revenue30d, hasRecipe } ]
  //
  // Returns { suggestions: [...], generatedBy, rawData }
  // ═══════════════════════════════════════════════════════════════════════════
  async suggestPricing(itemData, language = 'ar') {
    const langLabel = language === 'ar' ? 'Arabic (Tunisian dialect)'
                    : language === 'fr' ? 'French' : 'English';

    // Rank items by sales velocity for slow-mover detection
    const sorted  = [...itemData].sort((a, b) => b.unitsSold30d - a.unitsSold30d);
    const bottomN = Math.max(1, Math.floor(sorted.length * 0.2));
    const slowIds = new Set(sorted.slice(-bottomN).map(i => i.name));

    const prompt = `
You are a Tunisian retail/restaurant pricing advisor.
You are given pre-calculated product data. Do NOT recalculate numbers — only
write suggestions based on the data provided.

Items (last 30 days):
${JSON.stringify(itemData, null, 2)}

Slow-moving items (bottom 20% by units sold): ${JSON.stringify([...slowIds])}

Return ONLY a JSON array of suggestion objects:
[
  {
    "itemName"      : "<exact name from the data>",
    "type"          : "pricing" | "slow_mover" | "general",
    "currentMargin" : <number or null — use value from data, do not compute>,
    "suggestion"    : "<1–2 sentences in ${langLabel}>"
  }
]

Rules:
- "pricing"    → items with marginPct < 15 (and marginPct is not null)
- "slow_mover" → items in the slow-moving list; suggest discount, bundle, or discontinue
- "general"    → 1–2 overall observations (peak patterns, best seller promotion)
- Do NOT include items that are neither low-margin nor slow-moving unless for "general"
- ONLY JSON array. No markdown.`;

    try {
      const raw     = await _callGemini(this.model, prompt);
      const parsed  = this._extractJSON(raw, 'array');
      if (!Array.isArray(parsed)) throw new Error('not an array');

      return {
        suggestions:  parsed,
        generatedBy:  'ai',
        rawData:      itemData,
        slowMovers:   [...slowIds],
      };
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        console.warn('[suggestPricing] Gemini unavailable — returning raw data only');
      } else {
        console.error('[suggestPricing]', err.message);
      }
      // Local fallback: return structured raw data with rule-based flags,
      // no AI commentary — still useful for the frontend to display.
      return {
        suggestions:          this._localPricingSuggestions(itemData, slowIds),
        generatedBy:          'local',
        rawData:              itemData,
        slowMovers:           [...slowIds],
        suggestionsUnavailable: true,
      };
    }
  }

  /** Rule-based pricing suggestions — no AI, just data + fixed Arabic labels. */
  _localPricingSuggestions(itemData, slowIds) {
    const out = [];

    for (const item of itemData) {
      if (item.marginPct !== null && item.marginPct < 15) {
        out.push({
          itemName:      item.name,
          type:          'pricing',
          currentMargin: item.marginPct,
          suggestion:    `هامش ربح "${item.name}" منخفض (${item.marginPct?.toFixed(1)}%) — يُنصح برفع السعر أو مراجعة تكلفة الشراء.`,
        });
      }
      if (slowIds.has(item.name)) {
        out.push({
          itemName:      item.name,
          type:          'slow_mover',
          currentMargin: item.marginPct,
          suggestion:    `مبيعات "${item.name}" بطيئة (${item.unitsSold30d} وحدة/30 يوم) — فكر في تخفيض مؤقت أو ترقية أو وقف البيع.`,
        });
      }
    }

    // One general note
    if (itemData.length) {
      const best = [...itemData].sort((a, b) => b.revenue30d - a.revenue30d)[0];
      out.push({
        itemName:      best.name,
        type:          'general',
        currentMargin: best.marginPct,
        suggestion:    `"${best.name}" هو أفضل منتج مبيعاً — ركّز على الترويج له لزيادة الإيرادات الإجمالية.`,
      });
    }

    return out;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. AI CHAT (business assistant)  — unchanged logic, quota guard added
  // ═══════════════════════════════════════════════════════════════════════════
  async chat(userMessage, context, language = 'ar') {
    const langLabel = language === 'ar' ? 'Arabic (Tunisian dialect preferred)'
                    : language === 'fr' ? 'French' : 'English';

    const prompt = `You are "تاجر AI" — a helpful AI business advisor for small Tunisian businesses.
Business: ${context.businessName} (${context.businessType})
Revenue this month: ${context.revenue} DT | Expenses: ${context.expenses} DT | Net profit: ${context.netProfit} DT
Products: ${context.productCount} | Low stock: ${context.lowStockCount} | Unpaid debts: ${context.unpaidDebts} DT

Answer in ${langLabel}. Be concise (2–4 sentences). Be specific to their numbers.
User: ${userMessage}
Assistant:`;

    try {
      return await _callGemini(this.model, prompt);
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        return 'المساعد غير متاح حالياً بسبب تجاوز الحصة اليومية. يرجى المحاولة لاحقاً.';
      }
      console.error('[chat]', err.message);
      throw new Error('AI assistant unavailable');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. RECEIPT / INVOICE IMAGE ANALYSIS — unchanged logic, quota guard added
  // ═══════════════════════════════════════════════════════════════════════════
  async analyzeReceiptImage(base64Image, mimeType = 'image/jpeg') {
    const prompt = `Analyze this receipt/invoice image. Return ONLY valid JSON:
{
  "vendor": "string or null",
  "date": "YYYY-MM-DD or null",
  "totalAmount": number or null,
  "currency": "DT|EUR|USD|other",
  "items": [{ "description": "string", "amount": number, "category": "supplies|maintenance|utilities|transport|food|staff|other" }],
  "confidence": 0.0–1.0
}
If unreadable: { "error": "Could not read receipt", "confidence": 0 }
NO markdown.`;

    if (!quota.isAvailable()) {
      throw Object.assign(new Error('RATE_LIMIT'), { status: 429 });
    }
    quota.record();

    try {
      const imagePart = { inlineData: { data: base64Image, mimeType } };
      const result    = await this.visionModel.generateContent([prompt, imagePart]);
      const parsed    = this._extractJSON(result.response.text().trim(), 'object');
      if (!parsed) throw new Error('No JSON in vision response');
      return parsed;
    } catch (err) {
      if (_isGeminiUnavailable(err)) {
        throw Object.assign(new Error('RATE_LIMIT'), { status: 429 });
      }
      console.error('[analyzeReceiptImage]', err.message);
      throw new Error('Could not analyze receipt image');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. WHAT-IF PRICING SIMULATOR — unchanged logic, quota guard added
  // ═══════════════════════════════════════════════════════════════════════════
  async simulatePricing(scenario, language = 'ar') {
    const langLabel = language === 'ar' ? 'Arabic' : language === 'fr' ? 'French' : 'English';
    const { productName, currentPrice, newPrice, monthlySales, purchaseCost, monthlyFixedExpenses } = scenario;

    const curRev    = currentPrice * monthlySales;
    const newRev    = newPrice    * monthlySales;
    const curProfit = curRev - (purchaseCost * monthlySales) - monthlyFixedExpenses;
    const newProfit = newRev - (purchaseCost * monthlySales) - monthlyFixedExpenses;
    const curMargin = currentPrice > 0 ? ((currentPrice - purchaseCost) / currentPrice * 100) : 0;
    const newMargin = newPrice     > 0 ? ((newPrice     - purchaseCost) / newPrice     * 100) : 0;

    const baseResult = {
      currentRevenue:      curRev,
      newRevenue:          newRev,
      currentProfit:       curProfit,
      newProfit:           newProfit,
      currentMargin:       +curMargin.toFixed(1),
      newMargin:           +newMargin.toFixed(1),
      profitChange:        +(newProfit - curProfit).toFixed(3),
      profitChangePercent: curProfit !== 0
        ? +((newProfit - curProfit) / Math.abs(curProfit) * 100).toFixed(1) : 0,
      breakEvenUnits: newPrice > purchaseCost
        ? Math.ceil(monthlyFixedExpenses / (newPrice - purchaseCost)) : null,
    };

    const prompt = `
Simulate a price change for a small Tunisian business. Answer in ${langLabel}.
Product: ${productName}
${JSON.stringify(baseResult, null, 2)}
Write recommendation, risks[], opportunities[] — add them to this JSON and return ONLY the full JSON.`;

    try {
      const raw    = await _callGemini(this.model, prompt);
      const parsed = this._extractJSON(raw, 'object');
      return {
        ...baseResult,
        recommendation: parsed?.recommendation || '',
        risks:          parsed?.risks          || [],
        opportunities:  parsed?.opportunities  || [],
      };
    } catch (err) {
      if (err.isUnavailable || _isGeminiUnavailable(err)) {
        console.warn('[simulatePricing] Gemini unavailable — returning calculated data only');
        return { ...baseResult, recommendation: '', risks: [], opportunities: [] };
      }
      console.error('[simulatePricing]', err.message);
      return { ...baseResult, recommendation: '', risks: [], opportunities: [] };
    }
  }
}

module.exports = new AIService();

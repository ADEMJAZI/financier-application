'use strict';

const mongoose   = require('mongoose');
const aiService  = require('../services/aiService');
const quota      = require('../utils/geminiQuotaGuard');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

const Expense      = require('../models/Expense');
const Sale         = require('../models/Sale');
const MenuItemSale = require('../models/MenuItemSale');
const Order        = require('../models/Order');
const Product      = require('../models/Product');
const MenuItem     = require('../models/MenuItem');
const CustomerDebt = require('../models/CustomerDebt');
const CashRegister = require('../models/CashRegister');
const Business     = require('../models/Business');
const Waste        = require('../models/Waste');

// ─── shared helpers ───────────────────────────────────────────────────────────
const toObjId = (id) => new mongoose.Types.ObjectId(id);

async function getOwnerOrFail(businessId, userId, res) {
  const ok = await verifyBusinessOwnership(businessId, userId);
  if (!ok) { res.status(404).json({ success: false, message: 'Business not found' }); return false; }
  return true;
}

function validObjId(id) {
  return id && mongoose.Types.ObjectId.isValid(id);
}

async function getTotalRevenue(bId, from, to) {
  const [saleAgg, menuAgg] = await Promise.all([
    Sale.aggregate([
      { $match: { business: bId, date: { $gte: from, $lte: to } } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } },
    ]),
    MenuItemSale.aggregate([
      { $match: { business: bId, date: { $gte: from, $lte: to } } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } },
    ]),
  ]);
  return (saleAgg[0]?.total || 0) + (menuAgg[0]?.total || 0);
}

async function getTotalExpenses(bId, from, to) {
  const agg = await Expense.aggregate([
    { $match: { business: bId, date: { $gte: from, $lte: to } } },
    { $group: { _id: null, total: { $sum: '$amount' } } },
  ]);
  return agg[0]?.total || 0;
}

// ─── In-memory result cache ───────────────────────────────────────────────────
// Keyed by "<businessId>:<cacheKey>" → { data, expiresAt }
// TTL: 3 hours for summary + pricing (slow-changing data).
// Anomalies are cheap DB queries — no cache needed there.
const _cache   = new Map();
const CACHE_TTL = 3 * 60 * 60 * 1000; // 3 h in ms

function cacheGet(key) {
  const entry = _cache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) { _cache.delete(key); return null; }
  return entry.data;
}

function cacheSet(key, data) {
  _cache.set(key, { data, expiresAt: Date.now() + CACHE_TTL });
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PARSE EXPENSE FROM TEXT — POST /api/ai/parse-expense
// ─────────────────────────────────────────────────────────────────────────────
exports.parseExpense = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || typeof text !== 'string' || !text.trim()) {
      return res.status(400).json({ success: false, message: 'text is required and must be a non-empty string' });
    }
    const data        = await aiService.parseExpense(text.trim());
    const usedFallback = data.parsedBy === 'local';
    return res.status(200).json({
      success: true,
      data,
      ...(usedFallback && { warning: 'AI indisponible — résultat extrait localement. Veuillez vérifier les détails.' }),
    });
  } catch (err) {
    if (err.status === 429 || err.message === 'RATE_LIMIT') {
      return res.status(429).json({ success: false, message: 'تم تجاوز حد الطلبات، يرجى الانتظار دقيقة والمحاولة مجدداً' });
    }
    if (err.message?.includes('Could not extract') || err.message?.includes('Invalid amount')) {
      return res.status(400).json({ success: false, message: 'لم يتمكن الذكاء الاصطناعي من استخراج مبلغ من النص. حاول مثلاً: "شريت قهوة بـ 5 دينار"' });
    }
    console.error('[parseExpense ctrl]', err.message);
    return res.status(500).json({ success: false, message: 'حدث خطأ أثناء معالجة الطلب. يرجى المحاولة مجدداً.' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. WEEKLY / MONTHLY NARRATIVE SUMMARY
//    GET /api/ai/summary/:businessId?period=week|month&language=ar
//
//    ALL numbers are computed here in JS/MongoDB.
//    aiService.generateSummary() only writes prose around them.
//    Results cached 3 h per business+period combo.
// ─────────────────────────────────────────────────────────────────────────────
exports.generateSummary = async (req, res) => {
  try {
    const { businessId }         = req.params;
    const { period = 'week', language = 'ar' } = req.query;

    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    const cacheKey = `summary:${businessId}:${period}:${language}`;
    const cached   = cacheGet(cacheKey);
    if (cached) return res.status(200).json({ success: true, data: cached, cached: true });

    const bId = toObjId(businessId);
    const now = new Date();

    // ── Date windows ──────────────────────────────────────────────────────
    let curStart, prevStart, prevEnd;
    if (period === 'week') {
      curStart  = new Date(now); curStart.setDate(now.getDate() - 7);
      prevEnd   = new Date(curStart); prevEnd.setMilliseconds(-1);
      prevStart = new Date(prevEnd); prevStart.setDate(prevEnd.getDate() - 7);
    } else {
      curStart  = new Date(now.getFullYear(), now.getMonth(), 1);
      prevEnd   = new Date(curStart); prevEnd.setMilliseconds(-1);
      prevStart = new Date(prevEnd.getFullYear(), prevEnd.getMonth(), 1);
    }

    // ── Parallel DB queries ───────────────────────────────────────────────
    const [
      curRev, prevRev, curExp, prevExp,
      topProductAgg, topMenuAgg, wasteAgg,
    ] = await Promise.all([
      getTotalRevenue(bId, curStart, now),
      getTotalRevenue(bId, prevStart, prevEnd),
      getTotalExpenses(bId, curStart, now),
      getTotalExpenses(bId, prevStart, prevEnd),
      // Top product by revenue (resale)
      Sale.aggregate([
        { $match: { business: bId, date: { $gte: curStart, $lte: now } } },
        { $group: { _id: '$product', revenue: { $sum: '$totalAmount' } } },
        { $sort: { revenue: -1 } }, { $limit: 1 },
        { $lookup: { from: 'products', localField: '_id', foreignField: '_id', as: 'p' } },
        { $unwind: { path: '$p', preserveNullAndEmptyArrays: true } },
        { $project: { name: '$p.name', revenue: 1 } },
      ]),
      // Top menu item by revenue (manufacturing)
      Order.aggregate([
        { $match: { business: bId, status: 'completed', date: { $gte: curStart, $lte: now } } },
        { $unwind: '$items' },
        { $group: { _id: '$items.menuItem', name: { $first: '$items.name' }, revenue: { $sum: '$items.subtotal' } } },
        { $sort: { revenue: -1 } }, { $limit: 1 },
      ]),
      // Waste / loss total
      Waste.aggregate([
        { $match: { business: bId, date: { $gte: curStart, $lte: now } } },
        { $group: { _id: null, total: { $sum: '$estimatedLoss' } } },
      ]),
    ]);

    // ── Pre-calculate all numbers ─────────────────────────────────────────
    const netProfit         = curRev  - curExp;
    const previousNetProfit = prevRev - prevExp;
    const profitChangePct   = previousNetProfit !== 0
      ? (netProfit - previousNetProfit) / Math.abs(previousNetProfit) * 100 : 0;

    const topProductEntry = topProductAgg[0] || topMenuAgg[0] || null;
    const topProduct      = topProductEntry?.name || null;
    const topProductRevenue = topProductEntry?.revenue || 0;
    const wasteTotal      = wasteAgg[0]?.total || 0;

    const business = await Business.findById(bId).select('name').lean();

    const metrics = {
      period, language,
      businessName: business?.name || 'Business',
      currentRevenue:     curRev,
      previousRevenue:    prevRev,
      currentExpenses:    curExp,
      previousExpenses:   prevExp,
      netProfit,
      previousNetProfit,
      profitChangePct,
      topProduct,
      topProductRevenue,
      wasteTotal,
    };

    // ── AI narrative (Gemini prose or template fallback) ──────────────────
    const { summary, generatedBy } = await aiService.generateSummary(metrics);

    const responseData = { summary, generatedBy, metrics };
    cacheSet(cacheKey, responseData);

    return res.status(200).json({ success: true, data: responseData });
  } catch (err) {
    console.error('[generateSummary ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 3. ANOMALY DETECTION
//    GET /api/ai/anomalies/:businessId?language=ar
//
//    Rule-based detection is 100% JS/MongoDB — always works.
//    Gemini only writes the human-readable message per flag.
//    No cache: queries are cheap, anomalies should always be fresh.
// ─────────────────────────────────────────────────────────────────────────────
exports.detectAnomalies = async (req, res) => {
  try {
    const { businessId }       = req.params;
    const { language = 'ar' } = req.query;

    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    const bId  = toObjId(businessId);
    const now  = new Date();
    const d7   = new Date(now); d7.setDate(now.getDate() - 7);
    const d30  = new Date(now); d30.setDate(now.getDate() - 30);
    const d37  = new Date(now); d37.setDate(now.getDate() - 37);

    // ── 4 weeks of daily revenue for weekday-baseline anomaly ────────────
    const d28 = new Date(now); d28.setDate(now.getDate() - 28);

    const [
      registers7d,
      expenses7d,
      expCatBaseline,
      wasteWeek,
      revenueWeek,
      dailyRevenue28d,
    ] = await Promise.all([
      // Rule A: cash register differences last 7 days
      CashRegister.find({
        business: bId, status: 'closed',
        date: { $gte: d7 },
        difference: { $ne: null },
      }).select('date openingBalance difference').lean(),

      // Rule B: individual expenses last 7 days
      Expense.find({ business: bId, date: { $gte: d7 } })
        .select('amount category date description').lean(),

      // Rule B baseline: per-category average over prior 30-day window
      Expense.aggregate([
        { $match: { business: bId, date: { $gte: d37, $lt: d7 } } },
        { $group: { _id: '$category', avg: { $avg: '$amount' }, total: { $sum: '$amount' }, n: { $sum: 1 } } },
      ]),

      // Rule D: waste total this week
      Waste.aggregate([
        { $match: { business: bId, date: { $gte: d7 } } },
        { $group: { _id: null, total: { $sum: '$estimatedLoss' } } },
      ]),

      // Rule D: revenue this week (reuse helper)
      getTotalRevenue(bId, d7, now),

      // Rule C: daily revenue for last 28 days grouped by day-of-week
      Sale.aggregate([
        { $match: { business: bId, date: { $gte: d28 } } },
        { $group: {
          _id: {
            dow:  { $dayOfWeek: '$date' },      // 1=Sun … 7=Sat
            date: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
          },
          dayTotal: { $sum: '$totalAmount' },
        }},
      ]),
    ]);

    const rawFlags = [];

    // ── Rule A: cash discrepancy > 15 % of opening balance ───────────────
    for (const reg of registers7d) {
      if (!reg.openingBalance || reg.openingBalance === 0) continue;
      const absDiff = Math.abs(reg.difference);
      const pct     = absDiff / reg.openingBalance * 100;
      if (pct > 15) {
        rawFlags.push({
          type:          'cash_discrepancy',
          severity:      pct > 30 ? 'high' : 'medium',
          value:         reg.difference,
          expectedValue: 0,
          relatedDate:   reg.date,
        });
      }
    }

    // ── Rule B: single expense > 3x category average ─────────────────────
    const avgByCategory = Object.fromEntries(expCatBaseline.map(c => [c._id, c.avg]));
    for (const exp of expenses7d) {
      const avg = avgByCategory[exp.category];
      if (avg && exp.amount > avg * 3) {
        rawFlags.push({
          type:          'expense_spike',
          severity:      exp.amount > avg * 5 ? 'high' : 'medium',
          value:         exp.amount,
          expectedValue: +avg.toFixed(3),
          category:      exp.category,
          relatedDate:   exp.date,
          relatedEntity: exp.description || null,
        });
      }
    }

    // ── Rule C: daily revenue drops > 40 % vs same weekday 4-week average ─
    // Build weekday averages from the 28-day history (exclude the current week)
    const dowTotals = {};   // dow → [dailyTotals]
    for (const row of dailyRevenue28d) {
      const { dow, date } = row._id;
      const rowDate = new Date(date);
      if (rowDate >= d7) continue;                 // skip current week in baseline
      if (!dowTotals[dow]) dowTotals[dow] = [];
      dowTotals[dow].push(row.dayTotal);
    }
    const dowAvg = {};
    for (const [dow, vals] of Object.entries(dowTotals)) {
      dowAvg[dow] = vals.reduce((s, v) => s + v, 0) / vals.length;
    }
    // Check each day in the current week
    for (const row of dailyRevenue28d) {
      const { dow, date } = row._id;
      const rowDate = new Date(date);
      if (rowDate < d7) continue;                  // only current week
      const avg = dowAvg[dow];
      if (avg && row.dayTotal < avg * 0.6) {       // > 40 % drop
        const dropPct = (1 - row.dayTotal / avg) * 100;
        rawFlags.push({
          type:          'revenue_drop',
          severity:      dropPct > 60 ? 'high' : 'medium',
          value:         +row.dayTotal.toFixed(3),
          expectedValue: +avg.toFixed(3),
          relatedDate:   new Date(date),
        });
      }
    }

    // ── Rule D: waste > 10 % of weekly revenue ────────────────────────────
    const wasteTotalVal = wasteWeek[0]?.total || 0;
    if (revenueWeek > 0 && wasteTotalVal / revenueWeek > 0.10) {
      rawFlags.push({
        type:          'waste_spike',
        severity:      wasteTotalVal / revenueWeek > 0.20 ? 'high' : 'medium',
        value:         +wasteTotalVal.toFixed(3),
        expectedValue: +(revenueWeek * 0.10).toFixed(3),
      });
    }

    // ── AI explanation layer (template fallback built into service) ────────
    const anomalies = await aiService.explainAnomalies(rawFlags, language);

    return res.status(200).json({
      success: true,
      data:    anomalies,
      quotaStats: quota.stats(),
    });
  } catch (err) {
    console.error('[detectAnomalies ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 4. PRICING & SALES ADVISOR
//    GET /api/ai/pricing-advice/:businessId?language=ar
//
//    Margins + velocity calculated here. Gemini writes suggestions.
//    Results cached 3 h per business.
// ─────────────────────────────────────────────────────────────────────────────
exports.pricingAdvice = async (req, res) => {
  try {
    const { businessId }       = req.params;
    const { language = 'ar' } = req.query;

    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    const cacheKey = `pricing:${businessId}:${language}`;
    const cached   = cacheGet(cacheKey);
    if (cached) return res.status(200).json({ success: true, data: cached, cached: true });

    const bId  = toObjId(businessId);
    const now  = new Date();
    const d30  = new Date(now); d30.setDate(now.getDate() - 30);

    const business = await Business.findById(bId).select('businessType').lean();
    const bType    = business?.businessType || 'resale';

    let itemData = [];

    if (bType === 'resale') {
      // ── Resale: Products + Sale velocity ────────────────────────────────
      const [products, salesAgg] = await Promise.all([
        Product.find({ business: bId, quantity: { $gte: 0 } }).lean(),
        Sale.aggregate([
          { $match: { business: bId, date: { $gte: d30 } } },
          { $group: { _id: '$product', unitsSold: { $sum: '$quantity' }, revenue: { $sum: '$totalAmount' } } },
        ]),
      ]);

      const salesMap = Object.fromEntries(salesAgg.map(s => [s._id.toString(), s]));

      itemData = products.map(p => {
        const s           = salesMap[p._id.toString()] || { unitsSold: 0, revenue: 0 };
        const marginPct   = p.price > 0
          ? +((p.price - p.purchasePrice) / p.price * 100).toFixed(2) : null;
        return {
          name:          p.name,
          type:          'product',
          sellingPrice:  p.price,
          purchaseCost:  p.purchasePrice,
          marginPct,
          unitsSold30d:  s.unitsSold  || 0,
          revenue30d:    s.revenue    || 0,
          hasRecipe:     false,
        };
      });

    } else {
      // ── Manufacturing: MenuItems + Order velocity ────────────────────────
      const [menuItems, orderAgg] = await Promise.all([
        MenuItem.find({ business: bId, isActive: true }).lean(),
        Order.aggregate([
          { $match: { business: bId, status: 'completed', date: { $gte: d30 } } },
          { $unwind: '$items' },
          { $group: {
            _id:       '$items.menuItem',
            unitsSold: { $sum: '$items.quantity' },
            revenue:   { $sum: '$items.subtotal' },
          }},
        ]),
      ]);

      const orderMap = Object.fromEntries(orderAgg.map(o => [o._id.toString(), o]));

      // For menu items with a recipe, calculate raw-material cost
      const productIds = [...new Set(
        menuItems.flatMap(m => m.recipe.map(r => r.rawMaterial.toString()))
      )];
      const productDocs = productIds.length
        ? await Product.find({ _id: { $in: productIds } }).select('purchasePrice').lean()
        : [];
      const priceMap = Object.fromEntries(productDocs.map(p => [p._id.toString(), p.purchasePrice]));

      itemData = menuItems.map(m => {
        const o        = orderMap[m._id.toString()] || { unitsSold: 0, revenue: 0 };
        const hasRecipe = m.recipe && m.recipe.length > 0;
        let purchaseCost = null;
        let marginPct    = null;

        if (hasRecipe) {
          purchaseCost = m.recipe.reduce((sum, r) => {
            const unitCost = priceMap[r.rawMaterial.toString()] || 0;
            return sum + unitCost * r.quantityRequired;
          }, 0);
          marginPct = m.sellingPrice > 0
            ? +((m.sellingPrice - purchaseCost) / m.sellingPrice * 100).toFixed(2) : null;
        }

        return {
          name:          m.name,
          type:          'menuItem',
          sellingPrice:  m.sellingPrice,
          purchaseCost:  hasRecipe ? +purchaseCost.toFixed(3) : null,
          marginPct,
          unitsSold30d:  o.unitsSold || 0,
          revenue30d:    o.revenue   || 0,
          hasRecipe,
        };
      });
    }

    if (!itemData.length) {
      return res.status(200).json({ success: true, data: { suggestions: [], rawData: [], message: 'No items found' } });
    }

    const result = await aiService.suggestPricing(itemData, language);
    cacheSet(cacheKey, result);

    return res.status(200).json({ success: true, data: result });
  } catch (err) {
    console.error('[pricingAdvice ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. AI CHAT — POST /api/ai/chat/:businessId
// ─────────────────────────────────────────────────────────────────────────────
exports.chat = async (req, res) => {
  try {
    const { businessId }           = req.params;
    const { message, language = 'ar' } = req.body;

    if (!message) return res.status(400).json({ success: false, message: 'message is required' });
    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    const bId       = toObjId(businessId);
    const now       = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [business, expenses, revenue, productCount, debts, allProducts] = await Promise.all([
      Business.findById(bId).lean(),
      getTotalExpenses(bId, monthStart, now),
      getTotalRevenue(bId, monthStart, now),
      Product.countDocuments({ business: bId }),
      CustomerDebt.find({ business: bId, status: { $ne: 'paid' } }).lean(),
      Product.find({ business: bId }).select('quantity reorderPoint').lean(),
    ]);

    const lowStockCount = allProducts.filter(p => p.quantity <= (p.reorderPoint || 0)).length;
    const unpaidDebts   = debts.reduce((s, d) => s + (d.totalAmount - d.paidAmount), 0);

    const reply = await aiService.chat(message, {
      businessName: business?.name || 'Business',
      businessType: business?.businessType || 'resale',
      revenue, expenses,
      netProfit:    revenue - expenses,
      productCount,
      lowStockCount,
      unpaidDebts,
    }, language);

    return res.status(200).json({ success: true, data: { reply } });
  } catch (err) {
    console.error('[chat ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. RECEIPT IMAGE ANALYSIS — POST /api/ai/analyze-receipt
// ─────────────────────────────────────────────────────────────────────────────
exports.analyzeReceipt = async (req, res) => {
  try {
    const { base64Image, mimeType = 'image/jpeg' } = req.body;
    if (!base64Image) return res.status(400).json({ success: false, message: 'base64Image is required' });

    const data = await aiService.analyzeReceiptImage(base64Image, mimeType);
    return res.status(200).json({ success: true, data });
  } catch (err) {
    if (err.status === 429 || err.message === 'RATE_LIMIT') {
      return res.status(429).json({ success: false, message: 'تم تجاوز حد الطلبات، يرجى المحاولة لاحقاً' });
    }
    console.error('[analyzeReceipt ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. DASHBOARD INSIGHTS — GET /api/ai/insights/:businessId
// ─────────────────────────────────────────────────────────────────────────────
exports.generateInsights = async (req, res) => {
  try {
    const { businessId }       = req.params;
    const { language = 'ar' } = req.query;

    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    // Reuse the pricing advice data to build insights instead of a separate Gemini call
    // (avoids burning quota on a near-duplicate request)
    const bId        = toObjId(businessId);
    const now        = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [expenses, revenue, products, debts] = await Promise.all([
      getTotalExpenses(bId, monthStart, now),
      getTotalRevenue(bId, monthStart, now),
      Product.find({ business: bId }).lean(),
      CustomerDebt.find({ business: bId, status: { $ne: 'paid' } }).lean(),
    ]);

    const lowStockCount = products.filter(p => p.quantity <= (p.reorderPoint || 0)).length;
    const unpaidDebts   = debts.reduce((s, d) => s + (d.totalAmount - d.paidAmount), 0);
    const netProfit     = revenue - expenses;
    const debtRatio     = revenue > 0 ? +((unpaidDebts / revenue) * 100).toFixed(1) : 0;

    // Build rule-based insights without extra AI call
    const insights = [];
    if (netProfit < 0)          insights.push({ icon: 'warning',    priority: 'high',   title: 'خسارة صافية',         description: `الخسارة الصافية هذا الشهر ${Math.abs(netProfit).toFixed(3)} دينار. راجع المصاريف الكبيرة وحاول تقليصها.` });
    if (lowStockCount > 0)      insights.push({ icon: 'inventory',  priority: 'medium', title: 'مخزون منخفض',         description: `${lowStockCount} منتج وصل لمستوى إعادة الطلب. تحقق من المخزون لتجنب نفاد البضاعة.` });
    if (debtRatio > 20)         insights.push({ icon: 'money',      priority: 'high',   title: 'ديون عالية',           description: `الديون غير المدفوعة تمثّل ${debtRatio}% من الإيرادات. تواصل مع العملاء المتأخرين.` });
    if (netProfit > 0 && debtRatio < 10 && lowStockCount === 0)
                                insights.push({ icon: 'trending_up', priority: 'low',   title: 'أداء جيد',             description: `ربح صافي ${netProfit.toFixed(3)} دينار، ديون منخفضة، مخزون كافٍ — استمر في نفس الإيقاع!` });
    if (!insights.length)       insights.push({ icon: 'lightbulb',  priority: 'low',   title: 'لا تنبيهات',           description: 'لا توجد مشاكل ملحوظة هذا الشهر. راقب المصاريف والمخزون بانتظام.' });

    return res.status(200).json({ success: true, data: insights.slice(0, 3) });
  } catch (err) {
    console.error('[generateInsights ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 8. WHAT-IF PRICING SIMULATOR — POST /api/ai/simulate-pricing/:businessId
// ─────────────────────────────────────────────────────────────────────────────
exports.simulatePricing = async (req, res) => {
  try {
    const { businessId }                                           = req.params;
    const { productId, productName, currentPrice, newPrice, language = 'ar' } = req.body;

    if (!validObjId(businessId)) return res.status(400).json({ success: false, message: 'Invalid businessId' });
    if (!(await getOwnerOrFail(businessId, req.user._id, res))) return;

    const bId  = toObjId(businessId);
    const now  = new Date();
    const d30  = new Date(now); d30.setDate(now.getDate() - 30);

    let purchaseCost  = 0;
    let monthlySales  = 1;
    let resolvedName  = productName || 'Product';

    if (productId && mongoose.Types.ObjectId.isValid(productId)) {
      const pId = toObjId(productId);
      const [product, salesAgg] = await Promise.all([
        Product.findOne({ _id: pId, business: bId }).lean(),
        Sale.aggregate([
          { $match: { business: bId, product: pId, date: { $gte: d30 } } },
          { $group: { _id: null, qty: { $sum: '$quantity' } } },
        ]),
      ]);
      if (product) { purchaseCost = product.purchasePrice; resolvedName = product.name; }
      if (salesAgg[0]) monthlySales = Math.max(salesAgg[0].qty, 1);
    }

    const expAgg = await Expense.aggregate([
      { $match: { business: bId, date: { $gte: d30 }, isFixed: true } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);

    const result = await aiService.simulatePricing({
      productName:          resolvedName,
      currentPrice:         Number(currentPrice),
      newPrice:             Number(newPrice),
      monthlySales,
      purchaseCost,
      monthlyFixedExpenses: expAgg[0]?.total || 0,
    }, language);

    return res.status(200).json({ success: true, data: result });
  } catch (err) {
    console.error('[simulatePricing ctrl]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ── Quota stats endpoint (internal monitoring) ────────────────────────────────
exports.quotaStats = (_req, res) => res.status(200).json({ success: true, data: quota.stats() });

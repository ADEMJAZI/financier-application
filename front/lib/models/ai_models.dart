// ─── AI Response Models ────────────────────────────────────────────────────────

class ParsedExpense {
  final double amount;
  final String category;
  final String description;
  final double confidence;

  const ParsedExpense({
    required this.amount,
    required this.category,
    required this.description,
    required this.confidence,
  });

  factory ParsedExpense.fromJson(Map<String, dynamic> json) => ParsedExpense(
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        description: json['description'] as String,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      );
}

// ─── Business Summary ─────────────────────────────────────────────────────────
class BusinessSummaryMetrics {
  final double currentRevenue;
  final double previousRevenue;
  final double currentExpenses;
  final double previousExpenses;
  final double currentProfit;
  final double previousProfit;

  const BusinessSummaryMetrics({
    required this.currentRevenue,
    required this.previousRevenue,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.currentProfit,
    required this.previousProfit,
  });

  factory BusinessSummaryMetrics.fromJson(Map<String, dynamic> json) =>
      BusinessSummaryMetrics(
        currentRevenue: (json['currentRevenue'] as num?)?.toDouble() ?? 0,
        previousRevenue: (json['previousRevenue'] as num?)?.toDouble() ?? 0,
        currentExpenses: (json['currentExpenses'] as num?)?.toDouble() ?? 0,
        previousExpenses: (json['previousExpenses'] as num?)?.toDouble() ?? 0,
        currentProfit: (json['currentProfit'] as num?)?.toDouble() ?? 0,
        previousProfit: (json['previousProfit'] as num?)?.toDouble() ?? 0,
      );

  double get profitChangePercent {
    if (previousProfit == 0) return 0;
    return (currentProfit - previousProfit) / previousProfit.abs() * 100;
  }
}

class AiBusinessSummary {
  final String summaryText;
  final BusinessSummaryMetrics metrics;

  const AiBusinessSummary({required this.summaryText, required this.metrics});

  factory AiBusinessSummary.fromJson(Map<String, dynamic> json) =>
      AiBusinessSummary(
        summaryText: json['summary'] as String,
        metrics: BusinessSummaryMetrics.fromJson(
            json['metrics'] as Map<String, dynamic>),
      );
}

// ─── Anomaly ──────────────────────────────────────────────────────────────────
class AiAnomaly {
  final String type;
  final String severity; // low | medium | high
  final String message;
  final String? category;
  final double value;
  final double expectedValue;

  const AiAnomaly({
    required this.type,
    required this.severity,
    required this.message,
    this.category,
    required this.value,
    required this.expectedValue,
  });

  factory AiAnomaly.fromJson(Map<String, dynamic> json) => AiAnomaly(
        type: json['type'] as String? ?? 'unknown',
        severity: json['severity'] as String? ?? 'low',
        message: json['message'] as String? ?? '',
        category: json['category'] as String?,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        expectedValue: (json['expectedValue'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Insight ──────────────────────────────────────────────────────────────────
class AiInsight {
  final String icon;
  final String title;
  final String description;
  final String priority; // high | medium | low

  const AiInsight({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) => AiInsight(
        icon: json['icon'] as String? ?? 'lightbulb',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priority: json['priority'] as String? ?? 'low',
      );
}

// ─── Product Analysis ─────────────────────────────────────────────────────────
class ProductPerformer {
  final String name;
  final double margin;
  final String insight;

  const ProductPerformer(
      {required this.name, required this.margin, required this.insight});

  factory ProductPerformer.fromJson(Map<String, dynamic> json) =>
      ProductPerformer(
        name: json['name'] as String? ?? '',
        margin: (json['margin'] as num?)?.toDouble() ?? 0,
        insight: json['insight'] as String? ?? '',
      );
}

class ProductUnderPerformer {
  final String name;
  final String issue;
  final String suggestion;

  const ProductUnderPerformer(
      {required this.name, required this.issue, required this.suggestion});

  factory ProductUnderPerformer.fromJson(Map<String, dynamic> json) =>
      ProductUnderPerformer(
        name: json['name'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        suggestion: json['suggestion'] as String? ?? '',
      );
}

class PricingOpportunity {
  final String name;
  final double currentPrice;
  final double suggestedPrice;
  final String reason;

  const PricingOpportunity({
    required this.name,
    required this.currentPrice,
    required this.suggestedPrice,
    required this.reason,
  });

  factory PricingOpportunity.fromJson(Map<String, dynamic> json) =>
      PricingOpportunity(
        name: json['name'] as String? ?? '',
        currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
        suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String? ?? '',
      );
}

class AiProductAnalysis {
  final List<ProductPerformer> topPerformers;
  final List<ProductUnderPerformer> underPerformers;
  final List<PricingOpportunity> pricingOpportunities;
  final String summary;

  const AiProductAnalysis({
    required this.topPerformers,
    required this.underPerformers,
    required this.pricingOpportunities,
    required this.summary,
  });

  factory AiProductAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? json;
    return AiProductAnalysis(
      topPerformers: (analysis['topPerformers'] as List<dynamic>? ?? [])
          .map((e) => ProductPerformer.fromJson(e as Map<String, dynamic>))
          .toList(),
      underPerformers:
          (analysis['underPerformers'] as List<dynamic>? ?? [])
              .map((e) =>
                  ProductUnderPerformer.fromJson(e as Map<String, dynamic>))
              .toList(),
      pricingOpportunities:
          (analysis['pricingOpportunities'] as List<dynamic>? ?? [])
              .map((e) =>
                  PricingOpportunity.fromJson(e as Map<String, dynamic>))
              .toList(),
      summary: analysis['summary'] as String? ?? '',
    );
  }
}

// ─── What-if Pricing Simulation ───────────────────────────────────────────────
class PricingSimulation {
  final double currentRevenue;
  final double newRevenue;
  final double currentProfit;
  final double newProfit;
  final double currentMargin;
  final double newMargin;
  final double profitChange;
  final double profitChangePercent;
  final int? breakEvenUnits;
  final String recommendation;
  final List<String> risks;
  final List<String> opportunities;

  const PricingSimulation({
    required this.currentRevenue,
    required this.newRevenue,
    required this.currentProfit,
    required this.newProfit,
    required this.currentMargin,
    required this.newMargin,
    required this.profitChange,
    required this.profitChangePercent,
    this.breakEvenUnits,
    required this.recommendation,
    required this.risks,
    required this.opportunities,
  });

  factory PricingSimulation.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return PricingSimulation(
      currentRevenue: (d['currentRevenue'] as num?)?.toDouble() ?? 0,
      newRevenue: (d['newRevenue'] as num?)?.toDouble() ?? 0,
      currentProfit: (d['currentProfit'] as num?)?.toDouble() ?? 0,
      newProfit: (d['newProfit'] as num?)?.toDouble() ?? 0,
      currentMargin: (d['currentMargin'] as num?)?.toDouble() ?? 0,
      newMargin: (d['newMargin'] as num?)?.toDouble() ?? 0,
      profitChange: (d['profitChange'] as num?)?.toDouble() ?? 0,
      profitChangePercent:
          (d['profitChangePercent'] as num?)?.toDouble() ?? 0,
      breakEvenUnits: (d['breakEvenUnits'] as num?)?.toInt(),
      recommendation: d['recommendation'] as String? ?? '',
      risks: (d['risks'] as List<dynamic>? ?? []).cast<String>(),
      opportunities:
          (d['opportunities'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

// ─── Receipt Analysis ─────────────────────────────────────────────────────────
class ReceiptItem {
  final String description;
  final double amount;
  final String category;

  const ReceiptItem(
      {required this.description,
      required this.amount,
      required this.category});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        description: json['description'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? 'other',
      );
}

class ReceiptAnalysis {
  final String? vendor;
  final DateTime? date;
  final double? totalAmount;
  final String currency;
  final List<ReceiptItem> items;
  final double confidence;

  const ReceiptAnalysis({
    this.vendor,
    this.date,
    this.totalAmount,
    required this.currency,
    required this.items,
    required this.confidence,
  });

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    DateTime? parsedDate;
    if (d['date'] != null) {
      try {
        parsedDate = DateTime.parse(d['date'] as String);
      } catch (_) {}
    }
    return ReceiptAnalysis(
      vendor: d['vendor'] as String?,
      date: parsedDate,
      totalAmount: (d['totalAmount'] as num?)?.toDouble(),
      currency: d['currency'] as String? ?? 'DT',
      items: (d['items'] as List<dynamic>? ?? [])
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidence: (d['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Pricing & Sales Advice ───────────────────────────────────────────────────
class PricingSuggestion {
  final String itemName;
  final String type; // 'pricing' | 'slow_mover' | 'general'
  final double? currentMargin;
  final String suggestion;

  const PricingSuggestion({
    required this.itemName,
    required this.type,
    this.currentMargin,
    required this.suggestion,
  });

  factory PricingSuggestion.fromJson(Map<String, dynamic> json) =>
      PricingSuggestion(
        itemName: json['itemName'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        currentMargin: (json['currentMargin'] as num?)?.toDouble(),
        suggestion: json['suggestion'] as String? ?? '',
      );
}

class PricingRawItem {
  final String name;
  final double sellingPrice;
  final double? purchaseCost;
  final double? marginPct;
  final int unitsSold30d;
  final double revenue30d;

  const PricingRawItem({
    required this.name,
    required this.sellingPrice,
    this.purchaseCost,
    this.marginPct,
    required this.unitsSold30d,
    required this.revenue30d,
  });

  factory PricingRawItem.fromJson(Map<String, dynamic> json) => PricingRawItem(
        name: json['name'] as String? ?? '',
        sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
        purchaseCost: (json['purchaseCost'] as num?)?.toDouble(),
        marginPct: (json['marginPct'] as num?)?.toDouble(),
        unitsSold30d: (json['unitsSold30d'] as num?)?.toInt() ?? 0,
        revenue30d: (json['revenue30d'] as num?)?.toDouble() ?? 0,
      );
}

class AiPricingAdvice {
  final List<PricingSuggestion> suggestions;
  final List<PricingRawItem> rawData;
  final String generatedBy; // 'ai' | 'local'
  final bool suggestionsUnavailable;

  const AiPricingAdvice({
    required this.suggestions,
    required this.rawData,
    required this.generatedBy,
    required this.suggestionsUnavailable,
  });

  factory AiPricingAdvice.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return AiPricingAdvice(
      suggestions: (d['suggestions'] as List<dynamic>? ?? [])
          .map((e) => PricingSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawData: (d['rawData'] as List<dynamic>? ?? [])
          .map((e) => PricingRawItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedBy: d['generatedBy'] as String? ?? 'ai',
      suggestionsUnavailable: d['suggestionsUnavailable'] as bool? ?? false,
    );
  }
}

// ─── Chat Message ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

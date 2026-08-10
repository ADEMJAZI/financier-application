// ─── OrderItem ─────────────────────────────────────────────────────────────────
// Matches the subdocument shape from Order.js:
//   { menuItem, name, quantity, unitPrice, subtotal }
class OrderItem {
  final String menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItem'] is String
          ? json['menuItem'] as String
          : (json['menuItem'] as Map<String, dynamic>)['_id'] as String,
      name: json['name'] as String? ?? 'Unknown Item',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItemId,
      'quantity': quantity,
    };
  }

  @override
  String toString() =>
      'OrderItem($name x$quantity @ $unitPrice = $subtotal)';
}

// ─── StockConsumptionEntry ──────────────────────────────────────────────────────
// Matches stockConsumption subdocument from Order.js:
//   { product, productName, quantityConsumed }
// The daily-summary endpoint returns:
//   { productName, totalQuantityConsumed, unit }
class StockConsumptionEntry {
  final String productId;
  final String productName;
  final double quantityConsumed;
  final String? unit; // present in daily-summary responses only

  StockConsumptionEntry({
    required this.productId,
    required this.productName,
    required this.quantityConsumed,
    this.unit,
  });

  factory StockConsumptionEntry.fromJson(Map<String, dynamic> json) {
    // Per-order stockConsumption snapshot uses { product, productName, quantityConsumed }
    // Daily-summary aggregation uses { productName, totalQuantityConsumed, unit }
    final productId = json['product'] is String
        ? json['product'] as String
        : json['product'] is Map
            ? (json['product'] as Map<String, dynamic>)['_id'] as String? ?? ''
            : '';

    final consumed = json.containsKey('totalQuantityConsumed')
        ? (json['totalQuantityConsumed'] as num).toDouble()
        : (json['quantityConsumed'] as num).toDouble();

    return StockConsumptionEntry(
      productId: productId,
      productName: json['productName'] as String? ?? 'Unknown Material',
      quantityConsumed: consumed,
      unit: json['unit'] as String?,
    );
  }

  @override
  String toString() =>
      'StockConsumption($productName: $quantityConsumed ${unit ?? ''})';
}

// ─── InsufficientStockItem ──────────────────────────────────────────────────────
// Returned inside the 400 "Insufficient stock" response body:
//   { productName, required, available }
class InsufficientStockItem {
  final String productName;
  final double required;
  final double available;
  final double shortfall;

  InsufficientStockItem({
    required this.productName,
    required this.required,
    required this.available,
    required this.shortfall,
  });

  factory InsufficientStockItem.fromJson(Map<String, dynamic> json) {
    final req = (json['required'] as num).toDouble();
    final avail = (json['available'] as num).toDouble();
    return InsufficientStockItem(
      productName: json['productName'] as String? ??
          json['rawMaterialName'] as String? ?? // fallback
          'Unknown Material',
      required: req,
      available: avail,
      shortfall: req - avail,
    );
  }
}

// ─── Order Status ───────────────────────────────────────────────────────────────
enum OrderStatus { completed, voided }

// ─── Order ─────────────────────────────────────────────────────────────────────
// Matches the top-level Order schema from Order.js:
//   { business, invoiceNumber(Number), items[], totalAmount,
//     stockConsumption[], status, voidedAt, voidReason, date, createdAt, updatedAt }
class Order {
  final String id;
  final String business;
  final int invoiceNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final List<StockConsumptionEntry> stockConsumption;
  final OrderStatus status;
  final String? voidReason;
  final DateTime? voidedAt;
  final DateTime date;      // the business date field (Date.now default)
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.business,
    required this.invoiceNumber,
    required this.items,
    required this.totalAmount,
    required this.stockConsumption,
    required this.status,
    this.voidReason,
    this.voidedAt,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Human-readable invoice label, e.g. "INV-0042"
  String get invoiceLabel =>
      'INV-${invoiceNumber.toString().padLeft(4, '0')}';

  bool get isVoided => status == OrderStatus.voided;

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final stockJson = json['stockConsumption'] as List<dynamic>? ?? [];

    return Order(
      id: json['_id'] as String,
      business: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      invoiceNumber: (json['invoiceNumber'] as num).toInt(),
      items: itemsJson
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      stockConsumption: stockJson
          .map((e) => StockConsumptionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] == 'voided'
          ? OrderStatus.voided
          : OrderStatus.completed,
      voidReason: json['voidReason'] as String?,
      voidedAt: json['voidedAt'] != null
          ? DateTime.tryParse(json['voidedAt'] as String)
          : null,
      // Use `date` field (the business date); fall back to `createdAt`
      date: DateTime.parse(
          (json['date'] ?? json['createdAt']) as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'business': business,
      'invoiceNumber': invoiceNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status == OrderStatus.voided ? 'voided' : 'completed',
      'voidReason': voidReason,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Order($invoiceLabel, ${items.length} items, $totalAmount, $status)';
}

// ─── OrderDailySummary ──────────────────────────────────────────────────────────
// GET /api/orders/business/:id/daily-summary response shape:
//   { date, totalRevenue, orderCount, byMenuItem[], stockConsumed[] }
class OrderDailySummaryItem {
  final String name;
  final int quantitySold;
  final double revenue;

  OrderDailySummaryItem({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory OrderDailySummaryItem.fromJson(Map<String, dynamic> json) {
    return OrderDailySummaryItem(
      name: json['name'] as String,
      quantitySold: (json['quantitySold'] as num).toInt(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class OrderDailySummary {
  final DateTime date;
  final double totalRevenue;
  final int orderCount;
  final List<OrderDailySummaryItem> byMenuItem;
  final List<StockConsumptionEntry> stockConsumed;

  OrderDailySummary({
    required this.date,
    required this.totalRevenue,
    required this.orderCount,
    required this.byMenuItem,
    required this.stockConsumed,
  });

  factory OrderDailySummary.fromJson(Map<String, dynamic> json) {
    final byMenuItemJson = json['byMenuItem'] as List<dynamic>? ?? [];
    // Backend key is 'stockConsumed' in the daily-summary response
    final stockJson = json['stockConsumed'] as List<dynamic>? ?? [];

    return OrderDailySummary(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      orderCount: (json['orderCount'] as num).toInt(),
      byMenuItem: byMenuItemJson
          .map((item) =>
              OrderDailySummaryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      stockConsumed: stockJson
          .map((e) =>
              StockConsumptionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── OrderDailyProfit ───────────────────────────────────────────────────────────
// GET /api/orders/business/:id/daily-profit response shape:
//   { date, totalRevenue, totalExpenses, netProfit }
class OrderDailyProfit {
  final DateTime date;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  OrderDailyProfit({
    required this.date,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory OrderDailyProfit.fromJson(Map<String, dynamic> json) {
    return OrderDailyProfit(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
    );
  }
}
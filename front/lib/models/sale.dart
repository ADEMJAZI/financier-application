class Sale {
  final String id;
  final String businessId;
  final String productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.businessId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      productId: json['product'] is String
          ? json['product'] as String
          : (json['product'] as Map<String, dynamic>)['_id'] as String,
      productName: json['product'] is Map
          ? (json['product'] as Map<String, dynamic>)['name'] as String?
          : null,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'product': productId,
      'quantity': quantity,
    };
  }
}

class DailySummary {
  final DateTime date;
  final double totalRevenue;
  final int saleCount;
  final List<ProductSummary> byProduct;

  DailySummary({
    required this.date,
    required this.totalRevenue,
    required this.saleCount,
    required this.byProduct,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      saleCount: json['saleCount'] as int,
      byProduct: (json['byProduct'] as List)
          .map((item) => ProductSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductSummary {
  final String productName;
  final double quantitySold;
  final double revenue;

  ProductSummary({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      productName: json['productName'] as String,
      quantitySold: (json['quantitySold'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class DailyProfitReport {
  final DateTime date;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  DailyProfitReport({
    required this.date,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory DailyProfitReport.fromJson(Map<String, dynamic> json) {
    return DailyProfitReport(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
    );
  }

  bool get isProfitable => netProfit > 0;
}

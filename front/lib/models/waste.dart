class Waste {
  final String id;
  final String businessId;
  final String? productId;
  final String productName;
  final double quantity;
  final String unit;
  final String reason;
  final double estimatedLoss;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Waste({
    required this.id,
    required this.businessId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.reason,
    required this.estimatedLoss,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Waste.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    String? productId;
    String productName;

    if (productRaw is Map<String, dynamic>) {
      productId = productRaw['_id'] as String?;
      productName = productRaw['name'] as String? ?? 'Unknown Product';
    } else if (productRaw is String) {
      productId = productRaw;
      productName = json['productName'] as String? ?? 'Unknown Product';
    } else {
      productName = json['productName'] as String? ?? 'Unknown Product';
    }

    return Waste(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      productId: productId,
      productName: productName,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      reason: json['reason'] as String,
      estimatedLoss: (json['estimatedLoss'] as num? ?? 0).toDouble(),
      date: DateTime.parse(json['date'] as String? ?? json['createdAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      if (productId != null) 'product': productId,
      'quantity': quantity,
      'reason': reason,
      'estimatedLoss': estimatedLoss,
      'date': date.toIso8601String(),
    };
  }
}

class WasteReason {
  static const String expired = 'Expired';
  static const String damaged = 'Damaged';
  static const String theft = 'Theft';
  static const String spillage = 'Spillage';
  static const String overProduction = 'Over Production';
  static const String other = 'Other';

  static List<String> get all => [
    expired,
    damaged,
    theft,
    spillage,
    overProduction,
    other,
  ];
}

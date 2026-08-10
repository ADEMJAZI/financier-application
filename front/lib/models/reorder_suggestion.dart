class ReorderSuggestion {
  final String productId;
  final String productName;
  final double currentQuantity;
  final double reorderPoint;
  final double reorderQuantity;
  final String unit;

  ReorderSuggestion({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.reorderPoint,
    required this.reorderQuantity,
    required this.unit,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    String productId;
    String productName;

    if (productRaw is Map<String, dynamic>) {
      productId = productRaw['_id'] as String;
      productName = productRaw['name'] as String;
    } else {
      productId = json['productId'] as String? ?? '';
      productName = json['productName'] as String? ?? 'Unknown';
    }

    return ReorderSuggestion(
      productId: productId,
      productName: productName,
      currentQuantity: (json['currentQuantity'] as num? ??
              json['quantity'] as num? ?? 0)
          .toDouble(),
      reorderPoint: (json['reorderPoint'] as num? ?? 0).toDouble(),
      reorderQuantity: (json['reorderQuantity'] as num? ??
              json['suggestedQuantity'] as num? ?? 0)
          .toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
    );
  }

  /// Urgency: 0 = not urgent, 1 = low, 2 = medium, 3 = critical
  int get urgencyLevel {
    if (reorderPoint <= 0) return 0;
    final ratio = currentQuantity / reorderPoint;
    if (currentQuantity <= 0) return 3;
    if (ratio <= 0.25) return 3;
    if (ratio <= 0.5) return 2;
    return 1;
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
      case 3:
        return 'Critical';
      case 2:
        return 'Medium';
      case 1:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  double get shortfall => reorderPoint - currentQuantity;
}

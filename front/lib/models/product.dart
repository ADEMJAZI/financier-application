class Product {
  final String id;
  final String businessId;
  final String name;
  final double purchasePrice;
  final double price;
  final double quantity;
  final String unit;
  final double reorderPoint;
  final double reorderQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.purchasePrice,
    required this.price,
    required this.quantity,
    required this.unit,
    this.reorderPoint = 0,
    this.reorderQuantity = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      name: json['name'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      reorderPoint: (json['reorderPoint'] as num? ?? 0).toDouble(),
      reorderQuantity: (json['reorderQuantity'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'name': name,
      'purchasePrice': purchasePrice,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'reorderPoint': reorderPoint,
      'reorderQuantity': reorderQuantity,
    };
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? name,
    double? purchasePrice,
    double? price,
    double? quantity,
    String? unit,
    double? reorderPoint,
    double? reorderQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => reorderPoint > 0 && quantity <= reorderPoint;
  double get profit => price - purchasePrice;
  double get profitMargin => price > 0 ? ((price - purchasePrice) / price * 100) : 0;
  double get totalValue => price * quantity;
}

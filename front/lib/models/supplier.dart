class Supplier {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? address;
  final List<SupplierPurchase> purchases;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.address,
    required this.purchases,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      purchases: (json['purchases'] as List? ?? [])
          .map((p) => SupplierPurchase.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
  }

  Supplier copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? address,
    List<SupplierPurchase>? purchases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      purchases: purchases ?? this.purchases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalPurchaseValue =>
      purchases.fold(0.0, (sum, p) => sum + p.total);
}

class SupplierPurchase {
  final String? productId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;
  final DateTime date;

  SupplierPurchase({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
    required this.date,
  });

  factory SupplierPurchase.fromJson(Map<String, dynamic> json) {
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

    return SupplierPurchase(
      productId: productId,
      productName: productName,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      date: DateTime.parse(
          json['date'] as String? ?? json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'product': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

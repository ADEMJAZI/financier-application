class Expense {
  final String id;
  final String businessId;
  final String category;
  final double amount;
  final bool isFixed;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.businessId,
    required this.category,
    required this.amount,
    required this.isFixed,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] as String,
      businessId: json['business'] is String 
          ? json['business'] as String 
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      isFixed: json['isFixed'] as bool,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'category': category,
      'amount': amount,
      'isFixed': isFixed,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? businessId,
    String? category,
    double? amount,
    bool? isFixed,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      isFixed: isFixed ?? this.isFixed,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Common expense categories
class ExpenseCategory {
  static const String rent = 'rent';
  static const String water = 'water';
  static const String electricity = 'electricity';
  static const String maintenance = 'maintenance';
  static const String equipmentPurchase = 'equipment purchase';
  static const String other = 'other';

  static List<String> get all => [
    rent,
    water,
    electricity,
    maintenance,
    equipmentPurchase,
    other,
  ];

  // Display names for UI
  static String getDisplayName(String category) {
    switch (category) {
      case rent:
        return 'Rent';
      case water:
        return 'Water';
      case electricity:
        return 'Electricity';
      case maintenance:
        return 'Maintenance';
      case equipmentPurchase:
        return 'Equipment Purchase';
      case other:
        return 'Other';
      default:
        return category;
    }
  }
}

class CashRegister {
  final String id;
  final String businessId;
  final double openingBalance;
  final double? closingBalance;
  final double? expectedBalance;
  final String status; // 'open' | 'closed'
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CashRegister({
    required this.id,
    required this.businessId,
    required this.openingBalance,
    this.closingBalance,
    this.expectedBalance,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      closingBalance: json['closingBalance'] != null
          ? (json['closingBalance'] as num).toDouble()
          : null,
      expectedBalance: json['expectedBalance'] != null
          ? (json['expectedBalance'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'open',
      // Backend sends "date" field, not "openedAt"
      openedAt: DateTime.parse(
          json['date'] as String? ?? 
          json['openedAt'] as String? ?? 
          json['createdAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'openingBalance': openingBalance,
    };
  }

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  double? get difference {
    if (closingBalance != null && expectedBalance != null) {
      return closingBalance! - expectedBalance!;
    }
    return null;
  }

  bool get hasDiscrepancy {
    final diff = difference;
    return diff != null && diff.abs() > 0.001;
  }
}

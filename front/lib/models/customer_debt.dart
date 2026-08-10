class CustomerDebt {
  final String id;
  final String businessId;
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final List<Payment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerDebt({
    required this.id,
    required this.businessId,
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.payments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerDebt.fromJson(Map<String, dynamic> json) {
    return CustomerDebt(
      id: json['_id'] as String,
      businessId: json['business'] is String 
          ? json['business'] as String 
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      customerName: json['customerName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      status: json['status'] as String,
      payments: (json['payments'] as List?)
          ?.map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'customerName': customerName,
      'totalAmount': totalAmount,
    };
  }

  double get remainingAmount => totalAmount - paidAmount;
  double get paidPercentage => totalAmount > 0 ? (paidAmount / totalAmount * 100) : 0;
  bool get isFullyPaid => status == 'paid';
  bool get isPartiallyPaid => status == 'partial';
  bool get isUnpaid => status == 'unpaid';

  CustomerDebt copyWith({
    String? id,
    String? businessId,
    String? customerName,
    double? totalAmount,
    double? paidAmount,
    String? status,
    List<Payment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerDebt(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Payment {
  final double amount;
  final DateTime date;
  final String? note;

  Payment({
    required this.amount,
    required this.date,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      if (note != null) 'note': note,
    };
  }
}

class Reserve {
  final String id;
  final String businessId;
  final String name;
  final double balance;
  final List<ReserveTransaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reserve({
    required this.id,
    required this.businessId,
    required this.name,
    required this.balance,
    required this.transactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reserve.fromJson(Map<String, dynamic> json) {
    return Reserve(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      transactions: (json['transactions'] as List? ?? [])
          .map((t) => ReserveTransaction.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'name': name,
      'balance': balance,
    };
  }

  Reserve copyWith({
    String? id,
    String? businessId,
    String? name,
    double? balance,
    List<ReserveTransaction>? transactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reserve(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReserveTransaction {
  final String type; // 'deposit' | 'withdrawal'
  final double amount;
  final String? note;
  final DateTime date;

  ReserveTransaction({
    required this.type,
    required this.amount,
    this.note,
    required this.date,
  });

  factory ReserveTransaction.fromJson(Map<String, dynamic> json) {
    return ReserveTransaction(
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  bool get isDeposit => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
}

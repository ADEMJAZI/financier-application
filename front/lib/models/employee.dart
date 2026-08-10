class Employee {
  final String id;
  final String businessId;
  final String name;
  final String? role;
  final double salary;
  final String status; // 'active' | 'inactive'
  final List<SalaryPayment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.businessId,
    required this.name,
    this.role,
    required this.salary,
    required this.status,
    required this.payments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>)['_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String?,
      salary: (json['salary'] as num).toDouble(),
      status: json['status'] as String? ?? 'active',
      payments: (json['payments'] as List? ?? [])
          .map((p) => SalaryPayment.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business': businessId,
      'name': name,
      if (role != null) 'role': role,
      'salary': salary,
    };
  }

  Employee copyWith({
    String? id,
    String? businessId,
    String? name,
    String? role,
    double? salary,
    String? status,
    List<SalaryPayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'active';
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
}

class SalaryPayment {
  final double amount;
  final DateTime date;
  final String? note;

  SalaryPayment({
    required this.amount,
    required this.date,
    this.note,
  });

  factory SalaryPayment.fromJson(Map<String, dynamic> json) {
    return SalaryPayment(
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(
          json['date'] as String? ?? json['createdAt'] as String),
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

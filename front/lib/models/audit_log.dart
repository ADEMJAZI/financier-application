class AuditLog {
  final String id;
  final String businessId;
  final String collection;
  final String action; // 'create' | 'update' | 'delete'
  final String? documentId;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.businessId,
    required this.collection,
    required this.action,
    this.documentId,
    this.changes,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['_id'] as String,
      businessId: json['business'] is String
          ? json['business'] as String
          : (json['business'] as Map<String, dynamic>?)?['_id'] as String? ?? '',
      collection: json['collection'] as String? ?? json['entity'] as String? ?? 'Unknown',
      action: json['action'] as String,
      documentId: json['documentId'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      default:
        return action;
    }
  }

  String get collectionLabel {
    switch (collection.toLowerCase()) {
      case 'product':
      case 'products':
        return 'Product';
      case 'expense':
      case 'expenses':
        return 'Expense';
      case 'customerdebt':
      case 'debts':
        return 'Debt';
      case 'supplier':
      case 'suppliers':
        return 'Supplier';
      case 'employee':
      case 'employees':
        return 'Employee';
      case 'reserve':
      case 'reserves':
        return 'Reserve';
      case 'waste':
        return 'Waste';
      case 'cashregister':
      case 'cash_register':
        return 'Cash Register';
      default:
        return collection;
    }
  }

  List<String> get changeDescriptions {
    if (changes == null) return [];
    final descriptions = <String>[];
    changes!.forEach((key, value) {
      if (value is Map && value.containsKey('from') && value.containsKey('to')) {
        descriptions.add('$key changed from "${value['from']}" to "${value['to']}"');
      } else {
        descriptions.add('$key: $value');
      }
    });
    return descriptions;
  }
}

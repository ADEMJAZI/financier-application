import 'menu_item.dart';

class MenuItemSale {
  final String id;
  final String business;
  final String menuItemId;
  final MenuItem? menuItem; // Populated menu item details
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemSale({
    required this.id,
    required this.business,
    required this.menuItemId,
    this.menuItem,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemSale.fromJson(Map<String, dynamic> json) {
    return MenuItemSale(
      id: json['_id'] as String,
      business: json['business'] as String,
      menuItemId: json['menuItem'] is String 
          ? json['menuItem'] as String 
          : (json['menuItem'] as Map<String, dynamic>)['_id'] as String,
      menuItem: json['menuItem'] is Map<String, dynamic>
          ? MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>)
          : null,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'business': business,
      'menuItem': menuItemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MenuItemSale(id: $id, menuItem: ${menuItem?.name ?? menuItemId}, quantity: $quantity, totalAmount: $totalAmount)';
  }
}

class MenuItemSaleSummary {
  final DateTime date;
  final double totalRevenue;
  final int saleCount;
  final List<MenuItemSummaryItem> byMenuItem;

  MenuItemSaleSummary({
    required this.date,
    required this.totalRevenue,
    required this.saleCount,
    required this.byMenuItem,
  });

  factory MenuItemSaleSummary.fromJson(Map<String, dynamic> json) {
    return MenuItemSaleSummary(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      saleCount: json['saleCount'] as int,
      byMenuItem: (json['byMenuItem'] as List<dynamic>)
          .map((item) => MenuItemSummaryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuItemSummaryItem {
  final String name;
  final double quantitySold;
  final double revenue;

  MenuItemSummaryItem({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory MenuItemSummaryItem.fromJson(Map<String, dynamic> json) {
    return MenuItemSummaryItem(
      name: json['name'] as String,
      quantitySold: (json['quantitySold'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class DailyProfitReport {
  final DateTime date;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  DailyProfitReport({
    required this.date,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory DailyProfitReport.fromJson(Map<String, dynamic> json) {
    return DailyProfitReport(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
    );
  }
}

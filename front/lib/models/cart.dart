import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;

  CartItem({
    required this.menuItem,
    required this.quantity,
  });

  double get totalPrice => menuItem.sellingPrice * quantity;

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }

  // For creating order items
  Map<String, dynamic> toOrderItem() {
    return {
      'menuItem': menuItem.id,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'CartItem(${menuItem.name} x$quantity = \$${totalPrice.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menuItem.id == menuItem.id &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => menuItem.id.hashCode ^ quantity.hashCode;
}

class Cart {
  final List<CartItem> items;

  Cart({this.items = const []});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }

  // Convert to order format for API
  List<Map<String, dynamic>> toOrderItems() {
    return items.map((item) => item.toOrderItem()).toList();
  }

  @override
  String toString() {
    return 'Cart(${items.length} items, total: \$${totalAmount.toStringAsFixed(2)})';
  }
}
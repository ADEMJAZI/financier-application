import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/menu_item.dart';

class OrderCartNotifier extends StateNotifier<Cart> {
  OrderCartNotifier() : super(Cart());

  // Add item to cart (increment quantity if already exists)
  void addItem(MenuItem menuItem) {
    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex != -1) {
      // Item exists, increment quantity
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + 1,
      );
    } else {
      // New item, add to cart
      currentItems.add(CartItem(menuItem: menuItem, quantity: 1));
    }

    state = Cart(items: currentItems);
  }

  // Update item quantity
  void updateItemQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex != -1) {
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: newQuantity,
      );
      state = Cart(items: currentItems);
    }
  }

  // Increment item quantity
  void incrementItem(String menuItemId) {
    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex != -1) {
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + 1,
      );
      state = Cart(items: currentItems);
    }
  }

  // Decrement item quantity
  void decrementItem(String menuItemId) {
    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex != -1) {
      final newQuantity = currentItems[existingIndex].quantity - 1;
      if (newQuantity <= 0) {
        currentItems.removeAt(existingIndex);
      } else {
        currentItems[existingIndex] = currentItems[existingIndex].copyWith(
          quantity: newQuantity,
        );
      }
      state = Cart(items: currentItems);
    }
  }

  // Remove item completely from cart
  void removeItem(String menuItemId) {
    final currentItems = state.items.where(
      (item) => item.menuItem.id != menuItemId,
    ).toList();

    state = Cart(items: currentItems);
  }

  // Clear all items from cart
  void clearCart() {
    state = Cart();
  }

  // Get item quantity by menu item id
  int getItemQuantity(String menuItemId) {
    final item = state.items.where(
      (item) => item.menuItem.id == menuItemId,
    ).firstOrNull;
    return item?.quantity ?? 0;
  }

  // Check if item is in cart
  bool isInCart(String menuItemId) {
    return state.items.any((item) => item.menuItem.id == menuItemId);
  }
}

// Provider for the order cart
final orderCartProvider = StateNotifierProvider<OrderCartNotifier, Cart>((ref) {
  return OrderCartNotifier();
});
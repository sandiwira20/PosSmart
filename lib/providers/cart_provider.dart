import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/menu_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  List<CartItemModel> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  int getItemQuantity(String menuId) {
    return _items[menuId]?.quantity ?? 0;
  }

  void addItem(MenuModel menu) {
    if (_items.containsKey(menu.id)) {
      _items[menu.id]!.quantity += 1;
    } else {
      _items[menu.id] = CartItemModel(menu: menu, quantity: 1);
    }
    notifyListeners();
  }

  void removeItem(String menuId) {
    if (!_items.containsKey(menuId)) return;
    if (_items[menuId]!.quantity > 1) {
      _items[menuId]!.quantity -= 1;
    } else {
      _items.remove(menuId);
    }
    notifyListeners();
  }

  void deleteItem(String menuId) {
    _items.remove(menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

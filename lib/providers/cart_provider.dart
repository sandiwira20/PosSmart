import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/menu_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get tax => subtotal * 0.10;

  double get total => subtotal + tax;

  bool get isEmpty => _items.isEmpty;

  int getQuantity(String menuId) {
    final index = _items.indexWhere((item) => item.menu.id == menuId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  void addItem(MenuModel menu) {
    final index = _items.indexWhere((item) => item.menu.id == menu.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItemModel(menu: menu));
    }
    notifyListeners();
  }

  void removeItem(String menuId) {
    final index = _items.indexWhere((item) => item.menu.id == menuId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }
    notifyListeners();
  }

  void deleteItem(String menuId) {
    _items.removeWhere((item) => item.menu.id == menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

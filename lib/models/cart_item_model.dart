import 'menu_model.dart';

class CartItemModel {
  final MenuModel menu;
  int quantity;
  String? notes;

  CartItemModel({
    required this.menu,
    this.quantity = 1,
    this.notes,
  });

  double get subtotal => menu.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuId': menu.id,
      'menuName': menu.name,
      'price': menu.price,
      'quantity': quantity,
      'subtotal': subtotal,
      'notes': notes,
    };
  }

  factory CartItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CartItemModel(
      menu: MenuModel(
        id: map['menuId'] ?? '',
        name: map['menuName'] ?? '',
        category: 'Umum',
        price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
        imageUrl: '',
      ),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
    );
  }
}

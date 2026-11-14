import 'menu_model.dart';

class CartItemModel {
  final MenuModel menu;
  int quantity;

  CartItemModel({
    required this.menu,
    this.quantity = 1,
  });

  double get subtotal => menu.price * quantity;

  CartItemModel copyWith({MenuModel? menu, int? quantity}) {
    return CartItemModel(
      menu: menu ?? this.menu,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() => 'CartItemModel(menu: ${menu.name}, qty: $quantity)';
}

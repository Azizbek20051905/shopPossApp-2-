import 'cart_item.dart';

class Cart {
  final String id;
  String name;
  final List<CartItem> items;

  Cart({
    required this.id,
    required this.name,
    required this.items,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get itemCount => items.fold(0.0, (sum, item) => sum + item.quantity);

  void clear() {
    items.clear();
  }
}

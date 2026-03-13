import 'product.dart';

class CartItem {
  final Product product;
  double quantity;
  final double price;

  CartItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}

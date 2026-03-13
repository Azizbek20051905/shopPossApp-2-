import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/cart.dart';
import '../services/sales_service.dart';

final cartProvider = ChangeNotifierProvider<CartProvider>((ref) {
  return CartProvider();
});

class CartProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();
  
  final List<Cart> _carts = [
    Cart(id: '1', name: 'Cart 1', items: []),
  ];
  int _activeCartIndex = 0;

  List<Cart> get carts => List.unmodifiable(_carts);
  int get activeCartIndex => _activeCartIndex;
  
  Cart get activeCart => _carts[_activeCartIndex];
  List<CartItem> get items => List.unmodifiable(activeCart.items);
  double get total => activeCart.total;
  double get itemCount => activeCart.itemCount;

  void addNewCart() {
    if (_carts.length >= 10) return;
    
    final newId = (DateTime.now().millisecondsSinceEpoch % 10000).toString();
    _carts.add(Cart(
      id: newId,
      name: 'Cart ${_carts.length + 1}',
      items: [],
    ));
    _activeCartIndex = _carts.length - 1;
    notifyListeners();
  }

  void switchCart(int index) {
    if (index >= 0 && index < _carts.length) {
      _activeCartIndex = index;
      notifyListeners();
    }
  }

  void deleteCart(int index) {
    if (_carts.length <= 1) {
      _carts[0].clear();
    } else {
      _carts.removeAt(index);
      if (_activeCartIndex >= _carts.length) {
        _activeCartIndex = _carts.length - 1;
      }
    }
    notifyListeners();
  }

  void addToCart(Product product, {double quantity = 1}) {
    final cartItems = activeCart.items;
    final existing = cartItems.indexWhere((i) => i.product.id == product.id);
    
    if (existing >= 0) {
      cartItems[existing].quantity += quantity;
    } else {
      cartItems.add(CartItem(
        product: product,
        quantity: quantity,
        price: product.price,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    activeCart.items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = activeCart.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      activeCart.items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearActiveCart() {
    activeCart.clear();
    notifyListeners();
  }

  Future<bool> sell() async {
    if (activeCart.items.isEmpty) return false;

    final success = await _salesService.createSale(activeCart.items);
    if (success) {
      clearActiveCart();
    }
    return success;
  }
}

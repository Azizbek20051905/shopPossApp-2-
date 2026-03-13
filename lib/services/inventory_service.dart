import 'api_service.dart';
import '../models/product.dart';

class InventoryService {
  /// GET /api/products/low-stock/
  /// Fetches products that are below their minimum stock threshold.
  Future<List<Product>> fetchLowStockProducts() async {
    try {
      final response = await ApiService.dio.get('products/low-stock/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch Low Stock Error: $e');
      return [];
    }
  }

  /// POST /api/inventory/add-stock/
  /// Adds stock to a specific product.
  Future<bool> addStock(int productId, double quantity) async {
    try {
      final response = await ApiService.dio.post('inventory/add-stock/', data: {
        'product_id': productId,
        'quantity': quantity,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Add Stock Error: $e');
      return false;
    }
  }
}

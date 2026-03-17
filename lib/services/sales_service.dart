import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/cart_item.dart';

class SalesService {
  /// POST /api/sales/
  /// Submits a sale transaction to the backend.
  Future<int?> submitSale({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiService.dio.post('sales/', data: {
        'items': items,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['id'];
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('Submit Sale Error [${e.response?.statusCode}]: ${e.response?.data}');
      } else {
        print('Submit Sale Error: $e');
      }
      return null;
    }
  }

  /// Wrapper for CartProvider that takes [CartItem] objects.
  Future<bool> createSale(List<CartItem> items) async {
    final payload = items.map((item) => {
      'product': item.product.id,
      'quantity': item.quantity,
    }).toList();

    final result = await submitSale(items: payload);
    return result != null;
  }

  /// GET /api/sales/
  /// Fetches the sales history from the backend.
  Future<List<Map<String, dynamic>>> fetchSalesHistory() async {
    try {
      final response = await ApiService.dio.get('sales/');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print('Fetch Sales History Error: $e');
      return [];
    }
  }
  
  /// GET /api/sales/{id}/
  /// Fetches a detailed receipt for a specific sale.
  Future<Map<String, dynamic>?> fetchReceipt(int saleId) async {
    try {
      final response = await ApiService.dio.get('sales/$saleId/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Fetch Receipt Error: $e');
      return null;
    }
  }
}

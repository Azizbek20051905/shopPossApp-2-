import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'api_service.dart';

class ProductService {
  final Dio _dio = ApiService.dio;

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _dio.get('products/');
      print('API Response for products: ${response.data}');
      if (response.data is List) {
        print('Response is a List');
        return (response.data as List)
            .map((json) => Product.fromMap(json))
            .toList();
      }
      // If it's paginated (Django DRF default pagination), data is in 'results'
      if (response.data is Map && response.data.containsKey('results')) {
        print('Response has results key');
        return (response.data['results'] as List)
            .map((json) => Product.fromMap(json))
            .toList();
      }
      print('Unexpected response structure: ${response.data}');
      return [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final url = 'products/barcode/$barcode/';
      print('Fetching product from: ${ApiService.baseUrl}$url');
      final response = await _dio.get(url);
      if (response.data != null) {
        return Product.fromMap(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch product by barcode: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData, {XFile? image}) async {
    try {
      dynamic data;
      if (image != null) {
        final formDataMap = <String, dynamic>{};
        productData.forEach((key, value) {
          formDataMap[key] = value.toString();
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          formDataMap['image'] = MultipartFile.fromBytes(
            bytes,
            filename: image.name,
          );
        } else {
          formDataMap['image'] = await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          );
        }
        data = FormData.fromMap(formDataMap);
      } else {
        data = productData;
      }

      await _dio.post('products/', data: data);
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to create product: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData, {XFile? image}) async {
    try {
      dynamic data;
      if (image != null) {
        final formDataMap = <String, dynamic>{};
        productData.forEach((key, value) {
          formDataMap[key] = value.toString();
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          formDataMap['image'] = MultipartFile.fromBytes(
            bytes,
            filename: image.name,
          );
        } else {
          formDataMap['image'] = await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          );
        }
        data = FormData.fromMap(formDataMap);
      } else {
        data = productData;
      }

      await _dio.put('products/$id/', data: data);
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to update product: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _dio.delete('products/$id/');
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to delete product: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<ProductCategory>> fetchCategories() async {
    try {
      final response = await _dio.get('categories/');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ProductCategory.fromMap(json))
            .toList();
      }
      if (response.data is Map && response.data.containsKey('results')) {
        return (response.data['results'] as List)
            .map((json) => ProductCategory.fromMap(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<ProductCategory> createCategory(String name) async {
    try {
      final response = await _dio.post('categories/', data: {'name': name});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductCategory.fromMap(response.data);
      }
      throw Exception('Failed to create category');
    } on DioException catch (e) {
      throw Exception('Failed to create category: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

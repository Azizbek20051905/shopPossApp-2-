import 'package:dio/dio.dart';
import 'api_service.dart';

class AnalyticsService {
  final Dio _dio = ApiService.dio;

  /// GET /api/analytics/?period=today|week|month|year
  Future<Map<String, dynamic>> fetchAnalytics({String period = 'month'}) async {
    try {
      final response = await _dio.get('analytics/', queryParameters: {'period': period});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Fetch Analytics Error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }
}

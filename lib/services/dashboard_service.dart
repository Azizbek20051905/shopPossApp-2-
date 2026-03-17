import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final Dio _dio = ApiService.dio;

  Future<DashboardData> fetchDashboardData() async {
    try {
      final response = await _dio.get('dashboard/');
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard data: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

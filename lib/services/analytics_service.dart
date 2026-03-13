import 'api_service.dart';

class AnalyticsService {
  /// GET /api/analytics/
  /// Fetches sales summary and top products for the dashboard.
  Future<Map<String, dynamic>?> fetchAnalytics() async {
    try {
      final response = await ApiService.dio.get('analytics/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Fetch Analytics Error: $e');
      return null;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String serverUrl = 'https://fastittest.pythonanywhere.com';
  static const String baseUrl = '$serverUrl/api/';

  static final Dio dio = _initDio();

  static Dio _initDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          print('Auth Token check: ${token != null ? "Token found (${token.substring(0, 10)}...)" : "No token found"}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print('API Error [${e.response?.statusCode}]: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
    return dio;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../env.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: EnvConfig.baseUrl)),
        _storage = storage ?? const FlutterSecureStorage() {
    print('ApiClient initialized with baseUrl: ${EnvConfig.baseUrl}'); // Debug log
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('Making request to: ${options.uri}'); // Debug log
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('Dio error: ${error.message}'); // Debug log
          print('Dio error type: ${error.type}'); // Debug log
          print('Dio error response: ${error.response?.statusCode}'); // Debug log
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Dio get client => _dio;
}



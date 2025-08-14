import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class AuthApi {
  AuthApi(this._apiClient);

  final ApiClient _apiClient;

  Future<void> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _apiClient.client.post('/api/auth/register/', data: {
      'email': email,
      'password': password,
      'role': role.name,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final Response res = await _apiClient.client.post(
      '/api/auth/login/',
      data: {'email': email, 'password': password},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _apiClient.client.get('/api/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateMe(Map<String, dynamic> patch) async {
    await _apiClient.client.patch('/api/me', data: patch);
  }
}



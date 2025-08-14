import '../../../core/network/api_client.dart';

class LessonRequestsApi {
  LessonRequestsApi(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> list({String? role, String? status}) async {
    final res = await _apiClient.client.get(
      '/api/lesson-requests/',
      queryParameters: {
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    try {
      final res = await _apiClient.client.post('/api/lesson-requests/', data: body);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(int id, Map<String, dynamic> body) async {
    final res = await _apiClient.client.patch('/api/lesson-requests/$id', data: body);
    return res.data as Map<String, dynamic>;
  }
}



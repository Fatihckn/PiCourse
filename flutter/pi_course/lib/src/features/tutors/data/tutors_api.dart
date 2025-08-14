import '../../../core/network/api_client.dart';

class TutorsApi {
  TutorsApi(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listTutors({
    int? subjectId,
    String? ordering,
    String? search,
    int? limit,
    int? offset,
  }) async {
    final res = await _apiClient.client.get('/api/tutors', queryParameters: {
      if (subjectId != null) 'subject': subjectId,
      if (ordering != null) 'ordering': ordering,
      if (search != null) 'search': search,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTutor(int id) async {
    final res = await _apiClient.client.get('/api/tutors/$id');
    return res.data as Map<String, dynamic>;
  }
}



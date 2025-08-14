import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/pagination.dart';
import '../../../core/di/providers.dart';
import '../domain/lesson_request.dart';
import 'lesson_requests_api.dart';

final lessonRequestsApiProvider = Provider<LessonRequestsApi>((ref) {
  return LessonRequestsApi(ref.watch(apiClientProvider));
});

final lessonRequestsRepositoryProvider = Provider<LessonRequestsRepository>((ref) {
  return LessonRequestsRepository(ref.watch(lessonRequestsApiProvider));
});

class LessonRequestsRepository {
  LessonRequestsRepository(this.api);
  final LessonRequestsApi api;

  Future<PaginatedResponse<LessonRequestModel>> list({String? role, String? status}) async {
    final json = await api.list(role: role, status: status);
    final count = json['count'] as int;
    final results = (json['results'] as List)
        .cast<Map<String, dynamic>>()
        .map(LessonRequestModel.fromJson)
        .toList();
    return PaginatedResponse(count: count, results: results);
  }

  Future<LessonRequestModel> create({
    required int tutorId,
    required int subjectId,
    required String startTime,
    required int durationMinutes,
    String? note,
  }) async {
    try {
      final json = await api.create({
        'tutor': tutorId,  // Backend 'tutor' alanını bekliyor
        'subject': subjectId,  // Backend 'subject' alanını bekliyor
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        if (note != null) 'note': note,
      });
      return LessonRequestModel.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<LessonRequestModel> patchStatus(int id, LessonRequestStatus status) async {
    try {
      final json = await api.patch(id, {'status': status.name});
      return LessonRequestModel.fromJson(json);
    } catch (e) {
      print('Status güncelleme hatası: $e');
      rethrow;
    }
  }
}



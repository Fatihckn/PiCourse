import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/pagination.dart';
import '../../../core/di/providers.dart';
import '../domain/tutor.dart';
import 'tutors_api.dart';

final tutorsApiProvider = Provider<TutorsApi>((ref) {
  return TutorsApi(ref.watch(apiClientProvider));
});

final tutorsRepositoryProvider = Provider<TutorsRepository>((ref) {
  return TutorsRepository(ref.watch(tutorsApiProvider));
});

class TutorsRepository {
  TutorsRepository(this.api);
  final TutorsApi api;

  Future<PaginatedResponse<TutorModel>> list({
    int? subjectId,
    String? ordering,
    String? search,
    int? limit,
    int? offset,
  }) async {
    final json = await api.listTutors(
      subjectId: subjectId,
      ordering: ordering,
      search: search,
      limit: limit,
      offset: offset,
    );
    final count = json['count'] as int;
    final results = (json['results'] as List)
        .cast<Map<String, dynamic>>()
        .map(TutorModel.fromJson)
        .toList();
    return PaginatedResponse(count: count, results: results);
  }

  Future<TutorModel> get(int id) async {
    final json = await api.getTutor(id);
    return TutorModel.fromJson(json);
  }
}



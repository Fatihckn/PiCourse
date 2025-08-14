import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../domain/tutor.dart';
import 'tutor_profile_api.dart';

final tutorProfileApiProvider = Provider<TutorProfileApi>((ref) {
  return TutorProfileApi(ref.watch(apiClientProvider));
});

final tutorProfileRepositoryProvider = Provider<TutorProfileRepository>((ref) {
  return TutorProfileRepository(ref.watch(tutorProfileApiProvider));
});

class TutorProfileRepository {
  TutorProfileRepository(this._api);

  final TutorProfileApi _api;

  Future<TutorModel> updateProfile({
    required String name,
    required String bio,
    required num hourlyRate,
    required List<int> subjectIds,
  }) async {
    final json = await _api.updateProfile(
      name: name,
      bio: bio,
      hourlyRate: hourlyRate,
      subjectIds: subjectIds,
    );
    return TutorModel.fromJson(json);
  }

  Future<TutorModel> getMyProfile() async {
    final json = await _api.getMyProfile();
    return TutorModel.fromJson(json);
  }
}


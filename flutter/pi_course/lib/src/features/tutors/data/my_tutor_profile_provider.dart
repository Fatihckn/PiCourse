import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/tutor.dart';
import 'tutor_profile_repository.dart';

final myTutorProfileProvider = StateNotifierProvider<MyTutorProfileNotifier, TutorModel?>((ref) {
  return MyTutorProfileNotifier(ref.watch(tutorProfileRepositoryProvider));
});

class MyTutorProfileNotifier extends StateNotifier<TutorModel?> {
  MyTutorProfileNotifier(this._repository) : super(null);

  final TutorProfileRepository _repository;

  Future<void> loadProfile() async {
    try {
      final profile = await _repository.getMyProfile();
      state = profile;
    } catch (e) {
      // Profil yüklenemezse null olarak kalır
      state = null;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    required num hourlyRate,
    required List<int> subjectIds,
  }) async {
    try {
      final updatedProfile = await _repository.updateProfile(
        name: name,
        bio: bio,
        hourlyRate: hourlyRate,
        subjectIds: subjectIds,
      );
      
      // Güncellenmiş profili state'e ata
      if (updatedProfile != null) {
        state = updatedProfile;
      } else {
        // Eğer updatedProfile null ise, mevcut state'i koru
        // Bu durumda profil güncelleme başarılı ama response boş olabilir
        print('Profil güncellendi ama response boş, mevcut state korunuyor');
      }
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  void setProfile(TutorModel profile) {
    state = profile;
  }

  void clearProfile() {
    state = null;
  }
}


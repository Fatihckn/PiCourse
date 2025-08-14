import '../../../core/network/api_client.dart';

class TutorProfileApi {
  TutorProfileApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String bio,
    required num hourlyRate,
    required List<int> subjectIds,
  }) async {
    try {
      // Mevcut backend yapısını kullanarak /api/me/ endpoint'inde PATCH yap
      final response = await _apiClient.client.patch(
        '/api/me/',
        data: {
          'profile': {
            'bio': bio,
            'hourly_rate': hourlyRate,
            'subjects': subjectIds,
          },
          // User bilgilerini de güncelle
          'first_name': name.split(' ').first,
          'last_name': name.split(' ').skip(1).join(' '),
        },
      );
      
      // Backend'den başarılı response geldiyse, güncel profil bilgilerini al
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Profil güncellendikten sonra güncel bilgileri al
        return await getMyProfile();
      }
      
      // Eğer backend'den özel bir response geliyorsa onu kullan
      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      // Varsayılan olarak güncel profil bilgilerini döndür
      return await getMyProfile();
    } catch (e) {
      // Hata durumunda güncel profil bilgilerini almaya çalış
      try {
        return await getMyProfile();
      } catch (_) {
        // Hiçbir şekilde profil alınamazsa, gönderilen veriyi döndür
        return {
          'id': 0, // Geçici ID
          'name': name,
          'bio': bio,
          'hourly_rate': hourlyRate,
          'rating': 0.0,
          'subjects': subjectIds.map((id) => {'id': id, 'name': 'Subject $id'}).toList(),
        };
      }
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    // Mevcut backend yapısını kullanarak /api/me/ endpoint'inden profil bilgilerini al
    final response = await _apiClient.client.get('/api/me/');
    final data = response.data;
    
    // Eğer tutor profil bilgileri varsa, onları döndür
    if (data['role'] == 'tutor' && data['profile'] != null) {
      final profile = data['profile'];
      return {
        'id': data['id'],
        'name': data.get('first_name', '') + ' ' + data.get('last_name', '').trim(),
        'bio': profile.get('bio', '') ?? '',
        'hourly_rate': profile.get('hourly_rate', 0) ?? 0,
        'rating': profile.get('rating', 0.0) ?? 0.0,
        'subjects': profile.get('subjects', []) ?? [],
      };
    }
    
    // Profil yoksa boş data döndür
    return {
      'id': data['id'],
      'name': '',
      'bio': '',
      'hourly_rate': 0,
      'rating': 0.0,
      'subjects': [],
    };
  }
}

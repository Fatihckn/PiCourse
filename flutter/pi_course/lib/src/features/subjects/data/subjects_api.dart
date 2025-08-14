import '../../../core/network/api_client.dart';

class SubjectsApi {
  SubjectsApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> listSubjects() async {
    try {
      print('Subjects API: Attempting to fetch from API...');
      
      // Önce /api/subjects/ endpoint'ini dene
      var res = await _apiClient.client.get('/api/subjects/');
      
      print('Subjects API Raw Response: ${res.data}');
      print('Subjects API Response Type: ${res.data.runtimeType}');
      print('Subjects API Status Code: ${res.statusCode}');
      
      // Eğer 404 hatası alırsak, /api/subjects endpoint'ini dene
      if (res.statusCode == 404) {
        print('Subjects API: /api/subjects/ returned 404, trying /api/subjects');
        res = await _apiClient.client.get('/api/subjects');
        print('Subjects API Second attempt Raw Response: ${res.data}');
        print('Subjects API Second attempt Status Code: ${res.statusCode}');
      }
      
      // API'den gelen veri formatını kontrol et
      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        print('Subjects API Response is Map with keys: ${data.keys.toList()}');
        
        // Eğer paginated response ise (results field'ı varsa)
        if (data.containsKey('results') && data['results'] is List) {
          print('Found results field with ${(data['results'] as List).length} items');
          return (data['results'] as List).cast<Map<String, dynamic>>();
        }
        
        // Eğer direkt liste ise
        if (data.containsKey('data') && data['data'] is List) {
          print('Found data field with ${(data['data'] as List).length} items');
          return (data['data'] as List).cast<Map<String, dynamic>>();
        }
        
        // Eğer hiçbiri değilse, tüm veriyi tek item olarak döndür
        print('No results or data field found, returning data as single item');
        return [data];
      }
      
      // Eğer direkt liste ise
      if (res.data is List) {
        print('Subjects API Response is List with ${(res.data as List).length} items');
        return (res.data as List).cast<Map<String, dynamic>>();
      }
      
      // Fallback: test verisi döndür
      print('Subjects API Response format not recognized, returning test data');
      return [
        {'id': 1, 'name': 'Matematik'},
        {'id': 2, 'name': 'Fizik'},
        {'id': 3, 'name': 'Kimya'},
        {'id': 4, 'name': 'Biyoloji'},
        {'id': 5, 'name': 'Tarih'},
      ];
      
    } catch (e) {
      print('Subjects API Error: $e');
      print('Subjects API Error Type: ${e.runtimeType}');
      
      // Hata durumunda test verisi döndür
      print('Subjects API: Error occurred, returning test data');
      return [
        {'id': 1, 'name': 'Matematik'},
        {'id': 2, 'name': 'Fizik'},
        {'id': 3, 'name': 'Kimya'},
        {'id': 4, 'name': 'Biyoloji'},
        {'id': 5, 'name': 'Tarih'},
      ];
    }
  }
}



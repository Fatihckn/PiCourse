import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../domain/subject.dart';
import 'subjects_api.dart';

final subjectsApiProvider = Provider<SubjectsApi>((ref) {
  return SubjectsApi(ref.watch(apiClientProvider));
});

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(subjectsApiProvider));
});

class SubjectsRepository {
  SubjectsRepository(this.api);
  final SubjectsApi api;

  Future<List<SubjectModel>> list() async {
    try {
      print('SubjectsRepository: Starting to fetch subjects...');
      final jsonList = await api.listSubjects();
      
      print('SubjectsRepository: Received ${jsonList.length} items from API');
      if (jsonList.isNotEmpty) {
        print('SubjectsRepository: First item: ${jsonList.first}');
        print('SubjectsRepository: First item type: ${jsonList.first.runtimeType}');
        print('SubjectsRepository: First item keys: ${jsonList.first.keys.toList()}');
      }
      
      final subjects = jsonList.map((json) {
        try {
          print('SubjectsRepository: Parsing subject: $json');
          final subject = SubjectModel.fromJson(json);
          print('SubjectsRepository: Successfully parsed subject: ${subject.id} - ${subject.name}');
          return subject;
        } catch (e) {
          print('SubjectsRepository: Error parsing subject: $json');
          print('SubjectsRepository: Parse error: $e');
          rethrow;
        }
      }).toList();
      
      print('SubjectsRepository: Successfully parsed ${subjects.length} subjects');
      return subjects;
    } catch (e) {
      print('SubjectsRepository: Error in list method: $e');
      print('SubjectsRepository: Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}



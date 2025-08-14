import 'package:json_annotation/json_annotation.dart';
import '../../subjects/domain/subject.dart';

part 'tutor.g.dart';

@JsonSerializable()
class TutorModel {
  const TutorModel({
    required this.id,
    required this.name,
    required this.hourlyRate,
    required this.rating,
    required this.bio,
    required this.subjects,
  });

  final int id;
  final String name;
  @JsonKey(name: 'hourly_rate', fromJson: _parseNum)
  final num hourlyRate;
  @JsonKey(fromJson: _parseNum)
  final num rating;
  final String bio;
  @JsonKey(fromJson: _parseSubjects)
  final List<SubjectModel> subjects;

  static num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<SubjectModel> _parseSubjects(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is Map<String, dynamic>) {
          return SubjectModel.fromJson(e);
        }
        return SubjectModel(id: 0, name: 'Unknown');
      }).toList();
    }
    return [];
  }

  factory TutorModel.fromJson(Map<String, dynamic> json) =>
      _$TutorModelFromJson(json);
  Map<String, dynamic> toJson() => _$TutorModelToJson(this);
}



import 'package:json_annotation/json_annotation.dart';

part 'subject.g.dart';

@JsonSerializable()
class SubjectModel {
  const SubjectModel({required this.id, required this.name});

  final int id;
  final String name;

  factory SubjectModel.fromJson(Map<String, dynamic> json) =>
      _$SubjectModelFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectModelToJson(this);
}



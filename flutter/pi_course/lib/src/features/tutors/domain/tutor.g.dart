// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TutorModel _$TutorModelFromJson(Map<String, dynamic> json) => TutorModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  hourlyRate: TutorModel._parseNum(json['hourly_rate']),
  rating: TutorModel._parseNum(json['rating']),
  bio: json['bio'] as String,
  subjects: TutorModel._parseSubjects(json['subjects']),
);

Map<String, dynamic> _$TutorModelToJson(TutorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hourly_rate': instance.hourlyRate,
      'rating': instance.rating,
      'bio': instance.bio,
      'subjects': instance.subjects,
    };

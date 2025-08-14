import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole { student, tutor }

@JsonSerializable()
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  final int id;
  final String email;
  final UserRole role;
  final String? name;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}



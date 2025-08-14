part of 'user.dart';

// JsonSerializableGenerator

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  name: json['name'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'name': instance.name,
};

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.tutor: 'tutor',
};

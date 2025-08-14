import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/di/providers.dart';
import '../domain/user.dart';
import 'auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authApi: ref.watch(authApiProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required this.authApi, required this.storage});

  final AuthApi authApi;
  final FlutterSecureStorage storage;

  Future<void> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await authApi.register(email: email, password: password, role: role);
  }

  Future<void> login({required String email, required String password}) async {
    final tokens = await authApi.login(email: email, password: password);
    await storage.write(key: 'access_token', value: tokens['access'] as String);
    await storage.write(key: 'refresh_token', value: tokens['refresh'] as String);
  }

  Future<UserModel> me() async {
    final json = await authApi.me();
    return UserModel.fromJson(json);
  }

  Future<void> updateMe(Map<String, dynamic> patch) => authApi.updateMe(patch);

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}



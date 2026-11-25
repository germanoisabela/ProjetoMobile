import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<AuthUser?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String whatsapp,
    String? cep,
    String? city,
    int? age,
  });

  Future<void> sendPasswordResetEmail(String email);
}

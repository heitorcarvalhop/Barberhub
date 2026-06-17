import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_supabase_datasource.dart';
import 'package:barber_hub/features/auth/data/models/user_model.dart';
import 'package:barber_hub/features/auth/domain/entities/user_entity.dart';
import 'package:barber_hub/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:barber_hub/shared/mock/mock_data.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthMockDatasource _mock;
  final AuthSupabaseDatasource _supabase;
  final AuthLocalDatasource _local;

  const AuthRepositoryImpl(this._mock, this._supabase, this._local);

  bool get _useSupabase => _supabase.isConfigured;

  @override
  Future<(UserEntity?, Failure?)> login(String email, String password) async {
    final (user, failure) = _useSupabase
        ? await _supabase.login(email, password)
        : await _mock.login(email, password);
    if (failure != null) return (null, failure);

    await _local.saveSession(user!);
    return (user, null);
  }

  @override
  Future<(UserEntity?, Failure?)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final (user, failure) = _useSupabase
        ? await _supabase.register(
            name: name,
            email: email,
            password: password,
          )
        : await _mock.register(
            name: name,
            email: email,
            password: password,
          );
    if (failure != null) return (null, failure);

    if (!_useSupabase) {
      final json = user!.toJson();
      json['password'] = password;
      await _local.saveRegisteredUser(json);
    }

    await _local.saveSession(user!);
    return (user, null);
  }

  @override
  Future<UserEntity?> tryAutoLogin() async {
    if (_useSupabase) {
      final user = await _supabase.currentUser();
      if (user == null) {
        await _local.clearSession();
        return null;
      }
      await _local.saveSession(user);
      return user;
    }

    final cachedUsers = await _local.loadRegisteredUsers();
    for (final cachedUser in cachedUsers) {
      final email = cachedUser['email'] as String?;
      if (email == null) continue;
      if (!MockData.users.any((u) => u['email'] == email)) {
        MockData.users.add({
          'id': cachedUser['id'],
          'name': cachedUser['name'],
          'email': cachedUser['email'],
          'password': cachedUser['password'],
          'role': cachedUser['role'],
          'linkedId': cachedUser['linkedId'],
        });
      }
    }

    final session = await _local.loadSession();
    if (session == null) return null;

    final valid = MockData.users.any(
      (u) => u['id'] == session.id && u['email'] == session.email,
    );
    if (!valid) {
      await _local.clearSession();
      return null;
    }
    return session;
  }

  @override
  Future<void> logout() async {
    if (_useSupabase) {
      await _supabase.logout();
    }
    await _local.clearSession();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (_useSupabase) {
      await _supabase.sendPasswordReset(email);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> verifyPasswordResetCode(String email, String token) async {
    if (_useSupabase) {
      await _supabase.verifyPasswordResetCode(email, token);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (_useSupabase) {
      await _supabase.updatePassword(newPassword);
    }
  }

  @override
  Future<(UserEntity?, Failure?)> updateProfile({required String name}) async {
    final session = await _local.loadSession();
    if (session == null) {
      return (null, const AuthFailure('Sessão inválida.'));
    }

    final (user, failure) = _useSupabase
        ? await _supabase.updateProfile(name: name)
        : await _mock.updateProfile(id: session.id, name: name);
    if (failure != null) return (null, failure);

    if (!_useSupabase) await _persistMockUser(user!);
    await _local.saveSession(user!);
    return (user, null);
  }

  @override
  Future<Failure?> requestEmailChange(String newEmail) async {
    if (_useSupabase) {
      return await _supabase.requestEmailChange(newEmail);
    }
    await Future.delayed(const Duration(milliseconds: 700));
    return null;
  }

  @override
  Future<(UserEntity?, Failure?)> confirmEmailChange({
    required String newEmail,
    required String token,
  }) async {
    final session = await _local.loadSession();
    if (session == null) {
      return (null, const AuthFailure('Sessão inválida.'));
    }

    final (user, failure) = _useSupabase
        ? await _supabase.confirmEmailChange(newEmail: newEmail, token: token)
        : await _mock.updateEmail(id: session.id, newEmail: newEmail);
    if (failure != null) return (null, failure);

    if (!_useSupabase) await _persistMockUser(user!);
    await _local.saveSession(user!);
    return (user, null);
  }

  /// Mantém a lista de usuários registrados (cache local de dev/mock) em
  /// sincronia após alteração de perfil, preservando a senha já salva.
  Future<void> _persistMockUser(UserModel user) async {
    final json = user.toJson();
    final cachedUsers = await _local.loadRegisteredUsers();
    final cached = cachedUsers.firstWhere(
      (u) => u['id'] == user.id,
      orElse: () => const {},
    );
    json['password'] = cached['password'];
    await _local.saveRegisteredUser(json);
  }
}

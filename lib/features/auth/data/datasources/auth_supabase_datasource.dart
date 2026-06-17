import 'package:barber_hub/core/constants/user_role.dart';
import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/core/services/supabase_service.dart';
import 'package:barber_hub/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSupabaseDatasource {
  SupabaseClient? get _client => SupabaseService.client;

  bool get isConfigured => _client != null;

  Future<(UserModel?, Failure?)> login(String email, String password) async {
    final client = _client;
    if (client == null) {
      return (null, const AuthFailure('Supabase nao configurado.'));
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final authUser = response.user;
      if (authUser == null) {
        return (null, const AuthFailure('E-mail ou senha incorretos.'));
      }

      final profile = await _loadProfile(authUser.id);
      return (_toUser(authUser, profile), null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_authMessage(e.message)));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  Future<(UserModel?, Failure?)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return (null, const AuthFailure('Supabase nao configurado.'));
    }

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': UserRole.client.name,
        },
      );
      final authUser = response.user;
      if (authUser == null) {
        return (null, const AuthFailure('Nao foi possivel criar a conta.'));
      }

      final profile = await _upsertProfile(
        id: authUser.id,
        name: name,
        email: email,
        role: UserRole.client,
      );
      return (_toUser(authUser, profile), null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_authMessage(e.message)));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  Future<UserModel?> currentUser() async {
    final client = _client;
    final authUser = client?.auth.currentUser;
    if (client == null || authUser == null) return null;

    final profile = await _loadProfile(authUser.id);
    return _toUser(authUser, profile);
  }

  Future<void> logout() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    final client = _client;
    if (client == null) return;
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyPasswordResetCode(String email, String token) async {
    final client = _client;
    if (client == null) return;
    await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) return;
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<(UserModel?, Failure?)> updateProfile({required String name}) async {
    final client = _client;
    final authUser = client?.auth.currentUser;
    if (client == null || authUser == null) {
      return (null, const AuthFailure('Sessao invalida.'));
    }

    try {
      final profile = await client
          .from('profiles')
          .update({
            'name': name,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id)
          .select()
          .single();

      await client.auth.updateUser(UserAttributes(data: {'name': name}));

      return (_toUser(authUser, profile), null);
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  Future<Failure?> requestEmailChange(String newEmail) async {
    final client = _client;
    if (client == null) {
      return const AuthFailure('Supabase nao configurado.');
    }

    try {
      await client.auth.updateUser(UserAttributes(email: newEmail));
      return null;
    } on AuthException catch (e) {
      return AuthFailure(_authMessage(e.message));
    } catch (_) {
      return const UnknownFailure();
    }
  }

  Future<(UserModel?, Failure?)> confirmEmailChange({
    required String newEmail,
    required String token,
  }) async {
    final client = _client;
    if (client == null) {
      return (null, const AuthFailure('Supabase nao configurado.'));
    }

    try {
      final response = await client.auth.verifyOTP(
        email: newEmail,
        token: token,
        type: OtpType.emailChange,
      );
      final authUser = response.user ?? client.auth.currentUser;
      if (authUser == null) {
        return (
          null,
          const AuthFailure('Nao foi possivel confirmar o e-mail.')
        );
      }

      final profile = await client
          .from('profiles')
          .update({
            'email': newEmail,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id)
          .select()
          .single();

      return (_toUser(authUser, profile), null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_authMessage(e.message)));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(String id) async {
    final client = _client;
    if (client == null) return null;

    return client.from('profiles').select().eq('id', id).maybeSingle();
  }

  Future<Map<String, dynamic>> _upsertProfile({
    required String id,
    required String name,
    required String email,
    required UserRole role,
  }) async {
    final client = _client!;
    final data = {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    return client.from('profiles').upsert(data).select().single();
  }

  UserModel _toUser(User user, Map<String, dynamic>? profile) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final roleName =
        profile?['role'] as String? ?? metadata['role'] as String? ?? 'client';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.client,
    );

    return UserModel(
      id: user.id,
      name: profile?['name'] as String? ??
          metadata['name'] as String? ??
          user.email?.split('@').first ??
          'Usuario',
      email: profile?['email'] as String? ?? user.email ?? '',
      role: role,
      linkedId: profile?['linked_id'] as String?,
    );
  }

  String _authMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already exists')) {
      return 'Este e-mail ja esta cadastrado.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (normalized.contains('token has expired') ||
        normalized.contains('invalid') && normalized.contains('otp')) {
      return 'Código inválido ou expirado. Solicite um novo código.';
    }
    return message;
  }
}

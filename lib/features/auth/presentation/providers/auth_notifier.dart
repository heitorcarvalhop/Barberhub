/// Por que Riverpod?
///
/// - Compile-time safety: providers não podem ser acessados fora do
///   ProviderScope, eliminando erros de runtime comuns com Provider.
/// - Sem dependência de BuildContext para leitura/escrita de estado.
/// - Testabilidade: fácil substituição de dependências sem InheritedWidget.
/// - AsyncNotifier nativo + watch/listen/ref.invalidate sem boilerplate.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:barber_hub/features/auth/domain/usecases/login_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/register_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/auto_login_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final AutoLoginUseCase _autoLogin;
  final LogoutUseCase _logout;
  final IAuthRepository _repository;

  AuthNotifier({
    required LoginUseCase login,
    required RegisterUseCase register,
    required AutoLoginUseCase autoLogin,
    required LogoutUseCase logout,
    required IAuthRepository repository,
  })  : _login = login,
        _register = register,
        _autoLogin = autoLogin,
        _logout = logout,
        _repository = repository,
        super(const AuthInitial());

  // ── Auto-login ─────────────────────────────────────────────────────────────

  /// Chamado pelo SplashScreen. Retorna a rota inicial.
  Future<String> tryAutoLogin() async {
    state = const AuthLoading();
    try {
      final user = await _autoLogin();
      if (user != null) {
        state = AuthAuthenticated(user);
        return user.initialRoute;
      }
    } catch (e, st) {
      // RISCO #5 CORRIGIDO: o catch original era `catch (_) {}` — engolia
      // qualquer exceção sem deixar rastro, tornando falhas de SharedPreferences
      // corrompido ou decode inválido completamente invisíveis em debug.
      //
      // Em modo debug, loga o erro completo com stack trace para facilitar
      // diagnóstico. Em release, o bloco é removido pelo compilador (kDebugMode).
      // Integre aqui um serviço de crash reporting (ex: Firebase Crashlytics)
      // quando o backend real for implementado:
      //   FirebaseCrashlytics.instance.recordError(e, st);
      if (kDebugMode) {
        debugPrint('[AuthNotifier.tryAutoLogin] Erro ao restaurar sessão: $e');
        debugPrint(st.toString());
      }
    }
    state = const AuthUnauthenticated();
    return '/login';
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Retorna null em sucesso, mensagem de erro em falha.
  Future<String?> login(String email, String password) async {
    state = const AuthLoading();
    final (user, failure) = await _login(email, password);
    if (failure != null) {
      state = AuthError(failure.message);
      return failure.message;
    }
    state = AuthAuthenticated(user!);
    return null;
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = const AuthLoading();
    final (user, failure) = await _register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (failure != null) {
      state = AuthError(failure.message);
      return failure.message;
    }
    state = AuthAuthenticated(user!);
    return null;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _logout();
    state = const AuthUnauthenticated();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    state = const AuthLoading();
    try {
      await _repository.sendPasswordReset(email);
    } catch (_) {
      // ignora erro — a UI mostra tela de confirmação de qualquer forma
      // para não vazar se o email existe ou não
    }
    state = const AuthUnauthenticated();
  }

  Future<String?> verifyPasswordResetCode(String email, String token) async {
    state = const AuthLoading();
    try {
      await _repository.verifyPasswordResetCode(email, token);
      state = const AuthUnauthenticated();
      return null;
    } catch (_) {
      const msg = 'Código inválido ou expirado. Solicite um novo código.';
      state = const AuthError(msg);
      return msg;
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    state = const AuthLoading();
    try {
      await _repository.updatePassword(newPassword);
      state = const AuthUnauthenticated();
      return null;
    } catch (e) {
      final msg = 'Não foi possível atualizar a senha. Tente novamente.';
      state = AuthError(msg);
      return msg;
    }
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }

  // ── Editar perfil ──────────────────────────────────────────────────────────

  /// Retorna null em sucesso, mensagem de erro em falha.
  Future<String?> updateProfile({required String name}) async {
    final previous = state;
    state = const AuthLoading();
    final (user, failure) = await _repository.updateProfile(name: name);
    if (failure != null) {
      state = previous;
      return failure.message;
    }
    state = AuthAuthenticated(user!);
    return null;
  }

  /// Envia o código de confirmação para o novo e-mail. Retorna null em
  /// sucesso, mensagem de erro em falha.
  Future<String?> requestEmailChange(String newEmail) async {
    final previous = state;
    state = const AuthLoading();
    final failure = await _repository.requestEmailChange(newEmail);
    state = previous;
    return failure?.message;
  }

  /// Confirma a troca de e-mail com o código recebido. Retorna null em
  /// sucesso, mensagem de erro em falha.
  Future<String?> confirmEmailChange({
    required String newEmail,
    required String token,
  }) async {
    final previous = state;
    state = const AuthLoading();
    final (user, failure) = await _repository.confirmEmailChange(
      newEmail: newEmail,
      token: token,
    );
    if (failure != null) {
      state = previous;
      return failure.message;
    }
    state = AuthAuthenticated(user!);
    return null;
  }
}

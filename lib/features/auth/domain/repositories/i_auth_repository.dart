import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/auth/domain/entities/user_entity.dart';

/// Contrato do repositório de autenticação.
/// O domínio define a interface; a camada data implementa.
abstract interface class IAuthRepository {
  /// Autentica com email/senha. Retorna null em erro, lança [AuthFailure].
  Future<(UserEntity?, Failure?)> login(String email, String password);

  /// Cria nova conta.
  Future<(UserEntity?, Failure?)> register({
    required String name,
    required String email,
    required String password,
  });

  /// Tenta restaurar sessão salva. Null se não houver sessão.
  Future<UserEntity?> tryAutoLogin();

  /// Encerra sessão.
  Future<void> logout();

  /// Envia código de recuperação de senha para o email.
  Future<void> sendPasswordReset(String email);

  /// Verifica o código de 6 dígitos recebido no email.
  Future<void> verifyPasswordResetCode(String email, String token);

  /// Atualiza a senha após verificação do código.
  Future<void> updatePassword(String newPassword);

  /// Atualiza dados do perfil do usuário autenticado.
  Future<(UserEntity?, Failure?)> updateProfile({required String name});

  /// Inicia a troca de e-mail: envia um código de confirmação para o novo
  /// endereço. O e-mail só é efetivado após [confirmEmailChange].
  Future<Failure?> requestEmailChange(String newEmail);

  /// Confirma a troca de e-mail com o código recebido em [newEmail].
  Future<(UserEntity?, Failure?)> confirmEmailChange({
    required String newEmail,
    required String token,
  });
}

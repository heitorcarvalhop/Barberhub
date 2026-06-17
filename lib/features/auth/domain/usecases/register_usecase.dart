import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/auth/domain/entities/user_entity.dart';
import 'package:barber_hub/features/auth/domain/repositories/i_auth_repository.dart';

/// Caso de uso: criar nova conta de cliente.
class RegisterUseCase {
  final IAuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.trim().length < 3) {
      return (null, const ValidationFailure('Nome muito curto.'));
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      return (null, const ValidationFailure('E-mail inválido.'));
    }
    if (password.length < 6) {
      return (
        null,
        const ValidationFailure('Senha deve ter mínimo 6 caracteres.')
      );
    }
    if (password != confirmPassword) {
      return (null, const ValidationFailure('As senhas não coincidem.'));
    }
    return _repository.register(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}

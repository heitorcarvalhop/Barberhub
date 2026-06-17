import 'package:barber_hub/core/constants/user_role.dart';
import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/auth/data/models/user_model.dart';
import 'package:barber_hub/shared/mock/mock_data.dart';

/// Datasource que simula um backend remoto usando dados em memória.
/// Injeta os usuários do MockData. Simula latência de rede.
class AuthMockDatasource {
  Future<(UserModel?, Failure?)> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // RISCO #4 CORRIGIDO: a comparação original era u['email'] == email,
    // sensível a maiúsculas/minúsculas. O LoginUseCase já normaliza o e-mail
    // antes de chamar o repositório, mas qualquer chamada direta ao datasource
    // (testes, outros fluxos) falharia silenciosamente com e-mails em casing
    // diferente. Normalização aplicada também aqui como defesa em profundidade.
    final normalizedEmail = email.trim().toLowerCase();

    final match = MockData.users
        .where(
          (u) =>
              (u['email'] as String).toLowerCase() == normalizedEmail &&
              u['password'] == password,
        )
        .firstOrNull;

    if (match == null) {
      return (null, const AuthFailure('E-mail ou senha incorretos.'));
    }

    return (
      UserModel(
        id: match['id'] as String,
        name: match['name'] as String,
        email: match['email'] as String,
        role: match['role'] as UserRole,
        linkedId: match['linkedId'] as String?,
      ),
      null,
    );
  }

  Future<(UserModel?, Failure?)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // RISCO #4 CORRIGIDO: mesma normalização aplicada ao cadastro para garantir
    // que duplicatas com casing diferente sejam detectadas corretamente.
    final normalizedEmail = email.trim().toLowerCase();

    final exists = MockData.users.any(
      (u) => (u['email'] as String).toLowerCase() == normalizedEmail,
    );
    if (exists) {
      return (null, const AuthFailure('Este e-mail já está cadastrado.'));
    }

    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': normalizedEmail,
      'password': password,
      'role': UserRole.client,
    };
    MockData.users.add(newUser);

    return (
      UserModel(
        id: newUser['id'] as String,
        name: newUser['name'] as String,
        email: newUser['email'] as String,
        role: UserRole.client,
      ),
      null,
    );
  }

  Future<(UserModel?, Failure?)> updateProfile({
    required String id,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = MockData.users.indexWhere((u) => u['id'] == id);
    if (idx == -1) {
      return (null, const AuthFailure('Usuário não encontrado.'));
    }

    MockData.users[idx] = {...MockData.users[idx], 'name': name};
    final updated = MockData.users[idx];

    return (
      UserModel(
        id: updated['id'] as String,
        name: updated['name'] as String,
        email: updated['email'] as String,
        role: updated['role'] as UserRole,
        linkedId: updated['linkedId'] as String?,
      ),
      null,
    );
  }

  Future<(UserModel?, Failure?)> updateEmail({
    required String id,
    required String newEmail,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = MockData.users.indexWhere((u) => u['id'] == id);
    if (idx == -1) {
      return (null, const AuthFailure('Usuário não encontrado.'));
    }

    final normalizedEmail = newEmail.trim().toLowerCase();
    final alreadyUsed = MockData.users.any(
      (u) =>
          u['id'] != id &&
          (u['email'] as String).toLowerCase() == normalizedEmail,
    );
    if (alreadyUsed) {
      return (null, const AuthFailure('Este e-mail já está cadastrado.'));
    }

    MockData.users[idx] = {...MockData.users[idx], 'email': normalizedEmail};
    final updated = MockData.users[idx];

    return (
      UserModel(
        id: updated['id'] as String,
        name: updated['name'] as String,
        email: updated['email'] as String,
        role: updated['role'] as UserRole,
        linkedId: updated['linkedId'] as String?,
      ),
      null,
    );
  }
}

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:barber_hub/features/auth/data/datasources/auth_supabase_datasource.dart';
import 'package:barber_hub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:barber_hub/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:barber_hub/features/auth/domain/usecases/auto_login_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/login_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/logout_usecase.dart';
import 'package:barber_hub/features/auth/domain/usecases/register_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

export 'auth_state.dart';
export 'auth_notifier.dart';

final _mockDatasourceProvider = Provider<AuthMockDatasource>(
  (_) => AuthMockDatasource(),
);

final _supabaseDatasourceProvider = Provider<AuthSupabaseDatasource>(
  (_) => AuthSupabaseDatasource(),
);

final _localDatasourceProvider = Provider<AuthLocalDatasource>(
  (_) => AuthLocalDatasource(),
);

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(_mockDatasourceProvider),
    ref.read(_supabaseDatasourceProvider),
    ref.read(_localDatasourceProvider),
  );
});

final _loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

final _registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);

final _autoLoginUseCaseProvider = Provider(
  (ref) => AutoLoginUseCase(ref.read(authRepositoryProvider)),
);

final _logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    login: ref.read(_loginUseCaseProvider),
    register: ref.read(_registerUseCaseProvider),
    autoLogin: ref.read(_autoLoginUseCaseProvider),
    logout: ref.read(_logoutUseCaseProvider),
    repository: ref.read(authRepositoryProvider),
  );
});

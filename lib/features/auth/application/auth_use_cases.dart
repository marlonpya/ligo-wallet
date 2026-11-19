import 'package:wallet_domain/wallet_domain.dart';

/// Casos de uso de autenticación (capa Application).
///
/// Son deliberadamente delgados: la regla de negocio vive en el dominio y en
/// el repositorio. Existen para que la presentación dependa de acciones
/// concretas ("iniciar sesión") y no de todo el contrato del repositorio
/// (principio de segregación de interfaces), igual que un UseCase/Interactor
/// en Android o iOS.

/// Inicia sesión con email y contraseña.
final class LoginUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final AuthRepository _repository;

  /// Ejecuta el login. Devuelve el usuario o el `Failure` correspondiente.
  Future<Result<User>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}

/// Cierra la sesión actual.
final class LogoutUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final AuthRepository _repository;

  /// Ejecuta el logout. Nunca falla.
  Future<void> call() => _repository.logout();
}

/// Recupera la sesión guardada al arrancar.
final class RestoreSessionUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final AuthRepository _repository;

  /// Devuelve el estado de sesión inicial. Nunca falla.
  Future<SessionStatus> call() => _repository.restoreSession();
}

/// Observa los cambios de sesión (login, logout, expiración).
final class WatchSessionUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final AuthRepository _repository;

  /// Stream de cambios de sesión.
  Stream<SessionStatus> call() => _repository.sessionStatus;
}

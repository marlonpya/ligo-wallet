import 'dart:async';

import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/src/auth/session_expiry_handler.dart';
import 'package:wallet_data/src/core/api_failure_mapper.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_storage/wallet_storage.dart';

/// Implementación de [AuthRepository] sobre un [WalletApi] y un
/// [SessionStorage].
///
/// Es la misma en todos los flavors: lo que cambia por entorno es el
/// datasource (`DioWalletApi` o `FakeWalletApi`).
final class DefaultAuthRepository
    implements AuthRepository, SessionExpiryHandler {
  /// Crea el repositorio.
  new({required this._api, required this._storage});

  final WalletApi _api;
  final SessionStorage _storage;
  final StreamController<SessionStatus> _statusController =
      StreamController<SessionStatus>.broadcast();

  SessionStatus _current = const Unauthenticated();

  @override
  Stream<SessionStatus> get sessionStatus => _statusController.stream;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final LoginResponseDto response;
    try {
      response = await _api.login(
        LoginRequestDto(email: email.trim(), password: password),
      );
    } on ApiUnauthorizedException {
      // En el login, un 401 significa credenciales incorrectas, no sesión
      // expirada.
      return const Err(InvalidCredentialsFailure());
    } on ApiException catch (exception) {
      return Err(mapApiException(exception));
    }

    if (response.token.isEmpty) return const Err(DataFailure());

    final user = User(id: response.user.id, name: response.user.name);
    try {
      await _storage.write(
        StoredSession(
          token: response.token,
          userId: user.id,
          userName: user.name,
        ),
      );
    } on SessionStorageException {
      // Sin token persistido no hay sesión utilizable: no autenticamos.
      return const Err(UnexpectedFailure());
    }

    _emit(Authenticated(user));
    return Ok(user);
  }

  @override
  Future<SessionStatus> restoreSession() async {
    StoredSession? stored;
    try {
      stored = await _storage.read();
    } on SessionStorageException {
      // Almacenamiento corrupto o inaccesible: se descarta y se pide login.
      await _clearSilently();
    }

    final status = stored == null
        ? const Unauthenticated()
        : Authenticated(User(id: stored.userId, name: stored.userName));
    _emit(status);
    return status;
  }

  @override
  Future<void> logout() async {
    await _clearSilently();
    _emit(const Unauthenticated(UnauthenticatedReason.signedOut));
  }

  @override
  Future<void> expireSession() async {
    // Varias peticiones pueden recibir 401 a la vez: solo la primera cierra.
    // El estado se marca antes del `await` para que una segunda llamada
    // concurrente ya lo vea cerrado.
    if (_current is Unauthenticated) return;
    const expired = Unauthenticated(UnauthenticatedReason.expired);
    _current = expired;
    await _clearSilently();
    _statusController.add(expired);
  }

  /// Libera el stream de sesión.
  Future<void> dispose() => _statusController.close();

  void _emit(SessionStatus status) {
    _current = status;
    _statusController.add(status);
  }

  // Cerrar sesión no puede fallar para el usuario: si el borrado falla, el
  // token igual dejará de ser válido en el backend.
  Future<void> _clearSilently() async {
    try {
      await _storage.clear();
    } on SessionStorageException {
      return;
    }
  }
}

import 'package:wallet_domain/src/auth/session_status.dart';
import 'package:wallet_domain/src/auth/user.dart';
import 'package:wallet_domain/src/core/result.dart';

/// Contrato de autenticación y gestión de sesión.
///
/// La implementación es la única dueña del token: lo guarda en
/// almacenamiento seguro, lo adjunta a las peticiones y lo borra al cerrar
/// sesión o al recibir un 401.
abstract interface class AuthRepository {
  /// Cambios de sesión (login, logout y expiración).
  ///
  /// Es la fuente de verdad para el guard de navegación: cualquier 401 en
  /// cualquier repositorio termina emitiendo
  /// `Unauthenticated(UnauthenticatedReason.expired)`.
  Stream<SessionStatus> get sessionStatus;

  /// Inicia sesión con [email] y [password].
  ///
  /// Devuelve `InvalidCredentialsFailure` si el backend las rechaza.
  Future<Result<User>> login({required String email, required String password});

  /// Recupera la sesión guardada al arrancar la app.
  ///
  /// Nunca falla: si no hay sesión o el almacenamiento no se puede leer,
  /// devuelve `Unauthenticated` (y limpia lo que hubiera).
  Future<SessionStatus> restoreSession();

  /// Cierra la sesión y borra el token guardado.
  Future<void> logout();
}

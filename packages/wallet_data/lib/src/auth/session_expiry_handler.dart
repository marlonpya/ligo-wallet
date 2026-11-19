/// Capacidad de cerrar la sesión cuando el backend rechaza el token.
///
/// Los repositorios que llaman endpoints autenticados dependen de esta
/// interfaz (y no de todo `AuthRepository`) para reaccionar a un 401.
abstract interface class SessionExpiryHandler {
  /// Borra la sesión guardada y emite `Unauthenticated(expired)`.
  Future<void> expireSession();
}

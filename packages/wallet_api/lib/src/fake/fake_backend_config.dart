/// Falla forzada que el backend fake devuelve en cada petición.
enum FakeFailureMode {
  /// Responde normalmente.
  none,

  /// Simula falta de conexión.
  network,

  /// Simula un HTTP 500.
  server,

  /// Simula una respuesta que no cumple el contrato.
  malformed,
}

/// Perillas del backend fake para mostrar en la demo los estados de carga,
/// vacío, error y sesión expirada sin tocar código.
///
/// Es mutable a propósito: el panel de depuración del flavor `development`
/// la modifica en caliente.
final class FakeBackendConfig {
  /// Crea la configuración. Por defecto responde bien con algo de latencia.
  new({
    this.latency = const Duration(milliseconds: 800),
    this.failureMode = FakeFailureMode.none,
    this.emptyMovements = false,
    this.sessionExpired = false,
  });

  /// Demora artificial de cada respuesta (para ver el skeleton).
  Duration latency;

  /// Falla forzada aplicada a todas las peticiones.
  FakeFailureMode failureMode;

  /// Si es `true`, `GET /movements` devuelve una lista vacía.
  bool emptyMovements;

  /// Si es `true`, el backend rechaza el token con 401 (sesión expirada).
  bool sessionExpired;
}

import 'package:feature_auth/feature_auth.dart' show DemoCredentials;
import 'package:flutter/foundation.dart';

/// Entorno de ejecución, uno por flavor.
enum AppEnvironment {
  /// Backend fake en memoria.
  development,

  /// Backend real de pruebas.
  staging,

  /// Backend real de producción.
  production,
}

/// Escenarios que el backend fake puede simular en la demo.
enum DemoScenario {
  /// Responde bien.
  normal,

  /// Responde bien pero con 3 s de latencia (para ver el skeleton).
  slowNetwork,

  /// La cuenta no tiene movimientos.
  empty,

  /// Sin conexión.
  networkError,

  /// HTTP 500.
  serverError,

  /// La respuesta no cumple el contrato.
  malformedResponse,

  /// El token fue rechazado (401): cierra la sesión.
  sessionExpired,
}

/// Controles del backend fake, solo en el flavor `development`.
///
/// La UI solo cambia [scenario]; `bootstrap.dart` traduce el escenario a la
/// configuración de `FakeWalletApi`. Así la presentación no conoce el
/// paquete de datos.
final class DemoBackend {
  new({required this.credentials, required this.scenario});

  final DemoCredentials credentials;
  final ValueNotifier<DemoScenario> scenario;
}

/// Configuración de la app que la presentación puede leer.
///
/// Se arma en `bootstrap.dart`; así la UI no necesita importar los paquetes
/// de datos para saber, por ejemplo, si mostrar la cuenta demo.
final class AppConfig {
  const new({required this.environment, this.demoBackend});

  final AppEnvironment environment;

  /// Solo presente en `development`.
  final DemoBackend? demoBackend;
}

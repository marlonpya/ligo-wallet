import 'package:equatable/equatable.dart';

/// Entorno de ejecución, uno por flavor.
enum AppEnvironment {
  /// Backend fake en memoria.
  development,

  /// Backend real de pruebas.
  staging,

  /// Backend real de producción.
  production,
}

/// Credenciales de la cuenta demo del backend fake.
final class DemoCredentials extends Equatable {
  const new({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Configuración de la app que la presentación puede leer.
///
/// Se arma en `bootstrap.dart`; así la UI no necesita importar los paquetes
/// de datos para saber, por ejemplo, si mostrar la cuenta demo.
final class AppConfig extends Equatable {
  const new({required this.environment, this.demoCredentials});

  final AppEnvironment environment;

  /// Solo presente en `development`: se muestra como ayuda en el login.
  final DemoCredentials? demoCredentials;

  @override
  List<Object?> get props => [environment, demoCredentials];
}

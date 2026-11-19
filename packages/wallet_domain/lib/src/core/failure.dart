import 'package:equatable/equatable.dart';

/// Error de negocio tipado que viaja desde la capa de datos hasta la UI.
///
/// Es `sealed`, así que la presentación puede hacer un `switch` exhaustivo
/// para traducir cada caso a un mensaje localizado. Ningún caso lleva texto
/// del servidor ni stacktrace: la UI nunca debe mostrar datos crudos.
sealed class Failure extends Equatable {
  /// Constructor base para las subclases.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Sin conexión, timeout o cualquier fallo de transporte.
final class NetworkFailure extends Failure {
  /// Crea un [NetworkFailure].
  const new();
}

/// La sesión ya no es válida (HTTP 401 con token inválido o expirado).
///
/// Quien la recibe debe asumir que la sesión fue cerrada.
final class UnauthorizedFailure extends Failure {
  /// Crea un [UnauthorizedFailure].
  const new();
}

/// El login fue rechazado por credenciales incorrectas.
final class InvalidCredentialsFailure extends Failure {
  /// Crea un [InvalidCredentialsFailure].
  const new();
}

/// El servidor respondió con un error (5xx u otro código no esperado).
final class ServerFailure extends Failure {
  /// Crea un [ServerFailure] con el código HTTP, si se conoce.
  const new({this.statusCode});

  /// Código HTTP de la respuesta. Útil para diagnóstico, nunca para la UI.
  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// El recurso solicitado no existe (por ejemplo, un movimiento por id).
final class NotFoundFailure extends Failure {
  /// Crea un [NotFoundFailure].
  const new();
}

/// La respuesta no cumple el contrato esperado (campos faltantes o inválidos).
final class DataFailure extends Failure {
  /// Crea un [DataFailure].
  const new();
}

/// Cualquier error no contemplado. Último recurso; no debería ser frecuente.
final class UnexpectedFailure extends Failure {
  /// Crea un [UnexpectedFailure].
  const new();
}

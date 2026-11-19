import 'package:dio/dio.dart';

/// Error tipado de la capa HTTP.
///
/// Es lo único que puede salir de `WalletApi`: ni `DioException` ni errores de
/// parseo cruzan este límite. La capa de datos lo traduce a `Failure`.
/// Ningún caso guarda el cuerpo de la respuesta ni headers (podrían contener
/// datos sensibles).
sealed class ApiException implements Exception {
  /// Constructor base para las subclases.
  const new();

  /// Traduce una [DioException] al caso correspondiente.
  factory fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const ApiNetworkException();
      case DioExceptionType.badResponse:
        return ApiException.fromStatusCode(exception.response?.statusCode);
      case DioExceptionType.unknown:
        // Dio reporta como `unknown` los fallos al convertir el cuerpo (por
        // ejemplo, un objeto donde se esperaba una lista): es contrato roto.
        final cause = exception.error;
        return cause is TypeError || cause is FormatException
            ? const ApiMalformedResponseException()
            : const ApiUnknownException();
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return const ApiUnknownException();
    }
  }

  /// Traduce un código HTTP de error al caso correspondiente.
  factory fromStatusCode(int? statusCode) => switch (statusCode) {
    401 => const ApiUnauthorizedException(),
    404 => const ApiNotFoundException(),
    _ => ApiServerException(statusCode: statusCode),
  };
}

/// Sin conexión o timeout.
final class ApiNetworkException extends ApiException {
  /// Crea la excepción.
  const new();
}

/// HTTP 401: credenciales o token rechazados.
final class ApiUnauthorizedException extends ApiException {
  /// Crea la excepción.
  const new();
}

/// HTTP 404: recurso inexistente.
final class ApiNotFoundException extends ApiException {
  /// Crea la excepción.
  const new();
}

/// Cualquier otra respuesta de error del servidor.
final class ApiServerException extends ApiException {
  /// Crea la excepción con el código HTTP, si se conoce.
  const new({this.statusCode});

  /// Código HTTP de la respuesta.
  final int? statusCode;
}

/// La respuesta llegó pero no cumple el contrato (JSON inválido o campos
/// faltantes).
final class ApiMalformedResponseException extends ApiException {
  /// Crea la excepción.
  const new();
}

/// Error no clasificable (petición cancelada, certificado inválido, etc.).
final class ApiUnknownException extends ApiException {
  /// Crea la excepción.
  const new();
}

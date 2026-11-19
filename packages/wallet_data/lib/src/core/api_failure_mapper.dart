import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Punto único de traducción de errores de la capa HTTP a errores de
/// dominio. Todos los repositorios pasan por aquí.
Failure mapApiException(ApiException exception) => switch (exception) {
  ApiNetworkException() => const NetworkFailure(),
  ApiUnauthorizedException() => const UnauthorizedFailure(),
  ApiNotFoundException() => const NotFoundFailure(),
  ApiServerException(:final statusCode) => ServerFailure(
    statusCode: statusCode,
  ),
  ApiMalformedResponseException() => const DataFailure(),
  ApiUnknownException() => const UnexpectedFailure(),
};

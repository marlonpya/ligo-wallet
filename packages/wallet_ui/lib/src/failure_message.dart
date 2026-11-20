import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

/// Punto único de traducción `Failure` → mensaje para el usuario.
///
/// El `switch` es exhaustivo sobre la clase sellada: si el dominio agrega un
/// nuevo tipo de fallo, esto deja de compilar hasta darle un mensaje. Nunca
/// se muestra información técnica (códigos HTTP, stacktraces, cuerpo de la
/// respuesta).
extension FailureMessage on Failure {
  /// Mensaje localizado y genérico para este fallo.
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.failureNetwork,
    UnauthorizedFailure() => l10n.failureUnauthorized,
    InvalidCredentialsFailure() => l10n.failureInvalidCredentials,
    ServerFailure() => l10n.failureServer,
    NotFoundFailure() => l10n.failureNotFound,
    DataFailure() => l10n.failureData,
    UnexpectedFailure() => l10n.failureUnexpected,
  };
}

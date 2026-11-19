import 'package:wallet_domain/src/core/result.dart';
import 'package:wallet_domain/src/movements/movement.dart';

/// Contrato de acceso a los movimientos de la cuenta del usuario en sesión.
///
/// Hay una implementación por entorno (remota y fake). Ningún método lanza
/// excepciones: todo error llega como `Err` con un `Failure`.
abstract interface class MovementsRepository {
  /// Obtiene los movimientos del usuario, más recientes primero.
  ///
  /// Si la sesión expiró devuelve `UnauthorizedFailure` y, además, la
  /// implementación debe cerrar la sesión.
  Future<Result<List<Movement>>> getMovements();

  /// Obtiene un movimiento por [id].
  ///
  /// Devuelve `NotFoundFailure` si no existe.
  Future<Result<Movement>> getMovementById(String id);
}

import 'package:wallet_domain/wallet_domain.dart';

/// Obtiene los movimientos del usuario en sesión.
final class GetMovementsUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final MovementsRepository _repository;

  /// Devuelve los movimientos (más recientes primero) o el `Failure`.
  Future<Result<List<Movement>>> call() => _repository.getMovements();
}

/// Obtiene un movimiento por id (pantalla de detalle).
final class GetMovementByIdUseCase {
  /// Crea el caso de uso.
  const new(this._repository);

  final MovementsRepository _repository;

  /// Devuelve el movimiento o `NotFoundFailure` si no existe.
  Future<Result<Movement>> call(String id) => _repository.getMovementById(id);
}

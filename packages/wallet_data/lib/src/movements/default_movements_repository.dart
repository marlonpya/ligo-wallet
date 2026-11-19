import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/src/auth/session_expiry_handler.dart';
import 'package:wallet_data/src/core/api_failure_mapper.dart';
import 'package:wallet_data/src/movements/movement_mapper.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Implementación de [MovementsRepository] sobre un [WalletApi].
///
/// - Un 401 cierra la sesión vía [SessionExpiryHandler]: la autorización se
///   verifica aquí y no solo en el guard de navegación.
/// - Si un movimiento rompe el contrato, se rechaza toda la respuesta con
///   `DataFailure`: en una billetera es preferible no mostrar nada a mostrar
///   un historial incompleto sin avisar.
/// - Guarda en memoria el último listado para resolver el detalle sin otra
///   petición (no hay `GET /movements/{id}` en el contrato).
final class DefaultMovementsRepository implements MovementsRepository {
  /// Crea el repositorio.
  new({required this._api, required this._sessionExpiryHandler});

  final WalletApi _api;
  final SessionExpiryHandler _sessionExpiryHandler;

  Map<String, Movement> _cache = const {};

  @override
  Future<Result<List<Movement>>> getMovements() async {
    final List<MovementDto> dtos;
    try {
      dtos = await _api.getMovements();
    } on ApiUnauthorizedException {
      await _sessionExpiryHandler.expireSession();
      _cache = const {};
      return const Err(UnauthorizedFailure());
    } on ApiException catch (exception) {
      return Err(mapApiException(exception));
    }

    final List<Movement> movements;
    try {
      movements = dtos.map(movementFromDto).toList();
    } on FormatException {
      return const Err(DataFailure());
    }

    _sortNewestFirst(movements);
    _cache = {for (final movement in movements) movement.id: movement};
    return Ok(List.unmodifiable(movements));
  }

  @override
  Future<Result<Movement>> getMovementById(String id) async {
    final cached = _cache[id];
    if (cached != null) return Ok(cached);

    // Sin caché (por ejemplo, un deep link en web tras recargar): se pide el
    // listado y se busca ahí.
    final result = await getMovements();
    return switch (result) {
      Ok() => switch (_cache[id]) {
        final Movement movement => Ok(movement),
        null => const Err(NotFoundFailure()),
      },
      Err(:final failure) => Err(failure),
    };
  }

  // Más recientes primero; los que no tienen fecha van al final. El orden
  // es estable, así que se respeta el de la API ante empates.
  static void _sortNewestFirst(List<Movement> movements) {
    final indexed = movements.indexed.toList()
      ..sort((a, b) {
        final dateA = a.$2.date;
        final dateB = b.$2.date;
        if (dateA == null && dateB == null) return a.$1.compareTo(b.$1);
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        final byDate = dateB.compareTo(dateA);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    movements
      ..clear()
      ..addAll(indexed.map((entry) => entry.$2));
  }
}

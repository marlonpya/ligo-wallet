part of 'movements_bloc.dart';

/// Etapa de la carga inicial.
enum MovementsStatus {
  /// Aún no se pidió nada.
  initial,

  /// Cargando sin datos previos (skeleton).
  loading,

  /// Hay datos (la lista puede estar vacía).
  success,

  /// La carga falló y no hay datos que mostrar (pantalla de error + Retry).
  failure,
}

/// Estado del listado de movimientos.
///
/// Los estados de UI (skeleton, vacío, sin resultados, error, lista) se
/// derivan de aquí con getters para que haya una única fuente de verdad.
final class MovementsState extends Equatable {
  const new({
    this.status = MovementsStatus.initial,
    this.movements = const [],
    this.query = const MovementQuery(),
    this.isRefreshing = false,
    this.failure,
  });

  final MovementsStatus status;

  /// Todos los movimientos recibidos, sin filtrar.
  final List<Movement> movements;

  /// Búsqueda y filtro actuales.
  final MovementQuery query;

  /// `true` durante un pull to refresh (la lista sigue visible).
  final bool isRefreshing;

  /// Último fallo. Con [MovementsStatus.failure] se muestra a pantalla
  /// completa; con datos visibles (refresco fallido) se avisa con snackbar.
  final Failure? failure;

  /// `true` si ya se cargó algo al menos una vez.
  bool get hasData => status == MovementsStatus.success;

  /// Movimientos que cumplen la búsqueda y el filtro.
  List<Movement> get visibleMovements => query.apply(movements);

  /// La cuenta no tiene movimientos.
  bool get isEmpty => hasData && movements.isEmpty;

  /// Hay movimientos, pero ninguno cumple la búsqueda/filtro.
  bool get hasNoResults =>
      hasData && movements.isNotEmpty && visibleMovements.isEmpty;

  MovementsState copyWith({
    MovementsStatus? status,
    List<Movement>? movements,
    MovementQuery? query,
    bool? isRefreshing,
    Failure? failure,
    bool clearFailure = false,
  }) => MovementsState(
    status: status ?? this.status,
    movements: movements ?? this.movements,
    query: query ?? this.query,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, movements, query, isRefreshing, failure];

  // Sin el detalle de los movimientos: son datos financieros.
  @override
  String toString() =>
      'MovementsState(status: $status, count: ${movements.length}, '
      'refreshing: $isRefreshing, failure: $failure)';
}

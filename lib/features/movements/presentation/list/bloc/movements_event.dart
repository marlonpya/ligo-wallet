part of 'movements_bloc.dart';

/// Eventos del [MovementsBloc].
sealed class MovementsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

/// Carga inicial o reintento tras un error (muestra skeleton).
final class MovementsLoadRequested extends MovementsEvent {
  const new();
}

/// Pull to refresh o botón de refrescar (conserva la lista visible).
final class MovementsRefreshRequested extends MovementsEvent {
  const new();
}

/// Cambió el texto de búsqueda (se aplica con debounce).
final class MovementsSearchChanged extends MovementsEvent {
  const new(this.term);

  final String term;

  @override
  List<Object?> get props => [term];
}

/// Cambió el filtro Todos / Ingresos / Salidas.
final class MovementsFilterChanged extends MovementsEvent {
  const new(this.filter);

  final MovementFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Limpiar búsqueda y filtro (desde el estado "sin resultados").
final class MovementsQueryCleared extends MovementsEvent {
  const new();
}

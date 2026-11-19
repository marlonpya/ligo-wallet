import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:wallet_domain/wallet_domain.dart';

part 'movements_event.dart';
part 'movements_state.dart';

/// Espera antes de aplicar la búsqueda mientras el usuario escribe.
const Duration searchDebounce = Duration(milliseconds: 300);

/// Aplica la búsqueda solo cuando el usuario deja de escribir
/// ([searchDebounce]) y descarta la anterior si llega una nueva (equivalente a
/// `debounce` + `flatMapLatest` en Flow/Combine).
EventTransformer<E> _debounceRestartable<E>(Duration duration) =>
    (events, mapper) =>
        restartable<E>().call(events.debounce(duration), mapper);

/// Listado de movimientos con búsqueda, filtro, refresco y reintento.
///
/// La regla de qué se muestra vive en el dominio (`MovementQuery`); el bloc
/// solo guarda la lista completa y el criterio actual.
class MovementsBloc extends Bloc<MovementsEvent, MovementsState> {
  /// Crea el bloc.
  new({required this._getMovements}) : super(const MovementsState()) {
    // `droppable`: cargar/refrescar mientras ya hay una petición en curso no
    // dispara otra.
    on<MovementsLoadRequested>(_onLoadRequested, transformer: droppable());
    on<MovementsRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<MovementsSearchChanged>(
      _onSearchChanged,
      transformer: _debounceRestartable(searchDebounce),
    );
    on<MovementsFilterChanged>(_onFilterChanged);
    on<MovementsQueryCleared>(_onQueryCleared);
  }

  final GetMovementsUseCase _getMovements;

  Future<void> _onLoadRequested(
    MovementsLoadRequested event,
    Emitter<MovementsState> emit,
  ) async {
    emit(state.copyWith(status: MovementsStatus.loading, clearFailure: true));
    final result = await _getMovements();
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(status: MovementsStatus.success, movements: value));
      case Err(:final failure):
        emit(state.copyWith(status: MovementsStatus.failure, failure: failure));
    }
  }

  Future<void> _onRefreshRequested(
    MovementsRefreshRequested event,
    Emitter<MovementsState> emit,
  ) async {
    // Sin datos previos, refrescar equivale a cargar (con skeleton).
    if (!state.hasData) {
      await _onLoadRequested(const MovementsLoadRequested(), emit);
      return;
    }

    emit(state.copyWith(isRefreshing: true, clearFailure: true));
    final result = await _getMovements();
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(movements: value, isRefreshing: false));
      case Err(:final failure):
        // Se conservan los datos que ya se veían; la UI avisa con un
        // snackbar en lugar de reemplazar la lista por la pantalla de error.
        emit(state.copyWith(isRefreshing: false, failure: failure));
    }
  }

  void _onSearchChanged(
    MovementsSearchChanged event,
    Emitter<MovementsState> emit,
  ) {
    emit(state.copyWith(query: state.query.copyWith(searchTerm: event.term)));
  }

  void _onFilterChanged(
    MovementsFilterChanged event,
    Emitter<MovementsState> emit,
  ) {
    emit(state.copyWith(query: state.query.copyWith(filter: event.filter)));
  }

  void _onQueryCleared(
    MovementsQueryCleared event,
    Emitter<MovementsState> emit,
  ) {
    emit(state.copyWith(query: const MovementQuery()));
  }
}

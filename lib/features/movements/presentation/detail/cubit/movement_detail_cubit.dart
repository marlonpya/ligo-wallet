import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Estado del detalle de un movimiento.
sealed class MovementDetailState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

/// Buscando el movimiento.
final class MovementDetailLoading extends MovementDetailState {
  const new();
}

/// Movimiento encontrado.
final class MovementDetailLoaded extends MovementDetailState {
  const new(this.movement);

  final Movement movement;

  @override
  List<Object?> get props => [movement];
}

/// No se pudo obtener (no existe, sin red, etc.).
final class MovementDetailFailure extends MovementDetailState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Detalle de un movimiento. Cubit (sin eventos) porque solo tiene dos
/// acciones simples: cargar y reintentar.
class MovementDetailCubit extends Cubit<MovementDetailState> {
  /// Crea el cubit para el movimiento [_movementId].
  new({required this._getMovementById, required this._movementId})
    : super(const MovementDetailLoading());

  final GetMovementByIdUseCase _getMovementById;
  final String _movementId;

  /// Carga (o recarga) el movimiento.
  Future<void> load() async {
    emit(const MovementDetailLoading());
    final result = await _getMovementById(_movementId);
    emit(switch (result) {
      Ok(:final value) => MovementDetailLoaded(value),
      Err(:final failure) => MovementDetailFailure(failure),
    });
  }
}

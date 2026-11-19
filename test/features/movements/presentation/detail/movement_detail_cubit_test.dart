import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:ligo_wallet/features/movements/presentation/detail/cubit/movement_detail_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late MovementsRepository repository;

  setUp(() => repository = MockMovementsRepository());

  MovementDetailCubit buildCubit() => MovementDetailCubit(
    getMovementById: GetMovementByIdUseCase(repository),
    movementId: 'mov_001',
  );

  test('empieza cargando', () {
    expect(buildCubit().state, const MovementDetailLoading());
  });

  blocTest<MovementDetailCubit, MovementDetailState>(
    'carga el movimiento',
    setUp: () =>
        when(() => repository.getMovementById('mov_001'))
            .thenAnswer((_) async => Ok(qrPayment)),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const MovementDetailLoading(),
      MovementDetailLoaded(qrPayment),
    ],
  );

  blocTest<MovementDetailCubit, MovementDetailState>(
    'expone el fallo si no existe',
    setUp: () =>
        when(() => repository.getMovementById('mov_001'))
            .thenAnswer((_) async => const Err(NotFoundFailure())),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const MovementDetailLoading(),
      const MovementDetailFailure(NotFoundFailure()),
    ],
  );

  test('los estados comparan por valor', () {
    expect(const MovementDetailLoading().props, isEmpty);
    expect(
      const MovementDetailFailure(NetworkFailure()),
      isNot(const MovementDetailFailure(ServerFailure())),
    );
    expect(MovementDetailLoaded(qrPayment), MovementDetailLoaded(qrPayment));
  });
}

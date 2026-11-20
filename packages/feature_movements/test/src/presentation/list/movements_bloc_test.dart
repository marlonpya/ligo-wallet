import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_movements/src/application/movements_use_cases.dart';
import 'package:feature_movements/src/presentation/list/bloc/movements_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  // Margen sobre el debounce: esperar exactamente `searchDebounce` compite
  // con el timer y falla de forma intermitente con la máquina cargada.
  final debounceWait = searchDebounce + const Duration(milliseconds: 150);

  late MovementsRepository repository;

  setUp(() => repository = MockMovementsRepository());

  MovementsBloc buildBloc() =>
      MovementsBloc(getMovements: GetMovementsUseCase(repository));

  final loaded = MovementsState(
    status: MovementsStatus.success,
    movements: allMovements,
  );

  test('el estado inicial no tiene datos', () {
    final state = buildBloc().state;

    expect(state.status, MovementsStatus.initial);
    expect(state.hasData, isFalse);
    expect(state.visibleMovements, isEmpty);
  });

  group('MovementsLoadRequested', () {
    blocTest<MovementsBloc, MovementsState>(
      'loading -> success con los movimientos',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => Ok(allMovements)),
      build: buildBloc,
      act: (bloc) => bloc.add(const MovementsLoadRequested()),
      expect: () => [
        const MovementsState(status: MovementsStatus.loading),
        loaded,
      ],
    );

    blocTest<MovementsBloc, MovementsState>(
      'lista vacía: success y estado vacío',
      setUp: () =>
          when(repository.getMovements).thenAnswer((_) async => const Ok([])),
      build: buildBloc,
      act: (bloc) => bloc.add(const MovementsLoadRequested()),
      skip: 1,
      expect: () => [const MovementsState(status: MovementsStatus.success)],
      verify: (bloc) {
        expect(bloc.state.isEmpty, isTrue);
        expect(bloc.state.hasNoResults, isFalse);
      },
    );

    blocTest<MovementsBloc, MovementsState>(
      'error de red: loading -> failure con el motivo',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const MovementsLoadRequested()),
      expect: () => [
        const MovementsState(status: MovementsStatus.loading),
        const MovementsState(
          status: MovementsStatus.failure,
          failure: NetworkFailure(),
        ),
      ],
    );

    blocTest<MovementsBloc, MovementsState>(
      'reintentar tras un error limpia el fallo y carga',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => Ok(allMovements)),
      build: buildBloc,
      seed: () => const MovementsState(
        status: MovementsStatus.failure,
        failure: NetworkFailure(),
      ),
      act: (bloc) => bloc.add(const MovementsLoadRequested()),
      expect: () => [
        const MovementsState(status: MovementsStatus.loading),
        loaded,
      ],
    );
  });

  group('MovementsRefreshRequested', () {
    blocTest<MovementsBloc, MovementsState>(
      'con datos: mantiene la lista visible mientras refresca',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => Ok([qrPayment])),
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc.add(const MovementsRefreshRequested()),
      expect: () => [
        loaded.copyWith(isRefreshing: true),
        loaded.copyWith(movements: [qrPayment]),
      ],
    );

    blocTest<MovementsBloc, MovementsState>(
      'refresco fallido conserva los datos y expone el fallo',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => const Err(ServerFailure())),
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc.add(const MovementsRefreshRequested()),
      expect: () => [
        loaded.copyWith(isRefreshing: true),
        loaded.copyWith(failure: const ServerFailure()),
      ],
      verify: (bloc) => expect(bloc.state.visibleMovements, allMovements),
    );

    blocTest<MovementsBloc, MovementsState>(
      'sin datos previos se comporta como una carga',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => Ok(allMovements)),
      build: buildBloc,
      act: (bloc) => bloc.add(const MovementsRefreshRequested()),
      expect: () => [
        const MovementsState(status: MovementsStatus.loading),
        loaded,
      ],
    );

    blocTest<MovementsBloc, MovementsState>(
      'ignora refrescos repetidos mientras hay uno en curso',
      setUp: () {
        final completer = Completer<Result<List<Movement>>>();
        when(repository.getMovements).thenAnswer((_) => completer.future);
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => completer.complete(Ok(allMovements)),
        );
      },
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc
        ..add(const MovementsRefreshRequested())
        ..add(const MovementsRefreshRequested()),
      wait: const Duration(milliseconds: 20),
      verify: (_) => verify(repository.getMovements).called(1),
    );
  });

  group('búsqueda y filtro', () {
    blocTest<MovementsBloc, MovementsState>(
      'la búsqueda se aplica tras el debounce',
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc.add(const MovementsSearchChanged('pago')),
      wait: debounceWait,
      expect: () => [
        loaded.copyWith(query: const MovementQuery(searchTerm: 'pago')),
      ],
      verify: (bloc) => expect(bloc.state.visibleMovements, [qrPayment]),
    );

    blocTest<MovementsBloc, MovementsState>(
      'escribir rápido solo aplica el último término',
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) => bloc
        ..add(const MovementsSearchChanged('p'))
        ..add(const MovementsSearchChanged('pa'))
        ..add(const MovementsSearchChanged('pago')),
      wait: debounceWait,
      expect: () => [
        loaded.copyWith(query: const MovementQuery(searchTerm: 'pago')),
      ],
    );

    blocTest<MovementsBloc, MovementsState>(
      'el filtro se aplica de inmediato',
      build: buildBloc,
      seed: () => loaded,
      act: (bloc) =>
          bloc.add(const MovementsFilterChanged(MovementFilter.income)),
      expect: () => [
        loaded.copyWith(
          query: const MovementQuery(filter: MovementFilter.income),
        ),
      ],
      verify: (bloc) => expect(bloc.state.visibleMovements, [salary]),
    );

    blocTest<MovementsBloc, MovementsState>(
      'búsqueda + filtro sin coincidencias: estado sin resultados',
      build: buildBloc,
      seed: () => loaded.copyWith(
        query: const MovementQuery(filter: MovementFilter.income),
      ),
      act: (bloc) => bloc.add(const MovementsSearchChanged('pago')),
      wait: debounceWait,
      verify: (bloc) {
        expect(bloc.state.visibleMovements, isEmpty);
        expect(bloc.state.hasNoResults, isTrue);
        expect(bloc.state.isEmpty, isFalse);
      },
    );

    blocTest<MovementsBloc, MovementsState>(
      'limpiar restablece búsqueda y filtro',
      build: buildBloc,
      seed: () => loaded.copyWith(
        query: const MovementQuery(
          searchTerm: 'x',
          filter: MovementFilter.expense,
        ),
      ),
      act: (bloc) => bloc.add(const MovementsQueryCleared()),
      expect: () => [loaded],
    );

    blocTest<MovementsBloc, MovementsState>(
      'el refresco conserva la búsqueda y el filtro',
      setUp: () =>
          when(repository.getMovements)
              .thenAnswer((_) async => Ok(allMovements)),
      build: buildBloc,
      seed: () => loaded.copyWith(
        query: const MovementQuery(filter: MovementFilter.income),
      ),
      act: (bloc) => bloc.add(const MovementsRefreshRequested()),
      skip: 1,
      verify: (bloc) => expect(bloc.state.visibleMovements, [salary]),
    );
  });

  group('MovementsState', () {
    test('toString no expone los movimientos', () {
      expect(loaded.toString(), isNot(contains('Pago QR')));
      expect(loaded.toString(), contains('count: 3'));
    });

    test('los eventos comparan por valor', () {
      expect(
        const MovementsSearchChanged('a'),
        isNot(const MovementsSearchChanged('b')),
      );
      expect(
        const MovementsFilterChanged(MovementFilter.all),
        isNot(const MovementsFilterChanged(MovementFilter.income)),
      );
      expect(const MovementsLoadRequested().props, isEmpty);
    });
  });
}

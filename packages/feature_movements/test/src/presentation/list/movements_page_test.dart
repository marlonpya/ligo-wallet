import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_movements/src/presentation/list/bloc/movements_bloc.dart';
import 'package:feature_movements/src/presentation/list/view/movements_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

class _MockMovementsBloc extends MockBloc<MovementsEvent, MovementsState>
    implements MovementsBloc;

void main() {
  final loaded = MovementsState(
    status: MovementsStatus.success,
    movements: allMovements,
  );

  late MovementsBloc movementsBloc;

  setUpAll(() => registerFallbackValue(const MovementsLoadRequested()));

  setUp(() {
    movementsBloc = _MockMovementsBloc();
  });

  Future<void> pumpView(
    WidgetTester tester,
    MovementsState state, {
    String? userName = 'Ronald Castillo',
    ValueChanged<String>? onMovementSelected,
    List<Widget> actions = const [],
  }) async {
    when(() => movementsBloc.state).thenReturn(state);
    await tester.pumpApp(
      BlocProvider.value(
        value: movementsBloc,
        child: MovementsView(
          userName: userName,
          onMovementSelected: onMovementSelected ?? (_) {},
          actions: actions,
        ),
      ),
    );
  }

  testWidgets('saluda al usuario en sesión', (tester) async {
    await pumpView(tester, loaded);

    expect(find.text('Hola, Ronald Castillo'), findsOneWidget);
  });

  testWidgets('muestra el skeleton mientras carga', (tester) async {
    await pumpView(
      tester,
      const MovementsState(status: MovementsStatus.loading),
    );

    expect(find.byKey(const Key('movementsSkeleton')), findsOneWidget);
    expect(find.bySemanticsLabel('Cargando movimientos'), findsOneWidget);
  });

  group('error', () {
    testWidgets('muestra el mensaje genérico y reintenta', (tester) async {
      await pumpView(
        tester,
        const MovementsState(
          status: MovementsStatus.failure,
          failure: NetworkFailure(),
        ),
      );

      expect(find.byKey(const Key('movements_errorView')), findsOneWidget);
      expect(
        find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reintentar'));

      verify(() => movementsBloc.add(const MovementsLoadRequested())).called(1);
    });
  });

  testWidgets('cuenta sin movimientos muestra el estado vacío', (tester) async {
    await pumpView(
      tester,
      const MovementsState(status: MovementsStatus.success),
    );

    expect(find.byKey(const Key('movements_emptyView')), findsOneWidget);
    expect(find.text('Aún no tienes movimientos'), findsOneWidget);
  });

  testWidgets('sin resultados permite limpiar filtros', (tester) async {
    await pumpView(
      tester,
      loaded.copyWith(query: const MovementQuery(searchTerm: 'netflix')),
    );

    expect(find.byKey(const Key('movements_noResultsView')), findsOneWidget);
    await tester.tap(find.text('Limpiar filtros'));

    verify(() => movementsBloc.add(const MovementsQueryCleared())).called(1);
  });

  group('lista', () {
    testWidgets('muestra cada movimiento con monto con signo', (tester) async {
      await pumpView(tester, loaded);

      expect(find.text('Pago QR'), findsOneWidget);
      expect(find.text('−S/ 25.50'), findsOneWidget);
      expect(find.text('+S/ 3,500.00'), findsOneWidget);
      expect(find.text('18 nov 2026'), findsOneWidget);
    });

    testWidgets('etiqueta los pendientes pero no los completados', (
      tester,
    ) async {
      await pumpView(tester, loaded);

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Completado'), findsNothing);
    });

    testWidgets('muestra solo los movimientos que cumplen el filtro', (
      tester,
    ) async {
      await pumpView(
        tester,
        loaded.copyWith(
          query: const MovementQuery(filter: MovementFilter.income),
        ),
      );

      expect(find.text('Abono de sueldo'), findsOneWidget);
      expect(find.text('Pago QR'), findsNothing);
    });

    testWidgets('pull to refresh pide refrescar y espera el resultado', (
      tester,
    ) async {
      final states = StreamController<MovementsState>();
      addTearDown(states.close);
      whenListen(movementsBloc, states.stream, initialState: loaded);
      when(() => movementsBloc.add(const MovementsRefreshRequested()))
          .thenAnswer((_) {
            states
              ..add(loaded.copyWith(isRefreshing: true))
              ..add(loaded);
          });
      await pumpView(tester, loaded);

      await tester.fling(find.text('Pago QR'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      verify(() => movementsBloc.add(const MovementsRefreshRequested()))
          .called(1);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('el indicador termina aunque el bloc se cierre', (
      tester,
    ) async {
      final states = StreamController<MovementsState>();
      whenListen(movementsBloc, states.stream, initialState: loaded);
      when(() => movementsBloc.add(const MovementsRefreshRequested()))
          .thenAnswer((_) => states.close());
      await pumpView(tester, loaded);

      await tester.fling(find.text('Pago QR'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });
  });

  group('acciones', () {
    testWidgets('escribir en la búsqueda envía el término', (tester) async {
      await pumpView(tester, loaded);

      await tester.enterText(
        find.byKey(const Key('movements_searchField')),
        'pago',
      );

      verify(() => movementsBloc.add(const MovementsSearchChanged('pago')))
          .called(1);
    });

    testWidgets('el botón de la búsqueda la limpia', (tester) async {
      await pumpView(tester, loaded);
      await tester.enterText(
        find.byKey(const Key('movements_searchField')),
        'pago',
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pump();

      verify(() => movementsBloc.add(const MovementsSearchChanged('')))
          .called(1);
      expect(find.text('pago'), findsNothing);
    });

    testWidgets('limpiar filtros desde fuera vacía el campo', (tester) async {
      final searching = loaded.copyWith(
        query: const MovementQuery(searchTerm: 'pago'),
      );
      final states = StreamController<MovementsState>();
      addTearDown(states.close);
      whenListen(movementsBloc, states.stream, initialState: searching);
      await pumpView(tester, searching);
      await tester.enterText(
        find.byKey(const Key('movements_searchField')),
        'pago',
      );

      states.add(loaded);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('movements_searchField')),
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('el filtro envía la opción elegida', (tester) async {
      await pumpView(tester, loaded);

      await tester.tap(find.text('Ingresos'));

      verify(
        () => movementsBloc.add(
          const MovementsFilterChanged(MovementFilter.income),
        ),
      ).called(1);
    });

    testWidgets('el botón de refrescar pide refrescar', (tester) async {
      await pumpView(tester, loaded);

      await tester.tap(find.byKey(const Key('movements_refreshButton')));

      verify(() => movementsBloc.add(const MovementsRefreshRequested()))
          .called(1);
    });

    testWidgets('el botón de refrescar se desactiva mientras refresca', (
      tester,
    ) async {
      await pumpView(tester, loaded.copyWith(isRefreshing: true));

      final button = tester.widget<IconButton>(
        find.byKey(const Key('movements_refreshButton')),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('un refresco fallido avisa sin ocultar la lista', (tester) async {
    whenListen(
      movementsBloc,
      Stream.fromIterable([loaded.copyWith(failure: const ServerFailure())]),
      initialState: loaded,
    );
    await tester.pumpApp(
      BlocProvider.value(
        value: movementsBloc,
        child: MovementsView(onMovementSelected: (_) {}),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'No se pudo actualizar: Estamos teniendo problemas. '
        'Inténtalo más tarde.',
      ),
      findsOneWidget,
    );
    expect(find.text('Pago QR'), findsOneWidget);
  });

  group('composición desde el app shell', () {
    testWidgets('sin nombre no saluda', (tester) async {
      await pumpView(tester, loaded, userName: null);

      expect(find.textContaining('Hola'), findsNothing);
    });

    testWidgets('tocar un movimiento avisa su id', (tester) async {
      final selected = <String>[];
      await pumpView(tester, loaded, onMovementSelected: selected.add);

      await tester.tap(find.text('Pago QR'));

      expect(selected, ['mov_001']);
    });

    testWidgets('muestra las acciones extra en la barra', (tester) async {
      await pumpView(
        tester,
        loaded,
        actions: [const Icon(Icons.logout, key: Key('extraAction'))],
      );

      expect(find.byKey(const Key('extraAction')), findsOneWidget);
    });
  });
}

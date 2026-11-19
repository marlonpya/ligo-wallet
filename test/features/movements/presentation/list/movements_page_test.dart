import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/list/bloc/movements_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/list/view/movements_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../../helpers/helpers.dart';

class _MockMovementsBloc extends MockBloc<MovementsEvent, MovementsState>
    implements MovementsBloc;

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc;

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');
  final loaded = MovementsState(
    status: MovementsStatus.success,
    movements: allMovements,
  );

  late MovementsBloc movementsBloc;
  late SessionBloc sessionBloc;

  setUpAll(() => registerFallbackValue(const MovementsLoadRequested()));

  setUp(() {
    movementsBloc = _MockMovementsBloc();
    sessionBloc = _MockSessionBloc();
    when(() => sessionBloc.state).thenReturn(const SessionAuthenticated(user));
  });

  Future<void> pumpView(
    WidgetTester tester,
    MovementsState state, {
    AppConfig config = testConfig,
  }) async {
    when(() => movementsBloc.state).thenReturn(state);
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: movementsBloc),
          BlocProvider.value(value: sessionBloc),
        ],
        child: const MovementsView(),
      ),
      config: config,
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: movementsBloc),
          BlocProvider.value(value: sessionBloc),
        ],
        child: const MovementsView(),
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

  group('panel de escenarios demo', () {
    testWidgets('no aparece sin backend fake', (tester) async {
      await pumpView(tester, loaded);

      expect(find.byKey(const Key('movements_demoPanelButton')), findsNothing);
    });

    testWidgets('cambia el escenario y recarga', (tester) async {
      final scenario = ValueNotifier(DemoScenario.normal);
      await pumpView(
        tester,
        loaded,
        config: AppConfig(
          environment: AppEnvironment.development,
          demoBackend: DemoBackend(
            credentials: const DemoCredentials(email: 'a', password: 'b'),
            scenario: scenario,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('movements_demoPanelButton')));
      await tester.pumpAndSettle();
      expect(find.text('Escenario del backend fake'), findsOneWidget);
      for (final value in DemoScenario.values) {
        expect(find.byKey(Key('demoScenario_${value.name}')), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('demoScenario_networkError')));
      await tester.pumpAndSettle();

      expect(scenario.value, DemoScenario.networkError);
      verify(() => movementsBloc.add(const MovementsLoadRequested())).called(1);
    });

    testWidgets('cerrar el panel sin elegir no cambia nada', (tester) async {
      final scenario = ValueNotifier(DemoScenario.empty);
      await pumpView(
        tester,
        loaded,
        config: AppConfig(
          environment: AppEnvironment.development,
          demoBackend: DemoBackend(
            credentials: const DemoCredentials(email: 'a', password: 'b'),
            scenario: scenario,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('movements_demoPanelButton')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(scenario.value, DemoScenario.empty);
      verifyNever(() => movementsBloc.add(any()));
    });
  });
}

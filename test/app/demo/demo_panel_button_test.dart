import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_movements/feature_movements.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/app/demo/demo_panel_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockMovementsBloc extends MockBloc<MovementsEvent, MovementsState>
    implements MovementsBloc;

void main() {
  late MovementsBloc movementsBloc;

  setUpAll(() => registerFallbackValue(const MovementsLoadRequested()));

  setUp(() {
    movementsBloc = _MockMovementsBloc();
    when(() => movementsBloc.state).thenReturn(const MovementsState());
  });

  Future<ValueNotifier<DemoScenario>> pumpButton(
    WidgetTester tester,
    DemoScenario initial,
  ) async {
    final scenario = ValueNotifier(initial);
    await tester.pumpApp(
      BlocProvider.value(
        value: movementsBloc,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              DemoPanelButton(
                demo: DemoBackend(
                  credentials: const DemoCredentials(email: 'a', password: 'b'),
                  scenario: scenario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return scenario;
  }

  testWidgets('cambia el escenario y recarga el listado', (tester) async {
    final scenario = await pumpButton(tester, DemoScenario.normal);

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
    final scenario = await pumpButton(tester, DemoScenario.empty);

    await tester.tap(find.byKey(const Key('movements_demoPanelButton')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(scenario.value, DemoScenario.empty);
    verifyNever(() => movementsBloc.add(any()));
  });
}

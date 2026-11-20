import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/helpers.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc;

void main() {
  late SessionBloc sessionBloc;

  setUpAll(() => registerFallbackValue(const SessionStarted()));

  setUp(() {
    sessionBloc = _MockSessionBloc();
    when(() => sessionBloc.state).thenReturn(const SessionInitial());
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpApp(
      BlocProvider.value(
        value: sessionBloc,
        child: Scaffold(appBar: AppBar(actions: const [LogoutButton()])),
      ),
    );
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('confirmar pide el cierre de sesión', (tester) async {
    await openDialog(tester);
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutConfirmButton')));
    await tester.pumpAndSettle();

    verify(() => sessionBloc.add(const SessionLogoutRequested())).called(1);
  });

  testWidgets('cancelar no cierra la sesión', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsNothing);
    verifyNever(() => sessionBloc.add(any()));
  });
}

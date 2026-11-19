import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/app.dart';
import 'package:ligo_wallet/app/view/splash_page.dart';
import 'package:ligo_wallet/features/auth/presentation/login/view/login_page.dart';
import 'package:ligo_wallet/features/movements/presentation/view/movements_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../helpers/helpers.dart';

/// Flujo de sesión completo sobre la app real (router + guard + blocs), con
/// el repositorio simulado.
void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');

  late AuthRepository repository;
  late StreamController<SessionStatus> statusController;

  setUp(() {
    repository = MockAuthRepository();
    statusController = StreamController<SessionStatus>.broadcast();
    when(() => repository.sessionStatus)
        .thenAnswer((_) => statusController.stream);
  });

  tearDown(() => statusController.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      App(config: testConfig, authRepository: repository),
    );
  }

  testWidgets('muestra el splash mientras restaura la sesión', (tester) async {
    final completer = Completer<SessionStatus>();
    when(repository.restoreSession).thenAnswer((_) => completer.future);

    await pumpApp(tester);
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    completer.complete(const Unauthenticated());
    await tester.pumpAndSettle();
  });

  testWidgets('sin sesión guardada lleva al login', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Unauthenticated());

    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('con sesión guardada entra directo a movimientos', (
    tester,
  ) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Authenticated(user));

    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(MovementsPage), findsOneWidget);
    expect(find.text('Hola, Ronald Castillo'), findsOneWidget);
  });

  testWidgets('login exitoso navega a movimientos', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Unauthenticated());
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      statusController.add(const Authenticated(user));
      return const Ok(user);
    });
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_emailField')),
      'demo@ligo.pe',
    );
    await tester.enterText(
      find.byKey(const Key('login_passwordField')),
      'ligo1234',
    );
    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MovementsPage), findsOneWidget);
  });

  testWidgets('logout confirmado vuelve al login', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Authenticated(user));
    when(repository.logout).thenAnswer((_) async {
      statusController.add(
        const Unauthenticated(UnauthenticatedReason.signedOut),
      );
    });
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logoutConfirmButton')));
    await tester.pumpAndSettle();

    verify(repository.logout).called(1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('cancelar el logout mantiene la sesión', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Authenticated(user));
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(repository.logout);
    expect(find.byType(MovementsPage), findsOneWidget);
  });

  testWidgets('sesión expirada vuelve al login y avisa', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Authenticated(user));
    await pumpApp(tester);
    await tester.pumpAndSettle();

    statusController.add(const Unauthenticated(UnauthenticatedReason.expired));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Tu sesión expiró. Vuelve a iniciar sesión.'),
      findsOneWidget,
    );
  });

  testWidgets('un idioma no soportado usa español por defecto', (tester) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Unauthenticated());
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      App(config: testConfig, authRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('con el dispositivo en inglés la app está en inglés', (
    tester,
  ) async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Unauthenticated());
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      App(config: testConfig, authRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}

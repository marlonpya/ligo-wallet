import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/features/auth/presentation/login/view/login_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../../helpers/helpers.dart';

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');
  late AuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_emailField')),
      'demo@ligo.pe',
    );
    await tester.enterText(
      find.byKey(const Key('login_passwordField')),
      'ligo1234',
    );
    await tester.tap(find.byKey(const Key('login_submitButton')));
  }

  testWidgets('enviar vacío muestra los errores de los campos', (tester) async {
    await tester.pumpApp(const LoginPage(), authRepository: repository);

    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('email con formato inválido muestra su error', (tester) async {
    await tester.pumpApp(const LoginPage(), authRepository: repository);

    await tester.enterText(find.byKey(const Key('login_emailField')), 'demo');
    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pump();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
  });

  testWidgets('muestra un indicador de carga mientras inicia sesión', (
    tester,
  ) async {
    final completer = Completer<Result<User>>();
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => completer.future);
    await tester.pumpApp(const LoginPage(), authRepository: repository);

    await fillAndSubmit(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(const Ok(user));
    await tester.pump();
  });

  testWidgets('credenciales inválidas muestran un mensaje genérico', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Err(InvalidCredentialsFailure()));
    await tester.pumpApp(const LoginPage(), authRepository: repository);

    await fillAndSubmit(tester);
    await tester.pump();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('el ojo alterna la visibilidad de la contraseña', (tester) async {
    await tester.pumpApp(const LoginPage(), authRepository: repository);
    TextField passwordField() =>
        tester.widget(find.byKey(const Key('login_passwordField')));

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('el teclado "listo" envía el formulario', (tester) async {
    await tester.pumpApp(const LoginPage(), authRepository: repository);

    await tester.tap(find.byKey(const Key('login_passwordField')));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
  });

  group('ayuda de cuenta demo', () {
    testWidgets('se muestra si el flavor tiene credenciales demo', (
      tester,
    ) async {
      await tester.pumpApp(
        const LoginPage(),
        authRepository: repository,
        config: const AppConfig(
          environment: AppEnvironment.development,
          demoCredentials: DemoCredentials(
            email: 'demo@ligo.pe',
            password: 'x',
          ),
        ),
      );

      expect(find.byKey(const Key('login_demoHint')), findsOneWidget);
    });

    testWidgets('no se muestra en producción', (tester) async {
      await tester.pumpApp(
        const LoginPage(),
        authRepository: repository,
        config: const AppConfig(environment: AppEnvironment.production),
      );

      expect(find.byKey(const Key('login_demoHint')), findsNothing);
    });
  });
}

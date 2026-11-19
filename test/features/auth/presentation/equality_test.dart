import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/features/auth/presentation/login/bloc/login_bloc.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Igualdad por valor de eventos, estados y configuración: es lo que permite
/// a bloc descartar estados repetidos y a los tests compararlos.
void main() {
  test('eventos de login comparan por valor', () {
    expect(const LoginEmailChanged('a'), const LoginEmailChanged('a'));
    expect(const LoginEmailChanged('a'), isNot(const LoginEmailChanged('b')));
    expect(
      const LoginPasswordChanged('a'),
      isNot(const LoginPasswordChanged('b')),
    );
    expect(const LoginSubmitted().props, isEmpty);
  });

  test('eventos y estados de sesión comparan por valor', () {
    expect(const SessionStarted().props, isEmpty);
    expect(const SessionInitial().props, isEmpty);
    expect(
      const SessionUnauthenticated(),
      isNot(const SessionUnauthenticated(UnauthenticatedReason.expired)),
    );
  });

  test('Authenticated expone el usuario en props', () {
    const user = User(id: 'u_001', name: 'Ronald');

    expect(const Authenticated(user).props, [user]);
  });

  test('LoginState compara todos sus campos', () {
    expect(
      const LoginState(email: 'a'),
      isNot(const LoginState(email: 'a', showValidationErrors: true)),
    );
  });

  test('AppConfig y DemoCredentials comparan por valor', () {
    const demo = DemoCredentials(email: 'a', password: 'b');

    expect(
      const AppConfig(
        environment: AppEnvironment.development,
        demoCredentials: demo,
      ),
      isNot(const AppConfig(environment: AppEnvironment.development)),
    );
    expect(demo, isNot(const DemoCredentials(email: 'a', password: 'c')));
  });
}

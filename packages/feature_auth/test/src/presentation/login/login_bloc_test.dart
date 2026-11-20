import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/src/application/auth_use_cases.dart';
import 'package:feature_auth/src/presentation/login/bloc/login_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');
  const validState = LoginState(email: 'demo@ligo.pe', password: 'ligo1234');

  late AuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  LoginBloc buildBloc() => LoginBloc(login: LoginUseCase(repository));

  test('el estado inicial está vacío y sin errores visibles', () {
    final state = buildBloc().state;

    expect(state, const LoginState());
    expect(state.showValidationErrors, isFalse);
    expect(state.isValid, isFalse);
  });

  group('cambios de campos', () {
    blocTest<LoginBloc, LoginState>(
      'actualiza email y contraseña',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const LoginEmailChanged('demo@ligo.pe'))
        ..add(const LoginPasswordChanged('ligo1234')),
      expect: () => [const LoginState(email: 'demo@ligo.pe'), validState],
    );

    blocTest<LoginBloc, LoginState>(
      'editar tras un fallo limpia el error',
      build: buildBloc,
      seed: () => validState.copyWith(
        status: LoginStatus.failure,
        failure: const NetworkFailure(),
      ),
      act: (bloc) => bloc.add(const LoginEmailChanged('otro@ligo.pe')),
      expect: () => [
        const LoginState(email: 'otro@ligo.pe', password: 'ligo1234'),
      ],
    );
  });

  group('LoginSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'con formulario inválido muestra errores y no llama al repositorio',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [const LoginState(showValidationErrors: true)],
      verify: (_) => verifyNever(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<LoginBloc, LoginState>(
      'login correcto: submitting -> success',
      setUp: () => when(
        () => repository.login(email: 'demo@ligo.pe', password: 'ligo1234'),
      ).thenAnswer((_) async => const Ok(user)),
      build: buildBloc,
      seed: () => validState,
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        validState.copyWith(status: LoginStatus.submitting),
        validState.copyWith(status: LoginStatus.success),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'credenciales inválidas: submitting -> failure con el motivo',
      setUp: () => when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Err(InvalidCredentialsFailure())),
      build: buildBloc,
      seed: () => validState,
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        validState.copyWith(status: LoginStatus.submitting),
        validState.copyWith(
          status: LoginStatus.failure,
          failure: const InvalidCredentialsFailure(),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'ignora envíos repetidos mientras hay uno en curso',
      setUp: () {
        final completer = Completer<Result<User>>();
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) => completer.future);
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => completer.complete(const Ok(user)),
        );
      },
      build: buildBloc,
      seed: () => validState,
      act: (bloc) => bloc
        ..add(const LoginSubmitted())
        ..add(const LoginSubmitted()),
      wait: const Duration(milliseconds: 20),
      verify: (_) => verify(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1),
    );
  });

  group('LoginState', () {
    test('toString no expone la contraseña', () {
      expect(validState.toString(), isNot(contains('ligo1234')));
    });

    test('LoginPasswordChanged.toString no expone la contraseña', () {
      expect(
        const LoginPasswordChanged('ligo1234').toString(),
        isNot(contains('ligo1234')),
      );
    });

    test('isSubmitting refleja el estado', () {
      expect(
        validState.copyWith(status: LoginStatus.submitting).isSubmitting,
        isTrue,
      );
    });
  });
}

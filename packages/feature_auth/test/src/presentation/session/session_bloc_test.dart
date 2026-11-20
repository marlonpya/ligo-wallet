import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/src/application/auth_use_cases.dart';
import 'package:feature_auth/src/presentation/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');

  late AuthRepository repository;
  late StreamController<SessionStatus> statusController;

  setUp(() {
    repository = MockAuthRepository();
    statusController = StreamController<SessionStatus>.broadcast();
    when(() => repository.sessionStatus)
        .thenAnswer((_) => statusController.stream);
    when(repository.logout).thenAnswer((_) async {});
  });

  tearDown(() => statusController.close());

  SessionBloc buildBloc() => SessionBloc(
    restoreSession: RestoreSessionUseCase(repository),
    watchSession: WatchSessionUseCase(repository),
    logout: LogoutUseCase(repository),
  );

  test('el estado inicial es SessionInitial', () {
    expect(buildBloc().state, const SessionInitial());
  });

  group('SessionStarted', () {
    blocTest<SessionBloc, SessionState>(
      'emite Authenticated si había sesión guardada',
      setUp: () =>
          when(repository.restoreSession)
              .thenAnswer((_) async => const Authenticated(user)),
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionStarted()),
      expect: () => [const SessionAuthenticated(user)],
    );

    blocTest<SessionBloc, SessionState>(
      'emite Unauthenticated si no había sesión',
      setUp: () =>
          when(repository.restoreSession)
              .thenAnswer((_) async => const Unauthenticated()),
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionStarted()),
      expect: () => [const SessionUnauthenticated()],
    );

    blocTest<SessionBloc, SessionState>(
      'refleja los cambios posteriores del repositorio (login y expiración)',
      setUp: () =>
          when(repository.restoreSession)
              .thenAnswer((_) async => const Unauthenticated()),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionStarted());
        await pumpEventQueue();
        statusController
          ..add(const Authenticated(user))
          ..add(const Unauthenticated(UnauthenticatedReason.expired));
      },
      expect: () => [
        const SessionUnauthenticated(),
        const SessionAuthenticated(user),
        const SessionUnauthenticated(UnauthenticatedReason.expired),
      ],
    );
  });

  group('SessionLogoutRequested', () {
    blocTest<SessionBloc, SessionState>(
      'pide el logout; el nuevo estado llega por el stream',
      setUp: () =>
          when(repository.restoreSession)
              .thenAnswer((_) async => const Authenticated(user)),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionStarted());
        await pumpEventQueue();
        bloc.add(const SessionLogoutRequested());
        await pumpEventQueue();
        statusController.add(
          const Unauthenticated(UnauthenticatedReason.signedOut),
        );
      },
      expect: () => [
        const SessionAuthenticated(user),
        const SessionUnauthenticated(UnauthenticatedReason.signedOut),
      ],
      verify: (_) => verify(repository.logout).called(1),
    );
  });
}

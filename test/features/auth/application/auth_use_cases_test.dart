import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/features/auth/application/auth_use_cases.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');
  late AuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  test(
    'LoginUseCase delega en el repositorio y devuelve su resultado',
    () async {
      when(() => repository.login(email: 'a@b.c', password: 'x'))
          .thenAnswer((_) async => const Ok(user));

      final result = await LoginUseCase(repository)(
        email: 'a@b.c',
        password: 'x',
      );

      expect(result, const Ok(user));
    },
  );

  test('LogoutUseCase cierra la sesión', () async {
    when(repository.logout).thenAnswer((_) async {});

    await LogoutUseCase(repository)();

    verify(repository.logout).called(1);
  });

  test('RestoreSessionUseCase devuelve el estado restaurado', () async {
    when(repository.restoreSession)
        .thenAnswer((_) async => const Authenticated(user));

    expect(
      await RestoreSessionUseCase(repository)(),
      const Authenticated(user),
    );
  });

  test('WatchSessionUseCase expone el stream del repositorio', () {
    when(() => repository.sessionStatus)
        .thenAnswer((_) => Stream.value(const Unauthenticated()));

    expect(WatchSessionUseCase(repository)(), emits(const Unauthenticated()));
  });
}

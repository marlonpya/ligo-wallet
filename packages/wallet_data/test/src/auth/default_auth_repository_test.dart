import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_storage/wallet_storage.dart';

class _MockWalletApi extends Mock implements WalletApi;

class _MockSessionStorage extends Mock implements SessionStorage;

void main() {
  const user = User(id: 'u_001', name: 'Ronald Castillo');
  const storedSession = StoredSession(
    token: 'mock-jwt-token',
    userId: 'u_001',
    userName: 'Ronald Castillo',
  );
  const loginResponse = LoginResponseDto(
    token: 'mock-jwt-token',
    user: UserDto(id: 'u_001', name: 'Ronald Castillo'),
  );

  late WalletApi api;
  late SessionStorage storage;
  late DefaultAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(const LoginRequestDto(email: '', password: ''));
    registerFallbackValue(storedSession);
  });

  setUp(() {
    api = _MockWalletApi();
    storage = _MockSessionStorage();
    repository = DefaultAuthRepository(api: api, storage: storage);
    when(() => storage.write(any())).thenAnswer((_) async {});
    when(storage.clear).thenAnswer((_) async {});
  });

  tearDown(() => repository.dispose());

  group('login', () {
    test(
      'guarda la sesión, emite Authenticated y devuelve el usuario',
      () async {
        when(() => api.login(any())).thenAnswer((_) async => loginResponse);
        final emitted = expectLater(
          repository.sessionStatus,
          emits(const Authenticated(user)),
        );

        final result = await repository.login(
          email: 'demo@ligo.pe',
          password: 'ligo1234',
        );

        expect(result, const Ok(user));
        verify(() => storage.write(storedSession)).called(1);
        await emitted;
      },
    );

    test('recorta el email pero no la contraseña', () async {
      when(() => api.login(any())).thenAnswer((_) async => loginResponse);

      await repository.login(email: ' demo@ligo.pe ', password: ' pass ');

      final request =
          verify(() => api.login(captureAny())).captured.single
              as LoginRequestDto;
      expect(request.email, 'demo@ligo.pe');
      expect(request.password, ' pass ');
    });

    test('401 en login son credenciales inválidas', () async {
      when(() => api.login(any())).thenThrow(const ApiUnauthorizedException());

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(result, const Err<User>(InvalidCredentialsFailure()));
      verifyNever(() => storage.write(any()));
    });

    test('otros errores pasan por el mapper central', () async {
      when(() => api.login(any())).thenThrow(const ApiNetworkException());

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(result, const Err<User>(NetworkFailure()));
    });

    test('un token vacío rompe el contrato', () async {
      when(() => api.login(any())).thenAnswer(
        (_) async => const LoginResponseDto(
          token: '',
          user: UserDto(id: 'u_001', name: 'Ronald'),
        ),
      );

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(result, const Err<User>(DataFailure()));
      verifyNever(() => storage.write(any()));
    });

    test('si no se puede guardar el token no autentica', () async {
      when(() => api.login(any())).thenAnswer((_) async => loginResponse);
      when(() => storage.write(any()))
          .thenThrow(const SessionStorageException('keystore'));

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(result, const Err<User>(UnexpectedFailure()));
    });
  });

  group('restoreSession', () {
    test('con sesión guardada devuelve y emite Authenticated', () async {
      when(storage.read).thenAnswer((_) async => storedSession);
      final emitted = expectLater(
        repository.sessionStatus,
        emits(const Authenticated(user)),
      );

      expect(await repository.restoreSession(), const Authenticated(user));
      await emitted;
    });

    test('sin sesión devuelve Unauthenticated(noSession)', () async {
      when(storage.read).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), const Unauthenticated());
    });

    test('si el almacenamiento falla limpia y pide login', () async {
      when(storage.read).thenThrow(const SessionStorageException('corrupt'));

      expect(await repository.restoreSession(), const Unauthenticated());
      verify(storage.clear).called(1);
    });
  });

  group('logout', () {
    test('borra la sesión y emite Unauthenticated(signedOut)', () async {
      final emitted = expectLater(
        repository.sessionStatus,
        emits(const Unauthenticated(UnauthenticatedReason.signedOut)),
      );

      await repository.logout();

      verify(storage.clear).called(1);
      await emitted;
    });

    test('no falla aunque el borrado falle', () async {
      when(storage.clear).thenThrow(const SessionStorageException('boom'));

      await expectLater(repository.logout(), completes);
    });
  });

  group('expireSession', () {
    Future<void> signIn() async {
      when(storage.read).thenAnswer((_) async => storedSession);
      await repository.restoreSession();
    }

    test('con sesión activa borra y emite expired', () async {
      await signIn();
      final emitted = expectLater(
        repository.sessionStatus,
        emits(const Unauthenticated(UnauthenticatedReason.expired)),
      );

      await repository.expireSession();

      verify(storage.clear).called(1);
      await emitted;
    });

    test('varios 401 simultáneos cierran la sesión una sola vez', () async {
      await signIn();
      final statuses = <SessionStatus>[];
      final subscription = repository.sessionStatus.listen(statuses.add);

      await Future.wait([
        repository.expireSession(),
        repository.expireSession(),
      ]);
      await pumpEventQueue();

      expect(statuses, [const Unauthenticated(UnauthenticatedReason.expired)]);
      await subscription.cancel();
    });

    test('sin sesión no hace nada', () async {
      await repository.expireSession();

      verifyNever(storage.clear);
    });
  });
}

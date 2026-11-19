import 'package:test/test.dart';
import 'package:wallet_api/wallet_api.dart';

void main() {
  late String? storedToken;
  late FakeBackendConfig config;
  late FakeWalletApi api;

  const validLogin = LoginRequestDto(
    email: FakeWalletApi.demoEmail,
    password: FakeWalletApi.demoPassword,
  );

  setUp(() {
    storedToken = FakeWalletApi.issuedToken;
    config = FakeBackendConfig(latency: Duration.zero);
    api = FakeWalletApi(tokenProvider: () async => storedToken, config: config);
  });

  group('FakeWalletApi.login', () {
    test('emite el token y usuario del contrato', () async {
      final response = await api.login(validLogin);

      expect(response.token, 'mock-jwt-token');
      expect(response.user.id, 'u_001');
      expect(response.user.name, 'Ronald Castillo');
    });

    test('el email no distingue mayúsculas ni espacios', () async {
      final response = await api.login(
        const LoginRequestDto(
          email: '  DEMO@ligo.pe ',
          password: FakeWalletApi.demoPassword,
        ),
      );

      expect(response.token, FakeWalletApi.issuedToken);
    });

    test('rechaza credenciales incorrectas con 401', () {
      expect(
        () => api.login(
          const LoginRequestDto(email: FakeWalletApi.demoEmail, password: 'x'),
        ),
        throwsA(isA<ApiUnauthorizedException>()),
      );
    });

    test('un login nuevo limpia la sesión expirada', () async {
      config.sessionExpired = true;

      await api.login(validLogin);

      expect(config.sessionExpired, isFalse);
    });
  });

  group('FakeWalletApi.getMovements', () {
    test('devuelve los movimientos de ejemplo con token válido', () async {
      expect(await api.getMovements(), fakeMovements);
    });

    test('rechaza con 401 si no hay token', () {
      storedToken = null;

      expect(api.getMovements, throwsA(isA<ApiUnauthorizedException>()));
    });

    test('rechaza con 401 si el token no es el emitido', () {
      storedToken = 'otro-token';

      expect(api.getMovements, throwsA(isA<ApiUnauthorizedException>()));
    });

    test('rechaza con 401 si la sesión expiró', () {
      config.sessionExpired = true;

      expect(api.getMovements, throwsA(isA<ApiUnauthorizedException>()));
    });

    test('devuelve lista vacía si así se configura', () async {
      config.emptyMovements = true;

      expect(await api.getMovements(), isEmpty);
    });

    test('respeta la latencia configurada', () async {
      config.latency = const Duration(milliseconds: 20);
      final stopwatch = Stopwatch()..start();

      await api.getMovements();

      expect(stopwatch.elapsed, greaterThanOrEqualTo(config.latency));
    });
  });

  group('FakeFailureMode', () {
    final expectations = {
      FakeFailureMode.network: isA<ApiNetworkException>(),
      FakeFailureMode.server: isA<ApiServerException>(),
      FakeFailureMode.malformed: isA<ApiMalformedResponseException>(),
    };

    for (final MapEntry(key: mode, value: matcher) in expectations.entries) {
      test('$mode afecta a login y a movimientos', () {
        config.failureMode = mode;

        expect(() => api.login(validLogin), throwsA(matcher));
        expect(api.getMovements, throwsA(matcher));
      });
    }
  });

  group('FakeBackendConfig', () {
    test('por defecto responde bien con latencia', () {
      final defaults = FakeBackendConfig();

      expect(defaults.latency, greaterThan(Duration.zero));
      expect(defaults.failureMode, FakeFailureMode.none);
      expect(defaults.emptyMovements, isFalse);
      expect(defaults.sessionExpired, isFalse);
    });

    test('FakeWalletApi crea una configuración por defecto', () {
      expect(
        FakeWalletApi(tokenProvider: () async => null).config.failureMode,
        FakeFailureMode.none,
      );
    });
  });
}

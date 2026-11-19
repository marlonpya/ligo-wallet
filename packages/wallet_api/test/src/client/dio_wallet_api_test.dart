import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wallet_api/wallet_api.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late String? token;
  late DioWalletApi api;

  const movementJson = {
    'id': 'mov_001',
    'description': 'Pago QR',
    'amount': 25.50,
    'type': 'out',
    'status': 'completed',
  };

  setUp(() {
    adapter = FakeHttpAdapter();
    token = 'mock-jwt-token';
    api = DioWalletApi(
      baseUrl: 'https://api.test',
      tokenProvider: () async => token,
      httpClientAdapter: adapter,
    );
  });

  group('DioWalletApi.login', () {
    const request = LoginRequestDto(email: 'demo@ligo.pe', password: 'x');

    test('hace POST /auth/login con el cuerpo y sin Authorization', () async {
      adapter.respondJson({
        'token': 'mock-jwt-token',
        'user': {'id': 'u_001', 'name': 'Ronald Castillo'},
      });

      final response = await api.login(request);

      expect(adapter.lastRequest!.method, 'POST');
      expect(
        adapter.lastRequest!.uri.toString(),
        'https://api.test/auth/login',
      );
      expect(adapter.lastRequest!.headers, isNot(contains('Authorization')));
      expect(jsonDecode(adapter.lastBody!), {
        'email': 'demo@ligo.pe',
        'password': 'x',
      });
      expect(response.token, 'mock-jwt-token');
      expect(response.user.name, 'Ronald Castillo');
    });

    test('401 se traduce a ApiUnauthorizedException', () async {
      adapter.respondJson({'message': 'bad credentials'}, statusCode: 401);

      expect(
        () => api.login(request),
        throwsA(isA<ApiUnauthorizedException>()),
      );
    });
  });

  group('DioWalletApi.getMovements', () {
    test('hace GET /movements con el token Bearer', () async {
      adapter.respondJson([movementJson]);

      final movements = await api.getMovements();

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.uri.path, '/movements');
      expect(
        adapter.lastRequest!.headers['Authorization'],
        'Bearer mock-jwt-token',
      );
      expect(movements, hasLength(1));
      expect(movements.single.id, 'mov_001');
      expect(movements.single.amount, 25.50);
    });

    test('sin token no envía Authorization', () async {
      token = null;
      adapter.respondJson(<Object>[]);

      await api.getMovements();

      expect(adapter.lastRequest!.headers, isNot(contains('Authorization')));
    });

    test('401 se traduce a ApiUnauthorizedException', () async {
      adapter.respondJson(null, statusCode: 401);

      expect(api.getMovements, throwsA(isA<ApiUnauthorizedException>()));
    });

    test('404 se traduce a ApiNotFoundException', () async {
      adapter.respondJson(null, statusCode: 404);

      expect(api.getMovements, throwsA(isA<ApiNotFoundException>()));
    });

    test('500 se traduce a ApiServerException con el código', () async {
      adapter.respondJson(null, statusCode: 500);

      expect(
        api.getMovements,
        throwsA(
          isA<ApiServerException>().having((e) => e.statusCode, 'code', 500),
        ),
      );
    });

    test('un error de conexión se traduce a ApiNetworkException', () async {
      adapter.errorToThrow = DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'offline',
      );

      expect(api.getMovements, throwsA(isA<ApiNetworkException>()));
    });

    test('un JSON que no cumple el contrato es malformado', () async {
      adapter.respondJson([
        {'id': 'mov_001'},
      ]);

      expect(api.getMovements, throwsA(isA<ApiMalformedResponseException>()));
    });

    test('un cuerpo que no es lista es malformado', () async {
      adapter.respondJson({'unexpected': true});

      expect(api.getMovements, throwsA(isA<ApiMalformedResponseException>()));
    });
  });
}

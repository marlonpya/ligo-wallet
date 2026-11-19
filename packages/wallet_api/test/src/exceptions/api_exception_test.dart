import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wallet_api/wallet_api.dart';

void main() {
  group('ApiException.fromStatusCode', () {
    test('401 es no autorizado', () {
      expect(ApiException.fromStatusCode(401), isA<ApiUnauthorizedException>());
    });

    test('404 es no encontrado', () {
      expect(ApiException.fromStatusCode(404), isA<ApiNotFoundException>());
    });

    test('otros códigos son error de servidor con el código', () {
      for (final code in [400, 403, 500, 503, null]) {
        expect(
          ApiException.fromStatusCode(code),
          isA<ApiServerException>().having((e) => e.statusCode, 'code', code),
        );
      }
    });
  });

  group('ApiException.fromDioException', () {
    ApiException map(DioExceptionType type, {int? statusCode}) {
      final options = RequestOptions();
      return ApiException.fromDioException(
        DioException(
          requestOptions: options,
          type: type,
          response: statusCode == null
              ? null
              : Response<void>(requestOptions: options, statusCode: statusCode),
        ),
      );
    }

    test('timeouts y errores de conexión son de red', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(map(type), isA<ApiNetworkException>(), reason: '$type');
      }
    });

    test('badResponse usa el código HTTP', () {
      expect(
        map(DioExceptionType.badResponse, statusCode: 401),
        isA<ApiUnauthorizedException>(),
      );
    });

    test('unknown con error de tipo o formato es respuesta malformada', () {
      for (final cause in [TypeError(), const FormatException('x')]) {
        expect(
          ApiException.fromDioException(
            DioException(requestOptions: RequestOptions(), error: cause),
          ),
          isA<ApiMalformedResponseException>(),
        );
      }
    });

    test('cancelación, certificado inválido y desconocidos son unknown', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        expect(map(type), isA<ApiUnknownException>(), reason: '$type');
      }
    });
  });
}

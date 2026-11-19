import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('mapApiException', () {
    final cases = <ApiException, Failure>{
      const ApiNetworkException(): const NetworkFailure(),
      const ApiUnauthorizedException(): const UnauthorizedFailure(),
      const ApiNotFoundException(): const NotFoundFailure(),
      const ApiServerException(statusCode: 503): const ServerFailure(
        statusCode: 503,
      ),
      const ApiMalformedResponseException(): const DataFailure(),
      const ApiUnknownException(): const UnexpectedFailure(),
    };

    for (final MapEntry(key: exception, value: failure) in cases.entries) {
      test('${exception.runtimeType} -> ${failure.runtimeType}', () {
        expect(mapApiException(exception), failure);
      });
    }
  });
}

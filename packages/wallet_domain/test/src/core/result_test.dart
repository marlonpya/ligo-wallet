import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('Result', () {
    test('Result.ok crea un Ok con el valor', () {
      const result = Result<int>.ok(1);

      expect(result, isA<Ok<int>>());
      expect(result.isOk, isTrue);
      expect(result, equals(const Ok(1)));
    });

    test('Result.err crea un Err con el fallo', () {
      const result = Result<int>.err(NetworkFailure());

      expect(result, isA<Err<int>>());
      expect(result.isOk, isFalse);
      expect(result, equals(const Err<int>(NetworkFailure())));
    });

    group('fold', () {
      test('llama onOk cuando es Ok', () {
        final value = const Result<int>.ok(2)
            .fold(onOk: (v) => 'ok $v', onErr: (_) => 'err');

        expect(value, 'ok 2');
      });

      test('llama onErr cuando es Err', () {
        final value = const Result<int>.err(ServerFailure())
            .fold(onOk: (_) => 'ok', onErr: (f) => 'err ${f.runtimeType}');

        expect(value, 'err ServerFailure');
      });
    });

    group('map', () {
      test('transforma el valor de un Ok', () {
        expect(const Result<int>.ok(2).map((v) => v * 10), const Ok(20));
      });

      test('propaga el fallo de un Err sin llamar la transformación', () {
        var called = false;
        final mapped = const Result<int>.err(NotFoundFailure()).map((v) {
          called = true;
          return v;
        });

        expect(mapped, const Err<int>(NotFoundFailure()));
        expect(called, isFalse);
      });
    });
  });

  group('Failure', () {
    test('las instancias del mismo tipo son iguales', () {
      expect(const NetworkFailure(), const NetworkFailure());
      expect(const UnauthorizedFailure(), const UnauthorizedFailure());
      expect(
        const InvalidCredentialsFailure(),
        const InvalidCredentialsFailure(),
      );
      expect(const NotFoundFailure(), const NotFoundFailure());
      expect(const DataFailure(), const DataFailure());
      expect(const UnexpectedFailure(), const UnexpectedFailure());
    });

    test('ServerFailure compara por statusCode', () {
      expect(
        const ServerFailure(statusCode: 500),
        const ServerFailure(statusCode: 500),
      );
      expect(
        const ServerFailure(statusCode: 500),
        isNot(const ServerFailure(statusCode: 503)),
      );
    });

    test('los fallos sin datos no aportan props', () {
      expect(const NetworkFailure().props, isEmpty);
    });

    test('tipos distintos no son iguales', () {
      expect(const NetworkFailure(), isNot(const UnexpectedFailure()));
    });
  });
}

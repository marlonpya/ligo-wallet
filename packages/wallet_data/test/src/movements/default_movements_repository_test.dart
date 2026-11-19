import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_domain/wallet_domain.dart';

class _MockWalletApi extends Mock implements WalletApi;

class _MockSessionExpiryHandler extends Mock implements SessionExpiryHandler;

MovementDto _dto(String id, {String? date, String type = 'out'}) => MovementDto(
  id: id,
  description: 'Movimiento $id',
  amount: 10,
  type: type,
  status: 'completed',
  date: date,
);

void main() {
  late WalletApi api;
  late SessionExpiryHandler expiryHandler;
  late DefaultMovementsRepository repository;

  setUp(() {
    api = _MockWalletApi();
    expiryHandler = _MockSessionExpiryHandler();
    repository = DefaultMovementsRepository(
      api: api,
      sessionExpiryHandler: expiryHandler,
    );
    when(expiryHandler.expireSession).thenAnswer((_) async {});
  });

  group('getMovements', () {
    test('mapea la respuesta a entidades de dominio', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a')]);

      final result = await repository.getMovements();

      expect(result, isA<Ok<List<Movement>>>());
      final movements = (result as Ok<List<Movement>>).value;
      expect(movements.single.id, 'a');
      expect(movements.single.amount.cents, 1000);
    });

    test('una lista vacía es un resultado válido', () async {
      when(api.getMovements).thenAnswer((_) async => []);

      expect(await repository.getMovements(), const Ok<List<Movement>>([]));
    });

    test(
      'ordena por fecha, más recientes primero y sin fecha al final',
      () async {
        when(api.getMovements).thenAnswer(
          (_) async => [
            _dto('old', date: '2026-01-01T00:00:00Z'),
            _dto('no-date-1'),
            _dto('new', date: '2026-11-01T00:00:00Z'),
            _dto('no-date-2'),
            _dto('new-tie', date: '2026-11-01T00:00:00Z'),
          ],
        );

        final result = await repository.getMovements() as Ok<List<Movement>>;

        expect(result.value.map((m) => m.id), [
          'new',
          'new-tie',
          'old',
          'no-date-1',
          'no-date-2',
        ]);
      },
    );

    test('la lista devuelta no se puede modificar', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a')]);

      final result = await repository.getMovements() as Ok<List<Movement>>;

      expect(result.value.clear, throwsUnsupportedError);
    });

    test('un movimiento que rompe el contrato invalida la respuesta', () async {
      when(api.getMovements)
          .thenAnswer((_) async => [_dto('a'), _dto('b', type: 'refund')]);

      expect(
        await repository.getMovements(),
        const Err<List<Movement>>(DataFailure()),
      );
    });

    test('401 cierra la sesión y devuelve UnauthorizedFailure', () async {
      when(api.getMovements).thenThrow(const ApiUnauthorizedException());

      final result = await repository.getMovements();

      expect(result, const Err<List<Movement>>(UnauthorizedFailure()));
      verify(expiryHandler.expireSession).called(1);
    });

    test('otros errores pasan por el mapper central', () async {
      when(api.getMovements).thenThrow(const ApiNetworkException());

      expect(
        await repository.getMovements(),
        const Err<List<Movement>>(NetworkFailure()),
      );
      verifyNever(expiryHandler.expireSession);
    });
  });

  group('getMovementById', () {
    test('usa el listado en caché sin otra petición', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a'), _dto('b')]);
      await repository.getMovements();

      final result = await repository.getMovementById('b');

      expect((result as Ok<Movement>).value.id, 'b');
      verify(api.getMovements).called(1);
    });

    test('sin caché pide el listado y busca ahí', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a')]);

      final result = await repository.getMovementById('a');

      expect((result as Ok<Movement>).value.id, 'a');
    });

    test('devuelve NotFoundFailure si no existe', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a')]);

      expect(
        await repository.getMovementById('zzz'),
        const Err<Movement>(NotFoundFailure()),
      );
    });

    test('propaga el fallo del listado', () async {
      when(api.getMovements).thenThrow(const ApiServerException());

      expect(
        await repository.getMovementById('a'),
        const Err<Movement>(ServerFailure()),
      );
    });

    test('tras un 401 se descarta la caché', () async {
      when(api.getMovements).thenAnswer((_) async => [_dto('a')]);
      await repository.getMovements();
      when(api.getMovements).thenThrow(const ApiUnauthorizedException());
      await repository.getMovements();

      expect(
        await repository.getMovementById('a'),
        const Err<Movement>(UnauthorizedFailure()),
      );
    });
  });
}

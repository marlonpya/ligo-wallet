import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  late MovementsRepository repository;

  setUp(() => repository = MockMovementsRepository());

  test('GetMovementsUseCase devuelve el resultado del repositorio', () async {
    when(repository.getMovements).thenAnswer((_) async => Ok(allMovements));

    expect(await GetMovementsUseCase(repository)(), Ok(allMovements));
  });

  test('GetMovementByIdUseCase busca por id', () async {
    when(() => repository.getMovementById('mov_001'))
        .thenAnswer((_) async => Ok(qrPayment));

    expect(await GetMovementByIdUseCase(repository)('mov_001'), Ok(qrPayment));
  });
}

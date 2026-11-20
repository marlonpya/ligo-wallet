import 'package:feature_movements/src/presentation/detail/view/movement_detail_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  late MovementsRepository repository;
  late int backToListCalls;

  setUp(() {
    repository = MockMovementsRepository();
    backToListCalls = 0;
  });

  Future<void> pumpDetail(WidgetTester tester, String id) async {
    await tester.pumpApp(
      MovementDetailPage(movementId: id, onBackToList: () => backToListCalls++),
      movementsRepository: repository,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra todos los datos del movimiento', (tester) async {
    when(() => repository.getMovementById('mov_002'))
        .thenAnswer((_) async => Ok(salary));

    await pumpDetail(tester, 'mov_002');

    expect(find.text('+S/ 3,500.00'), findsOneWidget);
    expect(find.text('Abono de sueldo'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    // El estado aparece en la etiqueta y en la fila de detalle.
    expect(find.text('Completado'), findsNWidgets(2));
    expect(find.text('15 de noviembre de 2026 9:00'), findsOneWidget);
    expect(find.text('PEN'), findsOneWidget);
    expect(find.text('mov_002'), findsOneWidget);
  });

  testWidgets('indica cuando no hay fecha', (tester) async {
    when(() => repository.getMovementById('mov_003'))
        .thenAnswer((_) async => Ok(pendingTransfer));

    await pumpDetail(tester, 'mov_003');

    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('un id inexistente muestra "no encontrado"', (tester) async {
    when(() => repository.getMovementById('zzz'))
        .thenAnswer((_) async => const Err(NotFoundFailure()));

    await pumpDetail(tester, 'zzz');

    expect(find.byKey(const Key('movementDetail_notFound')), findsOneWidget);
    expect(find.text('Volver a movimientos'), findsOneWidget);

    await tester.tap(find.text('Volver a movimientos'));

    expect(backToListCalls, 1);
  });

  testWidgets('un error permite reintentar', (tester) async {
    var calls = 0;
    when(() => repository.getMovementById('mov_001')).thenAnswer((_) async {
      calls++;
      return calls == 1 ? const Err(NetworkFailure()) : Ok(qrPayment);
    });

    await pumpDetail(tester, 'mov_001');
    expect(find.byKey(const Key('movementDetail_error')), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('−S/ 25.50'), findsOneWidget);
  });
}

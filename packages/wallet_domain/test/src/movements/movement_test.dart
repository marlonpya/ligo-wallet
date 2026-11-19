import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('Movement', () {
    Movement build({
      MovementType type = MovementType.expense,
      int cents = 2550,
    }) => Movement(
      id: 'mov_001',
      description: 'Pago QR',
      amount: Money(cents: cents, currency: 'PEN'),
      type: type,
      status: MovementStatus.completed,
    );

    test('isIncome refleja el tipo', () {
      expect(build(type: MovementType.income).isIncome, isTrue);
      expect(build().isIncome, isFalse);
    });

    test('signedAmount es positivo para ingresos', () {
      expect(
        build(type: MovementType.income).signedAmount,
        const Money(cents: 2550, currency: 'PEN'),
      );
    });

    test('signedAmount es negativo para salidas', () {
      expect(build().signedAmount, const Money(cents: -2550, currency: 'PEN'));
    });

    test('rechaza montos negativos (la dirección la da el tipo)', () {
      expect(() => build(cents: -1), throwsA(isA<AssertionError>()));
    });

    test('dos movimientos con los mismos datos son iguales', () {
      expect(build(), build());
    });

    test('la fecha forma parte de la igualdad', () {
      final withDate = Movement(
        id: 'mov_001',
        description: 'Pago QR',
        amount: const Money(cents: 2550, currency: 'PEN'),
        type: MovementType.expense,
        status: MovementStatus.completed,
        date: DateTime.utc(2026, 11, 18),
      );

      expect(withDate, isNot(build()));
    });
  });
}

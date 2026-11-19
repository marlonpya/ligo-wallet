import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_domain/wallet_domain.dart';

MovementDto _dto({
  num amount = 25.50,
  String type = 'out',
  String status = 'completed',
  String? date,
  String? currency,
  String description = 'Pago QR',
}) => MovementDto(
  id: 'mov_001',
  description: description,
  amount: amount,
  type: type,
  status: status,
  date: date,
  currency: currency,
);

void main() {
  group('movementFromDto', () {
    test('mapea el movimiento del contrato', () {
      expect(
        movementFromDto(_dto()),
        Movement(
          id: 'mov_001',
          description: 'Pago QR',
          amount: const Money(cents: 2550, currency: 'PEN'),
          type: MovementType.expense,
          status: MovementStatus.completed,
        ),
      );
    });

    test('in es ingreso y out es salida', () {
      expect(movementFromDto(_dto(type: 'in')).type, MovementType.income);
      expect(movementFromDto(_dto()).type, MovementType.expense);
    });

    test('un tipo desconocido rompe el contrato', () {
      expect(
        () => movementFromDto(_dto(type: 'refund')),
        throwsFormatException,
      );
    });

    test('mapea los estados conocidos', () {
      expect(
        movementFromDto(_dto(status: 'pending')).status,
        MovementStatus.pending,
      );
      expect(
        movementFromDto(_dto(status: 'failed')).status,
        MovementStatus.failed,
      );
    });

    test('un estado desconocido no rompe: queda como unknown', () {
      expect(
        movementFromDto(_dto(status: 'reversed')).status,
        MovementStatus.unknown,
      );
    });

    group('monto', () {
      test('convierte a céntimos sin pasar por double', () {
        expect(movementFromDto(_dto(amount: 0.1)).amount.cents, 10);
        expect(movementFromDto(_dto(amount: 98.40)).amount.cents, 9840);
        expect(movementFromDto(_dto(amount: 3500)).amount.cents, 350000);
      });

      test('rechaza montos negativos', () {
        expect(() => movementFromDto(_dto(amount: -1)), throwsFormatException);
      });

      test('rechaza más de dos decimales', () {
        expect(
          () => movementFromDto(_dto(amount: 1.005)),
          throwsFormatException,
        );
      });

      test('rechaza notación científica', () {
        expect(
          () => movementFromDto(_dto(amount: 1e21)),
          throwsFormatException,
        );
      });
    });

    group('moneda', () {
      test('usa PEN si no viene', () {
        expect(movementFromDto(_dto()).amount.currency, defaultCurrency);
      });

      test('usa la moneda enviada', () {
        expect(movementFromDto(_dto(currency: 'USD')).amount.currency, 'USD');
      });

      test('rechaza códigos inválidos', () {
        expect(
          () => movementFromDto(_dto(currency: 'soles')),
          throwsFormatException,
        );
      });
    });

    group('fecha', () {
      test('interpreta ISO 8601', () {
        expect(
          movementFromDto(_dto(date: '2026-11-18T14:32:00Z')).date,
          DateTime.utc(2026, 11, 18, 14, 32),
        );
      });

      test('una fecha inválida se descarta sin romper el movimiento', () {
        expect(movementFromDto(_dto(date: 'ayer')).date, isNull);
      });
    });

    test('recorta espacios de la descripción', () {
      expect(
        movementFromDto(_dto(description: '  Pago QR ')).description,
        'Pago QR',
      );
    });

    test('mapea todos los movimientos del backend fake', () {
      expect(fakeMovements.map(movementFromDto), hasLength(12));
    });
  });
}

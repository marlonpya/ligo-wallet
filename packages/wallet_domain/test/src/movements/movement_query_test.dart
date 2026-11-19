import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

Movement _movement(String id, String description, MovementType type) =>
    Movement(
      id: id,
      description: description,
      amount: const Money(cents: 1000, currency: 'PEN'),
      type: type,
      status: MovementStatus.completed,
    );

void main() {
  final qrPayment = _movement('1', 'Pago QR', MovementType.expense);
  final salary = _movement('2', 'Abono de sueldo', MovementType.income);
  final credit = _movement('3', 'Abono de crédito', MovementType.income);
  final transfer = _movement('4', 'Transferencia a  Ana', MovementType.expense);
  final all = [qrPayment, salary, credit, transfer];

  group('MovementFilter', () {
    test('all acepta cualquier tipo', () {
      expect(all.where(MovementFilter.all.accepts), all);
    });

    test('income acepta solo ingresos', () {
      expect(all.where(MovementFilter.income.accepts), [salary, credit]);
    });

    test('expense acepta solo salidas', () {
      expect(all.where(MovementFilter.expense.accepts), [qrPayment, transfer]);
    });
  });

  group('MovementQuery', () {
    test('por defecto no filtra nada', () {
      const query = MovementQuery();

      expect(query.isEmpty, isTrue);
      expect(query.apply(all), all);
    });

    test('un término de solo espacios cuenta como vacío', () {
      expect(const MovementQuery(searchTerm: '   ').isEmpty, isTrue);
    });

    test('con filtro no es vacía', () {
      expect(
        const MovementQuery(filter: MovementFilter.income).isEmpty,
        isFalse,
      );
    });

    test('busca por descripción sin distinguir mayúsculas', () {
      expect(const MovementQuery(searchTerm: 'PAGO').apply(all), [qrPayment]);
    });

    test('busca ignorando tildes en ambos lados', () {
      expect(const MovementQuery(searchTerm: 'credito').apply(all), [credit]);
      expect(const MovementQuery(searchTerm: 'Crédito').apply(all), [credit]);
    });

    test('colapsa espacios repetidos', () {
      expect(
        const MovementQuery(searchTerm: ' transferencia   a ana ').apply(all),
        [transfer],
      );
    });

    test('búsqueda sin resultados devuelve lista vacía', () {
      expect(const MovementQuery(searchTerm: 'netflix').apply(all), isEmpty);
    });

    test('combina búsqueda y filtro', () {
      const query = MovementQuery(
        searchTerm: 'abono',
        filter: MovementFilter.income,
      );

      expect(query.apply(all), [salary, credit]);
    });

    test('búsqueda que coincide pero no pasa el filtro queda fuera', () {
      const query = MovementQuery(
        searchTerm: 'pago',
        filter: MovementFilter.income,
      );

      expect(query.apply(all), isEmpty);
    });

    test('lista vacía devuelve lista vacía', () {
      expect(const MovementQuery(searchTerm: 'pago').apply([]), isEmpty);
    });

    test('conserva el orden original', () {
      expect(const MovementQuery(searchTerm: 'a').apply(all), all);
    });

    test('copyWith reemplaza solo los campos indicados', () {
      const query = MovementQuery(searchTerm: 'qr');

      expect(
        query.copyWith(filter: MovementFilter.expense),
        const MovementQuery(searchTerm: 'qr', filter: MovementFilter.expense),
      );
      expect(query.copyWith(searchTerm: ''), const MovementQuery());
    });
  });
}

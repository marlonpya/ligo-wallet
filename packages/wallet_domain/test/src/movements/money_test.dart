import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('Money', () {
    group('tryParse', () {
      Money? parse(String input) => Money.tryParse(input, currency: 'PEN');

      test('interpreta decimales con dos dígitos', () {
        expect(parse('25.50'), const Money(cents: 2550, currency: 'PEN'));
      });

      test('interpreta decimales con un dígito', () {
        expect(parse('25.5'), const Money(cents: 2550, currency: 'PEN'));
      });

      test('interpreta enteros', () {
        expect(parse('25'), const Money(cents: 2500, currency: 'PEN'));
      });

      test('interpreta céntimos sin parte entera significativa', () {
        expect(parse('0.01'), const Money(cents: 1, currency: 'PEN'));
      });

      test('evita el error de punto flotante (0.1 + 0.2)', () {
        // En double, 0.1 + 0.2 = 0.30000000000000004.
        final sum = parse('0.1')!.cents + parse('0.2')!.cents;

        expect(sum, 30);
      });

      test('acepta ceros a la derecha más allá de dos decimales', () {
        expect(parse('10.500'), const Money(cents: 1050, currency: 'PEN'));
      });

      test('ignora espacios alrededor', () {
        expect(parse('  7.25 '), const Money(cents: 725, currency: 'PEN'));
      });

      test('interpreta negativos', () {
        expect(parse('-3.10'), const Money(cents: -310, currency: 'PEN'));
      });

      test('rechaza más de dos decimales significativos', () {
        expect(parse('1.005'), isNull);
      });

      test('rechaza texto no numérico', () {
        expect(parse('abc'), isNull);
        expect(parse(''), isNull);
        expect(parse('1,50'), isNull);
        expect(parse('.50'), isNull);
        expect(parse('1e3'), isNull);
      });

      test('rechaza montos que desbordarían los céntimos', () {
        expect(parse('1234567890123456'), isNull);
        expect(parse('123456789012345'), isNotNull);
      });
    });

    test('Money.zero tiene cero céntimos', () {
      expect(
        const Money.zero(currency: 'USD'),
        const Money(cents: 0, currency: 'USD'),
      );
    });

    test('el operador unario invierte el signo', () {
      expect(
        -const Money(cents: 100, currency: 'PEN'),
        const Money(cents: -100, currency: 'PEN'),
      );
      expect(const Money(cents: -1, currency: 'PEN').isNegative, isTrue);
      expect(const Money(cents: 0, currency: 'PEN').isNegative, isFalse);
    });

    test('compareTo ordena por céntimos en la misma moneda', () {
      const small = Money(cents: 100, currency: 'PEN');
      const big = Money(cents: 200, currency: 'PEN');

      expect(small.compareTo(big), lessThan(0));
      expect(big.compareTo(small), greaterThan(0));
      expect(small.compareTo(small), 0);
    });

    test('compareTo falla con monedas distintas', () {
      const pen = Money(cents: 100, currency: 'PEN');
      const usd = Money(cents: 100, currency: 'USD');

      expect(() => pen.compareTo(usd), throwsArgumentError);
    });

    test('la igualdad considera la moneda', () {
      expect(
        const Money(cents: 100, currency: 'PEN'),
        isNot(const Money(cents: 100, currency: 'USD')),
      );
    });
  });
}

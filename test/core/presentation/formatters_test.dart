import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ligo_wallet/core/presentation/formatters.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });

  group('Formatters.money', () {
    test('usa la convención peruana', () {
      expect(
        Formatters.money(const Money(cents: 2550, currency: 'PEN')),
        'S/ 25.50',
      );
      expect(
        Formatters.money(const Money(cents: 123456789, currency: 'PEN')),
        'S/ 1,234,567.89',
      );
    });

    test(r'usa US$ para dólares y el código para otras monedas', () {
      expect(
        Formatters.money(const Money(cents: 100, currency: 'USD')),
        r'US$ 1.00',
      );
      expect(
        Formatters.money(const Money(cents: 100, currency: 'EUR')),
        'EUR 1.00',
      );
    });

    test('con signo: + para positivos y − para negativos', () {
      expect(
        Formatters.money(
          const Money(cents: 350000, currency: 'PEN'),
          signed: true,
        ),
        '+S/ 3,500.00',
      );
      expect(
        Formatters.money(
          const Money(cents: -2550, currency: 'PEN'),
          signed: true,
        ),
        '−S/ 25.50',
      );
    });

    test('sin signo muestra el valor absoluto', () {
      expect(
        Formatters.money(const Money(cents: -2550, currency: 'PEN')),
        'S/ 25.50',
      );
    });

    test('cero nunca lleva signo', () {
      expect(
        Formatters.money(const Money.zero(currency: 'PEN'), signed: true),
        'S/ 0.00',
      );
    });
  });

  group('fechas', () {
    final date = DateTime(2026, 11, 18, 14, 32);

    test('shortDate según el idioma', () {
      expect(Formatters.shortDate(date, 'es'), '18 nov 2026');
      expect(Formatters.shortDate(date, 'en'), 'Nov 18, 2026');
    });

    test('longDateTime incluye la hora', () {
      expect(
        Formatters.longDateTime(date, 'es'),
        '18 de noviembre de 2026 14:32',
      );
    });
  });
}

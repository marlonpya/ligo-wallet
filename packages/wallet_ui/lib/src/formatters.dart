import 'package:intl/intl.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Formateo de montos y fechas.
///
/// Es la única frontera donde los céntimos se convierten a decimal, y solo
/// para mostrarlos: ningún cálculo usa el valor formateado.
abstract final class Formatters {
  // Convención peruana (la de la billetera) para cualquier idioma de la UI:
  // `S/ 1,234.56`. intl no trae datos de `es_PE` y con `es` produciría
  // `1.234,56 S/`, que un usuario peruano no reconoce como un monto.
  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en_US');

  static const Map<String, String> _symbols = {'PEN': 'S/', 'USD': r'US$'};

  /// Monto con símbolo de moneda, por ejemplo `S/ 25.50`.
  ///
  /// Con [signed] antepone `+` o `−` (signo menos tipográfico) para que la
  /// dirección no dependa solo del color (accesibilidad).
  static String money(Money money, {bool signed = false}) {
    final symbol = _symbols[money.currency] ?? money.currency;
    final absolute = '$symbol ${_amount.format(money.cents.abs() / 100)}';
    if (!signed || money.cents == 0) return absolute;
    return money.isNegative ? '−$absolute' : '+$absolute';
  }

  /// Fecha corta para la lista, por ejemplo `18 nov 2026`.
  static String shortDate(DateTime date, String locale) =>
      DateFormat.yMMMd(locale).format(date.toLocal());

  /// Fecha y hora completas para el detalle.
  static String longDateTime(DateTime date, String locale) =>
      DateFormat.yMMMMd(locale).add_Hm().format(date.toLocal());
}

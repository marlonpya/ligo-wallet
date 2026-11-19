import 'package:equatable/equatable.dart';

/// Monto monetario expresado en la unidad mínima de la moneda (céntimos).
///
/// Nunca se usa `double` para dinero: la aritmética binaria de punto flotante
/// no representa exactamente valores como 0.10, y en una billetera eso se
/// traduce en descuadres. Es el mismo criterio que `BigDecimal` en Android o
/// `Decimal` en Swift, resuelto aquí con un `int` de céntimos.
final class Money extends Equatable implements Comparable<Money> {
  /// Crea un monto a partir de céntimos.
  const new({required this.cents, required this.currency});

  /// Monto cero en la moneda indicada.
  const new zero({required this.currency}) : cents = 0;

  /// Cantidad de decimales que maneja el dominio (céntimos).
  static const int decimalDigits = 2;

  // Límite de dígitos enteros para que `cents` no desborde un int de 64 bits.
  static const int _maxIntegerDigits = 15;

  static final RegExp _decimalPattern = RegExp(r'^(-)?(\d+)(?:\.(\d+))?$');

  /// Interpreta un decimal en texto (por ejemplo `"25.50"`) sin pasar por
  /// `double`.
  ///
  /// Devuelve `null` si el texto no es un decimal válido o tiene más de
  /// [decimalDigits] decimales significativos: preferimos rechazar el dato a
  /// redondearlo en silencio.
  static Money? tryParse(String input, {required String currency}) {
    final match = _decimalPattern.firstMatch(input.trim());
    if (match == null) return null;

    final isNegative = match.group(1) != null;
    final integerPart = match.group(2)!;
    // Los ceros a la derecha no aportan precisión ("25.500" == "25.50").
    final fractionPart = (match.group(3) ?? '').replaceFirst(
      RegExp(r'0+$'),
      '',
    );

    if (fractionPart.length > decimalDigits) return null;
    if (integerPart.length > _maxIntegerDigits) return null;

    final cents =
        int.parse(integerPart) * 100 +
        int.parse(fractionPart.padRight(decimalDigits, '0'));
    return Money(cents: isNegative ? -cents : cents, currency: currency);
  }

  /// Monto en céntimos. Negativo solo si representa un débito con signo.
  final int cents;

  /// Código de moneda ISO 4217 (por ejemplo `PEN`).
  final String currency;

  /// `true` si el monto es menor que cero.
  bool get isNegative => cents < 0;

  /// Mismo monto con el signo invertido.
  Money operator -() => Money(cents: -cents, currency: currency);

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return cents.compareTo(other.cents);
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'No se pueden comparar montos de distinta moneda: '
        '$currency y ${other.currency}.',
      );
    }
  }

  @override
  List<Object?> get props => [cents, currency];
}

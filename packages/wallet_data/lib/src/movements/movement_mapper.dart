import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Moneda que se asume cuando la API no la envía (el contrato original no
/// incluye `currency`; la billetera opera en soles).
const String defaultCurrency = 'PEN';

final RegExp _currencyCode = RegExp(r'^[A-Z]{3}$');

/// Convierte un [MovementDto] en un [Movement] de dominio.
///
/// Lanza [FormatException] si un campo obligatorio rompe el contrato (tipo
/// desconocido, monto negativo o con más de dos decimales, moneda inválida).
/// Los campos opcionales inválidos (fecha mal formada) se descartan en lugar
/// de invalidar el movimiento.
Movement movementFromDto(MovementDto dto) {
  final type = switch (dto.type) {
    'in' => MovementType.income,
    'out' => MovementType.expense,
    _ => throw FormatException('Tipo de movimiento desconocido', dto.type),
  };

  final status = switch (dto.status) {
    'completed' => MovementStatus.completed,
    'pending' => MovementStatus.pending,
    'failed' => MovementStatus.failed,
    // Un estado nuevo del backend no debe romper la app.
    _ => MovementStatus.unknown,
  };

  final currency = dto.currency ?? defaultCurrency;
  if (!_currencyCode.hasMatch(currency)) {
    throw FormatException('Moneda inválida', currency);
  }

  // `num.toString()` produce la representación decimal más corta que
  // reconstruye el valor JSON (25.5 -> "25.5"), así que el parseo a céntimos
  // nunca hace aritmética con `double`.
  final amount = Money.tryParse(dto.amount.toString(), currency: currency);
  if (amount == null || amount.isNegative) {
    throw FormatException('Monto inválido', dto.amount);
  }

  return Movement(
    id: dto.id,
    description: dto.description.trim(),
    amount: amount,
    type: type,
    status: status,
    date: dto.date == null ? null : DateTime.tryParse(dto.date!),
  );
}

import 'package:equatable/equatable.dart';
import 'package:wallet_domain/src/movements/money.dart';

/// Dirección del dinero en un movimiento.
enum MovementType {
  /// Ingreso a la billetera (`"in"` en la API).
  income,

  /// Salida de la billetera (`"out"` en la API).
  expense,
}

/// Estado de procesamiento de un movimiento.
enum MovementStatus {
  /// Movimiento liquidado.
  completed,

  /// Movimiento en proceso.
  pending,

  /// Movimiento rechazado o revertido.
  failed,

  /// Estado que la app no reconoce. Permite que un valor nuevo del backend
  /// no rompa la app (se muestra como "desconocido").
  unknown,
}

/// Movimiento de cuenta de la billetera.
final class Movement extends Equatable {
  /// Crea un movimiento.
  ///
  /// [amount] siempre es positivo: la dirección la indica [type].
  new({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    this.date,
  }) : assert(!amount.isNegative, 'El monto debe ser positivo; usar type.');

  /// Identificador único del movimiento.
  final String id;

  /// Descripción visible (por ejemplo "Pago QR").
  final String description;

  /// Monto absoluto del movimiento.
  final Money amount;

  /// Ingreso o salida.
  final MovementType type;

  /// Estado de procesamiento.
  final MovementStatus status;

  /// Fecha del movimiento. Opcional: el contrato original no la incluye.
  final DateTime? date;

  /// `true` si es un ingreso.
  bool get isIncome => type == MovementType.income;

  /// Monto con signo: positivo para ingresos, negativo para salidas.
  Money get signedAmount => isIncome ? amount : -amount;

  @override
  List<Object?> get props => [id, description, amount, type, status, date];
}

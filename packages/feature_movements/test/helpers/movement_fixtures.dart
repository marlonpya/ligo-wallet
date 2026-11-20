import 'package:wallet_domain/wallet_domain.dart';

/// Movimientos de prueba reutilizados por los tests de la feature.
final qrPayment = Movement(
  id: 'mov_001',
  description: 'Pago QR',
  amount: const Money(cents: 2550, currency: 'PEN'),
  type: MovementType.expense,
  status: MovementStatus.completed,
  date: DateTime(2026, 11, 18, 14, 32),
);

final salary = Movement(
  id: 'mov_002',
  description: 'Abono de sueldo',
  amount: const Money(cents: 350000, currency: 'PEN'),
  type: MovementType.income,
  status: MovementStatus.completed,
  date: DateTime(2026, 11, 15, 9),
);

final pendingTransfer = Movement(
  id: 'mov_003',
  description: 'Transferencia a Ana',
  amount: const Money(cents: 12000, currency: 'PEN'),
  type: MovementType.expense,
  status: MovementStatus.pending,
);

final List<Movement> allMovements = [qrPayment, salary, pendingTransfer];

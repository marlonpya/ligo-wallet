import 'package:json_annotation/json_annotation.dart';

part 'movement_dto.g.dart';

/// Movimiento tal como lo devuelve `GET /movements`.
///
/// Es un espejo fiel del JSON: `type` y `status` quedan como texto y `amount`
/// como número. Interpretarlos (y rechazar valores inválidos) es trabajo del
/// mapper en `wallet_data`, no del DTO.
@JsonSerializable(checked: true)
final class MovementDto {
  /// Crea el DTO.
  const new({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    this.date,
    this.currency,
  });

  /// Construye desde JSON. Lanza si faltan campos o tienen otro tipo.
  factory fromJson(Map<String, dynamic> json) => _$MovementDtoFromJson(json);

  /// Id del movimiento.
  final String id;

  /// Descripción visible.
  final String description;

  /// Monto tal como llega en el JSON (por ejemplo `25.50`).
  final num amount;

  /// `"in"` o `"out"`.
  final String type;

  /// `"completed"`, `"pending"`, `"failed"` u otro valor futuro.
  final String status;

  /// Fecha ISO 8601. No está en el contrato original: es opcional.
  final String? date;

  /// Código ISO 4217. No está en el contrato original: es opcional.
  final String? currency;

  /// Serializa a JSON (lo usa el backend fake).
  Map<String, dynamic> toJson() => _$MovementDtoToJson(this);
}

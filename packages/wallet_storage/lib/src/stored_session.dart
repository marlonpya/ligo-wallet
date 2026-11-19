import 'package:equatable/equatable.dart';

/// Sesión persistida: el token y los datos mínimos del usuario para poder
/// restaurar la sesión al reabrir la app (el contrato no tiene `GET /me`).
final class StoredSession extends Equatable {
  /// Crea una sesión persistida.
  const new({
    required this.token,
    required this.userId,
    required this.userName,
  });

  /// Token de acceso (JWT). Dato sensible: nunca se loguea.
  final String token;

  /// Id del usuario en sesión.
  final String userId;

  /// Nombre del usuario en sesión.
  final String userName;

  @override
  List<Object?> get props => [token, userId, userName];

  // Evita que el token termine en un log por un `print(session)` accidental.
  @override
  String toString() => 'StoredSession(userId: $userId, token: <redacted>)';
}

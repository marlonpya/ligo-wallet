import 'package:equatable/equatable.dart';
import 'package:wallet_domain/src/auth/user.dart';

/// Estado de la sesión que observan la app y el guard de navegación.
///
/// El token nunca aparece aquí: es un detalle de la capa de datos y no debe
/// llegar a la UI ni a los logs.
sealed class SessionStatus extends Equatable {
  /// Constructor base para las subclases.
  const new();
}

/// Hay una sesión activa para [user].
final class Authenticated extends SessionStatus {
  /// Crea un estado autenticado.
  const new(this.user);

  /// Usuario en sesión.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// No hay sesión activa.
final class Unauthenticated extends SessionStatus {
  /// Crea un estado sin sesión indicando el [reason].
  const new([this.reason = UnauthenticatedReason.noSession]);

  /// Por qué no hay sesión; permite avisar al usuario si expiró.
  final UnauthenticatedReason reason;

  @override
  List<Object?> get props => [reason];
}

/// Motivo por el que no hay sesión.
enum UnauthenticatedReason {
  /// Nunca se inició sesión o no había una guardada.
  noSession,

  /// El usuario cerró sesión.
  signedOut,

  /// El backend rechazó el token (401): la sesión expiró o fue revocada.
  expired,
}

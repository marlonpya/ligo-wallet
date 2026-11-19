part of 'session_bloc.dart';

/// Estado de sesión visto por la presentación.
sealed class SessionState extends Equatable {
  const new();

  /// Traduce el estado de dominio al de presentación.
  factory fromStatus(SessionStatus status) => switch (status) {
    Authenticated(:final user) => SessionAuthenticated(user),
    Unauthenticated(:final reason) => SessionUnauthenticated(reason),
  };

  @override
  List<Object?> get props => const [];
}

/// Aún no se sabe si hay sesión (se está leyendo el almacenamiento).
final class SessionInitial extends SessionState {
  const new();
}

/// Hay sesión activa.
final class SessionAuthenticated extends SessionState {
  const new(this.user);

  /// Usuario en sesión.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// No hay sesión.
final class SessionUnauthenticated extends SessionState {
  const new([this.reason = UnauthenticatedReason.noSession]);

  /// Motivo; permite avisar si la sesión expiró.
  final UnauthenticatedReason reason;

  @override
  List<Object?> get props => [reason];
}

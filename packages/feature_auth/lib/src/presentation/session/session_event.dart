part of 'session_bloc.dart';

/// Eventos del [SessionBloc].
sealed class SessionEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

/// La app arrancó: restaurar la sesión y empezar a observarla.
final class SessionStarted extends SessionEvent {
  const new();
}

/// El usuario pidió cerrar sesión.
final class SessionLogoutRequested extends SessionEvent {
  const new();
}

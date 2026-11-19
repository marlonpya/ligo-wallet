part of 'login_bloc.dart';

/// Eventos del [LoginBloc].
sealed class LoginEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

/// Cambió el texto del email.
final class LoginEmailChanged extends LoginEvent {
  const new(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Cambió el texto de la contraseña.
final class LoginPasswordChanged extends LoginEvent {
  const new(this.password);

  final String password;

  @override
  List<Object?> get props => [password];

  // La contraseña no debe aparecer en `toString` ni en logs.
  @override
  String toString() => 'LoginPasswordChanged(<redacted>)';
}

/// El usuario envió el formulario.
final class LoginSubmitted extends LoginEvent {
  const new();
}

part of 'login_bloc.dart';

/// Etapa del envío del formulario.
enum LoginStatus {
  /// El usuario está escribiendo.
  editing,

  /// Login en curso.
  submitting,

  /// Login correcto (la navegación la hace el guard de sesión).
  success,

  /// El login falló; ver [LoginState.failure].
  failure,
}

/// Estado del formulario de login.
final class LoginState extends Equatable {
  const new({
    this.email = '',
    this.password = '',
    this.showValidationErrors = false,
    this.status = LoginStatus.editing,
    this.failure,
  });

  final String email;
  final String password;

  /// Los errores de campo se muestran recién tras el primer intento de envío,
  /// para no marcar en rojo un campo que el usuario aún no terminó.
  final bool showValidationErrors;

  final LoginStatus status;

  /// Motivo del último fallo; solo tiene sentido con [LoginStatus.failure].
  final Failure? failure;

  /// Error de formato del email (se calcula siempre, se muestra según
  /// [showValidationErrors]).
  EmailValidationError? get emailError =>
      CredentialsValidator.validateEmail(email);

  /// Error de formato de la contraseña.
  PasswordValidationError? get passwordError =>
      CredentialsValidator.validatePassword(password);

  /// `true` si el formulario puede enviarse.
  bool get isValid => emailError == null && passwordError == null;

  /// `true` mientras el login está en curso.
  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    String? email,
    String? password,
    bool? showValidationErrors,
    LoginStatus? status,
    Failure? failure,
  }) {
    final nextStatus = status ?? this.status;
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      status: nextStatus,
      // El fallo se descarta en cuanto el estado deja de ser `failure`.
      failure: nextStatus == LoginStatus.failure
          ? failure ?? this.failure
          : null,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    showValidationErrors,
    status,
    failure,
  ];

  // La contraseña nunca se imprime (BlocObserver, logs, reportes de error).
  @override
  String toString() =>
      'LoginState(email: $email, password: <redacted>, '
      'status: $status, failure: $failure)';
}

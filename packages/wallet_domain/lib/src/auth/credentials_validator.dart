/// Error de formato del email.
enum EmailValidationError {
  /// Campo vacío.
  empty,

  /// No tiene forma de email.
  invalidFormat,
}

/// Error de formato de la contraseña.
enum PasswordValidationError {
  /// Campo vacío.
  empty,
}

/// Reglas de formato de las credenciales de login.
///
/// Solo valida forma, no autenticidad. En el login no se aplican políticas de
/// fortaleza de contraseña (eso corresponde al registro): basta con que no
/// esté vacía.
abstract final class CredentialsValidator {
  // Validación pragmática: algo@algo.tld, sin espacios. Una regex "completa"
  // de RFC 5322 no aporta en un login y rechaza casos válidos.
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Devuelve el error del [email] o `null` si es válido.
  static EmailValidationError? validateEmail(String email) {
    final value = email.trim();
    if (value.isEmpty) return EmailValidationError.empty;
    if (!_emailPattern.hasMatch(value)) {
      return EmailValidationError.invalidFormat;
    }
    return null;
  }

  /// Devuelve el error del [password] o `null` si es válido.
  ///
  /// No se recorta: los espacios pueden ser parte de la contraseña.
  static PasswordValidationError? validatePassword(String password) {
    if (password.isEmpty) return PasswordValidationError.empty;
    return null;
  }
}

import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('CredentialsValidator', () {
    group('validateEmail', () {
      test('acepta un email válido', () {
        expect(CredentialsValidator.validateEmail('ronald@ligo.pe'), isNull);
      });

      test('recorta espacios antes de validar', () {
        expect(CredentialsValidator.validateEmail('  ronald@ligo.pe '), isNull);
      });

      test('detecta email vacío', () {
        expect(
          CredentialsValidator.validateEmail('   '),
          EmailValidationError.empty,
        );
      });

      test('detecta formatos inválidos', () {
        for (final email in ['ronald', 'ronald@', 'ronald@ligo', 'a b@c.d']) {
          expect(
            CredentialsValidator.validateEmail(email),
            EmailValidationError.invalidFormat,
            reason: email,
          );
        }
      });
    });

    group('validatePassword', () {
      test('acepta cualquier contraseña no vacía', () {
        expect(CredentialsValidator.validatePassword('x'), isNull);
      });

      test('no recorta espacios (pueden ser parte de la contraseña)', () {
        expect(CredentialsValidator.validatePassword(' '), isNull);
      });

      test('detecta contraseña vacía', () {
        expect(
          CredentialsValidator.validatePassword(''),
          PasswordValidationError.empty,
        );
      });
    });
  });

  group('SessionStatus', () {
    const user = User(id: 'u_001', name: 'Ronald Castillo');

    test('Authenticated compara por usuario', () {
      expect(const Authenticated(user), const Authenticated(user));
      expect(
        const Authenticated(user),
        isNot(const Authenticated(User(id: 'u_002', name: 'Otro'))),
      );
    });

    test('Unauthenticated usa noSession por defecto', () {
      expect(const Unauthenticated().reason, UnauthenticatedReason.noSession);
    });

    test('Unauthenticated compara por motivo', () {
      expect(
        const Unauthenticated(UnauthenticatedReason.expired),
        isNot(const Unauthenticated(UnauthenticatedReason.signedOut)),
      );
    });
  });
}

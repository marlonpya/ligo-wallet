import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/router/app_router.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  const authenticated = SessionAuthenticated(
    User(id: 'u_001', name: 'Ronald Castillo'),
  );

  group('sessionRedirect', () {
    test('mientras se restaura la sesión todo va al splash', () {
      expect(
        sessionRedirect(const SessionInitial(), AppRoutes.movements),
        AppRoutes.splash,
      );
      expect(sessionRedirect(const SessionInitial(), AppRoutes.splash), isNull);
    });

    test('sin sesión cualquier ruta va al login', () {
      for (final location in [AppRoutes.splash, AppRoutes.movements, '/x']) {
        expect(
          sessionRedirect(const SessionUnauthenticated(), location),
          AppRoutes.login,
          reason: location,
        );
      }
      expect(
        sessionRedirect(const SessionUnauthenticated(), AppRoutes.login),
        isNull,
      );
    });

    test('con sesión, login y splash llevan a movimientos', () {
      expect(
        sessionRedirect(authenticated, AppRoutes.login),
        AppRoutes.movements,
      );
      expect(
        sessionRedirect(authenticated, AppRoutes.splash),
        AppRoutes.movements,
      );
    });

    test('con sesión las rutas internas se respetan', () {
      expect(sessionRedirect(authenticated, AppRoutes.movements), isNull);
    });
  });

  group('AppRoutes.movementDetail', () {
    test('anida el id bajo /movements', () {
      expect(AppRoutes.movementDetail('mov_001'), '/movements/mov_001');
    });

    test('codifica caracteres especiales del id', () {
      expect(AppRoutes.movementDetail('a/b c'), '/movements/a%2Fb%20c');
    });

    test('el detalle requiere sesión', () {
      expect(
        sessionRedirect(
          const SessionUnauthenticated(),
          AppRoutes.movementDetail('mov_001'),
        ),
        AppRoutes.login,
      );
    });
  });
}

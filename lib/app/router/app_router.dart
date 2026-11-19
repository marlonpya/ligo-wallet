import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:ligo_wallet/app/view/splash_page.dart';
import 'package:ligo_wallet/features/auth/presentation/login/view/login_page.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/detail/view/movement_detail_page.dart';
import 'package:ligo_wallet/features/movements/presentation/list/view/movements_page.dart';
import 'package:material_ui/material_ui.dart';

/// Rutas de la app.
abstract final class AppRoutes {
  /// Pantalla de carga mientras se restaura la sesión.
  static const splash = '/splash';

  /// Login.
  static const login = '/login';

  /// Listado de movimientos (pantalla principal autenticada).
  static const movements = '/movements';

  /// Detalle de un movimiento.
  static String movementDetail(String id) =>
      '$movements/${Uri.encodeComponent(id)}';
}

/// Guard de sesión como función pura (testeable sin widgets).
///
/// Devuelve la ruta a la que hay que redirigir, o `null` si [location] es
/// válida para el [session] actual.
String? sessionRedirect(SessionState session, String location) {
  return switch (session) {
    SessionInitial() => location == AppRoutes.splash ? null : AppRoutes.splash,
    SessionUnauthenticated() =>
      location == AppRoutes.login ? null : AppRoutes.login,
    SessionAuthenticated() =>
      location == AppRoutes.login || location == AppRoutes.splash
          ? AppRoutes.movements
          : null,
  };
}

/// Crea el router. El guard se reevalúa cada vez que [refreshListenable]
/// notifica (un cambio de sesión).
///
/// Quien crea el router es dueño del listenable y debe liberarlo:
/// `GoRouter.dispose()` no lo hace.
GoRouter createAppRouter(
  SessionBloc sessionBloc, {
  required Listenable refreshListenable,
}) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: refreshListenable,
  redirect: (context, state) =>
      sessionRedirect(sessionBloc.state, state.matchedLocation),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.movements,
      builder: (context, state) => const MovementsPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              MovementDetailPage(movementId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

/// Adapta un `Stream` a `Listenable` para `refreshListenable` de go_router.
final class StreamListenable extends ChangeNotifier {
  new(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

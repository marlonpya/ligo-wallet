import 'dart:async';

import 'package:feature_auth/feature_auth.dart';
import 'package:feature_movements/feature_movements.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/app/demo/demo_panel_button.dart';
import 'package:ligo_wallet/app/view/splash_page.dart';
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
      builder: (context, state) => LoginPage(
        demoCredentials: context.read<AppConfig>().demoBackend?.credentials,
      ),
    ),
    GoRoute(
      path: AppRoutes.movements,
      builder: (context, state) => const _MovementsRoute(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => MovementDetailPage(
            movementId: state.pathParameters['id']!,
            onBackToList: () => context.go(AppRoutes.movements),
          ),
        ),
      ],
    ),
  ],
);

/// Compone el listado con lo que la feature no conoce: navegación al
/// detalle, nombre de la sesión, panel demo y logout.
class _MovementsRoute extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final demo = context.read<AppConfig>().demoBackend;
    final userName = context.select<SessionBloc, String?>(
      (bloc) => switch (bloc.state) {
        SessionAuthenticated(:final user) => user.name,
        _ => null,
      },
    );
    return MovementsPage(
      userName: userName,
      // `go` (no `push`) para que la URL refleje el detalle en web y se pueda
      // recargar o compartir; la ruta anidada deja el listado debajo.
      onMovementSelected: (id) => context.go(AppRoutes.movementDetail(id)),
      actions: [
        if (demo != null) DemoPanelButton(demo: demo),
        const LogoutButton(),
      ],
    );
  }
}

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

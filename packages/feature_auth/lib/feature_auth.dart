/// Feature de autenticación: login, estado de sesión y logout.
///
/// Expone pantallas y el `SessionBloc` para que el app shell arme la
/// navegación. No conoce el router, los flavors ni los datos: lee
/// `AuthRepository` (de `wallet_domain`) del contexto.
library;

export 'src/application/auth_use_cases.dart';
export 'src/presentation/login/demo_credentials.dart';
export 'src/presentation/login/view/login_page.dart';
export 'src/presentation/session/session_bloc.dart';
export 'src/presentation/widgets/logout_button.dart';

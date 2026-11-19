import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/app/router/app_router.dart';
import 'package:ligo_wallet/app/theme/app_theme.dart';
import 'package:ligo_wallet/features/auth/application/auth_use_cases.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Raíz de la app: expone las dependencias (equivalente al grafo de Hilt) y
/// crea el bloc de sesión global.
///
/// Solo recibe contratos del dominio; las implementaciones las elige
/// `bootstrap.dart` según el flavor.
class App extends StatelessWidget {
  const new({required this.config, required this.authRepository, super.key});

  final AppConfig config;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: config),
        RepositoryProvider.value(value: authRepository),
      ],
      child: BlocProvider(
        create: (_) => SessionBloc(
          restoreSession: RestoreSessionUseCase(authRepository),
          watchSession: WatchSessionUseCase(authRepository),
          logout: LogoutUseCase(authRepository),
        )..add(const SessionStarted()),
        child: const AppView(),
      ),
    );
  }
}

/// `MaterialApp.router` con tema, l10n y aviso de sesión expirada.
class AppView extends StatefulWidget {
  const new({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamListenable _sessionChanges = StreamListenable(
    context.read<SessionBloc>().stream,
  );
  late final GoRouter _router = createAppRouter(
    context.read<SessionBloc>(),
    refreshListenable: _sessionChanges,
  );

  @override
  void dispose() {
    _router.dispose();
    _sessionChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (_, current) =>
          current is SessionUnauthenticated &&
          current.reason == UnauthenticatedReason.expired,
      listener: (context, _) => _showSessionExpired(),
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        // El banner "DEBUG" tapa las acciones del AppBar (logout).
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        scaffoldMessengerKey: _messengerKey,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        routerConfig: _router,
      ),
    );
  }

  void _showSessionExpired() {
    final messenger = _messengerKey.currentState;
    final messengerContext = _messengerKey.currentContext;
    if (messenger == null || messengerContext == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(messengerContext.l10n.sessionExpiredMessage)),
    );
  }
}

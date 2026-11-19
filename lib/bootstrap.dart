import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ligo_wallet/app/app.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_storage/wallet_storage.dart';

/// Observer de blocs que solo registra **tipos**, nunca el contenido de
/// estados ni eventos: el estado de login tiene la contraseña y otros pueden
/// tener datos financieros. Solo activo en debug.
class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    log(
      '${bloc.runtimeType}: ${transition.event.runtimeType} -> '
      '${transition.nextState.runtimeType}',
      name: 'bloc',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} error: ${error.runtimeType}', name: 'bloc');
    super.onError(bloc, error, stackTrace);
  }
}

/// Composición de dependencias por flavor (el "módulo de Hilt" de la app).
///
/// Es el **único** archivo de la app que conoce `wallet_api`, `wallet_data` y
/// `wallet_storage`; el resto solo ve contratos de `wallet_domain`.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    // Solo el tipo del error: el mensaje podría incluir datos del usuario.
    log(details.exception.runtimeType.toString(), stackTrace: details.stack);
  };

  if (kDebugMode) Bloc.observer = const AppBlocObserver();

  final storage = SecureSessionStorage();
  final tokenProvider = sessionTokenProvider(storage);

  final WalletApi api;
  DemoCredentials? demoCredentials;
  switch (environment) {
    case AppEnvironment.development:
      api = FakeWalletApi(tokenProvider: tokenProvider);
      demoCredentials = const DemoCredentials(
        email: FakeWalletApi.demoEmail,
        password: FakeWalletApi.demoPassword,
      );
    case AppEnvironment.staging:
    case AppEnvironment.production:
      api = DioWalletApi(baseUrl: _apiBaseUrl(), tokenProvider: tokenProvider);
  }

  final authRepository = DefaultAuthRepository(api: api, storage: storage);

  runApp(
    App(
      config: AppConfig(
        environment: environment,
        demoCredentials: demoCredentials,
      ),
      authRepository: authRepository,
    ),
  );
}

/// URL del backend inyectada en build (`--dart-define=API_BASE_URL=...`).
/// Nunca se hardcodea en el código. Se exige HTTPS.
String _apiBaseUrl() {
  const url = String.fromEnvironment('API_BASE_URL');
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw StateError(
      'API_BASE_URL debe ser una URL https. '
      'Usa --dart-define=API_BASE_URL=https://...',
    );
  }
  return url;
}

import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:feature_auth/feature_auth.dart' show DemoCredentials;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ligo_wallet/app/app.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_domain/wallet_domain.dart' show Authenticated;
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

  runApp(composeApp(environment, storage: SecureSessionStorage()));
}

/// Arma el grafo de dependencias del [environment] y devuelve la raíz de la
/// app, sin ejecutarla.
///
/// Separado de [bootstrap] para que el test de integración use **la misma**
/// composición que la app real, cambiando solo el [storage] (en el emulador
/// (cada corrida empieza sin sesión guardada y no depende del Keystore).
App composeApp(AppEnvironment environment, {required SessionStorage storage}) {
  final tokenProvider = sessionTokenProvider(storage);

  final WalletApi api;
  DemoBackend? demoBackend;
  switch (environment) {
    case AppEnvironment.development:
      final fakeApi = FakeWalletApi(tokenProvider: tokenProvider);
      api = fakeApi;
      demoBackend = _demoBackendFor(fakeApi);
    case AppEnvironment.staging:
    case AppEnvironment.production:
      api = DioWalletApi(baseUrl: _apiBaseUrl(), tokenProvider: tokenProvider);
  }

  final authRepository = DefaultAuthRepository(api: api, storage: storage);
  final movementsRepository = DefaultMovementsRepository(
    api: api,
    sessionExpiryHandler: authRepository,
  );

  if (demoBackend != null) {
    final scenario = demoBackend.scenario;
    // El backend fake limpia la expiración en el siguiente login; el panel
    // vuelve a "Normal" para reflejarlo.
    authRepository.sessionStatus.listen((status) {
      if (status is Authenticated &&
          scenario.value == DemoScenario.sessionExpired) {
        scenario.value = DemoScenario.normal;
      }
    });
  }

  return App(
    config: AppConfig(environment: environment, demoBackend: demoBackend),
    authRepository: authRepository,
    movementsRepository: movementsRepository,
  );
}

/// Conecta el panel de escenarios de la UI con la configuración del backend
/// fake. La UI solo conoce [DemoScenario]; esto lo traduce a
/// [FakeBackendConfig].
DemoBackend _demoBackendFor(FakeWalletApi fakeApi) {
  final config = fakeApi.config;
  final defaultLatency = config.latency;
  final scenario = ValueNotifier(DemoScenario.normal);

  void apply() {
    final value = scenario.value;
    config
      ..latency = value == DemoScenario.slowNetwork
          ? const Duration(seconds: 3)
          : defaultLatency
      ..emptyMovements = value == DemoScenario.empty
      ..sessionExpired = value == DemoScenario.sessionExpired
      ..failureMode = switch (value) {
        DemoScenario.networkError => FakeFailureMode.network,
        DemoScenario.serverError => FakeFailureMode.server,
        DemoScenario.malformedResponse => FakeFailureMode.malformed,
        _ => FakeFailureMode.none,
      };
  }

  scenario.addListener(apply);
  return DemoBackend(
    credentials: const DemoCredentials(
      email: FakeWalletApi.demoEmail,
      password: FakeWalletApi.demoPassword,
    ),
    scenario: scenario,
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

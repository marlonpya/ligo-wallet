import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

class MockAuthRepository extends Mock implements AuthRepository;

class MockMovementsRepository extends Mock implements MovementsRepository;

const testConfig = AppConfig(environment: AppEnvironment.development);

extension PumpApp on WidgetTester {
  /// Monta [widget] con l10n en español y las dependencias de la app.
  Future<void> pumpApp(
    Widget widget, {
    AuthRepository? authRepository,
    MovementsRepository? movementsRepository,
    AppConfig config = testConfig,
  }) {
    return pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: config),
          RepositoryProvider<AuthRepository>.value(
            value: authRepository ?? MockAuthRepository(),
          ),
          RepositoryProvider<MovementsRepository>.value(
            value: movementsRepository ?? MockMovementsRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: widget,
        ),
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

class MockAuthRepository extends Mock implements AuthRepository;

extension PumpApp on WidgetTester {
  /// Monta [widget] con l10n en español y el [AuthRepository] de la feature.
  Future<void> pumpApp(Widget widget, {AuthRepository? authRepository}) {
    return pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: authRepository ?? MockAuthRepository(),
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

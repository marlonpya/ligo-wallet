import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

export 'movement_fixtures.dart';

class MockMovementsRepository extends Mock implements MovementsRepository;

extension PumpApp on WidgetTester {
  /// Monta [widget] con l10n en español y el [MovementsRepository] de la
  /// feature.
  Future<void> pumpApp(
    Widget widget, {
    MovementsRepository? movementsRepository,
  }) {
    return pumpWidget(
      RepositoryProvider<MovementsRepository>.value(
        value: movementsRepository ?? MockMovementsRepository(),
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

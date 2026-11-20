import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

void main() {
  test('español es el primer idioma (el de respaldo)', () {
    expect(appSupportedLocales.first, const Locale('es'));
    expect(appSupportedLocales, contains(const Locale('en')));
  });

  testWidgets('context.l10n entrega los textos del idioma activo', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            // Un TextField exige MaterialLocalizations de material_ui: si los
            // delegates no las proveen, este widget falla.
            return const Scaffold(body: TextField());
          },
        ),
      ),
    );

    expect(l10n.localeName, 'en');
    expect(tester.takeException(), isNull);
  });
}

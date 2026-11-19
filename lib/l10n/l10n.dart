import 'package:ligo_wallet/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

export 'package:ligo_wallet/l10n/gen/app_localizations.dart';

/// Delegates de localización de la app.
///
/// No se usa `AppLocalizations.localizationsDelegates` porque `gen-l10n`
/// agrega los delegates de `flutter_localizations`, que no proveen las
/// `MaterialLocalizations` del paquete desacoplado `material_ui`: con ellos,
/// cualquier `TextField` falla en un locale distinto de inglés.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Idiomas soportados. Español primero: es el idioma por defecto si el del
/// dispositivo no está soportado.
const List<Locale> appSupportedLocales = [Locale('es'), Locale('en')];

/// Acceso corto a los textos localizados.
extension AppLocalizationsX on BuildContext {
  /// Textos localizados del contexto actual.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

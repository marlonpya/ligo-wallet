# wallet_l10n

Textos de la app en **español** (por defecto) e **inglés**, generados con `gen-l10n` desde los ARB de `lib/src/arb/`. Los comparten el app shell y todas las features.

## Contenido

| Archivo | Qué define |
|---|---|
| `src/arb/app_{es,en}.arb` | Textos. `app_en.arb` es la plantilla |
| `src/l10n.dart` | `appLocalizationsDelegates`, `appSupportedLocales` y la extensión `context.l10n` |

## Decisiones

- **Delegates propios**: no se usa `AppLocalizations.localizationsDelegates` porque agrega los de `flutter_localizations`, que no proveen las `MaterialLocalizations` de `material_ui`; con ellos, cualquier `TextField` falla en español.
- **Un solo paquete de textos** para todas las features: con dos features, separar los ARB por feature agregaría generadores sin beneficio. Si una feature crece o cambia de dueño, sus textos pueden pasar a su propio paquete.
- El código generado (`lib/src/gen/`) no se versiona: `flutter pub get` lo regenera.

## Tests

```sh
very_good test --coverage --min-coverage 100
```

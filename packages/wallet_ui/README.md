# wallet_ui

**Design system** de la billetera: lo visual que comparten las features. No conoce features ni datos; solo `wallet_domain` (los tipos que muestra) y `wallet_l10n` (los textos).

## Contenido

| Archivo | Qué define |
|---|---|
| `theme/app_theme.dart` | Tema Material 3 claro y oscuro desde un color semilla |
| `widgets/message_view.dart` | Vista de ícono + título + mensaje + acción para los estados vacío, sin resultados y error |
| `formatters.dart` | Montos (`S/ 1,234.56`, con signo) y fechas según el idioma |
| `failure_message.dart` | `Failure.message(l10n)`: **único** punto que traduce un fallo a texto (el `switch` es exhaustivo) |

## Decisiones

- Un componente entra aquí cuando lo usan **dos o más features** o es identidad visual (tema). Lo propio de una feature vive en su paquete.
- Nunca muestra detalles técnicos: un `Failure` se traduce a un mensaje genérico.

## Tests

```sh
very_good test --coverage --min-coverage 100
```

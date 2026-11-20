# feature_auth

Feature de **autenticación**: login con validación, estado de sesión y logout con confirmación. Contiene sus casos de uso (*Application*) y su presentación.

## API pública (`feature_auth.dart`)

| Exporta | Para qué |
|---|---|
| `LoginPage` | Pantalla de login. Recibe `demoCredentials` opcional: la feature no sabe de flavors |
| `SessionBloc` (+ eventos y estados) | Sesión global; el app shell lo usa para el guard del router |
| `LogoutButton` | Acción de cierre de sesión que el app shell inyecta donde corresponda |
| Casos de uso | `LoginUseCase`, `LogoutUseCase`, `RestoreSessionUseCase`, `WatchSessionUseCase` |
| `DemoCredentials` | Cuenta demo a sugerir en el login |

## Reglas

- Depende solo de `wallet_domain`, `wallet_ui` y `wallet_l10n` (lo verifica `test/architecture_test.dart` de la app).
- No conoce el router ni otras features. Lee `AuthRepository` del contexto; la implementación la decide `bootstrap.dart`.
- `droppable()` en el envío del login: un doble toque no duplica la petición.

## Tests

```sh
very_good test --coverage
```

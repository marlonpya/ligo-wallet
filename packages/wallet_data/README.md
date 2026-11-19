# wallet_data

Capa **Repository**: implementa los contratos de `wallet_domain` sobre `wallet_api` y `wallet_storage`. Solo lo importa `bootstrap.dart` de la app.

## Contenido

| Archivo | Qué define |
|---|---|
| `core/api_failure_mapper.dart` | `mapApiException`: **único** punto de traducción `ApiException` → `Failure` |
| `auth/default_auth_repository.dart` | `AuthRepository`: login, restauración y cierre de sesión. Expone `sessionStatus` y, vía `SessionExpiryHandler`, la expiración por 401 |
| `auth/session_token_provider.dart` | `TokenProvider` que lee el token del storage en cada petición (un logout surte efecto de inmediato) |
| `movements/movement_mapper.dart` | `MovementDto` → `Movement` |
| `movements/default_movements_repository.dart` | `MovementsRepository`: listado, detalle desde caché, 401 → cierre de sesión |

## Decisiones

- **Un solo repositorio por feature** para todos los flavors; lo que cambia por entorno es el datasource (`DioWalletApi` o `FakeWalletApi`).
- En el **login**, un 401 es `InvalidCredentialsFailure`; en endpoints autenticados es `UnauthorizedFailure` y además **cierra la sesión** (la autorización se verifica en el repositorio, no solo en el guard de navegación).
- La sesión solo se emite como `Authenticated` cuando el token quedó **persistido**.
- Varios 401 simultáneos cierran la sesión **una sola vez**.
- **Mapper estricto**: montos parseados a céntimos desde su texto decimal (nunca `double`); tipo desconocido, monto negativo o con más de 2 decimales y moneda inválida rompen el contrato. `status` desconocido → `unknown`; fecha inválida → `null`.
- Si **un** movimiento rompe el contrato se rechaza **toda** la respuesta (`DataFailure`), para no mostrar un historial incompleto sin avisar.

## Tests

```sh
very_good test --coverage --min-coverage 100
```

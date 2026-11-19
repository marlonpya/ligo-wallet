# wallet_api

Capa **Datasource**: acceso HTTP al backend de la billetera. Solo lo importa `wallet_data` (y `bootstrap.dart` de la app para elegir la implementación).

## Contenido

| Archivo | Qué define |
|---|---|
| `client/wallet_api.dart` | Contrato `WalletApi` (`login`, `getMovements`). Todos sus métodos lanzan **solo** `ApiException` |
| `client/dio_wallet_api.dart` | Implementación real con **dio** (sin retrofit). `_guard` es el único punto que traduce `DioException` y errores de parseo a `ApiException` |
| `fake/fake_wallet_api.dart` | Backend en memoria que respeta el contrato y **valida el token** como un servidor real. Configurable con `FakeBackendConfig` (latencia, fallos, lista vacía, sesión expirada) |
| `interceptors/auth_interceptor.dart` | Adjunta `Authorization: Bearer` salvo en peticiones públicas (login) |
| `exceptions/api_exception.dart` | `ApiException` sellada: red, 401, 404, servidor, respuesta malformada, desconocido |
| `models/` | DTOs con `json_serializable` en modo *checked*. `toString()` oculta token y contraseña |

## Decisiones

- **dio sin retrofit**: con dos endpoints, la generación de código no aporta. dio queda por sus interceptores, cancelación y, a futuro, *certificate pinning* y `QueuedInterceptor` para renovar el token.
- **Sin `LogInterceptor`**: registraría el header `Authorization`.
- **Los DTOs son espejo del JSON** (`type` y `status` como texto, `amount` como número); interpretarlos es trabajo del mapper en `wallet_data`.

## Tests

```sh
very_good test --coverage --exclude-coverage "**/*.g.dart" --min-coverage 100
```

El cliente real se prueba contra un `HttpClientAdapter` en memoria: verifica rutas, headers, cuerpo, códigos 401/404/500, errores de red y JSON que rompe el contrato.

## Generación de código

```sh
dart run build_runner build --delete-conflicting-outputs
```

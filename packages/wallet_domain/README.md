# wallet_domain

Capa de dominio de la billetera. **Dart puro**: no depende de Flutter ni de otros paquetes del repo (solo `equatable`).

## Contenido

| Archivo | Qué define |
|---|---|
| `core/result.dart` | `Result<T>` sellado (`Ok` / `Err`): los repositorios no lanzan excepciones |
| `core/failure.dart` | `Failure` sellado: `Network`, `Unauthorized`, `InvalidCredentials`, `Server`, `NotFound`, `Data`, `Unexpected` |
| `movements/money.dart` | `Money` en céntimos (`int`) + parser de decimales sin `double` |
| `movements/movement.dart` | `Movement`, `MovementType` (`income`/`expense`), `MovementStatus` (con `unknown` de respaldo) |
| `movements/movement_query.dart` | `MovementFilter` y `MovementQuery`: búsqueda (sin mayúsculas ni tildes) + filtro combinados |
| `movements/movements_repository.dart` | Contrato `MovementsRepository` |
| `auth/` | `User`, `SessionStatus` sellado, `CredentialsValidator`, contrato `AuthRepository` |

## Decisiones

- **Dinero sin `double`**: `Money.tryParse('25.50')` → 2550 céntimos. Rechaza más de 2 decimales significativos en vez de redondear en silencio.
- **El token no existe en el dominio**: `AuthRepository` expone `SessionStatus` (usuario o motivo de no-sesión). Guardar y adjuntar el token es responsabilidad de la capa de datos.
- **Filtro y búsqueda en el dominio**: la regla de qué movimientos se muestran se testea sin Flutter y no queda en un widget.

## Tests

```sh
very_good test --coverage --min-coverage 100
```

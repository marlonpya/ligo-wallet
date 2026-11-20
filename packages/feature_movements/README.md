# feature_movements

Feature de **movimientos**: listado con skeleton, vacío, error con reintento, búsqueda con debounce, filtros y pull to refresh; y el detalle de un movimiento. Contiene sus casos de uso (*Application*) y su presentación.

## API pública (`feature_movements.dart`)

| Exporta | Para qué |
|---|---|
| `MovementsPage` | Listado. Recibe `onMovementSelected`, `userName` y `actions` (por ejemplo, logout) |
| `MovementDetailPage` | Detalle. Recibe `movementId` y `onBackToList` |
| `MovementsBloc` (+ eventos y estado) | Para que una acción inyectada (el panel demo) pueda recargar el listado |

## Reglas

- Depende solo de `wallet_domain`, `wallet_ui` y `wallet_l10n` (lo verifica `test/architecture_test.dart` de la app).
- **No conoce el router, la sesión ni otras features**: la navegación y lo que viene de otras features llega por parámetro desde el app shell. Así la feature se testea sola y puede moverse a otra app.
- Lee `MovementsRepository` del contexto; la implementación la decide `bootstrap.dart`.
- Los estados de la lista se **derivan** de un único `MovementsState`; búsqueda con `debounce + restartable`, refresco con `droppable`.

## Tests

```sh
very_good test --coverage
```

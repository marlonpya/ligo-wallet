# wallet_storage

Persistencia segura de la sesión (token + id y nombre del usuario) sobre `flutter_secure_storage`.

## Contenido

| Archivo | Qué define |
|---|---|
| `session_storage.dart` | Contrato `SessionStorage` (`read`, `write`, `clear`) y su implementación `SecureSessionStorage`. Los errores de plataforma se envuelven en `SessionStorageException` |
| `stored_session.dart` | `StoredSession`. Su `toString()` oculta el token |

## Decisiones

- **Keychain / Keystore** según plataforma. En iOS con `KeychainAccessibility.unlocked_this_device`: el token solo se lee con el equipo desbloqueado y no viaja en backups.
- Una sesión **incompleta** (por ejemplo, una escritura interrumpida) se trata como "sin sesión".
- Se guardan el id y el nombre del usuario porque el contrato no tiene `GET /me` para restaurar la sesión al reabrir la app.

## Riesgo en web

En web, `flutter_secure_storage` cifra con WebCrypto pero guarda la clave en el mismo `localStorage`. No equivale a Keychain/Keystore; ver la sección de seguridad del README principal.

## Tests

```sh
very_good test --coverage --min-coverage 100
```

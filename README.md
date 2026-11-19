# Ligo Wallet — Movimientos de Cuenta

[![CI](https://github.com/marlonpya/ligo-wallet/actions/workflows/main.yaml/badge.svg)](https://github.com/marlonpya/ligo-wallet/actions/workflows/main.yaml)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

Módulo de **Movimientos de Cuenta** de una billetera digital, construido para el *Flutter Senior Technical Challenge* de Ligo. Corre en **Android, iOS y Web** desde un mismo código, con Clean Architecture por capas, Bloc (MVI), sesión con JWT en almacenamiento seguro y un backend fake que permite demostrar cada estado de la UI.

| Login | Listado | Búsqueda + filtro | Detalle |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/01-login-validacion.jpg" width="190"> | <img src="docs/screenshots/03-listado.jpg" width="190"> | <img src="docs/screenshots/04-busqueda-filtro.jpg" width="190"> | <img src="docs/screenshots/05-detalle.jpg" width="190"> |

---

## Índice

1. [Funcionalidad](#funcionalidad)
2. [Cómo ejecutar](#cómo-ejecutar)
3. [Arquitectura](#arquitectura)
4. [Decisiones técnicas](#decisiones-técnicas)
5. [Manejo de estado y errores](#manejo-de-estado-y-errores)
6. [Testing](#testing)
7. [Seguridad](#seguridad)
8. [Supuestos sobre el contrato](#supuestos-sobre-el-contrato)
9. [Capturas](#capturas)
10. [Uso de IA](#uso-de-ia)
11. [Limitaciones y próximos pasos](#limitaciones-y-próximos-pasos)

---

## Funcionalidad

| Requisito del reto | Implementación |
|---|---|
| Login simulado con JWT | `FakeWalletApi` emite `mock-jwt-token` (el del contrato) y **valida el token** en cada petición como lo haría un backend real |
| Listado de movimientos | Más recientes primero; monto con signo, color e ícono; etiqueta de estado (pendiente, fallido) |
| Detalle de movimiento | Ruta `/movements/:id`; la URL se puede recargar o compartir en web |
| Loading / skeleton | Skeleton con la forma de las filas (sin dependencias externas) |
| Empty state | Dos estados distintos: **cuenta sin movimientos** y **sin resultados** para la búsqueda/filtro (con "Limpiar filtros") |
| Error state con Retry | Mensaje genérico localizado + "Reintentar". Si falla un refresco con datos visibles, se avisa con un snackbar sin ocultar la lista |
| Búsqueda por descripción | Debounce de 300 ms; ignora mayúsculas, tildes y espacios repetidos |
| Filtros Todos / Ingresos / Salidas | `SegmentedButton` de Material 3; se combina con la búsqueda |
| Pull to refresh | También con mouse/trackpad en web (`AppScrollBehavior`) y con un botón en la barra |
| Gestión de sesión y logout | Sesión restaurada al reabrir, logout con confirmación, **401 → cierre de sesión automático** con aviso |

Extras: i18n español/inglés (español por defecto), tema claro/oscuro, layout adaptado a web/tablet, y en el flavor `development` un **panel de escenarios** para forzar red lenta, cuenta vacía, errores o sesión expirada durante la demo.

---

## Cómo ejecutar

### Requisitos

- **Flutter ≥ 3.50** (Dart ≥ 3.14). El proyecto usa la sintaxis de constructores de Dart 3.14 que exige `very_good_analysis` 11; con versiones anteriores no compila.
- Opcional: [Very Good CLI](https://cli.vgv.dev) para correr los tests de todo el workspace con un comando.

```sh
git clone https://github.com/marlonpya/ligo-wallet.git
cd ligo-wallet
flutter pub get   # resuelve la app y los 4 paquetes (pub workspace)
```

### Flavors

| Flavor | Backend | Para qué |
|---|---|---|
| `development` | `FakeWalletApi` (en memoria, con latencia y fallos configurables) | Demo y desarrollo. **Es el que se debe usar para evaluar.** |
| `staging` | `DioWalletApi` → `API_BASE_URL` | Backend real de pruebas |
| `production` | `DioWalletApi` → `API_BASE_URL` | Backend real |

**Cuenta demo** (solo `development`): `demo@ligo.pe` / `ligo1234`. Cualquier otra combinación devuelve "Correo o contraseña incorrectos".

```sh
# Android / iOS
flutter run --flavor development --target lib/main_development.dart

# Web (Flutter web no soporta --flavor; el target elige el entorno)
flutter run -d chrome --target lib/main_development.dart
```

`staging` y `production` necesitan la URL del backend por `--dart-define`; la app exige HTTPS y falla al arrancar si falta:

```sh
flutter run --flavor production --target lib/main_production.dart \
  --dart-define=API_BASE_URL=https://api.ejemplo.com
```

> No hay un backend real detrás del contrato del reto: `staging`/`production` compilan y están cubiertos por tests contra un servidor HTTP simulado, pero solo `development` es navegable de punta a punta.

### Panel de escenarios (demo)

En `development`, el ícono 🧪 de la barra abre un panel para cambiar la respuesta del backend fake. Al elegir un escenario se recarga la lista:

| Escenario | Qué se ve |
|---|---|
| Red lenta (3 s) | Skeleton |
| Cuenta sin movimientos | Estado vacío |
| Sin conexión / Error del servidor / Respuesta malformada | Error con "Reintentar" |
| Sesión expirada (401) | Cierre de sesión, vuelta al login y aviso |

### Tests

```sh
# Todo el workspace (app + 4 paquetes) con cobertura
very_good test -r --coverage

# O por unidad
flutter test                         # app
cd packages/wallet_domain && dart test
```

### Generación de código

Solo los DTOs de `wallet_api` usan `json_serializable`. Los `*.g.dart` están versionados para que el proyecto corra sin pasos extra; para regenerarlos:

```sh
cd packages/wallet_api && dart run build_runner build --delete-conflicting-outputs
```

---

## Arquitectura

Capas pedidas por el reto — **Presentation → Application → Domain → Repository → Datasource** — implementadas como un monorepo liviano con [pub workspaces](https://dart.dev/tools/pub/workspaces) (un solo `pubspec.lock`). Las fronteras entre capas son **paquetes**, así que una dependencia indebida no compila.

```mermaid
flowchart TB
    subgraph app["ligo_wallet (app)"]
        direction TB
        P["<b>Presentation</b><br/>Pages · Widgets<br/>SessionBloc · LoginBloc<br/>MovementsBloc · MovementDetailCubit"]
        A["<b>Application</b><br/>LoginUseCase · LogoutUseCase<br/>GetMovementsUseCase · GetMovementByIdUseCase"]
        B["<b>bootstrap.dart</b><br/>composición por flavor"]
    end

    subgraph domain["wallet_domain (Dart puro)"]
        D["<b>Domain</b><br/>Movement · Money · User · SessionStatus<br/>MovementQuery · Failure · Result<br/>AuthRepository · MovementsRepository (contratos)"]
    end

    subgraph data["wallet_data"]
        R["<b>Repository</b><br/>DefaultAuthRepository<br/>DefaultMovementsRepository<br/>mappers · mapApiException"]
    end

    subgraph api["wallet_api"]
        DS["<b>Datasource</b><br/>WalletApi (contrato)<br/>DioWalletApi · FakeWalletApi<br/>DTOs · AuthInterceptor"]
    end

    subgraph storage["wallet_storage"]
        S["SecureSessionStorage<br/>(flutter_secure_storage)"]
    end

    P --> A --> D
    R -. implementa .-> D
    R --> DS
    R --> S
    B -. cablea .-> R
    B -. elige Dio o Fake .-> DS
```

**Reglas de dependencia** (verificadas por el compilador y por [`test/architecture_test.dart`](test/architecture_test.dart)):

- `wallet_domain` no depende de Flutter ni de ningún otro paquete del repo.
- La app solo conoce **contratos** del dominio. `wallet_api`, `wallet_data` y `wallet_storage` se importan **únicamente** en `lib/bootstrap.dart`.
- Ningún widget llama a la API ni a un repositorio: `Widget → Bloc → UseCase → Repository → Datasource`.

### Estructura

```
ligo_wallet/
├── lib/
│   ├── bootstrap.dart              # composición de dependencias por flavor
│   ├── main_{development,staging,production}.dart
│   ├── app/                        # App, router (go_router + guard), tema, config
│   ├── core/presentation/          # Failure → mensaje, formateo, widgets compartidos
│   ├── features/
│   │   ├── auth/        application/ + presentation/ (session, login)
│   │   └── movements/   application/ + presentation/ (list, detail)
│   └── l10n/                       # ARB es/en
├── packages/
│   ├── wallet_domain/   # entidades, Money, MovementQuery, Failure, Result, contratos
│   ├── wallet_api/      # WalletApi, DioWalletApi, FakeWalletApi, DTOs, AuthInterceptor
│   ├── wallet_storage/  # SessionStorage sobre flutter_secure_storage
│   └── wallet_data/     # repositorios, mappers, mapApiException
└── test/                # tests de la app (cada paquete tiene su propio test/)
```

### Flujo de una petición autenticada (y del 401)

```mermaid
sequenceDiagram
    participant UI as MovementsView
    participant B as MovementsBloc
    participant UC as GetMovementsUseCase
    participant R as DefaultMovementsRepository
    participant API as WalletApi
    participant AR as DefaultAuthRepository
    participant S as SessionBloc / router

    UI->>B: MovementsLoadRequested
    B->>UC: call()
    UC->>R: getMovements()
    R->>API: GET /movements (Bearer token)
    alt 200
        API-->>R: lista de MovementDto
        R-->>B: Ok(lista de Movement)
        B-->>UI: success (lista)
    else 401
        API-->>R: ApiUnauthorizedException
        R->>AR: expireSession()
        AR-->>S: Unauthenticated(expired)
        S-->>UI: redirect a /login + aviso
        R-->>B: Err(UnauthorizedFailure)
    end
```

---

## Decisiones técnicas

| Decisión | Por qué | Equivalente Android / iOS |
|---|---|---|
| **Bloc** (eventos para pantallas complejas, Cubit para el detalle) | Flujo unidireccional MVI, estados inmutables y transformers de eventos (debounce, `droppable`) | ViewModel + `StateFlow` / MVI · VIP |
| **Repository Pattern con fake a nivel de *datasource*** | Hay **un solo** repositorio por feature. El flavor `development` cambia `DioWalletApi` por `FakeWalletApi`, así la demo ejercita el repositorio real, el storage y el manejo de 401 | `FakeDataSource` inyectado con Hilt |
| **DI con `RepositoryProvider` + composición en `bootstrap.dart`** | Sin service locator global; el grafo es explícito y está en un solo archivo | Módulo de Hilt |
| **dio, sin retrofit** | dio aporta interceptores, cancelación y, a futuro, *certificate pinning* y `QueuedInterceptor` para renovar el token. Retrofit agregaba generación de código sin aportar claridad con 2 endpoints | OkHttp sin Retrofit |
| **`json_serializable` en modo *checked*, sin `freezed`** | DTOs simples con un solo generador; los errores de tipo se convierten en "respuesta malformada" | Moshi / `Codable` |
| **`Result<T>` + `Failure` sellados (Dart 3)** | El error es parte del tipo; el `switch` exhaustivo obliga a manejar cada caso | `Result` de Kotlin · `Result<_, Error>` de Swift |
| **Dinero en céntimos (`int`)** | Nunca `double`: `0.1 + 0.2 ≠ 0.3`. El JSON se parsea desde su texto decimal | `BigDecimal` · `Decimal` |
| **go_router con guard como función pura** | `sessionRedirect(state, location)` se testea sin widgets | Navigation Component + guard |
| **pub workspaces + 4 paquetes** | Las fronteras de capa son de compilación, no solo de convención | Módulos Gradle · Swift Packages |
| **`material_ui`** (Material desacoplado del SDK) | Es lo que genera la plantilla actual de Very Good CLI | — |

---

## Manejo de estado y errores

**Errores centralizados en dos puntos únicos:**

1. `DioWalletApi._guard` → convierte `DioException` y errores de parseo en `ApiException` tipada. Nada más sale del paquete `wallet_api`.
2. `mapApiException` (`wallet_data`) → convierte `ApiException` en `Failure` de dominio. Todos los repositorios pasan por aquí.
3. En presentación, `Failure.message(l10n)` es el único lugar que traduce un fallo a texto. El `switch` es exhaustivo: si se agrega un `Failure` nuevo, la app no compila hasta darle un mensaje.

| `Failure` | Origen | Lo que ve el usuario |
|---|---|---|
| `NetworkFailure` | timeout, sin conexión | "Sin conexión. Revisa tu internet…" |
| `UnauthorizedFailure` | 401 en endpoint autenticado | Cierre de sesión + "Tu sesión expiró…" |
| `InvalidCredentialsFailure` | 401 en login | "Correo o contraseña incorrectos." |
| `ServerFailure` | 5xx, otros códigos | "Estamos teniendo problemas…" |
| `NotFoundFailure` | 404 / id inexistente | "Movimiento no encontrado" |
| `DataFailure` | JSON que rompe el contrato | "Recibimos información inesperada…" |
| `UnexpectedFailure` | cualquier otro caso | "Algo salió mal…" |

**Decisiones de robustez:**

- Si **un** movimiento rompe el contrato (tipo desconocido, monto negativo o con más de 2 decimales), se rechaza **toda** la respuesta con `DataFailure`: en una billetera es preferible no mostrar nada a mostrar un historial incompleto sin avisar.
- Un `status` desconocido no rompe: se muestra como "Desconocido".
- Varios 401 simultáneos cierran la sesión **una sola vez** (condición de carrera detectada por un test y corregida).
- `droppable()` evita peticiones duplicadas por doble toque en "Ingresar" o refrescos repetidos; la búsqueda usa `debounce + restartable`.
- Los estados de la lista (skeleton, error, vacío, sin resultados, lista) se **derivan** de un único `MovementsState`, sin flags que puedan contradecirse.

---

## Testing

**278 tests** repartidos por capa, todos con mocks (`mocktail`) en las fronteras:

| Unidad | Tests | Cobertura | Qué cubre |
|---|---:|---:|---|
| `wallet_domain` | 57 | 100 % | `Money` (incl. 0.1 + 0.2), `MovementQuery` (tildes, filtro + búsqueda, sin resultados), `Result`, validación de credenciales |
| `wallet_api` | 42 | 100 %¹ | Cliente dio contra un servidor simulado (headers, 401/404/500, red, JSON inválido), DTOs, backend fake |
| `wallet_storage` | 11 | 100 % | Lectura/escritura/borrado, sesión incompleta, errores de plataforma, `toString` sin token |
| `wallet_data` | 52 | 100 % | Mappers (montos, monedas, fechas), repositorios con datasource mockeado, 401 → expiración, carrera de 401 |
| App | 116 | ~99 %² | Casos de uso, Blocs con `bloc_test`, guard del router, widgets de cada estado, flujos completos (login, logout, expiración, detalle, idioma) |

¹ Sin contar código generado. ² Sin contar l10n generado; los paquetes miden su cobertura por separado.

**Casos borde cubiertos:** lista vacía · búsqueda sin resultados · filtro + búsqueda combinados · token expirado · error de red y retry · refresco fallido con datos · doble envío · 401 concurrentes · respuesta malformada · deep link sin caché · idioma no soportado → español.

**Regla de arquitectura como test:** `test/architecture_test.dart` falla si un archivo fuera de `bootstrap.dart` importa los paquetes de datos, si la app importa dio/http, o si aparece un `print`.

El CI ([`.github/workflows/main.yaml`](.github/workflows/main.yaml)) corre formato, análisis, `bloc_lint` y tests con umbral de cobertura en **un job por paquete**, más un chequeo de licencias de todas las dependencias (directas y transitivas).

---

## Seguridad

### Implementado

- **Token solo en almacenamiento seguro** (`flutter_secure_storage`: Keychain en iOS, Keystore en Android). En iOS con `unlocked_this_device`: no viaja en backups ni a otro dispositivo. Nunca en `SharedPreferences`.
- **El token no existe fuera de la capa de datos**: el dominio expone `SessionStatus`, no el JWT.
- **Nada sensible en logs**: sin `LogInterceptor` (expondría el header `Authorization`); `toString()` de DTOs, sesión, estado y eventos de login ocultan token y contraseña; el `BlocObserver` registra solo **tipos** y solo en debug; `FlutterError` registra solo el tipo de error. Un test prohíbe `print`.
- **401 → cierre de sesión** desde el repositorio (no solo en el guard de navegación) y limpieza del storage.
- **Errores controlados**: la UI nunca muestra códigos HTTP, stacktraces ni cuerpo de respuesta.
- **Android**: `allowBackup="false"` y `data_extraction_rules.xml` que excluye todos los datos del backup en la nube y de la transferencia entre dispositivos.
- **Sin secretos en el código**: la URL del backend llega por `--dart-define` y se exige HTTPS.
- **Licencias**: CI verifica que todas las dependencias sean MIT/BSD/Apache.

### Riesgo conocido: web

En web, `flutter_secure_storage` cifra el token con WebCrypto pero guarda **la clave en el mismo `localStorage`** (verificado inspeccionando el navegador). No equivale a Keychain/Keystore: un XSS podría leer y descifrar el token. Mitigación recomendada para producción web: token de corta duración en memoria + *refresh token* en cookie `HttpOnly; Secure; SameSite=Strict` emitida por el backend, y CSP estricta.

### Plan para producción (no implementado)

- **Certificate pinning** en los endpoints de auth y pagos (dio `IOHttpClientAdapter.validateCertificate`, o `network_security_config` / `NSPinnedDomains`), con pines de respaldo y plan de rotación.
- **Ofuscación**: `flutter build apk --obfuscate --split-debug-info=build/symbols` (símbolos guardados fuera del artefacto para desofuscar crashes).
- **Renovación de token** con `QueuedInterceptor` (encola las peticiones durante el refresh).
- **Escaneo de dependencias**: `osv-scanner --lockfile=pubspec.lock` en CI.
- **RASP opcional**: freeRASP (root/jailbreak, hooking, depuración, app repackaged).
- **Checklist**: OWASP MASVS (L1 como base, L2 para pagos).
- Bloquear capturas en pantallas sensibles (`FLAG_SECURE` en Android, overlay en iOS al ir a background).

---

## Supuestos sobre el contrato

El contrato del reto es mínimo; estas son las interpretaciones tomadas:

| Tema | Supuesto |
|---|---|
| `POST /auth/login` (request) | No especificado: se envía `{ "email", "password" }`. Un 401 significa credenciales inválidas |
| `amount` | Número JSON positivo en la unidad de la moneda (`25.50`); se parsea a céntimos desde su texto, sin `double` |
| `type` | `in` → ingreso, `out` → salida. Otro valor rompe el contrato |
| `status` | `completed`, `pending`, `failed`; cualquier otro → "Desconocido" |
| `date`, `currency` | **No están en el contrato**; se aceptan como campos opcionales (ISO 8601 y código ISO 4217). Sin `currency` se asume `PEN` |
| Orden | Más recientes primero; los que no tienen fecha, al final |
| Detalle | No hay `GET /movements/{id}`: se resuelve desde el último listado (o se vuelve a pedir si se entra por URL) |
| Paginación | No hay; se asume que el backend devuelve una ventana acotada |
| Formato de montos | Convención peruana `S/ 1,234.56` en cualquier idioma de la UI |

---

## Capturas

| Validación | Skeleton | Vacío | Error + Retry | Sesión expirada |
|:---:|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/01-login-validacion.jpg" width="150"> | <img src="docs/screenshots/02-skeleton.jpg" width="150"> | <img src="docs/screenshots/06-vacio.jpg" width="150"> | <img src="docs/screenshots/07-error-reintentar.jpg" width="150"> | <img src="docs/screenshots/08-sesion-expirada.jpg" width="150"> |

| Panel de escenarios (development) | Web de escritorio, tema oscuro, inglés |
|:---:|:---:|
| <img src="docs/screenshots/09-panel-demo.jpg" width="190"> | <img src="docs/screenshots/10-web-escritorio-oscuro-en.jpg" width="420"> |

---

## Uso de IA

Ver [docs/USO_DE_IA.md](docs/USO_DE_IA.md).

---

## Limitaciones y próximos pasos

- **Dispositivos**: desarrollado en Windows. Verificado de punta a punta en **web** y compilado para **Android**; **iOS** no se pudo compilar ni probar (requiere macOS/Xcode).
- **Caché offline**: fuera de alcance. Siguiente paso: `drift` como fuente de verdad local (en web requiere `sqlite3.wasm` + worker) con *stale-while-revalidate*.
- **Paginación** del listado cuando el backend la ofrezca.
- **Integration test** (`integration_test`) del flujo login → listado → detalle sobre el flavor `development`.
- Renovación de token y certificate pinning (ver [Seguridad](#plan-para-producción-no-implementado)).

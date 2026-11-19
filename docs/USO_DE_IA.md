# Uso de IA

## Herramienta utilizada

**Claude Code** (modelo Claude Opus 5.5) en la app de escritorio de Claude, con acceso al repositorio, a la terminal (Flutter, git, `gh`) y a un navegador integrado para probar la app web.

## ¿Para qué la usé?

Como **par de programación**, no como generador autónomo. Antes de escribir código fijé el marco de trabajo en un archivo de instrucciones: capas exigidas, reglas de dependencia, stack, manejo de errores, seguridad y criterios de evaluación. A partir de ahí, la IA:

- Leyó el enunciado (PDF) y lo contrastó con mi plan, señalando lo que faltaba (escala de evaluación, SOLID, manejo de errores centralizado, cobertura) y los huecos del contrato (sin fecha, sin moneda, valores de `status`).
- Generó el scaffolding con Very Good CLI y configuró el pub workspace con los 4 paquetes.
- Implementó cada capa con sus tests, en el orden dominio → storage → api → data → app.
- Corrió `flutter analyze`, los tests y el CI después de cada paso, e investigó cada fallo hasta su causa.
- Probó la app en el navegador (login, sesión, listado, búsqueda, filtros, detalle, escenarios de error) y tomó las capturas.
- Redactó la documentación.

Las decisiones de arquitectura y de alcance fueron mías; la IA propuso opciones con sus pros y contras y yo elegí (ver abajo).

## ¿Qué código acepté?

- La estructura por capas y paquetes, los contratos del dominio, `Result`/`Failure` sellados y `Money` en céntimos.
- Los repositorios, mappers, Blocs/Cubit, router con guard y las pantallas.
- Los tests (≈280), después de revisar que probaran comportamiento y no implementación.
- La configuración del CI y la documentación, con ajustes.

## ¿Qué código descarté o corregí?

| Propuesta / resultado inicial | Qué pasó | Decisión final |
|---|---|---|
| Cliente HTTP con **dio + retrofit** | Pedí revisarlo: con 2 endpoints, retrofit agregaba generación de código sin aportar | dio directo, sin retrofit |
| Cambiar a `package:http` | Lo pedí y luego lo reconsideré tras comparar opciones para una fintech (renovación de token, pinning, cancelación) | Se revirtió a dio |
| `ErrorInterceptor` + `_guard` | Al medir cobertura apareció una rama muerta: ambos traducían los errores | Un único punto de traducción (`_guard`) |
| Fakes a nivel **repositorio** (patrón Compass) | El fake no habría ejercitado el repositorio real ni el manejo de 401 | Fake a nivel **datasource** (`FakeWalletApi`) |
| `freezed` para modelos | Excesivo para DTOs y entidades simples | `json_serializable` + `equatable` |
| `BlocObserver` de la plantilla registrando cada estado | Habría registrado la contraseña del `LoginState` | Solo tipos, solo en debug |
| `dart fix --apply` sobre archivos con errores | Quitó el tipo de los closures de `context.select` y después un import "sin uso" | Genéricos explícitos y revisión manual de cada `dart fix` |
| Delegates de l10n generados por la plantilla | Con `material_ui`, todo `TextField` fallaba en español | Delegates propios de `material_ui` |
| Montos con el formato de intl para `es` (`25,50 S/`) | No es como se lee un monto en Perú | Convención peruana `S/ 25.50` |
| Navegación al detalle con `push` | En web la URL no cambiaba | `go` con ruta anidada |
| Un test de igualdad que comparaba un objeto consigo mismo | No probaba nada | Reescrito para verificar el valor por defecto |

## ¿Qué validé manualmente?

- **En el navegador (flavor `development`)**: validación de formulario, credenciales inválidas, login, sesión restaurada tras recargar, logout con confirmación, listado, búsqueda sin tildes, búsqueda + filtro, "sin resultados" y "Limpiar filtros", detalle y enlace directo a `/movements/:id` tras recargar, pull to refresh arrastrando con el mouse, y cada escenario del panel (red lenta, vacío, sin conexión, 401 → login con aviso).
- **Almacenamiento en web**: inspeccioné `localStorage` para confirmar que el token no está en texto plano y que el logout borra las claves. Así encontré que la clave de cifrado vive en el mismo `localStorage` (documentado como riesgo).
- **APIs de terceros**: cuando una API era dudosa o nueva (opciones de `flutter_secure_storage` v11, tipos de `DioException`, delegates de `material_ui`, sintaxis de Dart 3.14), se verificó leyendo el código fuente del paquete instalado, no de memoria.
- **CI**: cada push se verificó en GitHub Actions. Dos fallos reales (jobs de Dart puro y chequeo de licencias, ambos incompatibles con pub workspaces) se diagnosticaron desde los logs.
- **Android**: compilación del APK debug y del release ofuscado (R8). Al hacerlo aparecieron tres desfases de la plantilla con Flutter 3.50 (versión de AGP, archivo de ProGuard y un `proguard-rules.pro` inexistente), corregidos. **No** probé en un dispositivo físico ni en iOS (trabajo en Windows).

## ¿Qué riesgos identifiqué?

1. **APIs inventadas o desactualizadas.** El ecosistema cambia rápido (Dart 3.14, `material_ui`, `flutter_secure_storage` v11). Mitigación: compilar y analizar en cada paso y leer el código fuente del paquete ante cualquier duda.
2. **Tests que pasan por la razón equivocada.** Un test verde no garantiza que pruebe algo. Mitigación: revisar los tests y medir cobertura línea por línea. Así aparecieron la rama muerta del interceptor, el test trivial y una fuga del `refreshListenable` del router.
3. **Errores de concurrencia sutiles.** El cierre de sesión con dos 401 simultáneos tenía una condición de carrera; la detectó un test escrito a propósito para ese caso.
4. **Fuga de datos sensibles en logs.** La plantilla y el código generado por defecto tienden a loguear estados completos. Mitigación: `toString` redactado, observer solo con tipos y un test que prohíbe `print`.
5. **Sobre-ingeniería.** La IA tiende a agregar capas, generadores y abstracciones. Se recortó (retrofit, freezed, interceptor duplicado) cuando no aportaban.
6. **Herramientas automáticas con efectos colaterales.** `dart fix --apply` y los formateadores cambiaron código en sentidos no deseados. Mitigación: revisar los diffs, no aplicarlos a ciegas.
7. **Dependencia del criterio humano.** La IA aceleró la implementación, pero las decisiones de seguridad, alcance y producto requieren revisión. Por eso todas quedaron documentadas con su porqué en el README.

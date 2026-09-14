# Norday — Contexto del proyecto (Flutter / Mobile)

Esta app (Norday Hábitos) es la primera de un ecosistema de apps Norday.
El motor genérico ya **no vive aquí**: está extraído en el paquete
[norday_flutter_core](https://github.com/jgrabalosa/norday_flutter_core),
que esta app consume como dependencia Git.

## Regla de arquitectura obligatoria: Motor vs Disparadores

- **Motor** = genérico y reutilizable → vive en `norday_flutter_core`.
- **Disparadores** = específico de "hábitos" → vive aquí.

**Ningún widget o servicio genérico debe conocer conceptos de dominio
como "hábito".** Por ejemplo, SonidoService solo conoce eventos tipo
`completar`/`logro`/`racha`, nunca nombres de hábitos concretos.

Antes de escribir algo genérico aquí, para: probablemente va en el paquete.

### Qué vive en el paquete

`ApiServiceCore` (sesión, usuario, preferencias, gamificación, tienda,
mascota, notificaciones), `ApiException`, `AnalyticsCore`,
`CelebracionService`, `SonidoService`, `IdiomaService`, `ZonaService`,
`AppTheme` y tokens, `IdentidadPaleta` y `catalogoIdentidades`,
`catalogoAvatares`, `Equipamiento`,
`assetMascota`, `Usuario`, los widgets genéricos, las 7 pantallas
genéricas (login, recuperación, tienda, mascota, logros, colección, perfil),
`NordayCoreLocalizations`, `CatalogosCore`, y los assets de animations,
sounds, mascota y avatares.

### Qué vive aquí

`ApiServiceHabitos`, `AnalyticsHabitos`, `Habito`, `HomeShell`, dashboard,
lista de hábitos, detalle de hábito, alta/edición de hábito, `Catalogos`
(categorías y logros de hábito), `CrashlyticsService`, `AppLocalizations`, y
`assets/branding/` — que es lo único de assets que **no** se comparte.

También `lib/widgets/identidad_ui.dart` (tarjeta de hábito, chip de frecuencia,
celda del heatmap y tema de la barra inferior) y `lib/widgets/estados_hoy.dart`
(los cuatro estados de Hoy: carga, vacío, error y todo hecho). Son UI genérica de aspecto pero de dominio
en lo que dicen, así que se quedan aquí. Despachan por `FormaIdentidad` con un
`switch` exhaustivo y sacan los radios de `IdentidadPaleta` — el mismo patrón
que el paquete usa en el halo, el terrario, el aro y el check. Al añadir una
pieza nueva a Hoy, seguirlo en vez de escribir números sueltos.

### Lo que esta app le enchufa al paquete

El paquete no puede importar de aquí, así que hay tres puntos de conexión:

1. **`destinoTrasLogin`** (función suelta en `home_shell.dart`) — se le pasa a
   `LoginScreen` y a `PerfilScreen`, que no pueden conocer `HomeShell`.
2. **`Catalogos.registrarEnElMotor()`** en `main()` — le da al motor los ~32
   logros de hábitos. En el paquete solo viven los cuatro sin dominio
   (`BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`, `INTERACCION_RESENA`).
3. **`nordayNavigatorKey`** — `MaterialApp` usa el del paquete en vez de uno
   propio, porque `CelebracionService` lo necesita.

## Identidad de marca (aplicar siempre en UI nueva)

- Tipografía: Manrope (única familia, distintos pesos).
- Paleta: Azul Noche `#0A1628`, Azul Acero `#23395D`, Verde Esmeralda
  `#27C76F` (nunca como texto pequeño sobre fondo claro — usar Verde
  Oscuro `#1EA85B` en ese caso), Gris Muy Claro `#EEF2F6`.
- Iconos: Lucide Icons (Material Icons ya sustituido).
- La mascota es una funcionalidad, no la identidad de marca (eso es el
  logo/brújula).

## Idioma y zona horaria

Son **dos preferencias independientes**, no una derivada de la otra: un
brasileño y un portugués hablan lo mismo y están a cuatro horas. Misma
pantalla, dos selectores (`SelectorPreferencias`). Los dos servicios viven
ya en el paquete.

- Idioma: `IdiomaService`. Se detecta del dispositivo en el primer arranque
  con caída a `es`, se persiste en `shared_preferences` y se sincroniza con
  el backend, que lo necesita para emails y push. `MaterialApp` escucha
  `localeNotifier`, así que cambiarlo repinta sin reiniciar.
- Zona: `ZonaService`. Dart no expone el nombre IANA de la zona del sistema,
  solo el desfase, y el desfase no identifica una zona — se propone la más
  probable y el usuario la corrige.
- Tras iniciar sesión, el backend manda la última palabra: puede haberlas
  cambiado desde otro dispositivo.

## Tema y avatar equipados

La fuente de verdad es el backend, no el dispositivo: `Equipamiento`
(en el paquete) lee `getInventarioProductos()` y casa el `codigo` del
producto contra los catálogos locales. Ya no se usa `SharedPreferences`.

No se puede cargar en `main()`: antes del login no hay ni `usuarioId` ni
token. Va tras el login y en el splash cuando ya hay sesión guardada, así
que hasta que responde se ve el tema por defecto.

## Textos

Ninguna pantalla nueva lleva literales. **Hay dos catálogos de textos y dos
clases**, y los dos delegados conviven en `MaterialApp`:

- Lo de hábitos → `lib/l10n/app_*.arb`, con `AppLocalizations.of(context)!`.
- Lo genérico → los `core_*.arb` del paquete, con
  `NordayCoreLocalizations.of(context)!`.

Ocho claves viven duplicadas a propósito porque las usan los dos lados
(`comunContinuar`, `logrosTitulo`, `navColeccion`, `navHoy`, `cancelar`,
`perfilTitulo`, `plantillaBeberAgua`, `dashCompletados`): al cambiar una hay
que cambiarla en los dos sitios.

Los `app_localizations*.dart` los genera `flutter gen-l10n` y **no** se
versionan. (En el paquete sí se versionan los suyos — ver su CLAUDE.md.)

Los catálogos llegan del backend con `codigo`. Categorías de hábito con
`Catalogos.categoria`; productos, niveles y logros con `CatalogosCore`.
**Caída obligatoria**: si el código no está traducido o viene a `null` —caso
de las categorías que crea el usuario— se muestra el nombre que manda el
backend. Nunca un código crudo.

## Tocar el paquete

Un cambio en `norday_flutter_core` no llega solo: hay que hacer push allí y
luego `flutter pub upgrade norday_flutter_core` aquí, porque la dependencia
va por `ref: main` y pub cachea el commit resuelto.

## Estilo de trabajo con el usuario

- Un paso a la vez, confirmar que compila antes de seguir.
- Si algo admite varios diseños o no está claro, preguntar antes de
  decidir — no asumir.

## Lecciones aprendidas

Errores que ya se cometieron una vez. No se vuelven a cometer.

### Flutter y tests

- **En `flutter test` Firebase no está inicializado**: acceder a
  `FirebaseAnalytics.instance` lanza `[core/no-app]`. Sirve para probar que un
  servicio no deja escapar el fallo.
- **`MaterialApp` interpola el tema con `AnimatedTheme`** y `TextStyle.lerp` no
  mezcla familias: en tests que cambian de identidad, `pumpAndSettle`, no
  `pump`.
- **El ticker de una animación toma la hora de inicio en su primer tic**: en
  tests de duración, un `pump()` sin duración antes de medir.
- **`containsSemantics` está deprecado desde Flutter 3.40** en favor de
  `isSemantics`, que tiene los mismos parámetros y también sólo comprueba lo
  indicado.
- **Tras editar un ARB, `flutter analyze` no regenera las traducciones**:
  `flutter gen-l10n` antes.
- **`setCrashlyticsCollectionEnabled` vale para todas las builds.** Combinar
  con `kReleaseMode`, nunca pasar un flag «de debug» tal cual.
- **El analizador de Dart promociona a no nulo a través de un `bool`
  intermedio.** Si `final bool b = x != null && ...`, dentro de `if (b)` la
  variable `x` ya es no nula: añadir `&& x != null` ahí dispara
  `unnecessary_null_comparison`.
- **Test en rojo antes del arreglo.** Si el test nuevo pasa contra el código
  sin arreglar, no demuestra nada: parar.

### Paquetes

- **`flutter pub outdated` no lista los paquetes que ya están en su última
  versión.** Las versiones resueltas se comprueban en `pubspec.lock`.
- **Una versión resuelta no se da por supuesta.** `permission_handler ^12.0.3`
  resolvió `permission_handler_android` 13.0.1, no la última 13.x.
- **Los changelogs se leen de la caché de pub**, no de la web:
  `dart pub cache add <paquete> --version <v>` sin tocar el proyecto. Las notas
  publicadas en la web estaban incompletas o se contradecían.
- **Una subida de mayor puede exigir más de lo que dice su nombre.**
  `permission_handler` 13 pide `compileSdk` 37 y Flutter 3.44.4 usa 36
  (`FlutterExtension.kt`). `flutter_secure_storage` 11.0.0 también lo pedía;
  11.1.0 vuelve a `flutter.compileSdkVersion`.
- **`flutter_secure_storage` 9→11 sin pasar por la 10**: lo guardado con la 9
  queda ilegible. Con `resetOnError` y el `catch` de `getToken`, el arranque ve
  `null` y manda al login: iniciar sesión una vez.

### Dispositivo

- **`adb shell pm revoke` falla en algunos fabricantes** con
  `SecurityException` (falta `REVOKE_RUNTIME_PERMISSIONS`). Para probar
  diálogos de permiso hace falta instalación limpia.
- **`logout()` no llama a `signOut()` de Google**: tras cerrar sesión,
  «Continuar con Google» entra con la misma cuenta sin selector.
- **Google Sign-In no funciona en debug.** Para probarlo, APK de release.

### Método de trabajo (vale para los cuatro repos)

- **La primera línea de un prompt se comprueba, no se recuerda.** Tres repos
  están en `C:\Dev\Norday\` (`habitos-app`, `habitos_app_mobile`,
  `norday_flutter_core`) y `conocimiento_app_mobile` está en
  `C:\Dev\Conocimiento\`.
- **Un solo agente por repo a la vez.** Todo lo que haga otro agente se revisa
  en el remoto antes de mergear.
- **Las cifras de verificación se cuentan contra el repositorio**, nunca se
  copian del roadmap. Y son cifras exactas, no adjetivos.
- **Enumerar sin asumir el patrón**: buscar por la forma que ya has visto sólo
  encuentra lo que ya sabías.
- **Un filtro que no encuentra nada no es un resultado.** Ante una salida
  vacía, mirar la fuente completa antes de concluir.
- **Un fichero de diagnóstico no prueba nada por existir.** Abrirlo y
  comprobar que contiene el fallo antes de darlo por documentado.
- **La base de una rama `wip` envejece.** Antes de dar una cifra, comprobar de
  qué commit sale la rama.
- **Al sustituir un bloque, incluir el comentario de encima.** Si no, el
  comentario queda sobre otra declaración y describe algo que ya no es cierto.
- **No escribir en el código el término cuya ausencia se va a verificar.**
- **Mirar dónde se pega cada bloque.** Un bloque para la máquina local,
  lanzado en el VPS, llegó a `git push` y pidió credenciales.
- **`git diff` y `git log` abren paginador**: `git --no-pager`.
- **`git diff HEAD~1` compara con el directorio de trabajo**: incluye lo no
  commiteado. Para ver sólo el commit, `git diff HEAD~1 HEAD` o el remoto.
- **Antes de `git tag`, `git --no-pager log -1`.** Se subió `v0.9.0` sobre el
  commit de `v0.8.0` por saltarse el merge.
- **Un tag anotado resuelve a su commit, no a sí mismo**:
  `git rev-parse <tag>^{commit}`.
- **PowerShell 5.1 lee los `.ps1` sin BOM como ANSI**: scripts sin acentos, o
  guardados con BOM.
- **`Set-Content` corrompió `login_screen.dart`** (219 secuencias dobles +
  BOM). Reparación con `[IO.File]::ReadAllBytes` / `WriteAllText` y
  `New-Object Text.UTF8Encoding $false`.

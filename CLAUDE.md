# Norday — Contexto del proyecto (Flutter / Mobile)

Esta app (Norday Habits) es la primera de un ecosistema de apps Norday.
El motor genérico ya **no vive aquí**: está extraído en el paquete
[norday_flutter_core](https://github.com/jgrabalosa/norday_flutter_core),
que esta app consume como dependencia Git, por tag (`ref: vX.Y.Z`).
Qué hace la app, para quien no la conozca: ver el `README.md`.

## Regla de arquitectura obligatoria: Motor vs Disparadores

- **Motor** = genérico y reutilizable → vive en `norday_flutter_core`.
- **Disparadores** = específico de "hábitos" → vive aquí.

**Ningún widget o servicio genérico debe conocer conceptos de dominio
como "hábito".** Por ejemplo, SonidoService solo conoce eventos tipo
`completar`/`logro`/`racha`, nunca nombres de hábitos concretos.

Antes de escribir algo genérico aquí, para: probablemente va en el paquete.

### Qué vive en el paquete

Sesión, usuario, preferencias, gamificación, tienda, mascota y
notificaciones (`ApiServiceCore`), los servicios genéricos (celebración,
sonido, idioma, zona, recorrido guiado), el tema y las identidades, los
widgets genéricos, los fondos de cada identidad, el cierre del día, las 8
pantallas genéricas (login, recuperación, elección de identidad, tienda,
mascota, logros, colección, perfil), `NordayCoreLocalizations`,
`CatalogosCore`, y los assets de animations, sounds y mascota. La lista
completa, en el `CLAUDE.md` del paquete.

### Qué vive aquí

- `screens/` — `HomeShell` (las pestañas Hoy, Mascota y Hábitos, y el menú),
  `DashboardScreen` (Hoy) y `dashboard_logica.dart` (sus decisiones sin
  widgets ni red, para poder probarlas), la lista de hábitos, el detalle y el
  alta/edición.
- `services/` — `ApiServiceHabitos`, `AnalyticsHabitos`,
  `CrashlyticsService`, el recorrido guiado (`recorrido_onboarding.dart`,
  con sus pasos, y `anclas_recorrido.dart`, las anclas en un solo sitio),
  `descubrimiento_detalle.dart` (si el usuario ya entró alguna vez en un
  detalle) y `habitos_refresh.dart` (aviso de que la lista ha cambiado).
- `models/habito.dart`.
- `l10n/` — `AppLocalizations` y `Catalogos` (categorías y logros de hábito).
- `widgets/` — ver abajo.
- `assets/branding/` — lo único de assets que **no** se comparte.
- `store/` — los gráficos de la ficha de Play: icono, icono adaptativo,
  banner, gráfico de funciones, logo horizontal y símbolos. El icono de la
  app y el splash salen de aquí (`flutter_launcher_icons` y
  `flutter_native_splash`, en el `pubspec.yaml`).

También `lib/widgets/identidad_ui.dart` (tarjeta de hábito, chip de frecuencia,
celda del heatmap y tema de la barra inferior) y `lib/widgets/estados_hoy.dart`
(los cuatro estados de Hoy: carga, vacío, error y todo hecho), junto con
`tira_semana.dart` (los siete días encima de Hoy, sin recargar red),
`chevron_detalle.dart` (el que anuncia que una tarjeta abre su detalle) y
`transito_fila.dart` (el paso de una fila de pendiente a hecha sin que la
lista dé tirones). Son UI genérica de aspecto pero de dominio
en lo que dicen, así que se quedan aquí. Despachan por `FormaIdentidad` con un
`switch` exhaustivo y sacan los radios de `IdentidadPaleta` — el mismo patrón
que el paquete usa en el halo, el terrario, el aro y el check. Al añadir una
pieza nueva a Hoy, seguirlo en vez de escribir números sueltos.

### Lo que esta app le enchufa al paquete

El paquete no puede importar de aquí, así que la app se conecta por estos
puntos:

1. **`destinoTrasLogin`** (función suelta en `home_shell.dart`) — se le pasa a
   `LoginScreen` y a `PerfilScreen`, que no pueden conocer `HomeShell`.
2. **`Catalogos.registrarEnElMotor()`** en `main()` — le da al motor los
   logros de hábitos: los 32 de dominio que siembra el backend. En el
   paquete sólo viven los que no saben de dominio
   (`BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`, los tres de identidad,
   los dos de la mascota e `INTERACCION_RESENA`, retirado).
3. **`nordayNavigatorKey`** — `MaterialApp` usa el del paquete en vez de uno
   propio, porque `CelebracionService` lo necesita.
4. **`MascotaScreen.ayudaAnimo` y `ayudaXp`** — `HomeShell` le pasa dos
   `AyudaCampo` con los textos que explican el ánimo de Nori y de dónde sale
   la XP, que hablan de hábitos.
5. **`EleccionIdentidadScreen.alElegir`** — tras elegir la identidad gratis
   del onboarding, a `HomeShell`.
6. **El progreso del día** — `DashboardScreen` publica cuántos hay y cuántos
   hechos con `publicarProgresoDia`; `HomeShell` monta `FondoIdentidad` y
   `CapaProgresoIdentidad`, y llama a `limpiarProgresoDia` al salir.
7. **El cierre del día** — `HomeShell` monta `CapaCierreDelDia` y
   `DashboardScreen` llama a `mostrarCierreDelDia` al completar lo último del
   día. Sale una vez al día por usuario (fecha guardada en el dispositivo,
   `cierre_dia_fecha_<usuarioId>`) y nunca durante el recorrido guiado.
8. **`SplashGenerico.rutaImagen`** — el símbolo de la brújula,
   `assets/branding/simbolo_negativo.png`.

## Identidad de marca (aplicar siempre en UI nueva)

- **Nombre**: **Norday Habits**, en todos los idiomas. **Norday** es la
  marca del ecosistema.
- **Símbolo**: la brújula con la N. Hoy es el icono de la app y su splash
  (`store/` y `assets/branding/`).
- **Nori** es la mascota y una funcionalidad central, y también aparece como
  presencia de marca en el login. **Si la cara de Norday es la brújula o Nori
  está por decidir**, después de la prueba cerrada con testers. Hasta
  entonces, no dar ninguna de las dos como decidida.
- **Identidades**: salen tres, Profundidad, Neotokyo+ y Dulce. Alba está
  retirada desde el 6-sep-2026. Cada identidad trae sus colores, tipografía,
  formas y fondo; el detalle, en el `CLAUDE.md` del paquete.
- **Tipografía**: la guía original fijaba Manrope como única familia. Hoy el
  tema por defecto usa Space Grotesk para titulares y Manrope para el
  cuerpo, y cada identidad trae las suyas.
- **Paleta**: Azul Noche `#0A1628`, Azul Acero `#23395D`, Verde Esmeralda
  `#27C76F` (nunca como texto pequeño sobre fondo claro — usar Verde
  Oscuro `#1EA85B` en ese caso), Gris Muy Claro `#EEF2F6`.
- **Iconos**: Lucide Icons (Material Icons ya sustituido).

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

## Identidad equipada

La fuente de verdad es el backend, no el dispositivo: `Equipamiento`
(en el paquete) lee `getInventarioProductos()` y casa el `codigo` del
producto contra `catalogoIdentidades`. Ya no se usa `SharedPreferences`.

Los avatares están retirados desde el 15-sep-2026: la app no los usa y el
avatar del usuario es Nori.

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
de las categorías que crea el usuario, que el backend admite aunque la app
hoy no permita crearlas— se muestra el nombre que manda el backend. Nunca un
código crudo.

## Tocar el paquete

Un cambio en `norday_flutter_core` no llega solo: se mergea y se tagea
allí, se cambia aquí el `ref:` al tag nuevo y se hace
`flutter pub upgrade norday_flutter_core`, porque pub cachea el commit
resuelto. Antes de probar, comprobar el `resolved-ref` del `pubspec.lock`.
Para probar una rama del core sin tag, `pubspec_overrides.yaml` con
`path: ../norday_flutter_core`, que no se commitea.

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
- **Google Sign-In en debug necesita la huella de depuración de esa
  máquina**: su SHA-1 en Firebase y un cliente OAuth Android propio en Google
  Cloud (Firebase sola no basta). Cada máquina tiene su clave de depuración,
  así que cada una necesita su cliente. Sin eso, se prueba con APK de release.

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

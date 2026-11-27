# Norday — Contexto del proyecto (Flutter / Mobile)

Esta app (Norday Habits) es la primera de un ecosistema de apps Norday.
El motor genérico ya **no vive aquí**: está extraído en el paquete
[norday_flutter_core](https://github.com/jgrabalosa/norday_flutter_core),
que esta app consume como dependencia Git, por tag (`ref: vX.Y.Z`).
Qué hace la app, para quien no la conozca: ver el `README.md`.

## Antes de tocar…, lee…

Lo que solo importa en una parte del código vive en `docs/`. Antes de tocar
esa parte, léelo.

- Antes de tocar `screens/`, `services/`, `models/`, `widgets/` o `store/`
  (qué hay en cada carpeta, el permiso de notificaciones, «Empezar sesión» y
  Focus, las piezas de Hoy por identidad), lee
  `docs/funcionamiento/estructura-de-la-app.md`.
- Antes de tocar `main.dart`, `home_shell.dart`, `destinoTrasLogin`, los
  registros en el motor (`Catalogos.registrarEnElMotor`,
  `registrarTextosHabits`), el progreso del día, el cierre del día o el grano
  de papel, lee `docs/funcionamiento/conexion-con-el-core.md`.
- Antes de tocar hábitos de minutos (`models/minutos.dart`,
  `widgets/panel_minutos.dart`, `l10n/textos_minutos.dart`, las plantillas),
  lee `docs/funcionamiento/habitos-de-minutos.md`.
- Antes de tocar `l10n/`, un `.arb` o los catálogos del backend (categorías,
  logros, productos), lee `docs/funcionamiento/textos.md`.
- Antes de tocar las pistas de Nori (`lib/services/pistas_nori.dart`,
  `widgets/nota_pista.dart` o una pista nueva), lee
  `docs/funcionamiento/pistas-nori.md`.
- Antes de tocar «Cómo funciona» (`screens/como_funciona_screen.dart`) o la
  tarjeta «Así fue tu semana» (`widgets/tarjeta_semana.dart`), lee
  `docs/funcionamiento/estructura-de-la-app.md`.
- Antes de tocar el idioma, la zona horaria o sus selectores (dos
  preferencias independientes), lee `docs/funcionamiento/idioma-y-zona.md`.
- Antes de tocar la identidad equipada (la manda el backend, no el
  dispositivo), el tema tras el login o el splash, lee
  `docs/funcionamiento/identidad-equipada.md`.
- Antes de cambiar el `ref:` de `norday_flutter_core`, el `pubspec.lock` o
  probar una rama del core, lee `docs/procedimientos/tocar-el-paquete.md`.
- Antes de tocar flavors, `lib/entorno.dart`, `google-services.json`,
  Google Sign-In o `build.gradle.kts`, lee
  `docs/procedimientos/variantes-y-entornos.md`.
- Antes de subir una dependencia o probar permisos y Google Sign-In en un
  móvil, lee `docs/lecciones/paquetes-y-dispositivo.md`.
- Antes de escribir un test o tocar animaciones, `l10n`, Crashlytics o la
  pantalla de borde a borde, lee `docs/lecciones/flutter-y-tests.md`.
- Antes de dar cifras, verificar, o escribir scripts de PowerShell, lee
  `docs/lecciones/metodo-de-trabajo.md`.

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
sonido, idioma, zona), el tema y las identidades, los
widgets genéricos, los fondos de cada identidad, el cierre del día, las 9
pantallas genéricas (login, recuperación, elección de identidad, tienda,
mascota, logros, colección, perfil y actualización obligatoria),
`NordayCoreLocalizations`,
`CatalogosCore`, y los assets de animations, sounds y mascota. La lista
completa, en el `CLAUDE.md` del paquete.

### Qué vive aquí

`screens/`, `services/`, `models/`, `l10n/`, `widgets/`, `assets/branding/`
(lo único de assets que **no** se comparte) y `store/`. El detalle, en
`docs/funcionamiento/estructura-de-la-app.md`.

La app debe fijar `ApiServiceCore.appId = 'habitos'` antes de `runApp`: el
core no puede asumir el dominio por defecto. El paquete no puede importar de
aquí; los puntos de conexión están en
`docs/funcionamiento/conexion-con-el-core.md`.

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
- **Espaciado**: rejilla de 4 (`AppSpacing` del paquete: 4, 8, 12, 16, 24, 32). Todo lo nuevo sale de ahí; lo existente se pasa cuando se toque.
- **Escala de letra**: los titulares van en pasos de 4 (16/20/24/28; la cifra, 32), con suelo de 11. Un tamaño nuevo se pide a un rol de la escala (`Theme.of(context).textTheme`), nunca con `fontSize` a mano.

## Textos

Ninguna pantalla nueva lleva literales. Dos catálogos y dos clases, y los dos
delegados conviven en `MaterialApp`: lo de hábitos en `lib/l10n/app_*.arb`
(`AppLocalizations.of(context)!`) y lo genérico en los `core_*.arb` del
paquete (`NordayCoreLocalizations.of(context)!`). Tras editar un ARB,
`flutter gen-l10n`; los `app_localizations*.dart` no se versionan.
**Caída obligatoria**: un código de catálogo sin traducir o `null` muestra el
nombre que manda el backend, nunca el código crudo. Las claves duplicadas y
el resto, en `docs/funcionamiento/textos.md`.

## Tocar el paquete y compilar

- **Core fijado por `v0.62.0`** (`resolved-ref` en el `pubspec.lock`, que se
  versiona). Cambiarlo es un procedimiento de varios pasos:
  `docs/procedimientos/tocar-el-paquete.md`. `pubspec_overrides.yaml` (rama
  del core sin tag) no se commitea.
- **`--flavor` siempre.** `produccion` es la de Play (`com.norday.habitos`).
  `prueba` es `com.norday.habitos.prueba`, se llama «Habits PRUEBA» y va contra
  staging con `--dart-define=NORDAY_API_URL=https://staging-api.norday.app/api`.
  Los comandos están en el README.
- **`lib/entorno.dart` para la app al arrancar** si el flavor y la URL no
  cuadran. No se quita ni se salta.
- **La de prueba nunca abre Google Play** (`AperturaEnfoque.faltaPrueba`).
- **Nunca se instala `--flavor produccion` en un móvil con la app de Play**:
  mismo paquete, otra firma, y la salida sería desinstalar la de Play.
- Cinta «PRUEBA», nombre visible, `google-services.json` y la SHA-1 de la
  firma de Play: `docs/procedimientos/variantes-y-entornos.md`.
- **Hábitos de minutos:** «Empezar sesión» está apagado
  (`PanelMinutos.enfoqueDisponible = false`) y Habits con él no sale a
  Producción hasta que Focus sea visible en Producción. Ver
  `docs/funcionamiento/habitos-de-minutos.md`.

## Formato del código

Todo el código Dart va formateado con `dart format`. Antes de cada commit que
toque un `.dart`, desde la raíz: `dart format lib test`.

- Sólo `lib` y `test`. Nunca `dart format .`.
- **Después de formatear, `flutter analyze`.** El formateador parte en varias
  líneas un `if` sin llaves que cabía en una, y entonces salta
  `curly_braces_in_flow_control_structures`. Se arregla poniendo llaves, no
  deshaciendo el formato.
- Un cambio que sólo reformatea va en su propio commit, sin mezclar con código.
- `dart format lib` toca también los `app_localizations*.dart` generados, que
  no se versionan: no importa, y por eso cuenta más ficheros de los que entran
  en el commit.

## Estilo de trabajo con el usuario

- Un paso a la vez, confirmar que compila antes de seguir.
- Si algo admite varios diseños o no está claro, preguntar antes de
  decidir — no asumir.

## Git

- **`git diff` y `git log` abren paginador**: `git --no-pager`.
- **`git diff HEAD~1` compara con el directorio de trabajo**: incluye lo no
  commiteado. Para ver sólo el commit, `git diff HEAD~1 HEAD` o el remoto.
- **Antes de `git tag`, `git --no-pager log -1`.** Se subió `v0.9.0` sobre el
  commit de `v0.8.0` por saltarse el merge.
- **Un tag anotado resuelve a su commit, no a sí mismo**:
  `git rev-parse <tag>^{commit}`.

## Lecciones aprendidas

Errores que ya se cometieron una vez. No se vuelven a cometer. Las de
paquetes, dispositivo y método de trabajo están en `docs/lecciones/`. Las de
Flutter y tests, en `docs/lecciones/flutter-y-tests.md`.

- **Test en rojo antes del arreglo.** Si el test nuevo pasa contra el código
  sin arreglar, no demuestra nada: parar.

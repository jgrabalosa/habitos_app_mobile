# Textos (catálogos ARB y catálogos del backend)

Movido tal cual del `CLAUDE.md`. El `CLAUDE.md` conserva el resumen
(«ninguna pantalla nueva lleva literales», dos catálogos, caída obligatoria).

Ninguna pantalla nueva lleva literales. **Hay dos catálogos de textos y dos
clases**, y los dos delegados conviven en `MaterialApp`:

- Lo de hábitos → `lib/l10n/app_*.arb`, con `AppLocalizations.of(context)!`.
- Lo genérico → los `core_*.arb` del paquete, con
  `NordayCoreLocalizations.of(context)!`.

Ocho claves viven duplicadas a propósito porque las usan los dos lados
(`comunContinuar`, `logrosTitulo`, `navColeccion`, `navHoy`, `cancelar`,
`perfilTitulo`, `plantillaBeberAgua`, `dashCompletados`).
`comunContinuar` solo la usa el core y `dashCompletados` solo la app.
`logrosTitulo` no vale lo mismo: «Mis logros» en el menú de la app y «Logros»
en el título de la pantalla del core. Las demás: al cambiar una hay que
cambiarla en los dos sitios.

Los `app_localizations*.dart` los genera `flutter gen-l10n` y **no** se
versionan. (En el paquete sí se versionan los suyos — ver su CLAUDE.md.)

Los catálogos llegan del backend con `codigo`. Categorías de hábito con
`Catalogos.categoria`; productos, niveles y logros con `CatalogosCore`.
**Caída obligatoria**: si el código no está traducido o viene a `null` —caso
de las categorías que crea el usuario (T-031b: se crean desde el formulario
del hábito y desde «Mis hábitos»)— se muestra el nombre que manda el backend
tal cual, sin traducir. Nunca un código crudo.

Una excepción a «el texto crudo del backend no se enseña al usuario»: el 409 de
crear o renombrar una categoría (nombre repetido, tope de 20) se enseña con el
texto del servidor debajo del campo de la hoja
(`ApiServiceHabitos.mensajeDelServidor`), porque la app no puede saber de
antemano cuál de los dos es. Cualquier otro fallo de esa hoja o del borrado
usa los textos de la app (`catErrorGuardar`, `catErrorBorrar`).

**Nori es chico en los tres idiomas** (D-9): «contento» y «adulto» en
español, «o Nori» en portugués y «he/him» en inglés, nunca «it» (Quim,
24-nov-2026; así también la ficha de Play en `store/ficha-play/` y Focus).

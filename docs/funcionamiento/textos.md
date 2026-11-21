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
de las categorías que crea el usuario, que el backend admite aunque la app
hoy no permita crearlas— se muestra el nombre que manda el backend. Nunca un
código crudo.

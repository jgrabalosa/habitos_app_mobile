# Pistas de Nori «la primera vez»

Movidas tal cual del `CLAUDE.md` (sección «Pistas de Nori "la primera vez"»).

Mecanismo genérico en `lib/services/pistas_nori.dart` (`PistasNori`) y
`widgets/nota_pista.dart` (`NotaPista`, sobre `BurbujaContexto` del core). Una
pista es un `id`; el servicio no sabe qué dice ni de qué trata.

- **Una vez por cuenta y móvil**: `pista_vista_<usuarioId>_<id>` en
  `SharedPreferences`. Se marca al enseñarla, no al cerrarla.
- **Como mucho una al día** (fecha del móvil, `pista_ultima_fecha_<usuarioId>`):
  si hoy ya salió una, aunque esté cerrada, las demás esperan. La pista que se
  pierde así no se apunta como vista.
- **Nunca con la pista del alta** (`RecorridoOnboarding.activo`) **ni con otra
  nota abierta**. Nada sale por abrir la app sin más: cada una, cuando se da su
  momento.
- **Va en la lista, junto a lo que explica, y empuja el resto**: nunca flota
  encima. Se cierra tocándola. Con «reducir movimiento», sin animación.
- **Se mide** con `AnalyticsHabitos.pistaVista(id)` (`pista_vista`, parámetro
  `pista`, como el core). Cuando el core traiga `AnalyticsCore.pistaVista`,
  cambiar la llamada.

**Añadir una pista:** `static const` con su `id` en `PistasNori`; su texto en
los tres `app_*.arb` (`pista…`); en el sitio donde se da el momento,
`await PistasNori.intentar(id, usuarioId: …)` y, si devuelve true, pintar
`NotaPista` donde corresponda hasta que se toque, y llamar a
`PistasNori.cerrar(id)` al cerrarla o al salir de la pantalla. Un test por
pista: sale la primera vez y no la segunda (`test/pistas_nori_test.dart`).
Las tres de hoy están en `DashboardScreen` (`_evaluarPistas`, `_ofrecerPista`).

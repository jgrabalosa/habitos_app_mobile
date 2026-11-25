# Tocar el paquete (`norday_flutter_core`)

Movido tal cual del `CLAUDE.md` (sección «Tocar el paquete»).

Un cambio en `norday_flutter_core` no llega solo: se mergea y se tagea
allí, se cambia aquí el `ref:` al tag nuevo y se hace
`flutter pub upgrade norday_flutter_core`, porque pub cachea el commit
resuelto. Antes de probar, comprobar el `resolved-ref` del `pubspec.lock`.
Para probar una rama del core sin tag, `pubspec_overrides.yaml` con
`path: ../norday_flutter_core`, que no se commitea (está en `.gitignore`).

**Core fijado por `v0.63.0`** (25-nov-2026: compartir a Nori con `TarjetaNori` y `alCompartir`, la mini Nori por toda la altura y el check vivo más rápido): `resolved-ref` `f5f0e97e13bd6bd7f116ba40cfc75c164f4066ae`. Antes, `v0.62.0` (23-nov-2026, para la primera mini: la versión recomendada, «Alimentar» arriba y Nori reacciona al comer, «Saber más», `escribirANorday`, la pista de la tienda y `AnalyticsCore.pistaVista`): `resolved-ref` `e8f8994774c91ae8e28dde574d37b4c04e7c0670`. Antes, `v0.61.0` (`6aba27e`): el aviso de versión nueva de Play, el interruptor «Avisos de Norday», los datos del widget de Nori, las ayudas con rastro y el fundido del ramo. Trae `home_widget` (transitiva). La 1.3.0+11 de Play salió con `v0.59.1` (`c9cd3a5`). El `pubspec.lock` se versiona;
al cambiar de tag, comprobar que dice `source: git`, el `ref:` nuevo y el
`resolved-ref` que da `git rev-parse <tag>^{commit}` en el core.

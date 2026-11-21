# Tocar el paquete (`norday_flutter_core`)

Movido tal cual del `CLAUDE.md` (sección «Tocar el paquete»).

Un cambio en `norday_flutter_core` no llega solo: se mergea y se tagea
allí, se cambia aquí el `ref:` al tag nuevo y se hace
`flutter pub upgrade norday_flutter_core`, porque pub cachea el commit
resuelto. Antes de probar, comprobar el `resolved-ref` del `pubspec.lock`.
Para probar una rama del core sin tag, `pubspec_overrides.yaml` con
`path: ../norday_flutter_core`, que no se commitea (está en `.gitignore`).

**Core fijado por `v0.60.0`** (21-nov-2026, tras la 1.3.0+11: el check
vivo, tu Nori como avatar, «Compartir» en el cierre del día y la prenda del
login): `resolved-ref` `ae7494fcebfdc82df1880392c10c67478566f956`. La
1.3.0+11 de Play salió con `v0.59.1` (`c9cd3a5`). El `pubspec.lock` se versiona;
al cambiar de tag, comprobar que dice `source: git`, el `ref:` nuevo y el
`resolved-ref` que da `git rev-parse <tag>^{commit}` en el core.

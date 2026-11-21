# Tocar el paquete (`norday_flutter_core`)

Movido tal cual del `CLAUDE.md` (sección «Tocar el paquete»).

Un cambio en `norday_flutter_core` no llega solo: se mergea y se tagea
allí, se cambia aquí el `ref:` al tag nuevo y se hace
`flutter pub upgrade norday_flutter_core`, porque pub cachea el commit
resuelto. Antes de probar, comprobar el `resolved-ref` del `pubspec.lock`.
Para probar una rama del core sin tag, `pubspec_overrides.yaml` con
`path: ../norday_flutter_core`, que no se commitea (está en `.gitignore`).

**Core fijado por `v0.59.1`** (20-nov-2026, versión 1.3.0+11, D-41: el
letrero y el ramo del día en su sitio de la lista de Hoy; los sonidos más
bajos; el letrero de la lista espera a que se vaya el velo del cierre):
`resolved-ref` `c9cd3a503669f23b535bc1af2ccd42dbda9d9da0`. El `pubspec.lock` se versiona;
al cambiar de tag, comprobar que dice `source: git`, el `ref:` nuevo y el
`resolved-ref` que da `git rev-parse <tag>^{commit}` en el core.

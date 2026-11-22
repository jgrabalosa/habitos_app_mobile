# Tocar el paquete (`norday_flutter_core`)

Movido tal cual del `CLAUDE.md` (sección «Tocar el paquete»).

Un cambio en `norday_flutter_core` no llega solo: se mergea y se tagea
allí, se cambia aquí el `ref:` al tag nuevo y se hace
`flutter pub upgrade norday_flutter_core`, porque pub cachea el commit
resuelto. Antes de probar, comprobar el `resolved-ref` del `pubspec.lock`.
Para probar una rama del core sin tag, `pubspec_overrides.yaml` con
`path: ../norday_flutter_core`, que no se commitea (está en `.gitignore`).

**Core fijado por `v0.61.0`** (22-nov-2026, para la primera mini: el aviso de versión nueva de Play, el interruptor «Avisos de Norday» en Perfil, los datos del widget de Nori, las ayudas con rastro y el fundido del ramo): `resolved-ref` `6aba27e9f70c4d19d77c151c79fd4e6e32591c77`. Trae `home_widget` (transitiva). La 1.3.0+11 de Play salió con `v0.59.1` (`c9cd3a5`). El `pubspec.lock` se versiona;
al cambiar de tag, comprobar que dice `source: git`, el `ref:` nuevo y el
`resolved-ref` que da `git rev-parse <tag>^{commit}` en el core.

# Idioma y zona horaria

Movido tal cual del `CLAUDE.md`.

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

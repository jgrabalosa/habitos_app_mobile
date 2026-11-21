# Hábitos de minutos

Movido tal cual del `CLAUDE.md`.

- **El check**: en Hoy, un hábito de minutos lleva el mismo `CheckCircular`
  que uno de veces (un solo check en toda la app, 20-nov-2026), marcado al
  cumplir la meta. Su toque, hecho o no, abre el panel; lo que se lleva a
  medias lo dice el chip de la fila.
- **Duraciones**: todo lo que enseña minutos pasa por `duracionLegible`
  (`l10n/textos_minutos.dart`): «45 min», «1 h», «1 h 30 min». Los pares
  hecho/objetivo, por `parMinutos`: «20 / 30 min» si las dos cifras son
  menores de 60, «45 min / 1 h 30 min» si alguna llega. Se guarda y se
  escribe siempre en minutos: los campos de entrada y los botones +5/+15/+30
  del panel siguen en minutos.
- **Panel** (`widgets/panel_minutos.dart`): solo suma. Bajo el progreso,
  «Te faltan …» o «Meta cumplida (· +… de más)». «Completar · +X», arriba y a
  todo lo ancho, envía justo lo que falta como una suma más (su clave,
  `MANUAL`); solo sale si falta algo. Los botones rápidos van en su casilla y,
  mientras falta, solo salen los menores que lo que falta. Deshacer quita la
  última entrada y dice su cantidad y la hora local (`Registro.creadoEn`, que
  llega en UTC sin zona). Cada envío lleva su clave y repite la misma si no
  hubo respuesta clara; mientras envía no se cierra, y cerrar tras un envío
  incierto devuelve `desconocido`. El hueco de Enfoque es lo último del panel:
  «Empezar sesión» solo sale si el día que se mira es hoy, porque una sesión
  cuenta en el día en que empieza y desde otro día sumaría a hoy. **Hoy está
  apagado**: `PanelMinutos.enfoqueDisponible = false` (salida A, 15-nov).
  Se enciende cuando Focus sea visible en Producción; los tests de «Empezar
  sesión» lo encienden en `setUp`.
- **Plantillas** (`models/plantilla_habito.dart`): son datos, 14 en el orden
  del día, con `unidad`, `minutos`, su hora de aviso (`horaAviso`, que el
  formulario trae puesta) y `nombresAntiguos` (los que tuvieron, para seguir
  ocultando la idea). Meditar (15 min), Caminar (30 min), Tocar un
  instrumento (20 min) y Leer (30 min) son de minutos; las demás, de veces.
  Los `id` no cambian nunca: van a Analytics.

# Hábitos de minutos

Movido tal cual del `CLAUDE.md`.

- **El check**: en Hoy, un hábito de minutos lleva el mismo `CheckCircular`
  que uno de veces (un solo check en toda la app, 20-nov-2026), marcado al
  cumplir la meta. Su toque, hecho o no, abre el panel; lo que se lleva a
  medias lo dice el chip de la fila.
- **Duraciones**: todo lo que enseña minutos pasa por `duracionLegible`
  (`l10n/textos_minutos.dart`): «45 min», «1 h», «1 h 30 min». Los pares
  hecho/objetivo, por `parMinutos`: «20 / 30 min» si las dos cifras son
  menores de 60, «45 min / 1 h 30 min» si alguna llega. Se guarda siempre en
  minutos; el campo de la cifra libre del panel y los botones +5/+15/+30
  siguen en minutos. **La meta del formulario ya no se escribe** (T-033):
  chips de `metasRapidasMinutos` (10, 15, 30 min, 1 h, 2 h) y «Otra…», que
  abre `mostrarHojaMetaMinutos` (`widgets/hoja_meta_minutos.dart`): dos
  `CupertinoPicker`, horas (0–10) y minutos (de 5 en 5), con «Listo». Sus
  reglas, en `minutos.dart` (`minutosDeRueda`): con 10 h solo 0 min; con 0 h
  no hay 0 min; una meta que ya existía y no es múltiplo de 5 (22 min) se
  incluye tal cual en su hora y queda elegida: nunca se redondea sola.
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
  Los `id` no cambian nunca: van a Analytics. Cada plantilla guarda el
  `codigoIcono` del catálogo (`models/iconos_habito.dart`) y `icono` es un
  getter que lo busca: una sola fuente para el icono de la idea y el del
  hábito. Una plantilla nueva trae un código que ya esté en el catálogo (un
  test lo comprueba).

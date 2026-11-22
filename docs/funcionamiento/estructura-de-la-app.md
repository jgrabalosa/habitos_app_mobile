# Qué vive en la app (carpetas de `lib/`)

Movido tal cual del `CLAUDE.md` (sección «Qué vive aquí»). Ver también
`conexion-con-el-core.md` (el punto 6 de ahí es «El progreso del día») y
`habitos-de-minutos.md`. «Ver abajo» de `widgets/` se refiere al último
párrafo de este fichero.

- `screens/` — `HomeShell` (las pestañas Hoy, Mascota y Hábitos, y el menú),
  `DashboardScreen` (Hoy) y `dashboard_logica.dart` (sus decisiones sin
  widgets ni red, para poder probarlas), la lista de hábitos
  (`habitos_screen.dart`), el detalle (`habito_detalle_screen.dart`), el
  alta/edición (`habito_screen.dart`) y las ideas para empezar
  (`ideas_habito_screen.dart`: «Empieza con una idea», con las plantillas;
  `abrirAltaHabito` va al formulario vacío si no queda ninguna idea) e
  «Invitar a un amigo» (`invitar_screen.dart`: `TarjetaInvitacion`, una
  postal 4:5 que se comparte como PNG de 1080 × 1350 con `share_plus`: el
  fondo de la identidad sin panel, Nori grande y vestida con `NoriVestida`,
  que el core no exporta en su barrel, y, arriba, un dato de quien invita
  sacado de `getMascota`, «Pipo ya es cría · nivel 7». El dato se puede
  quitar con un interruptor, encendido por defecto; sin red, la postal sale
  sin él. El enlace no se dibuja: va en su línea del texto que acompaña.
  `invitar_compartido` lleva `con_dato`. Para ver la postal sin móvil:
  `test/postal_exportar_test.dart`, que solo corre con
  `--dart-define=EXPORTAR_POSTAL=true` y deja los PNG en `build/postal/`). El panel del menú es la función suelta
  `mostrarMenuShell`, para poder probar sus entradas sin montar las
  pestañas. El alta
  nueva arranca en `HomeShell`: la bienvenida de una
  tarjeta (`widgets/bienvenida.dart`), el formulario real del primer hábito y,
  si se guarda, una pista sobre su círculo en Hoy. Nada de esto sale a quien
  no es alta nueva.
- **El regalo del gorro de Papá Noel** (T-057, `widgets/regalo_gorro.dart`) es
  lo otro que puede salir al entrar: una tarjeta como la bienvenida (sin
  «Ahora no», sin cerrar tocando fuera ni con atrás) con Nori con el gorro y un
  solo botón. `HomeShell` llama a `RegaloGorro.mostrarSiToca` tras
  `_cargarUsuario`, y sale solo si **no** es un alta nueva (esa la ve en la
  siguiente apertura), el recorrido guiado no está activo, el catálogo trae
  `PRENDA_GORRO_NOEL` con `precioEnTienda` gratis hoy (fecha del móvil) y el
  usuario no lo tiene en el inventario. Si el catálogo o el inventario fallan,
  no sale. **No se guarda nada en el móvil**: deja de salir sola al acabar la
  oferta (7-ene-2027) o en cuanto lo tiene. El botón compra
  (`ApiServiceCore.comprarProducto`; un 409 cuenta como hecho) y, si el
  inventario no tenía ninguna prenda equipada de `Cabeza`, lo equipa con
  `Equipamiento.equiparPrenda`; si la compra falla, la tarjeta se cierra igual
  sin mensaje y vuelve a salir en la siguiente apertura. Eventos:
  `regalo_gorro_visto` y `regalo_gorro_cogido` (`resultado`: `ok`,
  `ya_lo_tenia`, `fallo`). Seams de test: `RegaloGorro.obtenerCatalogo`,
  `obtenerInventario`, `comprar`, `equipar` y `ahora`. Importa
  `precio_tienda.dart` y `nori_vestida.dart` del core directamente, porque su
  barrel no los exporta.
- **La reseña de Play (In-App Review)** se pide justo después de la ceremonia
  del cierre del día, nunca a mitad del día. `DashboardScreen` cuenta los días
  de uso (distintos días en que se completa un hábito; `resena_dias_uso` y
  `resena_ultima_fecha`) antes de `_cerrarDia`; al llegar a un hito de
  `_hitosResena` (`[3, 15, 30]`, como mucho tres veces en la vida) solo guarda
  `resena_pendiente`, y `_cerrarDia` la pide y la borra tras
  `mostrarCierreDelDia`. Si no hay ceremonia (día ya cerrado, pista de Hoy
  abierta) no se pide y la marca sigue. Sin preguntas previas, sin botón y sin
  nada encima de la tarjeta (normas de Google). Justo antes de pedirla se
  registra el evento `resena_pedida` (`AnalyticsHabitos.resenaPedida`) con
  `hito` (3, 15 o 30): el último de `_hitosResena` que no pasa de los días de
  uso, porque puede pedirse días después de llegar al hito. Solo dice que se
  pidió: Google no cuenta si enseñó el diálogo ni si el usuario puntuó. Los
  seams de test son `DashboardScreen.solicitarResena` y
  `DashboardScreen.registrarResenaPedida`. El día que se comparte el cierre (T-043)
  no se pide: lo resuelve esa tarjeta.
- El permiso de notificaciones se pide al elegir la hora del recordatorio, en
  `habito_screen.dart`, con `NotificacionesService` del core: nunca al entrar.
  Al crear desde una plantilla, que trae la hora puesta, se pide al guardar
  si no se ha preguntado ya en ese formulario.
- El icono del hábito: `habito_screen.dart` manda el `codigoIcono` de la
  plantilla al crear desde ella y el que ya tenía el hábito al editar; desde
  cero, `sparkles`. La fila «Icono» abre la rejilla
  (`widgets/selector_icono_habito.dart`, con la forma de la identidad). El
  icono se ve en Hoy (20), en la lista de hábitos y en el detalle (24), en
  `textMuted`, y no cambia al completarse. El porqué, en
  `docs/decisiones/0001-catalogo-iconos-habito.md`.
- `services/` — `ApiServiceHabitos`, `AnalyticsHabitos`,
  `CrashlyticsService`, la pista de Hoy tras el primer hábito
  (`recorrido_onboarding.dart`, y `anclas_recorrido.dart`, que hoy tiene una
  sola ancla: el check del hábito),
  `descubrimiento_detalle.dart` (si el usuario ya entró alguna vez en un
  detalle), `habitos_refresh.dart` (aviso de que la lista ha cambiado),
  `app_refresh.dart` (la señal para que las pantallas vivas se recarguen al
  volver a primer plano), `al_volver.dart` (lo que pasa al volver a primer
  plano, en un solo punto: esa señal, la mascota, la identidad y el registro
  del aviso del móvil), `identidad_al_volver.dart` (vuelve a pedir la
  identidad equipada al backend, sin solapar peticiones), `clave_envio.dart`
  (el UUID v4 de la `clave` de cada envío de minutos, con `Random.secure()`),
  `pausa.dart` (el código del producto `PAUSA_HABITO` y cuántas pausas hay
  en el inventario) y `abrir_enfoque.dart` («Empezar sesión» del panel de
  minutos: abre Norday Focus con el hábito, o su ficha de Play (nunca desde
  la de prueba), por un canal
  de `MainActivity.kt`; los dos paquetes de Enfoque van en `<queries>` del
  AndroidManifest).
  **Norday Habits con «Empezar sesión» no sale a Producción hasta que Norday
  Focus sea visible en Producción** (o salen a la vez): sin ella, el botón
  lleva a una ficha que no existe. En prueba cerrada solo vale si los testers
  de Habits también lo son de Focus. La guía del despliegue conjunto está en
  `docs/despliegue.md` del backend (`habitos-app`). **Hoy está apagado**:
  `PanelMinutos.enfoqueDisponible = false` (salida A, 15-nov). Se enciende
  cuando Focus sea visible en Producción; los tests de «Empezar sesión» lo
  encienden en `setUp`.
- `models/` — `iconos_habito.dart` (el catálogo de 27 iconos de hábito, código
  → `LucideIcons`; `iconoDeHabito(codigo)` da `sparkles` si el código es nulo
  o desconocido, y `nombreIconoHabito` el nombre traducido para el lector de
  pantalla, claves `iconoHabito…` de los ARB), `habito.dart` (con
  `UnidadHabito`: veces o minutos, y `codigoIcono` / getter `icono`), `hoy.dart`
  (lo que manda `/hoy`: filas, secciones, tira y tendencia del ritmo),
  `minutos.dart` (las reglas de los hábitos de minutos, sin widgets ni red:
  límites 1–600, metas y sumas rápidas, lo que envía «Completar»),
  `registro.dart` (un registro de `/registros/habito/{id}`, con minutos,
  origen `MANUAL`/`ENFOQUE` y `creadoEn`), `objetivo_programado.dart` (un
  cambio de objetivo que aún no vale), `plantilla_habito.dart` (ver «Hábitos
  de minutos») y `ritmo_reciente.dart` (si un hábito o la lista acaban de
  empezar: menos de siete días desde el alta).
- `l10n/` — `AppLocalizations` y `Catalogos` (categorías y logros de hábito).
- `widgets/` — ver abajo.
- `assets/branding/` — lo único de assets que **no** se comparte.
- `store/` — los gráficos de la ficha de Play: icono, icono adaptativo,
  banner, gráfico de funciones, logo horizontal y símbolos. El icono de la
  app y el splash salen de aquí (`flutter_launcher_icons` y
  `flutter_native_splash`, en el `pubspec.yaml`).

También `lib/widgets/identidad_ui.dart` (tarjeta de hábito, chip de frecuencia,
celda del heatmap y tema de la barra inferior) y `lib/widgets/estados_hoy.dart`
(carga, vacío y error; la tarjeta «¡Todo hecho!», que solo queda, invisible,
en Profundidad como hueco de la constelación; y `FiguraDelDiaHoy` y
`FinalDelDiaHoy`, ver el punto 6), junto con
`tira_semana.dart` (los siete días de Hoy, con sus flechas de semana a los
extremos, sin recargar red) y `cabecera_otro_dia.dart` (el mes y el botón
«Hoy», encima de la tira, solo cuando el día que se mira no es hoy),
`chevron_detalle.dart` (el que anuncia que una tarjeta abre su detalle) y
`transito_fila.dart` (el paso de una fila de pendiente a hecha sin que la
lista dé tirones). Son UI genérica de aspecto pero de dominio
en lo que dicen, así que se quedan aquí. Despachan por `FormaIdentidad` con un
`switch` exhaustivo y sacan los radios de `IdentidadPaleta` — el mismo patrón
que el paquete usa en el halo, el terrario, el aro y el check. En Neotokyo+
las tarjetas de Hoy usan `FiloNeon` (core v0.40.0): latiendo si el hábito está
pendiente, encendido si está hecho y fijo si el día no se puede marcar. En
Dulce (core v0.43.0) el chip, las celdas, la barra de avance y la pestaña de la
barra van a lápiz de color: borde con `BordeLapiz` y lo hecho a rayas. Al
añadir una pieza nueva a Hoy, seguirlo en vez de escribir números sueltos.

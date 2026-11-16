# Norday Habits — Historial de cambios

## 1.0.0 (3) — 2026-09-24

Estado: publicada en Alpha.

### Novedades

- Primera versión de Norday Habits para las pruebas cerradas.

### Mejoras

- Creación y seguimiento visual de hábitos.
- Mascota Nori, colección, temas, logros y rachas.

### Arreglos

- Versión base validada durante la prueba cerrada.

Para anunciar: nada.

## 1.0.0 (4) — 2026-10-08

Estado: en preparación.

### Novedades

- Control de sonido: un paso nuevo en la bienvenida para activar o silenciar el sonido, y un interruptor en Usuario, junto al idioma.
- Enlace «Ver detalle» en cada hábito de Hoy.
- Nuevos textos de bienvenida y de ordenación de hábitos.

### Mejoras

- Idioma, Zona horaria y Sonido se muestran con el mismo aspecto en Usuario.
- Al volver a la app, Hoy se actualiza y vuelve al día actual.
- Textos en portugués europeo.
- Nori ocupa menos zona táctil y deja tocar los hábitos que quedan debajo.
- La nota de contexto de Hoy ya no aparece inclinada.
- El cierre de sesión vuelve a iniciar correctamente el recorrido de acceso.
- La sesión de Google permite elegir de nuevo la cuenta al volver a entrar.

### Arreglos

- La descripción de un hábito se actualiza después de editarla.
- Las sesiones caducadas llevan al usuario al login con un aviso.

Para anunciar: el control de sonido.

## 1.1.0 (5) — 2026-10-20

Estado: publicada en Producción el 2026-10-22.

### Novedades

- Hoy rediseñado: dos secciones con contador, tira semanal con flechas y un anillo de avance del día.
- Ritmo: sustituye a la racha. Tarjeta «Tu ritmo» en Hoy, panel propio y el ritmo de cada hábito en su fila y en su detalle.
- Pausar y reanudar hábitos.
- Logros por días hechos y logros de ritmo.
- Cierre del día: la constelación en Profundidad y el ramo en Dulce.
- Dulce a lápiz: chips, calendario, barra, pestañas, estrellas, botón «+» y ramo.
- Neotokyo+: el filo de cada hábito muestra su estado.
- Bienvenida nueva de una tarjeta, con el permiso de notificaciones pedido en contexto y una pista en Hoy hacia «Esta semana».
- «Empieza con una idea» en vez de las etiquetas, con siete plantillas.
- Actualización obligatoria: la app avisa cuando hay una versión mínima nueva.

### Mejoras

- Las identidades adaptan el tema a su brillo, con un tercer color en Neotokyo+ y Dulce, un gesto al marcar y grano de papel.
- Calendario: días vacíos en contorno y lo hecho en verde.
- «Acabas de empezar» mientras el ritmo tiene menos de 7 días.
- Explicación de «Lo que llevas» y «Días de este mes» en el detalle.
- Al volver a la app se refresca la mini Nori y se recarga la identidad.
- «Meta» pasa a «objetivo» en español y portugués.
- Los avisos del móvil se registran al arrancar y al volver a la app.

### Arreglos

- Si un registro no se puede deshacer, la app lo explica con un aviso claro.
- El panel «Tu ritmo» respeta la barra inferior del sistema.

Para anunciar: el ritmo, el nuevo aspecto de Dulce y el rediseño de la app.

## 1.2.0 (6) — en preparación

Estado: en preparación. Sale sin "Empezar sesión": el botón llega con una versión posterior, cuando Norday Focus esté en Producción.

### Novedades

- Hábitos de minutos: al crear un hábito se elige «Veces» o «Minutos». En minutos, un objetivo por día (10, 15, 30 o 60 de un toque, o una cifra de 1 a 600) al que se llega con varias sesiones que se suman.
- Panel de minutos en Hoy: +5, +15 y +30, una cifra libre, «Completar · +X», que suma justo lo que falta, y Deshacer la última entrada, con su cantidad y su hora. Con la meta cumplida se puede seguir sumando.
- Detalle de un hábito de minutos: tiempo total, días a medias en el calendario y minutos por día.
- Cambios de objetivo programados: si un cambio vale desde otro día (mañana o el lunes), se avisa al guardar, se ve en el formulario y se puede anular.

### Mejoras

- Desde 60 minutos, todo lo que enseña minutos va en horas: «1 h», «1 h 30 min».
- Los textos dicen su unidad: «3 veces al día», «3 días por semana» (un semanal cuenta días), «Entre 1 y 600 minutos (10 h)» y «+20 puntos por completar la semana».
- Plantillas: «Leer» (30 min) y «Meditar» (15 min) pasan a ser hábitos de minutos.
- El aviso del móvil se registra por app, para que Norday Focus no pise el de Norday Habits.

### Arreglos

- Actualización obligatoria: la comprobación de la versión mínima ya no se repite al abrir la app en frío. Era una segunda petición además de la del arranque y, con la app lanzada en segundo plano, fallaba por red. Volver a la app sigue comprobando.
- Ideas para empezar: un hábito oculta una idea solo si coinciden por palabras. Un nombre corto como «Be» ya no oculta «Beber agua»; «Agua» o «Reading» la siguen ocultando.

Para anunciar: a decidir.

## Sin publicar

Estado: rama `wip-focus-economia`. Sale con la versión que encienda «Empezar sesión», después del backend con la V27 (Norday Focus paga lo suyo).

### Mejoras

- Las ayudas del ánimo y de la experiencia de Nori dicen cómo funciona de verdad: Nori se alegra en cuanto das un paso y está exultante con todo hecho, y las sesiones de Norday Focus también cuentan.

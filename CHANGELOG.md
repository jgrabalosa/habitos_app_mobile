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

## 1.2.0 (6) — no publicada sola

Estado: no se publicó sola; va dentro de la 1.3.0.

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

## 1.3.0 (11) — 2026-11-21

Estado: publicada en Producción el 2026-11-21 (enviada a Google el 20-nov, con la publicación gestionada; se publicó tras desplegar el backend y el arte de producción). Con el core 0.59.1: Nori vestida, invierno y Navidad 2026, el letrero del día de Neotokyo+ y el ramo de Dulce en su sitio de Hoy, el check amarillo de Profundidad y los sonidos más bajos.

### Novedades

- Nori se viste: un vestidor en la pantalla de Nori, con una prenda para la cabeza y otra para el cuerpo. Nori sale vestida en su pantalla, en las fases y en la Nori pequeña de Hoy.
- En la tienda, la sección «Nori»: las prendas de Invierno (gorro de lana y bufanda de rayas, hasta el 28 de febrero) y de Navidad (gorro de Papá Noel, gratis toda la Navidad, y traje de Papá Noel, hasta el 7 de enero). Se pueden probar antes de comprarlas. Lo comprado es tuyo para siempre.
- El terrario de Nori se llena de nieve en Navidad.
- En Neotokyo+, el día tiene su letrero de neón, arriba de la lista de Hoy: cada hábito hecho añade un tubo y, al terminar el día, el letrero se enciende tubo a tubo. Ocho letreros, según cuántos hábitos tengas.
- En Dulce, el ramo del día crece arriba de la lista de Hoy: una flor a lápiz por cada hábito hecho y, al terminar el día, se colorea y se ata.
- En Profundidad, el círculo de un hábito por hacer es amarillo, para que se vea sobre el cielo, y pasa a verde al completarlo.
- Invita a un amigo desde el menú.
- Siete ideas de hábito nuevas, y cada idea trae su hora de aviso.

### Mejoras

- La app se queda siempre en vertical.
- Un solo check para todos los hábitos: los de minutos llevan el mismo que los demás, en vez del «+», y se marca al cumplir la meta. Tocarlo sigue abriendo el panel de minutos.
- Los sonidos, más bajos: el de completar un hábito sonaba demasiado fuerte.
- Seis dibujos de Nori a todo color (los cuatro huevos, y la cría triste y la dormida), y los huevos sin la sombra pegada debajo.
- Cuando Nori está triste, «te espera» en vez de «te echa de menos».
- Nori gasta menos memoria: cada dibujo se carga a su tamaño en pantalla.
- Si una compra ya no se puede hacer (fuera de temporada o ya es tuya), la tienda lo dice y se pone al día.
- Colección ya no enseña las prendas: se ponen en el vestidor.
- Al cerrar sesión, el móvil deja de recibir los avisos de esa cuenta.
- El aviso del móvil se vuelve a registrar una vez con el cambio a un token por app.
- La ayuda del ánimo de Nori explica cuándo se alegra y cuándo está radiante; en inglés y portugués, Nori es chico.

### Arreglos

- La app ya no se cierra al arrastrar a Nori en pantallas pequeñas.
- En «Empieza con una idea», la última idea ya no queda debajo de la barra de navegación de Android.

## 1.4.0 (12) — 2026-11-23

Estado: en preparación (la primera mini, D-49). Con el core 0.62.0. Al publicarla, la versión mínima sube a 12: la actualización es obligatoria.

### Novedades

- Nueva pantalla «Cómo funciona», en el Menú entre «Mi cuenta» y «Cerrar sesión»: la semana, el ritmo, los puntos, Nori y la tienda en seis apartados que se despliegan, y «Ver otra vez la pista» para repetir la del primer hábito.
- Los «?» cuentan ahora lo que pasa de verdad: el ritmo se pone al día al acabar el día (o la semana, en los semanales) y no al marcar; «Esta semana» avisa del plazo hasta el domingo, del +20 % de puntos y de que no hace falta para terminar el día; la experiencia de Nori dice cuánto sube (5 por hábito, 15 por comida) y cuándo crece (cría en el nivel 3, adulto en el 11); y la frecuencia dice que la semana va de lunes a domingo.
- Cada hábito tiene su icono: se elige al crearlo o editarlo, y se ve en Hoy, en la lista y en el detalle. Las ideas para empezar ya traen el suyo.
- La meta de un hábito de minutos se puede poner en horas: chips de 1 h, 1 h 30 min y 2 h, y unas ruedas de horas y minutos para cualquier otra.
- «Invitar a un amigo» es ahora una postal de Nori en 4:5, con su fase y un dato suyo que se puede quitar antes de compartir.
- El check vivo: de vez en cuando, algo da una vuelta al aro de un hábito sin hacer (un cohete en Profundidad, un destello de neón en Neotokyo+, una punta de lápiz en Dulce).
- Tu Nori, con su fase y lo que lleva puesto, es tu avatar en Colección y en Mi cuenta.
- Al cerrar el día, un botón «Compartir» al final de la ceremonia: una postal con la figura de tu día (constelación, letrero o ramo), la fecha y cuántos hábitos hiciste. Nunca lleva los nombres de tus hábitos.
- Nori te explica cada regla semanal la primera vez que aparece: «Esta semana», la semana que se cierra y el extra por semana completa. Una nota corta junto a lo que explica, que se cierra tocándola, una sola vez y como mucho una al día.
- Al entrar en la app, una tarjeta te regala el gorro de Papá Noel (gratis y tuyo para siempre) hasta el 7 de enero, si aún no lo tienes. Si no llevas nada en la cabeza, Nori se lo pone al momento.
- En Perfil, un interruptor «Avisos de Norday» para apagar los avisos de la app (como mucho dos a la semana: cuando llevas días sin pasar o una semana se queda a medias). Tus recordatorios no cambian.
- Nori te pide permiso para avisarte: al acabar de crear tu primer hábito, o una sola vez al abrir la app si ya la usabas y no tienes las notificaciones activadas. Con «Ahora no» no vuelve a preguntar. Nunca sale si ya hay permiso ni si lo desactivaste en los ajustes del móvil.
- Si hay una versión nueva en Google Play, la app te lo ofrece al abrirla (como mucho una vez al día): se descarga mientras la usas y, al acabar, un aviso te deja reiniciar. Nunca te obliga.
- «Así fue tu semana»: el primer día de la semana que abres la app, una tarjeta de Nori te cuenta lo que hiciste la semana pasada (hábitos hechos, días completos, objetivos semanales logrados y tu ritmo). Solo lo hecho, nunca lo que faltó, y solo si hubo actividad.
- Puedes crear tus propias categorías.
- Si Google Play no te ha ofrecido la versión nueva, una tarjeta de Nori te la recomienda, una sola vez por versión. Nunca obliga.
- La primera vez que abres la tienda, una nota te cuenta para qué son tus puntos.
- Nori reacciona cuando le das de comer.

### Mejoras

- La invitación a valorar la app en Google Play ya no sale a mitad del día: se pide justo después de la ceremonia del cierre del día, tras el tercer, el decimoquinto y el trigésimo día de uso. Google tiene su propia cuota y puede no enseñarla.
- En Neotokyo+, el sol de «La ola» sube un poco y ya no toca la cresta.
- En Colección, el nombre y el botón de cada identidad van en la misma fila.
- Fuera del AndroidManifest unos meta-data que ya no se usaban.
- En Dulce, cada flor nueva del ramo entra con su fundido, no solo la primera.
- La ayuda de la tienda menciona la ropa de Nori.
- Las notificaciones llevan la brújula de Norday en verde, en vez de un cuadrado vacío.
- En la pantalla de Nori, «Alimentar» y «Tienda» van justo debajo de él: ya no hay que bajar para darle de comer.

### Arreglos

- En Dulce, «Invitar a un amigo» ya no sale con el fondo negro: lleva el papel de la identidad.

Para anunciar: nada.

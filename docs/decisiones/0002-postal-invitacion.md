# 0002 — La invitación, una postal de Nori en 4:5 con un dato que se puede quitar

Fecha: 21-nov-2026 (decisión de Quim del 20-nov, tarea T-034).

## Contexto

«Invitar a un amigo» (menú de `HomeShell`) compartía un PNG 9:16 de
1080 × 1920: Nori pequeña dentro de un panel de la identidad, un titular, el
enlace `norday.app/invitar` dibujado y nada personal (T-013). En WhatsApp
salía estrecho y en miniatura no se leía.

## Decisión

Una postal 4:5 de 1080 × 1350 (`TarjetaInvitacion`):

- el fondo de la identidad a sangre, sin panel;
- la Nori de quien invita, grande (lo que se ve de ella, el 57 % del alto),
  en su fase y con lo que lleva puesto (`NoriVestida`);
- arriba, un dato de quien invita: «Pipo ya es cría · nivel 7», o
  «Mi Nori …» si no le puso nombre;
- abajo, el wordmark pequeño;
- sin enlace dibujado: va en su propia línea del texto que acompaña, donde se
  puede pulsar.

El dato es el nombre, la fase y el nivel porque es lo que da el backend
(`getMascota`; no hay «días»). Cambia la decisión de «nada personal» de
T-013: el dato sale encendido, pero un interruptor lo quita antes de
compartir, y Analytics mide si se compartió con él (`con_dato`), nunca el
nombre.

## Alternativas descartadas

- **Solo texto, con vista previa del enlace**: pide tocar el servidor
  (las etiquetas Open Graph de `norday.app/invitar`).
- **El arreglo mínimo** (la misma tarjeta, más ancha): no arregla que en
  miniatura no se lea.

## Consecuencias

- Todo vive en `habitos_app_mobile`: sin cambios en el core ni en el servidor.
- `NoriVestida` no está en el barrel del core: se importa
  `package:norday_flutter_core/widgets/nori_vestida.dart`.
- El dibujo de Nori deja aire transparente en su caja, distinto en cada
  fase. La postal guarda, por fase, cuánto ocupa la figura
  (`_encuadreNori`). Si cambia el arte de Nori, hay que volver a medirlo con
  `test/postal_exportar_test.dart`.
- Sin red, la postal sale sin dato y con Nori adulta, y se comparte igual.

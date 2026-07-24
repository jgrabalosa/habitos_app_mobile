# Norday — Contexto del proyecto (Flutter / Mobile)

Esta app (Norday Hábitos) es la primera de un ecosistema de apps Norday.
El starter kit de Flutter (ApiService, sistema de temas, CelebracionService,
SonidoService, login) está pensado para extraerse a un paquete Dart
compartido cuando exista la segunda app.

## Regla de arquitectura obligatoria: Motor vs Disparadores

- **Motor** = genérico y reutilizable: ApiService, temas/tokens de diseño,
  CelebracionService (logros), SonidoService, animaciones genéricas
  (ej. `AnimacionPuntos(cantidad)`), lógica de mascota (estado→animación).
- **Disparadores** = específico de "hábitos": pantallas y lógica de
  Habito, Registro, Categoria.

**Ningún widget o servicio genérico debe conocer conceptos de dominio
como "hábito".** Por ejemplo, SonidoService solo conoce eventos tipo
`completar`/`logro`/`racha`, nunca nombres de hábitos concretos.

## Identidad de marca (aplicar siempre en UI nueva)

- Tipografía: Manrope (única familia, distintos pesos).
- Paleta: Azul Noche `#0A1628`, Azul Acero `#23395D`, Verde Esmeralda
  `#27C76F` (nunca como texto pequeño sobre fondo claro — usar Verde
  Oscuro `#1EA85B` en ese caso), Gris Muy Claro `#EEF2F6`.
- Iconos: Lucide Icons (Material Icons ya sustituido).
- La mascota es una funcionalidad, no la identidad de marca (eso es el
  logo/brújula).

## Modularización futura (no ejecutar todavía, solo respetar la disciplina)

Cuando exista la segunda app del ecosistema, los servicios genéricos se
extraerán a un paquete Flutter compartido. Escribe el código nuevo
pensando ya en esa separación (evita acoplar lógica de motor a widgets
de hábitos).

## Estilo de trabajo con el usuario

- Un paso a la vez, confirmar que compila antes de seguir.
- Si algo admite varios diseños o no está claro, preguntar antes de
  decidir — no asumir.

# 0001 — Catálogo de iconos de hábito (T-011b)

## Contexto

Cada hábito puede llevar un icono (T-011). El backend (T-011a) solo guarda
un texto en `icono`, opcional: nulo si el hábito no tiene, y al actualizar,
si no llega o llega nulo, conserva el anterior. Las 14 plantillas de «Empieza
con una idea» ya tenían cada una su `IconData` de Lucide, escrito a mano en
`PlantillaHabito`.

## Decisión

- **El catálogo vive en la app**, en `lib/models/iconos_habito.dart`: un mapa
  fijo `iconosHabito` de código a `LucideIcons`, con 27 entradas. El código
  es el nombre del icono en `LucideIcons` (`bookOpen`, `flower2`…). Ni el core
  (los hábitos son dominio de la app) ni el backend (que solo guarda el
  texto).
- **Una sola fuente.** `PlantillaHabito` guarda `codigoIcono` y `icono` es un
  getter que lo busca en el catálogo. `Habito` igual: `codigoIcono` (lo que
  manda el backend) y el getter `icono`. El formulario manda el `codigoIcono`
  de la idea al crear desde ella, y el que ya tenía el hábito al editar.
- **Búsqueda con funciones sueltas**, no una clase de métodos estáticos:
  `iconoDeHabito(codigo)` da el `IconData` y `nombreIconoHabito(l, codigo)`
  el nombre traducido para el lector de pantalla (claves `iconoHabito…` de
  los ARB, con un `switch` porque `AppLocalizations` no se puede indexar por
  texto). Es el mismo estilo que `duracionLegible` o `parMinutos`.
- **Por defecto, `sparkles`**: un código nulo o desconocido (de una versión
  más nueva) da `sparkles` y su nombre. Nunca falla.
- El icono no tiene color propio: usa los de la identidad.

## Alternativas descartadas

- **Guardar en la plantilla el código y el `IconData`**: se pueden
  desincronizar.
- **Deducir el código a partir del `IconData`**: frágil si dos códigos dan el
  mismo dibujo.
- **Catálogo en el core o en el backend**: el core no puede saber de hábitos;
  el backend no dibuja.

## Consecuencias

- Añadir un icono es: una línea en `iconosHabito`, su nombre en los tres ARB y
  un caso en `nombreIconoHabito`. Los tests fallan si falta el nombre (cae al
  de `sparkles`) o si una plantilla trae un código que no está en el
  catálogo.
- Un código no se renombra nunca: está guardado en el backend. Si
  `lucide_icons_flutter` renombra un icono, se cambia el `LucideIcons.*` de la
  derecha, no la clave.
- Un hábito nuevo desde cero se crea sin icono hasta que llegue la rejilla de
  elección (T-011c).

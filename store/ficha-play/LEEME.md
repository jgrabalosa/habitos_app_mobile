# Ficha de Google Play

La fuente única de los textos de la ficha es **este repo**, no Play Console.
Si un texto cambia, se cambia aquí y después se pega en Play Console; si se
toca en Play Console, se copia aquí.

| Fichero | Idioma en Play Console |
|---|---|
| `es.md` | Español (España), la ficha predeterminada |
| `en-US.md` | English (United States) |
| `pt-PT.md` | Português (Portugal) |

Cada fichero tiene los mismos tres títulos `##`: **Nombre** (30 caracteres
como mucho), **Descripción breve** (80) y **Descripción completa** (4000).
`test/ficha_play_test.dart` vigila los límites y que los tres ficheros
tengan los mismos campos. «Norday Habits» no se traduce; las identidades
(Profundidad, Neotokyo+, Dulce) tampoco.

## Pasarlos a Play Console

1. Play Console → la app → «Ficha de Play Store» → «Ficha principal de la
   tienda» → «Gestionar traducciones» → «Añadir idioma» (una vez por idioma).
2. En cada idioma, pegar el texto de cada campo: nombre, descripción breve y
   descripción completa (sin el título `##`).
3. Guardar y enviar el cambio a revisión.

Las capturas y los gráficos no están aquí: siguen siendo los de la ficha
predeterminada hasta que haya versiones por idioma.

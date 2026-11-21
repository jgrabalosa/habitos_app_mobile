# Lecciones aprendidas: método de trabajo (vale para los cinco repos)

Movidas tal cual del `CLAUDE.md` (subsección «Método de trabajo»). Las de Git
(paginador, `HEAD~1`, `git tag`, tag anotado) se quedan en el `CLAUDE.md`;
aquí están las demás. Errores que ya se cometieron una vez.

- **La primera línea de un prompt se comprueba, no se recuerda.** Son cinco
  repos: cuatro están en `C:\Dev\Norday\` (`habitos-app`,
  `habitos_app_mobile`, `norday_flutter_core` y `enfoque_app_mobile`) y
  `conocimiento_app_mobile` está en `C:\Dev\Conocimiento\`.
- **Un solo agente por repo a la vez.** Todo lo que haga otro agente se revisa
  en el remoto antes de mergear.
- **Las cifras de verificación se cuentan contra el repositorio**, nunca se
  copian del roadmap. Y son cifras exactas, no adjetivos.
- **Enumerar sin asumir el patrón**: buscar por la forma que ya has visto sólo
  encuentra lo que ya sabías.
- **Un filtro que no encuentra nada no es un resultado.** Ante una salida
  vacía, mirar la fuente completa antes de concluir.
- **Un fichero de diagnóstico no prueba nada por existir.** Abrirlo y
  comprobar que contiene el fallo antes de darlo por documentado.
- **La base de una rama `wip` envejece.** Antes de dar una cifra, comprobar de
  qué commit sale la rama.
- **Al sustituir un bloque, incluir el comentario de encima.** Si no, el
  comentario queda sobre otra declaración y describe algo que ya no es cierto.
- **No escribir en el código el término cuya ausencia se va a verificar.**
- **Mirar dónde se pega cada bloque.** Un bloque para la máquina local,
  lanzado en el VPS, llegó a `git push` y pidió credenciales.
- **PowerShell 5.1 lee los `.ps1` sin BOM como ANSI**: scripts sin acentos, o
  guardados con BOM.
- **`Set-Content` corrompió `login_screen.dart`** (219 secuencias dobles +
  BOM). Reparación con `[IO.File]::ReadAllBytes` / `WriteAllText` y
  `New-Object Text.UTF8Encoding $false`.

# Lo que esta app le enchufa al paquete

Movido tal cual del `CLAUDE.md` (sección «Lo que esta app le enchufa al
paquete»).

La app debe fijar `ApiServiceCore.appId = 'habitos'` antes de `runApp`.
El core no puede asumir el dominio de esta aplicación por defecto.

El paquete no puede importar de aquí, así que la app se conecta por estos
puntos:

1. **`destinoTrasLogin`** (función suelta en `home_shell.dart`) — se le pasa a
   `LoginScreen` y a `PerfilScreen`, que no pueden conocer `HomeShell`.
2. **`Catalogos.registrarEnElMotor()`** en `main()` — hace dos registros en
   el motor:
   - **`CatalogosCore.registrarLogrosDeDominio`**: los 38 logros de hábitos
     que traduce la app. El backend siembra 39 con `origenApp` de hábitos
     (`LogrosHabitosInitializer`); el que no está en la app es
     `PRIMEROS_PASOS`, que traduce el core. En el paquete sólo viven los que
     no saben de dominio (`BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`, los
     tres de identidad, los dos de la mascota e `INTERACCION_RESENA`,
     retirado).
   - **`CatalogosCore.registrarProductosDeDominio`**: la pausa
     (`PAUSA_HABITO`, de `ProductosHabitosInitializer` en el backend), con
     nombre, descripción y uso. Como se gasta desde el detalle de un hábito,
     Colección enseña el uso en vez del botón «Usar».
3. **`nordayNavigatorKey`** — `MaterialApp` usa el del paquete en vez de uno
   propio, porque `CelebracionService` lo necesita.
4. **`MascotaScreen.ayudaAnimo` y `ayudaXp`** — `HomeShell` le pasa dos
   `AyudaCampo` con los textos que explican el ánimo de Nori y de dónde sale
   la XP, que hablan de hábitos.
5. **`EleccionIdentidadScreen.alElegir`** — tras elegir la identidad gratis
   del onboarding, a `HomeShell`.
6. **El progreso del día** — `DashboardScreen` publica cuántos hay y cuántos
   hechos con `publicarProgresoDia`; `HomeShell` monta `FondoIdentidad` y
   `CapaProgresoIdentidad` (la constelación de Profundidad), y llama a
   `limpiarProgresoDia` al salir. **El letrero de Neotokyo+ y el ramo de
   Dulce** (D-41, core v0.59.0) van en la lista: `DashboardScreen` monta
   `FiguraDelDiaHoy` (`estados_hoy.dart`, con `LetreroDelDia` o
   `RamoDelDia` del core) arriba de la sección «Hoy», bajo su título y
   encima del primer hábito, siempre que se mira hoy y la sección no está
   plegada, haya pendientes o no; con el día cerrado se lee «¡Todo hecho!» con
   el nombre de la figura. `FinalDelDiaHoy` solo ocupa sitio en
   Profundidad.
7. **El cierre del día** — `HomeShell` monta `CapaCierreDelDia` y
   `DashboardScreen` llama a `mostrarCierreDelDia` al completar lo último del
   día. Sale una vez al día por usuario (fecha guardada en el dispositivo,
   `cierre_dia_fecha_<usuarioId>`) y nunca mientras la pista de Hoy está
   abierta.
   Las páginas y la barra van envueltas en `OcultoAlLectorDuranteCierre`
   (core v0.39.0) para que el lector de pantalla no llegue a lo de debajo
   durante la ceremonia.
8. **`SplashGenerico.rutaImagen`** — el símbolo de la brújula,
   `assets/branding/simbolo_negativo.png`.
9. **El grano de papel** — el `builder` del `MaterialApp` (en `main.dart`,
   `envolverConGrano`) pone `GranoPapel` (core v0.45.0) encima de todo;
   solo pinta en Dulce.
10. **Los textos de la app en pantallas del core** — `registrarTextosHabits()`
    (`l10n/textos_habits.dart`) en `main()`, antes de `runApp`, llama a
    `TextosApp.registrar` (core v0.55.0) con el nombre, el lema del login y
    los textos de actualización obligatoria y de borrado de cuenta, que viven
    en los `app_*.arb`. Sin eso el core dice «Norday» y frases neutras.
    `onGenerateTitle` usa `appNombre` de la app, no `appTitulo` del core.

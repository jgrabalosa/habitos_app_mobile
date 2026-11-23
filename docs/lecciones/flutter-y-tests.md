# Lecciones aprendidas: Flutter y tests

Movidas tal cual del `CLAUDE.md` (subsección «Flutter y tests» de «Lecciones
aprendidas»). Errores que ya se cometieron una vez. No se vuelven a cometer.
«Test en rojo antes del arreglo» sigue también en el `CLAUDE.md`, porque vale en
cada sesión.

- **En `flutter test` Firebase no está inicializado**: acceder a
  `FirebaseAnalytics.instance` lanza `[core/no-app]`. Sirve para probar que un
  servicio no deja escapar el fallo.
- **`MaterialApp` interpola el tema con `AnimatedTheme`** y `TextStyle.lerp` no
  mezcla familias: en tests que cambian de identidad, `pumpAndSettle`, no
  `pump`.
- **El ticker de una animación toma la hora de inicio en su primer tic**: en
  tests de duración, un `pump()` sin duración antes de medir.
- **`containsSemantics` está deprecado desde Flutter 3.40** en favor de
  `isSemantics`, que tiene los mismos parámetros y también sólo comprueba lo
  indicado.
- **Tras editar un ARB, `flutter analyze` no regenera las traducciones**:
  `flutter gen-l10n` antes.
- **`setCrashlyticsCollectionEnabled` vale para todas las builds.** Combinar
  con `kReleaseMode`, nunca pasar un flag «de debug» tal cual.
- **El analizador de Dart promociona a no nulo a través de un `bool`
  intermedio.** Si `final bool b = x != null && ...`, dentro de `if (b)` la
  variable `x` ya es no nula: añadir `&& x != null` ahí dispara
  `unnecessary_null_comparison`.
- **Test en rojo antes del arreglo.** Si el test nuevo pasa contra el código
  sin arreglar, no demuestra nada: parar.
- **Android 15 dibuja la app de borde a borde** (`targetSdk` 36): la barra de
  navegación del sistema va encima de lo que la pantalla no aparte. Una
  pantalla que se abre encima (con su `Scaffold`) aparta abajo con
  `SafeArea` o, si la lista debe pasar por detrás, sumando
  `MediaQuery.paddingOf(context).bottom` a su `padding`; las hojas, como
  `panel_minutos.dart`. «Empieza con una idea» se quedó sin ninguna de las
  dos (20-nov-2026). Se prueba con `tester.view.padding`
  (`ideas_habito_screen_test.dart`).
- **Una pantalla que crea más de un `AnimationController` en su vida usa
  `TickerProviderStateMixin`, no `SingleTickerProviderStateMixin`.** El
  segundo ticker lanza un `assert` que solo salta en depuración: Hoy lo tuvo
  desde el 15-sep y cortaba `_trasCompletar` en el segundo check (T-045,
  `test/hoy_varios_checks_test.dart`).
- **La caja de `NoriVestida` no es Nori** (deja aire, distinto en cada fase;
  T-034): su tamaño se mide en el PNG de `test/postal_exportar_test.dart`.

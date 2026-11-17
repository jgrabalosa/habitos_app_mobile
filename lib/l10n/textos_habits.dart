import 'package:norday_flutter_core/norday_flutter_core.dart';

import 'app_localizations.dart';

/// Le da al core los textos que dependen de qué app es: el nombre, el lema
/// del login, la explicación de la actualización obligatoria y lo que se
/// pierde al borrar la cuenta.
///
/// Desde el core 0.55.0 sus claves `appTitulo`, `loginTagline`,
/// `actualizacionTexto` y `perfilEliminarCuerpo` son neutras («Norday» y
/// frases sin dominio). Los textos de aquí son los que esas claves tenían en
/// la 0.54.0, así que para quien usa Norday Habits no cambia nada.
///
/// Se llama en `main()`, antes de `runApp`, igual que se fija
/// `ApiServiceCore.appId`.
void registrarTextosHabits() {
  TextosApp.registrar(
    nombre: (c) => AppLocalizations.of(c)!.appNombre,
    lemaLogin: (c) => AppLocalizations.of(c)!.loginLema,
    actualizacionObligatoria: (c) =>
        AppLocalizations.of(c)!.actualizacionObligatoriaTexto,
    eliminarCuenta: (c) => AppLocalizations.of(c)!.eliminarCuentaCuerpo,
  );
}

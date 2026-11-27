# Variantes: produccion y prueba

Movido tal cual del `CLAUDE.md`. El `CLAUDE.md` conserva un resumen con las
reglas de cada compilación (`--flavor`, `entorno.dart`, nunca instalar
`produccion` sobre la de Play, la de prueba nunca abre Play).

- **`--flavor` siempre.** `produccion` es la de Play (`com.norday.habitos`).
  `prueba` es `com.norday.habitos.prueba`, se llama «Habits PRUEBA» y va contra
  staging con `--dart-define=NORDAY_API_URL=https://staging-api.norday.app/api`.
  Los comandos están en el README.
- **`lib/entorno.dart` para la app al arrancar** si el flavor y la URL no
  cuadran: `prueba` contra producción, `produccion` contra otra cosa, o sin
  flavor. No se quita ni se salta.
- **La de prueba se ve: cinta «PRUEBA»** arriba a la derecha en todas las
  pantallas, también en el login (`conCintaDeEntorno` de `lib/entorno.dart`,
  en el `builder` del `MaterialApp`). Sin cinta, es la de producción. Se puso
  el 16-nov-2026: con varias apps de prueba y de Play instaladas, Quim entró
  con una cuenta sin saber si era staging o producción.
- **La de prueba nunca abre Google Play.** Si falta Focus PRUEBA,
  «Empezar sesión» avisa (`AperturaEnfoque.faltaPrueba`) en vez de ir a la
  ficha de Play, que lleva a la Focus de producción. Mismo 16-nov.
- **El nombre visible sale de `manifestPlaceholders["appLabel"]`** en
  `android/app/build.gradle.kts`, no del manifest.
- **`google-services.json` lleva las dos apps.** Google Sign-In de la de prueba
  tiene sus propios clientes OAuth Android en Google Cloud, con la huella de
  depuración y la de subida. La de producción, además, se instala desde Play
  firmada con la **clave de firma de apps de Play**, no con la de subida: la
  SHA-1 de esa clave (Play Console → Integridad de la app → Firma de apps)
  tiene que estar en Firebase y en un cliente OAuth Android de
  `com.norday.habitos`. Sin ella, Google Sign-In falla en la app instalada
  desde Play aunque funcione en una build local.
- **Nunca se instala `--flavor produccion` en un móvil con la app de Play**:
  mismo paquete, otra firma, y la salida sería desinstalar la de Play.

# habitos_app_mobile — Norday Habits

App Android de **Norday Habits**, la app de hábitos del ecosistema **Norday**.
Versión en desarrollo: 1.1.0 (5). La publicada hasta ahora es la 1.0.0 (3),
en prueba cerrada en Google Play (`com.norday.habitos`).

## Qué hace

- **Hoy**: los hábitos del día, con un toque para completarlos, la semana en
  una tira y el progreso del día dibujado en el fondo de la identidad.
- **Hábitos** diarios o semanales, con meta de veces, días concretos,
  categoría, descripción y recordatorio a una hora. Siete plantillas para
  empezar (beber agua, leer 20 minutos, ejercicio, meditar, dormir 8 horas,
  caminar, escribir diario).
- **Detalle** de cada hábito con su historial, ritmo y notas.
- **Ritmo, puntos y logros**: cada hábito tiene un ritmo que sube al cumplirlo
  y baja despacio al fallar, y los hábitos se pueden pausar. Alcanzar la meta
  de un hábito suma puntos, y los puntos se gastan en la tienda.
- **Nori**, una mascota que se alimenta gastando puntos, crece con la
  constancia y evoluciona de huevo a cría y a adulto.
- **Tres identidades visuales** — Profundidad, Neotokyo+ y Dulce — que
  cambian colores, tipografía, formas y fondo de toda la app. La primera se
  elige gratis al empezar; las demás, en la tienda.
- **Cierre del día**: al completar lo último del día, en Profundidad se
  ilumina la constelación y en Dulce se completa el ramo; en Neotokyo+ termina
  en el acto.
- **Primer hábito** guiado: una bienvenida de una tarjeta lleva al formulario
  real, pide el permiso de notificaciones al elegir la hora de un recordatorio
  y, al guardarlo, Hoy señala su círculo una vez.
- En **español, inglés y portugués**, con zona horaria propia.
- Registro con email o con Google.

Pestañas: Hoy, Mascota y Hábitos, más un menú con Colección, Logros, Tienda
y Perfil.

## Stack

Flutter 3.44.4 (Dart 3.12) · Android · Firebase (Crashlytics, Analytics y
notificaciones) · Lucide Icons. El backend es
[`habitos-app`](https://github.com/jgrabalosa/habitos-app).

Todo lo genérico (sesión, tienda, mascota, logros, identidades, perfil) vive
en el paquete [`norday_flutter_core`](https://github.com/jgrabalosa/norday_flutter_core),
que esta app consume por tag. Aquí sólo vive lo que sabe de hábitos.

## Compilar

Hace falta, fuera de Git:

- `android/app/google-services.json` (Firebase), con las dos apps del
  proyecto `habitos-app-5a054`: `com.norday.habitos` y
  `com.norday.habitos.prueba`.
- `android/key.properties` y el keystore, sólo para builds de release.

Hay dos variantes (flavors), y **siempre se indica una** con `--flavor`:

| Flavor | Paquete | Nombre | Backend |
|---|---|---|---|
| `produccion` | `com.norday.habitos` | Norday Habits | Producción (por defecto) |
| `prueba` | `com.norday.habitos.prueba` | Norday PRUEBA | Staging, con `--dart-define` |

Al arrancar, la app comprueba que el flavor y la URL del backend van juntos
(`lib/entorno.dart`). Si no cuadran, se para en «Entorno incorrecto» sin hacer
ninguna petición.

App de prueba contra staging. Se instala junto a la de Play, sin sustituirla:

```powershell
flutter pub get
flutter run --flavor prueba --dart-define=NORDAY_API_URL=https://staging-api.norday.app/api
```

Para dejarla instalada y usarla sin cable:

```powershell
flutter build apk --debug --flavor prueba --dart-define=NORDAY_API_URL=https://staging-api.norday.app/api
adb install -r build\app\outputs\flutter-apk\app-prueba-debug.apk
```

**Nunca se instala `--flavor produccion` en un móvil que tenga la app de
Play.** Es el mismo paquete con otra firma: la instalación falla, y la única
salida sería desinstalar la de Play.

Los `app_localizations*.dart` se generan al compilar y no se versionan.

## Build de release para Google Play

Se compila siempre desde un `main` limpio e igual al remoto. En PowerShell,
desde la raíz del repo:

```powershell
git status --short                      # vacío, y sin pubspec_overrides.yaml
git fetch origin
git log -1 --format="%h %s"             # el mismo commit que origin/main
Select-String -Path pubspec.yaml -Pattern "^version:","ref: v0"
Select-String -Path pubspec.lock -Pattern "resolved-ref"
Select-String -Path android/app/build.gradle.kts -Pattern "appLabel"
```

Antes de seguir, comprobar:

- **`version:`** lleva un versionCode (el número tras el `+`) que no se haya
  subido nunca a Play. Un versionCode no se reutiliza jamás, ni aunque la
  versión anterior se descartara.
- **`ref:`** del core apunta a un tag, y `resolved-ref` es el commit de ese
  tag. Se busca sólo el hash, sin prefijo.
- **`appLabel`** del flavor `produccion` es «Norday Habits».

Después:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --flavor produccion
Get-Item build\app\outputs\bundle\produccionRelease\app-produccion-release.aab | Select-Object Name, Length, LastWriteTime
keytool -printcert -jarfile build\app\outputs\bundle\produccionRelease\app-produccion-release.aab | Select-String "SHA1"
```

La huella tiene que ser la de la **clave de subida**, la del keystore que
indica `android/key.properties`. Sin ese fichero la build de release falla.

En Play Console: Probar y publicar → Pruebas → canal → Crear nueva versión →
subir el `.aab` → comprobar el número de versión → notas con las etiquetas
`<es-ES>`, `<en-US>` y `<pt-PT>` → Siguiente → **Guardar, no enviar**. Los
cambios de ficha se hacen entonces, y todo se manda junto desde Resumen de
publicación. Mientras hay una revisión en curso no se toca nada.

## Documentación

- [`CLAUDE.md`](CLAUDE.md) — arquitectura, reglas obligatorias y lecciones aprendidas.
- `store/` — icono, icono adaptativo, banner, gráfico de funciones, logo
  horizontal y símbolos de la ficha de Play.

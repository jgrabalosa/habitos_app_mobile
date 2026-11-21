# Lecciones aprendidas: paquetes y dispositivo

Movidas tal cual del `CLAUDE.md` (subsecciones «Paquetes» y «Dispositivo» de
«Lecciones aprendidas»). Errores que ya se cometieron una vez. No se vuelven a
cometer.

## Paquetes

- **`flutter pub outdated` no lista los paquetes que ya están en su última
  versión.** Las versiones resueltas se comprueban en `pubspec.lock`.
- **Una versión resuelta no se da por supuesta.** `permission_handler ^12.0.3`
  resolvió `permission_handler_android` 13.0.1, no la última 13.x.
- **Los changelogs se leen de la caché de pub**, no de la web:
  `dart pub cache add <paquete> --version <v>` sin tocar el proyecto. Las notas
  publicadas en la web estaban incompletas o se contradecían.
- **Una subida de mayor puede exigir más de lo que dice su nombre.**
  `permission_handler` 13 pide `compileSdk` 37 y Flutter 3.44.4 usa 36
  (`FlutterExtension.kt`). `flutter_secure_storage` 11.0.0 también lo pedía;
  11.1.0 vuelve a `flutter.compileSdkVersion`.
- **`flutter_secure_storage` 9→11 sin pasar por la 10**: lo guardado con la 9
  queda ilegible. Con `resetOnError` y el `catch` de `getToken`, el arranque ve
  `null` y manda al login: iniciar sesión una vez.

## Dispositivo

- **`adb shell pm revoke` falla en algunos fabricantes** con
  `SecurityException` (falta `REVOKE_RUNTIME_PERMISSIONS`). Para probar
  diálogos de permiso hace falta instalación limpia.
- **Google Sign-In en debug necesita la huella de depuración de esa
  máquina**: su SHA-1 en Firebase y un cliente OAuth Android propio en Google
  Cloud (Firebase sola no basta). Cada máquina tiene su clave de depuración,
  así que cada una necesita su cliente. Sin eso, se prueba con APK de release.

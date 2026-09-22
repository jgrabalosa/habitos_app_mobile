# habitos_app_mobile — Norday Habits

App Android de **Norday Habits**, la app de hábitos del ecosistema **Norday**.
En septiembre de 2026 está en prueba cerrada en Google Play
(`com.norday.habitos`).

## Qué hace

- **Hoy**: los hábitos del día, con un toque para completarlos, la semana en
  una tira y el progreso del día dibujado en el fondo de la identidad.
- **Hábitos** diarios o semanales, con meta de veces, días concretos,
  categoría, descripción y recordatorio a una hora. Cinco plantillas para
  empezar (beber agua, ejercicio, meditar, caminar, escribir diario).
- **Detalle** de cada hábito con su historial, racha y notas.
- **Rachas, puntos y logros**: alcanzar la meta de un hábito suma puntos, y los
  puntos se gastan en la tienda.
- **Nori**, una mascota que se alimenta gastando puntos, crece con la
  constancia y evoluciona de huevo a cría y a adulto.
- **Tres identidades visuales** — Profundidad, Neotokyo+ y Dulce — que
  cambian colores, tipografía, formas y fondo de toda la app. La primera se
  elige gratis al empezar; las demás, en la tienda.
- **Cierre del día** en Profundidad: al completar lo último del día, la
  constelación del día se ilumina.
- **Recorrido guiado** la primera vez, repetible desde el menú.
- En **español, inglés y portugués**, con zona horaria propia.
- Registro con email o con Google.

Pestañas: Hoy, Mascota y Hábitos, más un menú con Colección, Logros, Tienda,
el recorrido y Perfil.

## Stack

Flutter 3.44.4 (Dart 3.12) · Android · Firebase (Crashlytics, Analytics y
notificaciones) · Lucide Icons. El backend es
[`habitos-app`](https://github.com/jgrabalosa/habitos-app).

Todo lo genérico (sesión, tienda, mascota, logros, identidades, perfil) vive
en el paquete [`norday_flutter_core`](https://github.com/jgrabalosa/norday_flutter_core),
que esta app consume por tag. Aquí sólo vive lo que sabe de hábitos.

## Compilar

Hace falta, fuera de Git:

- `android/app/google-services.json` (Firebase).
- `android/key.properties` y el keystore, sólo para builds de release.

```bash
flutter pub get
flutter run
```

Los `app_localizations*.dart` se generan al compilar y no se versionan.

## Documentación

- [`CLAUDE.md`](CLAUDE.md) — arquitectura, reglas obligatorias y lecciones aprendidas.
- `store/` — icono, icono adaptativo, banner, gráfico de funciones, logo
  horizontal y símbolos de la ficha de Play.

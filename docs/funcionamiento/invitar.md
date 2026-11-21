# Invitar a un amigo

`lib/screens/invitar_screen.dart`. Se abre desde el menú de `HomeShell`.
Por qué es así: [0001](../decisiones/0001-postal-invitacion.md).

## Qué hace

1. Al abrir, mide `invitar_abierto` y pide la mascota (`getMascota`): fase,
   nombre y nivel (`DatoNori`). Mientras llega, la postal sale sin Nori y
   «Compartir» espera.
2. Pinta la postal (`TarjetaInvitacion`, 360 × 450 puntos) escalada a la
   pantalla. Con nivel, lleva el dato arriba y, debajo de la postal, el
   interruptor «Incluir el nombre y el nivel de Nori», encendido.
3. «Compartir» captura la postal a 1080 × 1350 px y la manda, con el texto
   (el enlace `https://norday.app/invitar` en su última línea), al menú
   nativo de `share_plus`.
4. Mide `invitar_compartido` con `resultado` (`compartido`, `cancelado` o
   `no_disponible`) y `con_dato` (`true` o `false`).

## Casos

- **Sin red o con error**: Nori adulta, sin dato y sin interruptor. Se
  comparte igual, con `con_dato` a `false`.
- **Sin nombre**: «Mi Nori ya es cría · nivel 7».
- **Sin nivel**: como sin red, pero en la fase que llegó.
- **Interruptor apagado**: la postal sale sin la línea del dato. Nori sigue
  en su fase y vestida.
- **Prendas**: `NoriVestida` con `prendasEquipadasNotifier`. Sin el arte
  descargado, Nori sale sin prendas, como en el resto de la app.

## Ver la postal sin móvil

```
flutter test test/postal_exportar_test.dart --dart-define=EXPORTAR_POSTAL=true
```

Deja en `build/postal/` las tres identidades con y sin dato, y el huevo y
la adulta en Profundidad. Sin la variable, esos tests se omiten.

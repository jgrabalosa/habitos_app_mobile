# Identidad equipada

Movido tal cual del `CLAUDE.md`.

La fuente de verdad es el backend, no el dispositivo: `Equipamiento`
(en el paquete) lee `getInventarioProductos()` y casa el `codigo` del
producto contra `catalogoIdentidades`. Solo se guarda en el dispositivo, por
usuario, la última identidad que confirmó el backend, para aplicarla si falla
la red al arrancar (ver el `CLAUDE.md` del paquete).

Los avatares están retirados desde el 15-sep-2026: la app no los usa y el
avatar del usuario es Nori.

No se puede cargar en `main()`: antes del login no hay ni `usuarioId` ni
token. Va tras el login y en el splash cuando ya hay sesión guardada, así
que hasta que responde se ve el tema por defecto.

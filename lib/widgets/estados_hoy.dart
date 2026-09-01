import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import 'identidad_ui.dart';

/// Los cuatro momentos en que la pantalla Hoy no es una lista de hábitos:
/// cargando, sin ninguno creado, sin poder cargarlos, y con todos hechos.
///
/// Los tres primeros informan; el cuarto celebra, y por eso es el único con
/// vida propia. Todos hablan la lengua de la identidad equipada, igual que las
/// tarjetas: si el estado vacío fuera genérico, sería lo primero que ve un
/// usuario nuevo y lo único de la app sin identidad.

/// Silueta de carga. Reutiliza el pulso y los bloques del paquete —el patrón
/// de skeleton ya existía— pero con la forma real de una fila de Hoy: nombre,
/// chip, heatmap y check. `SkeletonLista` pinta una tarjeta genérica de dos
/// líneas, que no se parece a esto y hace que el contenido "salte" al llegar.
class SkeletonHoy extends StatelessWidget {
  final int cantidad;
  final EdgeInsetsGeometry padding;

  const SkeletonHoy({
    super.key,
    this.cantidad = 3,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: l.a11yCargando,
      child: ExcludeSemantics(
        child: SkeletonPulso(
          child: ListView(
            padding: padding,
            children: [
              // La cabecera: título, fecha y el aro del resumen.
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 22),
                        SizedBox(height: 8),
                        SkeletonBox(width: 180, height: 12),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 64, height: 64, radius: 32),
                ],
              ),
              const SizedBox(height: 24),
              ...List.generate(cantidad, (_) => const _FilaSkeleton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaSkeleton extends StatelessWidget {
  const _FilaSkeleton();

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        // Aunque no haya nada dentro, la silueta ya tiene la forma de la
        // identidad: el salto entre carga y contenido es sólo de contenido.
        shape: formaIdentidad(id, radio: id.radioSecundario),
        color: id.forma == FormaIdentidad.hairline ? null : t.surface,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 130, height: 15),
                    SizedBox(width: 8),
                    SkeletonBox(width: 62, height: 15, radius: 999),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonBox(height: 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBox(
            width: 44,
            height: 44,
            radius: id.forma == FormaIdentidad.chamfer ? 2 : 22,
          ),
        ],
      ),
    );
  }
}

/// Sin ningún hábito creado todavía. Lo primero que ve un usuario nuevo.
class EstadoVacioHoy extends StatelessWidget {
  const EstadoVacioHoy({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);

    return _PanelEstado(
      icono: LucideIcons.sprout,
      colorIcono: t.success,
      titulo: l.dashVacioTitulo,
      cuerpo: l.dashVacioCuerpo,
    );
  }
}

/// No se han podido cargar. Antes esto era un SnackBar y una lista vacía, que
/// se lee exactamente igual que "no tienes hábitos": el usuario no podía
/// distinguir un fallo de red de una cuenta recién creada.
class EstadoErrorHoy extends StatelessWidget {
  final VoidCallback onReintentar;

  const EstadoErrorHoy({super.key, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);

    return _PanelEstado(
      icono: LucideIcons.cloudOff,
      colorIcono: t.textMuted,
      titulo: l.dashErrorTitulo,
      cuerpo: l.dashErrorCuerpo,
      accion: OutlinedButton.icon(
        onPressed: onReintentar,
        icon: const Icon(LucideIcons.rotateCw, size: 18),
        label: Text(l.dashReintentar),
      ),
    );
  }
}

/// Panel común de los dos estados que sólo informan. Mismo esqueleto, misma
/// superficie que una tarjeta de hábito: son parte de la misma lista.
class _PanelEstado extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String cuerpo;
  final Widget? accion;

  const _PanelEstado({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.cuerpo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icono, size: 44, color: colorIcono),
            const SizedBox(height: 14),
            Text(titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: t.text)),
            const SizedBox(height: 6),
            Text(cuerpo,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: t.textMuted)),
            if (accion != null) ...[
              const SizedBox(height: 16),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Todos los hábitos del día, hechos.
///
/// Es el único de los cuatro que celebra, así que es el único con movimiento:
/// detrás del icono va el [HaloIdentidad] del paquete —el mismo de la
/// mascota, más pequeño y más flojo—, que late al ritmo de la identidad y ya
/// respeta "reducir movimiento" por su cuenta. No hace falta nada más: la
/// celebración gorda es la de subir de nivel, ésta se ve todos los días y
/// tiene que poder verse todos los días sin cansar.
class TarjetaTodoHecho extends StatelessWidget {
  const TarjetaTodoHecho({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final id = identidad(context);
    final t = tokens(context);

    // El icono del remate cambia con la identidad, no sólo su color: es el
    // único adorno de la tarjeta y decir "hecho" no se parece en las cuatro.
    final icono = switch (id.forma) {
      FormaIdentidad.glass => LucideIcons.circleCheckBig,
      FormaIdentidad.chamfer => LucideIcons.zap,
      FormaIdentidad.hairline => LucideIcons.sun,
      FormaIdentidad.pill => LucideIcons.heart,
    };

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                // El halo pinta algo más ancho que su caja a propósito.
                clipBehavior: Clip.none,
                children: [
                  const HaloIdentidad(tamano: 72, intensidad: 0.85),
                  Icon(icono, size: 36, color: t.success),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(l.dashTodoHecho,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: t.text)),
            const SizedBox(height: 4),
            Text(l.dashDisfruta,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

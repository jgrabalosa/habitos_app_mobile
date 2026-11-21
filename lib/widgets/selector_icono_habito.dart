import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../models/iconos_habito.dart';

/// La fila «Icono» del formulario: el dibujo elegido, su nombre y un chevron.
/// Al tocarla se abre la rejilla con los iconos del catálogo.
class FilaIconoHabito extends StatelessWidget {
  /// El código elegido; null (o desconocido) se enseña como el de por defecto.
  final String? codigo;
  final ValueChanged<String> alElegir;

  const FilaIconoHabito({
    super.key,
    required this.codigo,
    required this.alElegir,
  });

  Future<void> _abrir(BuildContext context) async {
    final elegido = await mostrarRejillaIconos(context, codigo: codigo);
    if (elegido != null) alElegir(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final nombre = nombreIconoHabito(l, codigo);
    return Semantics(
      button: true,
      label: '${l.habLabelIcono}: $nombre',
      excludeSemantics: true,
      onTap: () => _abrir(context),
      child: InkWell(
        onTap: () => _abrir(context),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text(l.habLabelIcono, style: texto.titleMedium),
              const Spacer(),
              Icon(iconoDeHabito(codigo), size: 24, color: t.text),
              const SizedBox(width: AppSpacing.sm),
              Text(
                nombre,
                style: texto.bodyMedium?.copyWith(color: t.textMuted),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(LucideIcons.chevronRight, size: 20, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre la rejilla y devuelve el código elegido, o null si se cierra sin
/// elegir.
Future<String?> mostrarRejillaIconos(
  BuildContext context, {
  required String? codigo,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RejillaIconos(codigo: codigo),
  );
}

class _RejillaIconos extends StatelessWidget {
  final String? codigo;
  const _RejillaIconos({required this.codigo});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final seleccionado = iconosHabito.containsKey(codigo)
        ? codigo!
        : codigoIconoPorDefecto;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.habLabelIcono,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.ms),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in iconosHabito.entries)
                  _CeldaIcono(
                    codigo: e.key,
                    icono: e.value,
                    elegido: e.key == seleccionado,
                    nombre: nombreIconoHabito(l, e.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Una celda de 48 × 48, con la forma de la identidad: pastilla redondeada en
/// Profundidad, esquina cortada con filo en Neotokyo+ y lápiz con rayas en
/// Dulce. La elegida lleva el color primario y su dibujo en tinta.
class _CeldaIcono extends StatelessWidget {
  final String codigo;
  final IconData icono;
  final bool elegido;
  final String nombre;

  const _CeldaIcono({
    required this.codigo,
    required this.icono,
    required this.elegido,
    required this.nombre,
  });

  ShapeBorder _forma(IdentidadPaleta id, TokensContextuales t) {
    // Sin token de borde en el core: el filo de lo no elegido es el texto
    // secundario, muy suave.
    final suave = t.textMuted.withValues(alpha: 0.35);
    return switch (id.forma) {
      FormaIdentidad.glass => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(id.radioSecundario),
        side: elegido
            ? BorderSide(color: t.primaryTrazo, width: 2)
            : BorderSide.none,
      ),
      FormaIdentidad.chamfer => BordeChaflan(
        chaflan: id.chaflan,
        side: BorderSide(color: elegido ? t.primary : suave, width: 1),
      ),
      FormaIdentidad.pill => BordeLapiz(
        radio: id.radioSecundario,
        side: BorderSide(color: elegido ? t.primaryTrazo : suave, width: 1.3),
        rayas: elegido ? t.primary : null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final id = identidad(context);
    // En Dulce el relleno son las rayas del lápiz, no un color liso.
    final lleno = elegido && id.forma != FormaIdentidad.pill;
    return Semantics(
      button: true,
      selected: elegido,
      label: nombre,
      excludeSemantics: true,
      onTap: () => Navigator.pop(context, codigo),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: _forma(id, t),
          onTap: () => Navigator.pop(context, codigo),
          child: Ink(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: lleno ? t.primary : t.surface2,
              shape: _forma(id, t),
            ),
            child: Icon(
              icono,
              size: 24,
              color: lleno ? t.tinta : (elegido ? t.text : t.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

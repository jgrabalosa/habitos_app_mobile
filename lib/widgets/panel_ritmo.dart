import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../models/habito.dart';
import '../models/hoy.dart';

/// La palabra del nivel de un ritmo, del 1 al 5.
String palabraRitmo(AppLocalizations l, int nivel) => switch (nivel) {
  <= 1 => l.ritmoNivel1,
  2 => l.ritmoNivel2,
  3 => l.ritmoNivel3,
  4 => l.ritmoNivel4,
  _ => l.ritmoNivel5,
};

/// La línea de la causa, según hacia dónde va el ritmo respecto a hace siete
/// días. El fallo no se nombra: si baja, se dice el siguiente paso.
String? causaRitmo(AppLocalizations l, TendenciaRitmo? tendencia) =>
    switch (tendencia) {
      TendenciaRitmo.sube => l.ritmoSube,
      TendenciaRitmo.igual => l.ritmoIgual,
      TendenciaRitmo.baja => l.ritmoBaja,
      null => null,
    };

/// El panel «Tu ritmo», que sube desde abajo sin salir de Hoy: la palabra, el
/// dibujo, la causa, qué es el ritmo y de dónde sale, hábito por hábito.
///
/// Sale de la misma respuesta de `/hoy` que la pantalla. La lista va en el
/// orden de Hoy, no de más a menos ritmo, para no clasificar los hábitos, y
/// sin números. Devuelve el hábito que se toca, para que quien lo abre lleve
/// a su detalle, o null si se cierra sin tocar ninguno.
Future<Habito?> mostrarPanelRitmo(BuildContext context, HoyLeido hoy) {
  final t = tokens(context);
  final id = identidad(context);
  return showModalBottomSheet<Habito>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: t.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(id.radioHero)),
    ),
    builder: (context) => _PanelRitmo(hoy: hoy),
  );
}

class _PanelRitmo extends StatelessWidget {
  final HoyLeido hoy;

  const _PanelRitmo({required this.hoy});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final nivel = hoy.ritmoNivel ?? 1;
    final palabra = palabraRitmo(l, nivel);
    final causa = causaRitmo(l, hoy.ritmoTendencia);
    final filas = [...hoy.delDia.habitos, ...hoy.deLaSemana.habitos];
    final estiloEtiqueta = texto.labelSmall?.copyWith(
      color: t.textMuted,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El asa: dice que esto se arrastra hacia abajo para cerrarlo.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.inactivo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: l.a11yRitmoGeneral(palabra, nivel),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        palabra,
                        style: texto.headlineSmall?.copyWith(
                          color: t.points,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IndicadorNivel(nivel: nivel, tamano: 20),
                  ],
                ),
              ),
            ),
            if (causa != null) ...[
              const SizedBox(height: 8),
              Text(causa, style: texto.bodyMedium?.copyWith(color: t.text)),
            ],
            const SizedBox(height: 12),
            Text(
              l.ritmoExplicacion,
              style: texto.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 20),
            Text(l.ritmoDeDondeSale, style: estiloEtiqueta),
            const SizedBox(height: 4),
            for (final f in filas) _FilaPanel(fila: f),
          ],
        ),
      ),
    );
  }
}

/// Un hábito en la lista del panel: su nombre, su palabra y su dibujo. Se
/// toca para ir a su detalle.
class _FilaPanel extends StatelessWidget {
  final FilaHoy fila;

  const _FilaPanel({required this.fila});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final palabra = palabraRitmo(l, fila.ritmoNivel);

    return Semantics(
      button: true,
      label: l.a11yRitmoHabitoDetalle(
        fila.habito.nombre,
        palabra,
        fila.ritmoNivel,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(fila.habito),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fila.habito.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texto.titleSmall?.copyWith(color: t.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palabra,
                      style: texto.bodySmall?.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IndicadorNivel(nivel: fila.ritmoNivel, tamano: 11),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: t.primaryTrazo),
            ],
          ),
        ),
      ),
    );
  }
}

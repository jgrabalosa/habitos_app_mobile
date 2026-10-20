import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../models/plantilla_habito.dart';
import '../widgets/identidad_ui.dart';
import 'habito_screen.dart';

/// Abre el alta de un hábito. Si hay ideas disponibles, primero la lista de
/// ideas; si no queda ninguna, el formulario vacío directamente.
///
/// Devuelve true si se guardó un hábito. «Atrás» sin guardar devuelve null.
Future<bool?> abrirAltaHabito(
  BuildContext context, {
  required int usuarioId,
  List<dynamic>? categoriasIniciales,
  List<String> nombresHabitosExistentes = const [],
  bool esPrimerHabito = false,
}) {
  final hayIdeas = plantillasDisponibles(nombresHabitosExistentes).isNotEmpty;
  final pantalla = hayIdeas
      ? IdeasHabitoScreen(
          usuarioId: usuarioId,
          categoriasIniciales: categoriasIniciales,
          nombresHabitosExistentes: nombresHabitosExistentes,
          esPrimerHabito: esPrimerHabito,
        )
      : HabitoScreen(
          usuarioId: usuarioId,
          categoriasIniciales: categoriasIniciales,
        );
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => pantalla),
  );
}

/// «Empieza con una idea»: una fila por plantilla disponible y, arriba del
/// todo, la de crear un hábito desde cero. Tocar una idea abre el formulario
/// relleno; si se guarda, esta lista se cierra con el mismo resultado.
class IdeasHabitoScreen extends StatelessWidget {
  final int usuarioId;
  final List<dynamic>? categoriasIniciales;
  final List<String> nombresHabitosExistentes;

  /// El primer hábito del onboarding: se avisa de que es solo una sugerencia.
  final bool esPrimerHabito;

  const IdeasHabitoScreen({
    super.key,
    required this.usuarioId,
    this.categoriasIniciales,
    this.nombresHabitosExistentes = const [],
    this.esPrimerHabito = false,
  });

  Future<void> _abrirFormulario(
    BuildContext context,
    PlantillaHabito? p,
  ) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitoScreen(
          usuarioId: usuarioId,
          categoriasIniciales: categoriasIniciales,
          plantilla: p,
        ),
      ),
    );
    if (guardado == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final disponibles = plantillasDisponibles(nombresHabitosExistentes);

    return Scaffold(
      appBar: AppBar(title: Text(l.habTituloNuevo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.ideasTitulo,
            style: texto.headlineSmall?.copyWith(color: t.text),
          ),
          if (esPrimerHabito) ...[
            const SizedBox(height: 8),
            Text(
              l.ideasSugerencia,
              style: texto.bodyMedium?.copyWith(color: t.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          _FilaDesdeCero(onTap: () => _abrirFormulario(context, null)),
          const SizedBox(height: 12),
          for (final p in disponibles) ...[
            _FilaIdea(
              key: ValueKey('idea_${p.id}'),
              plantilla: p,
              onTap: () => _abrirFormulario(context, p),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// La primera fila: un hábito en blanco. Va con borde discontinuo y sin
/// relleno, para que se note que no es una idea.
class _FilaDesdeCero extends StatelessWidget {
  final VoidCallback onTap;

  const _FilaDesdeCero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final id = identidad(context);
    final t = tokens(context);
    final forma = formaIdentidad(id, radio: id.radioSecundario);
    final texto = Theme.of(context).textTheme;

    return CustomPaint(
      painter: _BordeDiscontinuo(forma: forma, color: t.primaryTrazo),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: forma,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.plus, color: t.primaryTrazo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.ideasDesdeCero,
                    style: texto.titleMedium?.copyWith(color: t.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una idea: icono, nombre y debajo qué es (cada cuánto y cuántas veces).
class _FilaIdea extends StatelessWidget {
  final PlantillaHabito plantilla;
  final VoidCallback onTap;

  const _FilaIdea({super.key, required this.plantilla, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final nombre = nombrePlantilla(l, plantilla.id);
    final descripcion = descripcionPlantilla(l, plantilla);

    return Semantics(
      button: true,
      label: '$nombre. $descripcion',
      excludeSemantics: true,
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(plantilla.icono, color: t.primaryTrazo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: texto.titleMedium?.copyWith(color: t.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: texto.bodySmall?.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El contorno de una forma recorrido a trozos. Toma la forma de la identidad,
/// así que el discontinuo sigue el chaflán, la píldora o el cristal que toque.
class _BordeDiscontinuo extends CustomPainter {
  final ShapeBorder forma;
  final Color color;

  const _BordeDiscontinuo({required this.forma, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final contorno = forma.getOuterPath(Offset.zero & size);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    const trazo = 6.0;
    const hueco = 4.0;
    for (final metrica in contorno.computeMetrics()) {
      var inicio = 0.0;
      while (inicio < metrica.length) {
        final fin = math.min(inicio + trazo, metrica.length);
        canvas.drawPath(metrica.extractPath(inicio, fin), pincel);
        inicio += trazo + hueco;
      }
    }
  }

  @override
  bool shouldRepaint(_BordeDiscontinuo anterior) =>
      anterior.forma != forma || anterior.color != color;
}

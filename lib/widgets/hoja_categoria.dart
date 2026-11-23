import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';

/// Los emojis que se ofrecen para una categoría propia, en el orden de la
/// rejilla. Más «sin emoji», que no es uno de ellos.
const List<String> emojisCategoria = [
  '🏠',
  '🎯',
  '⭐',
  '🌱',
  '🔥',
  '💧',
  '🎵',
  '📖',
  '🧹',
  '🐾',
  '👪',
  '✈️',
  '🛠️',
  '🙏',
  '🎮',
  '🌍',
];

const int nombreCategoriaMinimo = 2;
const int nombreCategoriaMaximo = 30;

/// Si [nombre], ya recortado, tiene una longitud que el servidor admite.
/// Se cuenta en code points (`runes`), como el servidor: `length` cuenta
/// unidades UTF-16 y un emoji como «👪» mide 2.
bool nombreCategoriaValido(String nombre) {
  final largo = nombre.runes.length;
  return largo >= nombreCategoriaMinimo && largo <= nombreCategoriaMaximo;
}

/// Abre la hoja para crear una categoría propia o, con [categoria], para
/// cambiarle el nombre y el emoji.
///
/// [guardar] hace la llamada a la red (recibe el nombre ya recortado y el
/// emoji, o null) y devuelve la categoría que manda el servidor. Si lanza, la
/// hoja se queda abierta y dice por qué debajo del campo: con el texto del
/// servidor en un 409, con uno genérico en lo demás. Devuelve la categoría
/// guardada, o null si se cierra sin guardar.
Future<Map<String, dynamic>?> mostrarHojaCategoria(
  BuildContext context, {
  Map<String, dynamic>? categoria,
  required Future<Map<String, dynamic>> Function(String nombre, String? icono)
  guardar,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaCategoria(categoria: categoria, guardar: guardar),
  );
}

class _HojaCategoria extends StatefulWidget {
  final Map<String, dynamic>? categoria;
  final Future<Map<String, dynamic>> Function(String nombre, String? icono)
  guardar;

  const _HojaCategoria({required this.categoria, required this.guardar});

  @override
  State<_HojaCategoria> createState() => _HojaCategoriaState();
}

class _HojaCategoriaState extends State<_HojaCategoria> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.categoria?['nombre'] as String? ?? '',
  );
  late String? _icono = (widget.categoria?['icono'] as String?)?.trim();
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final l = AppLocalizations.of(context)!;
    final nombre = _nombre.text.trim();
    if (!nombreCategoriaValido(nombre)) {
      setState(() => _error = l.catNombreLongitud);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final guardada = await widget.guardar(
        nombre,
        (_icono ?? '').isEmpty ? null : _icono,
      );
      if (mounted) Navigator.pop(context, guardada);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = ApiServiceHabitos.mensajeDelServidor(e) ?? l.catErrorGuardar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final sinEmoji = (_icono ?? '').isEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        // Con el teclado abierto, la hoja sube y se puede seguir desplazando.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoria == null ? l.catNuevaEtiqueta : l.catCambiar,
              style: texto.titleMedium,
            ),
            const SizedBox(height: AppSpacing.ms),
            TextField(
              controller: _nombre,
              autofocus: true,
              maxLength: nombreCategoriaMaximo,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l.catLabelNombre,
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.catLabelEmoji, style: texto.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _CeldaEmoji(
                  etiqueta: l.catSinEmoji,
                  elegido: sinEmoji,
                  alTocar: () => setState(() => _icono = null),
                  hijo: Icon(
                    LucideIcons.ban,
                    size: 24,
                    color: sinEmoji ? t.text : t.textMuted,
                  ),
                ),
                for (final e in emojisCategoria)
                  _CeldaEmoji(
                    etiqueta: e,
                    elegido: _icono == e,
                    alTocar: () => setState(() => _icono = e),
                    hijo: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  child: Text(l.cancelar),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.tinta,
                          ),
                        )
                      : Text(l.catGuardar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Una celda de 48 × 48 con la forma de la identidad: pastilla redondeada en
/// Profundidad, esquina cortada con filo en Neotokyo+ y lápiz con rayas en
/// Dulce. La elegida lleva el color primario (en Dulce, las rayas).
class _CeldaEmoji extends StatelessWidget {
  final String etiqueta;
  final bool elegido;
  final VoidCallback alTocar;
  final Widget hijo;

  const _CeldaEmoji({
    required this.etiqueta,
    required this.elegido,
    required this.alTocar,
    required this.hijo,
  });

  ShapeBorder _forma(IdentidadPaleta id, TokensContextuales t) {
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
    // En Dulce el relleno son las rayas del lápiz, no un color liso. Un emoji
    // no se tiñe, así que el relleno de la elegida es un primario suave: se ve
    // el emoji entero y se distingue de las demás.
    final lleno = elegido && id.forma != FormaIdentidad.pill;
    return Semantics(
      button: true,
      selected: elegido,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: _forma(id, t),
          onTap: alTocar,
          child: Ink(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: lleno ? t.primary.withValues(alpha: 0.35) : t.surface2,
              shape: _forma(id, t),
            ),
            child: Center(child: hijo),
          ),
        ),
      ),
    );
  }
}

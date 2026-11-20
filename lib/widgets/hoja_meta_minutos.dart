import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../l10n/textos_minutos.dart';
import '../models/minutos.dart';

/// Altura de cada posición de las ruedas: 48 dp, la zona táctil mínima.
const double _altoItemRueda = 48;

/// La hoja de «Otra…» en la meta de minutos: dos ruedas, horas y minutos.
/// Devuelve la meta en minutos si se toca «Listo», o null si se cierra sin
/// más (la meta no cambia). Siempre devuelve una meta válida (1–600).
///
/// [inicial] es la meta de partida; si no es múltiplo de 5, la rueda de
/// minutos la incluye tal cual y la deja elegida.
Future<int?> mostrarHojaMetaMinutos(
  BuildContext context, {
  required int inicial,
}) {
  final id = identidad(context);
  final t = tokens(context);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: t.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(id.radioHero)),
    ),
    builder: (_) => _HojaMetaMinutos(inicial: inicial),
  );
}

class _HojaMetaMinutos extends StatefulWidget {
  final int inicial;
  const _HojaMetaMinutos({required this.inicial});

  @override
  State<_HojaMetaMinutos> createState() => _HojaMetaMinutosState();
}

class _HojaMetaMinutosState extends State<_HojaMetaMinutos> {
  late final int _metaInicial;
  late int _horas;
  late int _minuto;
  late List<int> _opcionesMinutos;
  late final FixedExtentScrollController _ruedaHoras;
  late FixedExtentScrollController _ruedaMinutos;

  /// Cambia al cambiar las opciones de minutos: la rueda se reconstruye.
  int _generacion = 0;

  @override
  void initState() {
    super.initState();
    // Un valor fuera de 1–600 no debería llegar; si llega, se parte de 30 min.
    _metaInicial = objetivoMinutosValido(widget.inicial) ? widget.inicial : 30;
    _horas = _metaInicial ~/ 60;
    _minuto = _metaInicial % 60;
    _opcionesMinutos = minutosDeRueda(_horas, existente: _metaInicial);
    _ruedaHoras = FixedExtentScrollController(initialItem: _horas);
    _ruedaMinutos = FixedExtentScrollController(
      initialItem: _opcionesMinutos.indexOf(_minuto),
    );
  }

  @override
  void dispose() {
    _ruedaHoras.dispose();
    _ruedaMinutos.dispose();
    super.dispose();
  }

  int get _total => _horas * 60 + _minuto;

  void _alCambiarHoras(int indice) {
    if (indice == _horas) return;
    setState(() {
      _horas = indice;
      final opciones = minutosDeRueda(_horas, existente: _metaInicial);
      _minuto = minutoMasCercano(opciones, _minuto);
      if (opciones.length != _opcionesMinutos.length ||
          !_mismasOpciones(opciones, _opcionesMinutos)) {
        _opcionesMinutos = opciones;
        _ruedaMinutos.dispose();
        _ruedaMinutos = FixedExtentScrollController(
          initialItem: opciones.indexOf(_minuto),
        );
        _generacion++;
      }
    });
  }

  bool _mismasOpciones(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _alCambiarMinutos(int indice) {
    setState(() => _minuto = _opcionesMinutos[indice]);
  }

  Widget _rueda({
    required Key key,
    required FixedExtentScrollController controlador,
    required int cantidad,
    required Widget Function(int) item,
    required ValueChanged<int> alCambiar,
    required Widget franja,
  }) {
    return CupertinoPicker(
      key: key,
      scrollController: controlador,
      itemExtent: _altoItemRueda,
      // Sin lupa ni curvatura de iOS: desentonan en Dulce y Neotokyo+.
      magnification: 1,
      useMagnifier: false,
      squeeze: 1,
      diameterRatio: 100,
      offAxisFraction: 0,
      selectionOverlay: franja,
      backgroundColor: Colors.transparent,
      onSelectedItemChanged: alCambiar,
      children: [for (var i = 0; i < cantidad; i++) item(i)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final id = identidad(context);
    final tema = Theme.of(context).textTheme;
    // La letra de cuerpo de la identidad y su color de texto.
    final estiloRueda = tema.titleLarge?.copyWith(
      fontFamily: id.fontBody,
      color: t.text,
    );
    final estiloUnidad = tema.titleMedium?.copyWith(
      fontFamily: id.fontBody,
      color: t.textMuted,
    );

    // La franja de lo elegido, con la figura y el borde de la identidad.
    final franja = IgnorePointer(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: t.primary.withValues(alpha: 0.12),
          shape: formaIdentidad(
            id,
            radio: id.radioSecundario,
            lado: BorderSide(color: t.primary, width: 1.4),
          ),
        ),
      ),
    );

    Widget unidad(String texto) => Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(texto, style: estiloUnidad),
    );

    // `useSafeArea` no aparta de abajo: se suma la barra del sistema, como en
    // el panel de minutos.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md +
            math.max(
              MediaQuery.viewInsetsOf(context).bottom,
              MediaQuery.viewPaddingOf(context).bottom,
            ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.habMetaTitulo,
            style: tema.titleLarge?.copyWith(color: t.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          // El resultado entero, que el lector anuncia al cambiar.
          Semantics(
            liveRegion: true,
            child: Text(
              duracionLegible(l, _total),
              style: tema.titleMedium?.copyWith(color: t.successText),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _altoItemRueda * 4,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _rueda(
                          key: const ValueKey('rueda-horas'),
                          controlador: _ruedaHoras,
                          cantidad: horasMaximasRueda + 1,
                          alCambiar: _alCambiarHoras,
                          franja: franja,
                          item: (i) => Semantics(
                            label: l.habMetaRuedaHoras(i),
                            excludeSemantics: true,
                            child: Center(
                              child: Text('$i', style: estiloRueda),
                            ),
                          ),
                        ),
                      ),
                      unidad(l.habMetaUnidadHoras),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _rueda(
                          key: ValueKey('rueda-minutos-$_generacion'),
                          controlador: _ruedaMinutos,
                          cantidad: _opcionesMinutos.length,
                          alCambiar: _alCambiarMinutos,
                          franja: franja,
                          item: (i) => Semantics(
                            label: l.habMetaRuedaMinutos(_opcionesMinutos[i]),
                            excludeSemantics: true,
                            child: Center(
                              child: Text(
                                '${_opcionesMinutos[i]}',
                                style: estiloRueda,
                              ),
                            ),
                          ),
                        ),
                      ),
                      unidad(l.habMetaUnidadMinutos),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _total),
              child: Text(l.habMetaListo),
            ),
          ),
        ],
      ),
    );
  }
}

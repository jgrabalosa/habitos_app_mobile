import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../services/idioma_service.dart';
import '../services/zona_service.dart';
import '../theme/app_theme.dart';

/// Dos selectores independientes: idioma y zona horaria.
///
/// Van juntos en la misma tarjeta porque se configuran a la vez, pero no
/// están acoplados: cambiar uno no toca el otro. Un brasileño y un portugués
/// hablan lo mismo y están a cuatro horas.
///
/// Motor: no conoce ningún concepto de hábitos.
class SelectorPreferencias extends StatefulWidget {
  final int usuarioId;
  const SelectorPreferencias({super.key, required this.usuarioId});

  @override
  State<SelectorPreferencias> createState() => _SelectorPreferenciasState();
}

class _SelectorPreferenciasState extends State<SelectorPreferencias> {
  String _zona = ZonaService.porDefecto;
  bool _zonaEsDetectada = false;

  @override
  void initState() {
    super.initState();
    _cargarZona();
  }

  Future<void> _cargarZona() async {
    final guardada = await ZonaService.obtenerGuardada();
    if (!mounted) return;
    setState(() {
      _zona = guardada;
      _zonaEsDetectada = guardada == ZonaService.detectarDelDispositivo();
    });
  }

  Future<void> _cambiarIdioma(String codigo) async {
    await IdiomaService.cambiar(codigo, usuarioId: widget.usuarioId);
    if (mounted) _avisar(AppLocalizations.of(context)!.preferenciasGuardadas);
  }

  Future<void> _cambiarZona(String zona) async {
    await ZonaService.cambiar(zona, usuarioId: widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _zona = zona;
      _zonaEsDetectada = zona == ZonaService.detectarDelDispositivo();
    });
    _avisar(AppLocalizations.of(context)!.preferenciasGuardadas);
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _nombreIdioma(AppLocalizations l, String codigo) => switch (codigo) {
        'en' => l.idiomaEn,
        'pt' => l.idiomaPt,
        _ => l.idiomaEs,
      };

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.preferencias,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
            Text(l.preferenciasSubtitulo, style: TextStyle(color: t.textMuted, fontSize: 12)),
            const SizedBox(height: 16),

            // ── Idioma ──
            Row(
              children: [
                Icon(LucideIcons.languages, size: 18, color: t.textMuted),
                const SizedBox(width: 8),
                Text(l.idioma, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Locale>(
              valueListenable: IdiomaService.localeNotifier,
              builder: (context, locale, _) {
                return Wrap(
                  spacing: 8,
                  children: IdiomaService.soportados.map((codigo) {
                    final seleccionado = locale.languageCode == codigo;
                    return ChoiceChip(
                      label: Text(_nombreIdioma(l, codigo)),
                      selected: seleccionado,
                      onSelected: (_) => _cambiarIdioma(codigo),
                      selectedColor: t.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: seleccionado ? t.primary : t.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Zona horaria ──
            Row(
              children: [
                Icon(LucideIcons.clock, size: 18, color: t.textMuted),
                const SizedBox(width: 8),
                Text(l.zonaHoraria, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.zonaAyuda, style: TextStyle(color: t.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirSelectorZona,
              icon: const Icon(LucideIcons.globe, size: 16),
              label: Text(_zona.replaceAll('_', ' ')),
            ),
            if (_zonaEsDetectada)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.zonaDetectada,
                    style: TextStyle(color: t.textMuted, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirSelectorZona() async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ListaZonas(zonaActual: _zona),
    );
    if (elegida != null) await _cambiarZona(elegida);
  }
}

/// Lista de zonas con buscador. La detectada aparece primero.
class _ListaZonas extends StatefulWidget {
  final String zonaActual;
  const _ListaZonas({required this.zonaActual});

  @override
  State<_ListaZonas> createState() => _ListaZonasState();
}

class _ListaZonasState extends State<_ListaZonas> {
  String _filtro = '';

  /// Las zonas que cubren a los usuarios previsibles. No es la lista IANA
  /// entera a propósito: son ~600 y la mayoría son alias históricos.
  static const List<String> _zonas = [
    'Europe/Madrid', 'Europe/Lisbon', 'Europe/London', 'Europe/Paris',
    'Europe/Berlin', 'Europe/Rome', 'Europe/Amsterdam', 'Europe/Dublin',
    'Europe/Moscow', 'Atlantic/Canary',
    'America/Sao_Paulo', 'America/Argentina/Buenos_Aires', 'America/Santiago',
    'America/Bogota', 'America/Lima', 'America/Mexico_City', 'America/New_York',
    'America/Chicago', 'America/Denver', 'America/Los_Angeles', 'America/Toronto',
    'Africa/Casablanca', 'Africa/Lagos', 'Africa/Johannesburg', 'Africa/Cairo',
    'Asia/Jerusalem', 'Asia/Dubai', 'Asia/Kolkata', 'Asia/Bangkok',
    'Asia/Shanghai', 'Asia/Tokyo', 'Asia/Seoul', 'Asia/Manila',
    'Australia/Perth', 'Australia/Sydney', 'Pacific/Auckland',
  ];

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final detectada = ZonaService.detectarDelDispositivo();

    final ordenadas = [
      if (_zonas.contains(detectada)) detectada,
      ..._zonas.where((z) => z != detectada),
    ];
    final visibles = ordenadas
        .where((z) => z.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.cambiarZona,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: l.buscarZona,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: visibles.isEmpty
                  ? Center(child: Text(l.sinResultados, style: TextStyle(color: t.textMuted)))
                  : ListView.builder(
                      itemCount: visibles.length,
                      itemBuilder: (context, i) {
                        final zona = visibles[i];
                        return ListTile(
                          title: Text(zona.replaceAll('_', ' ')),
                          subtitle: zona == detectada
                              ? Text(l.zonaDetectada,
                                  style: TextStyle(color: t.primary, fontSize: 11))
                              : null,
                          trailing: zona == widget.zonaActual
                              ? Icon(LucideIcons.check, color: t.primary, size: 18)
                              : null,
                          onTap: () => Navigator.pop(context, zona),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

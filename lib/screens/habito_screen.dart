import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/analytics_service.dart';
import '../l10n/catalogos.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';

class HabitoScreen extends StatefulWidget {
  final int usuarioId;
  final Habito? habito;
  final List<dynamic>? categoriasIniciales;
  final List<String>? nombresHabitosExistentes;
  const HabitoScreen({super.key, required this.usuarioId, this.habito, this.categoriasIniciales, this.nombresHabitosExistentes});

  @override
  State<HabitoScreen> createState() => _HabitoScreenState();
}

class _HabitoScreenState extends State<HabitoScreen> {
  /// Plantillas: 'id' identifica la clave de traducción, y la categoría se
  /// casa por CÓDIGO, no por nombre — el nombre que manda el backend puede
  /// venir traducido o cambiar, el código no.
  static const List<Map<String, dynamic>> _plantillas = [
    {'emoji': '💧', 'id': 'beberAgua', 'frecuencia': 'DIARIO', 'meta': 4, 'categoriaCodigo': 'CAT_SALUD'},
    {'emoji': '📖', 'id': 'leer20Min', 'frecuencia': 'DIARIO', 'meta': 1, 'categoriaCodigo': 'CAT_ESTUDIO'},
    {'emoji': '🏃', 'id': 'ejercicio', 'frecuencia': 'SEMANAL', 'meta': 3, 'dias': '2,4,6', 'categoriaCodigo': 'CAT_DEPORTE'},
    {'emoji': '🧘', 'id': 'meditar', 'frecuencia': 'DIARIO', 'meta': 1, 'categoriaCodigo': 'CAT_MENTE'},
    {'emoji': '😴', 'id': 'dormir8h', 'frecuencia': 'DIARIO', 'meta': 1, 'categoriaCodigo': 'CAT_SUENO'},
    {'emoji': '🚶', 'id': 'caminar', 'frecuencia': 'DIARIO', 'meta': 1, 'categoriaCodigo': 'CAT_SALUD'},
    {'emoji': '📓', 'id': 'escribirDiario', 'frecuencia': 'DIARIO', 'meta': 1, 'categoriaCodigo': 'CAT_MENTE'},
  ];

  /// Nombre de una plantilla en un idioma concreto.
  static String _nombrePlantilla(AppLocalizations l, String id) => switch (id) {
        'beberAgua' => l.plantillaBeberAgua,
        'leer20Min' => l.plantillaLeer20Min,
        'ejercicio' => l.plantillaEjercicio,
        'meditar' => l.plantillaMeditar,
        'dormir8h' => l.plantillaDormir8h,
        'caminar' => l.plantillaCaminar,
        'escribirDiario' => l.plantillaEscribirDiario,
        _ => id,
      };

  // Etiquetas L-D en orden ISO (1=lunes .. 7=domingo)
  static const List<String> _etiquetasDias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _frecuencia = 'DIARIO';
  int _meta = 1;
  Set<int> _diasSeleccionados = {}; // días ISO elegidos (solo SEMANAL)
  bool _recordatorioActivo = true;
  TimeOfDay? _recordatorioHora;
  bool _loading = false;
  String? _error;

  List<dynamic> _categorias = [];
  int? _categoriaId;
  bool _categoriasLoading = true;

  bool get _esEdicion => widget.habito != null;

  // Con días elegidos, la meta se deriva de ellos (un solo control)
  bool get _metaDerivada =>
      _frecuencia == 'SEMANAL' && _diasSeleccionados.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.habito!.nombre;
      _descripcionController.text = widget.habito!.descripcion ?? '';
      _frecuencia = widget.habito!.frecuencia;
      _meta = widget.habito!.meta;
      _categoriaId = widget.habito!.categoriaId;
      _diasSeleccionados = widget.habito!.diasPlanificados.toSet();
      _recordatorioActivo = widget.habito!.recordatorioActivo;
      _recordatorioHora = widget.habito!.recordatorioHoraTimeOfDay;
    }
    if (widget.categoriasIniciales != null) {
      _categorias = widget.categoriasIniciales!;
      _categoriasLoading = false;
    }
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await ApiServiceHabitos.getCategoriasUsuario(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _categoriasLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _categoriasLoading = false; });
    }
  }

  void _aplicarPlantilla(Map<String, dynamic> plantilla) {
    final l = AppLocalizations.of(context)!;
    setState(() {
      // El hábito es dato del usuario: se guarda en el idioma en el que lo creó
      _nombreController.text = _nombrePlantilla(l, plantilla['id']);
      _frecuencia = plantilla['frecuencia'];
      _meta = plantilla['meta'];
      _diasSeleccionados = plantilla['dias'] != null
          ? (plantilla['dias'] as String).split(',').map(int.parse).toSet()
          : {};

      final codigoCategoria = plantilla['categoriaCodigo'] as String?;
      if (codigoCategoria != null) {
        final match = _categorias.firstWhere(
          (c) => c['codigo'] == codigoCategoria,
          orElse: () => null,
        );
        if (match != null) {
          _categoriaId = match['categoriaId'];
        }
      }
    });
  }

  String _normalizar(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàä]'), 'a')
      .replaceAll(RegExp(r'[éèë]'), 'e')
      .replaceAll(RegExp(r'[íìï]'), 'i')
      .replaceAll(RegExp(r'[óòö]'), 'o')
      .replaceAll(RegExp(r'[úùü]'), 'u');

  /// Se compara contra las TRES traducciones, no solo la activa: un hábito
  /// creado en español debe seguir ocultando su plantilla si el usuario se
  /// pasa a inglés.
  static final List<AppLocalizations> _todosLosIdiomas = [
    lookupAppLocalizations(const Locale('es')),
    lookupAppLocalizations(const Locale('en')),
    lookupAppLocalizations(const Locale('pt')),
  ];

  bool _yaExiste(String idPlantilla) {
    final variantes = _todosLosIdiomas
        .map((l) => _normalizar(_nombrePlantilla(l, idPlantilla)))
        .toSet();
    return (widget.nombresHabitosExistentes ?? []).any((nombre) {
      final n = _normalizar(nombre);
      return variantes.any((v) => n == v || n.contains(v) || v.contains(n));
    });
  }

  List<Map<String, dynamic>> get _plantillasDisponibles =>
      _plantillas.where((p) => !_yaExiste(p['id'])).toList();

  void _alternarDia(int dia) {
    setState(() {
      if (_diasSeleccionados.contains(dia)) {
        _diasSeleccionados.remove(dia);
      } else {
        _diasSeleccionados.add(dia);
      }
      // Meta derivada: tantos días como haya marcados
      if (_diasSeleccionados.isNotEmpty) {
        _meta = _diasSeleccionados.length;
      }
    });
  }

  Future<void> _guardar() async {
    final l = AppLocalizations.of(context)!;
    if (widget.habito != null && _frecuencia != widget.habito!.frecuencia) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.habCambiarFrecTitulo),
          content: Text(l.habCambiarFrecCuerpo),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancelar),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.comunContinuar),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    if (_nombreController.text.isEmpty) {
      setState(() { _error = l.habNombreObligatorio; });
      return;
    }

    // Días solo si es SEMANAL y hay elegidos; null = semanal flexible o diario.
    // Ordenados para un CSV estable ("2,4,6").
    final String? diasSemana = _metaDerivada
        ? (_diasSeleccionados.toList()..sort()).join(',')
        : null;
    final int meta = _metaDerivada ? _diasSeleccionados.length : _meta;
    final String? recordatorioHora = _recordatorioHora == null
        ? null
        : '${_recordatorioHora!.hour.toString().padLeft(2, '0')}:${_recordatorioHora!.minute.toString().padLeft(2, '0')}';

    setState(() { _loading = true; _error = null; });
    try {
      if (_esEdicion) {
        await ApiServiceHabitos.actualizarHabito(
          widget.habito!.habitoId,
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          meta,
          widget.usuarioId,
          _categoriaId,
          diasSemana: diasSemana,
          recordatorioActivo: _recordatorioActivo,
          recordatorioHora: recordatorioHora,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final logrosOtorgados = await ApiServiceHabitos.crearHabito(
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          meta,
          widget.usuarioId,
          _categoriaId,
          diasSemana: diasSemana,
          recordatorioActivo: _recordatorioActivo,
          recordatorioHora: recordatorioHora,
        );
        await AnalyticsHabitos.habitoCreado(_frecuencia);
        if (mounted) Navigator.pop(context, true);
        if (logrosOtorgados.isNotEmpty) {
          CelebracionService.mostrar(logrosOtorgados);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = MensajesError.de(context, e,
              generico: _esEdicion ? l.habErrorActualizar : l.habErrorCrear);
        });
      }
    } finally {
      // En el camino bueno ya se ha hecho Navigator.pop: la pantalla puede
      // estar desmontada cuando llega este finally.
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _eliminar() async {
    final l = AppLocalizations.of(context)!;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.habEliminarTitulo),
        content: Text(l.habEliminarCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.comunEliminar, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() { _loading = true; });
      try {
        await ApiServiceHabitos.eliminarHabito(widget.habito!.habitoId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = MensajesError.de(context, e, generico: l.habErrorEliminar);
            _loading = false;
          });
        }
      }
    }
  }

  Future<void> _elegirHoraRecordatorio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _recordatorioHora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora != null && mounted) {
      setState(() { _recordatorioHora = hora; });
    }
  }

  Widget _selectorDias(TokensContextuales t) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.habDiasSemana,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final dia = i + 1;
            final bool activo = _diasSeleccionados.contains(dia);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _alternarDia(dia),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activo ? t.primary : t.surface2,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _etiquetasDias[i],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: activo ? t.tinta : t.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _diasSeleccionados.isEmpty
              ? l.habDiasAyudaSin
              : l.habDiasAyudaCon,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_esEdicion ? l.habTituloEditar : l.habTituloNuevo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_esEdicion && _plantillasDisponibles.isNotEmpty) ...[
                  Text(l.habRecomendados,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _plantillasDisponibles.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final p = _plantillasDisponibles[i];
                        return ActionChip(
                          avatar: Text(p['emoji'], style: const TextStyle(fontSize: 16)),
                          label: Text(_nombrePlantilla(
                              AppLocalizations.of(context)!, p['id'])),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          onPressed: () => _aplicarPlantilla(p),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.habLabelNombre,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.habLabelDescripcion,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _categoriasLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<int?>(
                        initialValue: _categoriaId,
                        decoration: InputDecoration(
                          labelText: l.habLabelCategoria,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l.habSinCategoria),
                          ),
                          ..._categorias.map((c) => DropdownMenuItem<int?>(
                                value: c['categoriaId'],
                                child: Text('${c['icono'] ?? ''} ${Catalogos.categoria(context, c['codigo'], c['nombre'])}'.trim()),
                              )),
                        ],
                        onChanged: (v) => setState(() { _categoriaId = v; }),
                      ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _frecuencia,
                  decoration: InputDecoration(
                    labelText: l.habLabelFrecuencia,
                    border: const OutlineInputBorder(),
                  ),
                  items: ['DIARIO', 'SEMANAL']
                      .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f == 'DIARIO' ? l.frecDiario : l.frecSemanal)))
                      .toList(),
                  onChanged: (v) => setState(() { _frecuencia = v!; }),
                ),
                if (_frecuencia == 'SEMANAL') ...[
                  const SizedBox(height: 16),
                  _selectorDias(t),
                ],
                const SizedBox(height: 12),
                if (_metaDerivada)
                  Row(
                    children: [
                      Text(l.habMeta),
                      Text(l.habDiasSemanaMeta(_diasSeleccionados.length),
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  )
                else
                  Row(
                    children: [
                      Text(l.habMeta),
                      IconButton(
                        icon: const Icon(LucideIcons.minus),
                        onPressed: () => setState(() { if (_meta > 1) _meta--; }),
                      ),
                      Text('$_meta', style: Theme.of(context).textTheme.headlineSmall),
                      IconButton(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () => setState(() { _meta++; }),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habRecordatorio),
                  subtitle: Text(_recordatorioActivo
                      ? (_recordatorioHora != null
                          ? l.habALas(_recordatorioHora!.format(context))
                          : l.habEligeHora)
                      : l.habDesactivado),
                  value: _recordatorioActivo,
                  onChanged: (v) => setState(() { _recordatorioActivo = v; }),
                ),
                if (_recordatorioActivo)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _elegirHoraRecordatorio,
                      icon: const Icon(LucideIcons.clock),
                      label: Text(_recordatorioHora == null
                          ? l.habElegirHora
                          : l.habCambiarHora(_recordatorioHora!.format(context))),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _guardar,
                    child: _loading
                        ? CircularProgressIndicator(color: t.tinta)
                        : Text(_esEdicion ? l.habBotonActualizar : l.habBotonCrear),
                  ),
                ),
                if (_esEdicion) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _eliminar,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l.habBotonEliminar,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/analytics_service.dart';
import '../l10n/catalogos.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';
import '../models/plantilla_habito.dart';

class HabitoScreen extends StatefulWidget {
  final int usuarioId;
  final Habito? habito;
  final List<dynamic>? categoriasIniciales;
  final List<String>? nombresHabitosExistentes;

  /// La idea de la que sale el hábito nuevo: se rellena el formulario con ella.
  final PlantillaHabito? plantilla;
  const HabitoScreen({
    super.key,
    required this.usuarioId,
    this.habito,
    this.categoriasIniciales,
    this.nombresHabitosExistentes,
    this.plantilla,
  });

  /// Seam de test: de dónde salen las categorías. En producción, la red.
  @visibleForTesting
  static Future<List<dynamic>> Function(int usuarioId) cargarCategorias =
      ApiServiceHabitos.getCategoriasUsuario;

  /// Seam de test: la llamada que crea el hábito. En producción, la red.
  @visibleForTesting
  static Future<List<String>> Function(
    String nombre,
    String descripcion,
    String frecuencia,
    int meta,
    int usuarioId,
    int? categoriaId, {
    String? diasSemana,
    bool recordatorioActivo,
    String? recordatorioHora,
  })
  crearHabito = ApiServiceHabitos.crearHabito;

  @override
  State<HabitoScreen> createState() => _HabitoScreenState();
}

class _HabitoScreenState extends State<HabitoScreen> {
  // Etiquetas L-D en orden ISO (1=lunes .. 7=domingo)
  static const List<String> _etiquetasDias = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

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
  // Una idea trae su categoría por código; si aún no ha llegado, queda aquí.
  String? _codigoCategoriaPendiente;
  // Si el usuario tocó el desplegable, la categoría ya no se cambia sola.
  bool _categoriaElegidaPorUsuario = false;
  // El nombre de una idea se pone al traducirlo, en didChangeDependencies.
  bool _nombrePendiente = false;
  bool _categoriasLoading = true;
  // Sólo es true si la carga falló y no hay categorías de antes que enseñar.
  bool _categoriasError = false;

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
    final plantilla = widget.plantilla;
    if (!_esEdicion && plantilla != null) {
      // El nombre va en didChangeDependencies: se traduce con el idioma activo.
      _nombrePendiente = true;
      _frecuencia = plantilla.frecuencia;
      _meta = plantilla.meta;
      _diasSeleccionados = plantilla.dias != null
          ? plantilla.dias!.split(',').map(int.parse).toSet()
          : {};
      _codigoCategoriaPendiente = plantilla.categoriaCodigo;
    }
    if (widget.categoriasIniciales != null) {
      _categorias = widget.categoriasIniciales!;
      _categoriasLoading = false;
    }
    _cargarCategorias();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nombrePendiente) {
      _nombrePendiente = false;
      _nombreController.text = nombrePlantilla(
        AppLocalizations.of(context)!,
        widget.plantilla!.id,
      );
    }
    _resolverCategoriaPendiente();
  }

  /// La plantilla trae una categoría por código, y las categorías pueden llegar
  /// después de abrir el formulario. Se aplica cuando aparece, solo si el
  /// usuario no ha elegido otra antes.
  void _resolverCategoriaPendiente() {
    final codigo = _codigoCategoriaPendiente;
    if (codigo == null || _categoriaElegidaPorUsuario) return;
    final match = _categorias.where((c) => c['codigo'] == codigo);
    if (match.isEmpty) return;
    _categoriaId = match.first['categoriaId'];
    _codigoCategoriaPendiente = null;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await HabitoScreen.cargarCategorias(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _categoriasLoading = false;
        _categoriasError = false;
        _resolverCategoriaPendiente();
      });
    } catch (e) {
      // Con categorías de antes (las de `categoriasIniciales`) se quedan ésas:
      // mejor una lista vieja que un error. Sin ninguna, se dice.
      if (mounted) {
        setState(() {
          _categoriasLoading = false;
          _categoriasError = _categorias.isEmpty;
        });
      }
    }
  }

  void _reintentarCategorias() {
    setState(() {
      _categoriasLoading = true;
      _categoriasError = false;
    });
    _cargarCategorias();
  }

  /// Sustituye al desplegable cuando las categorías no han cargado y no hay
  /// ninguna de antes. Sin desplegable no hay forma de quitarle la categoría
  /// al hábito sin querer, y `_categoriaId` se conserva: si se guarda sin
  /// reintentar, el hábito se queda con la que tenía.
  Widget _filaErrorCategorias(AppLocalizations l) {
    final t = tokens(context);
    return Row(
      children: [
        Icon(LucideIcons.cloudOff, size: 18, color: t.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l.habErrorCategorias,
            style: TextStyle(color: t.textMuted),
          ),
        ),
        TextButton.icon(
          onPressed: _reintentarCategorias,
          icon: const Icon(LucideIcons.rotateCw, size: 18),
          label: Text(l.dashReintentar),
        ),
      ],
    );
  }

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

    if (_nombreController.text.isEmpty) {
      setState(() {
        _error = l.habNombreObligatorio;
      });
      return;
    }

    // Recordatorio activo sin hora: el backend lo acepta y luego no notifica
    // nunca (ver Habito.java, "null = sin hora elegida todavía"). Silencioso
    // y con el interruptor en verde, que es la peor combinación.
    if (_recordatorioActivo && _recordatorioHora == null) {
      setState(() {
        _error = l.habHoraObligatoria;
      });
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

    setState(() {
      _loading = true;
      _error = null;
    });
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
        final logrosOtorgados = await HabitoScreen.crearHabito(
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
        if (logrosOtorgados.isNotEmpty) {
          // Sale aquí, antes de cerrar: es donde se acaba de ganar.
          await CelebracionService.mostrar(logrosOtorgados);
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = MensajesError.de(
            context,
            e,
            generico: _esEdicion ? l.habErrorActualizar : l.habErrorCrear,
          );
        });
      }
    } finally {
      // En el camino bueno ya se ha hecho Navigator.pop: la pantalla puede
      // estar desmontada cuando llega este finally.
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _eliminar() async {
    final l = AppLocalizations.of(context)!;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: formaIdentidad(
          identidad(context),
          radio: identidad(context).radioHero,
        ),
        title: Text(l.habEliminarTitulo),
        content: Text(l.habEliminarCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.comunEliminar,
              style: TextStyle(color: tonoError(context).texto),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _loading = true;
      });
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
      setState(() {
        _recordatorioHora = hora;
      });
      await _asegurarPermisoNotificaciones();
    }
  }

  /// El permiso se pide aquí, en contexto: el usuario acaba de decir a qué
  /// hora quiere el recordatorio. Si ya está dado, no se pregunta nada.
  Future<void> _asegurarPermisoNotificaciones() async {
    if (await NotificacionesService.concedido()) return;
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    if (await NotificacionesService.bloqueadoEnAjustes()) {
      _avisoAjustes(l);
      return;
    }
    if (!mounted) return;
    final permitir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.permisoTitulo),
        content: Text(l.permisoCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.permisoAhoraNo),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.permisoPermitir),
          ),
        ],
      ),
    );
    if (permitir != true) return;
    final concedido = await NotificacionesService.pedirYRegistrar(
      widget.usuarioId,
    );
    if (!concedido &&
        mounted &&
        await NotificacionesService.bloqueadoEnAjustes()) {
      _avisoAjustes(l);
    }
  }

  void _avisoAjustes(AppLocalizations l) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.permisoBloqueado),
        action: SnackBarAction(
          label: l.permisoAjustes,
          onPressed: NotificacionesService.abrirAjustes,
        ),
      ),
    );
  }

  Widget _selectorDias(TokensContextuales t) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.habDiasSemana, style: Theme.of(context).textTheme.titleMedium),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: activo ? t.tinta : t.textMuted),
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
          _diasSeleccionados.isEmpty ? l.habDiasAyudaSin : l.habDiasAyudaCon,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: t.textMuted),
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
      // Sin AppBar abajo que lo aparte, el final del formulario —el botón de
      // guardar— quedaba debajo de los botones de Android. Arriba ya se
      // encarga el AppBar.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    // Limitado para que lo que se escribe quepa donde se ve: una
                    // línea en el listado y sin ocupar media pantalla en el
                    // detalle. Antes no había tope y cabía un párrafo entero.
                    maxLength: 120,
                    maxLines: 2,
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
                      : _categoriasError
                      ? _filaErrorCategorias(l)
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
                            ..._categorias.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c['categoriaId'],
                                child: Text(
                                  '${c['icono'] ?? ''} ${Catalogos.categoria(context, c['codigo'], c['nombre'])}'
                                      .trim(),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _categoriaElegidaPorUsuario = true;
                            _categoriaId = v;
                          }),
                        ),
                  const SizedBox(height: 12),
                  // El título va fuera del recuadro, como «Días de la semana», y
                  // la ayuda va pegada a él como un exponente, igual que en «Meta».
                  Row(
                    children: [
                      Text(
                        l.habLabelFrecuencia,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AyudaCampo(
                        texto: l.habAyudaFrecuencia,
                        etiquetaSemantica: l.habAyudaFrecuenciaEtiqueta,
                        superindice: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _frecuencia,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ['DIARIO', 'SEMANAL']
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f == 'DIARIO' ? l.frecDiario : l.frecSemanal,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _frecuencia = v!;
                    }),
                  ),
                  if (_frecuencia == 'SEMANAL') ...[
                    const SizedBox(height: 16),
                    _selectorDias(t),
                  ],
                  const SizedBox(height: 12),
                  if (_metaDerivada)
                    Row(
                      children: [
                        // `trimRight`: el texto trae un espacio detrás de los
                        // dos puntos, y el interrogante va pegado a ellos como
                        // un exponente. El aire hasta lo siguiente ya lo da
                        // su propia caja.
                        Text(l.habMeta.trimRight()),
                        AyudaCampo(
                          texto: l.habAyudaMetaDias,
                          etiquetaSemantica: l.habAyudaMetaEtiqueta,
                          superindice: true,
                        ),
                        Text(
                          l.habDiasSemanaMeta(_diasSeleccionados.length),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // `trimRight`: ver la fila de los días marcados.
                        Text(l.habMeta.trimRight()),
                        AyudaCampo(
                          // Diario: veces al día. Semanal sin días marcados:
                          // veces por semana, el día que sea. Con días
                          // marcados no se llega aquí: es la otra fila.
                          texto: _frecuencia == 'DIARIO'
                              ? l.habAyudaMetaDiaria
                              : l.habAyudaMetaSemanal,
                          etiquetaSemantica: l.habAyudaMetaEtiqueta,
                          superindice: true,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.minus),
                          onPressed: () => setState(() {
                            if (_meta > 1) _meta--;
                          }),
                        ),
                        Text(
                          '$_meta',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plus),
                          onPressed: () => setState(() {
                            _meta++;
                          }),
                        ),
                      ],
                    ),
                  // Un semanal cobra un 20 % más al completar la semana: se
                  // dice aquí, que es donde se decide su objetivo.
                  if (_frecuencia == 'SEMANAL') ...[
                    const SizedBox(height: 4),
                    Text(
                      l.habExtraSemanal,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens(context).textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.habRecordatorio),
                    subtitle: Text(
                      _recordatorioActivo
                          ? (_recordatorioHora != null
                                ? l.habALas(_recordatorioHora!.format(context))
                                : l.habEligeHora)
                          : l.habDesactivado,
                    ),
                    value: _recordatorioActivo,
                    onChanged: (v) => setState(() {
                      _recordatorioActivo = v;
                    }),
                  ),
                  if (_recordatorioActivo)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _elegirHoraRecordatorio,
                        icon: const Icon(LucideIcons.clock),
                        label: Text(
                          _recordatorioHora == null
                              ? l.habElegirHora
                              : l.habCambiarHora(
                                  _recordatorioHora!.format(context),
                                ),
                        ),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: tonoError(context).texto),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _guardar,
                      child: _loading
                          ? CircularProgressIndicator(color: t.tinta)
                          : Text(
                              _esEdicion
                                  ? l.habBotonActualizar
                                  : l.habBotonCrear,
                            ),
                    ),
                  ),
                  if (_esEdicion) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _eliminar,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tonoError(context).borde),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          l.habBotonEliminar,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: tonoError(context).texto),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

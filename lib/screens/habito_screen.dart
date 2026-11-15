import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../l10n/textos_minutos.dart';
import '../models/minutos.dart';
import '../models/objetivo_programado.dart';
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

  /// La idea de la que sale el hábito nuevo: se rellena el formulario con ella.
  final PlantillaHabito? plantilla;

  /// El cambio de objetivo programado, si quien abre la edición ya lo tiene
  /// (el detalle). Si no llega, el formulario lo pide al abrir.
  final ObjetivoProgramado? objetivoProgramado;
  const HabitoScreen({
    super.key,
    required this.usuarioId,
    this.habito,
    this.categoriasIniciales,
    this.plantilla,
    this.objetivoProgramado,
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
    String? unidad,
    int? minutosObjetivo,
  })
  crearHabito = ApiServiceHabitos.crearHabito;

  /// Seam de test: la llamada que guarda los cambios. Devuelve `aplicaDesde`.
  @visibleForTesting
  static Future<DateTime?> Function(
    int habitoId,
    String nombre,
    String descripcion,
    String frecuencia,
    int meta,
    int usuarioId,
    int? categoriaId, {
    String? diasSemana,
    bool recordatorioActivo,
    String? recordatorioHora,
    String? unidad,
    int? minutosObjetivo,
  })
  actualizarHabito = ApiServiceHabitos.actualizarHabito;

  /// Seam de test: de dónde sale el cambio programado al editar.
  @visibleForTesting
  static Future<ObjetivoProgramado?> Function(int habitoId)
  cargarObjetivoProgramado = _objetivoProgramadoDelDetalle;

  /// Seam de test: la llamada que anula el cambio programado.
  @visibleForTesting
  static Future<void> Function(int habitoId) anularObjetivoProgramado =
      ApiServiceHabitos.anularObjetivoProgramado;

  static Future<ObjetivoProgramado?> _objetivoProgramadoDelDetalle(
    int habitoId,
  ) async => ObjetivoProgramado.deJson(
    (await ApiServiceHabitos.getHabitoDetalle(habitoId))['objetivoProgramado'],
  );

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

  /// En qué se mide. Un hábito nuevo empieza en veces, como siempre.
  UnidadHabito _unidad = UnidadHabito.veces;

  /// Los minutos por día elegidos con las metas rápidas.
  int _minutosObjetivo = 30;

  /// Si se escribe una cifra propia en vez de una meta rápida.
  bool _minutosLibre = false;
  final _minutosController = TextEditingController();

  /// El cambio de objetivo que todavía no vale, si lo hay.
  ObjetivoProgramado? _programado;

  /// Si se ha anulado el cambio programado: salir sin guardar también tiene
  /// que avisar a quien abrió el formulario de que algo ha cambiado.
  bool _huboCambios = false;
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

  bool get _esMinutos => _unidad == UnidadHabito.minutos;

  /// Un hábito que ya es de minutos no puede volver a veces (el backend
  /// responde 409): el selector ni lo ofrece.
  bool get _sinVueltaAVeces =>
      _esEdicion && widget.habito!.unidad == UnidadHabito.minutos;

  /// Los minutos por día que se guardarían, o null si la cifra propia no es
  /// un número.
  int? get _minutosElegidos => _minutosLibre
      ? int.tryParse(_minutosController.text.trim())
      : _minutosObjetivo;

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
      _unidad = widget.habito!.unidad;
      final minutos = widget.habito!.minutosObjetivo;
      if (minutos != null) {
        _minutosLibre = !metasRapidasMinutos.contains(minutos);
        if (_minutosLibre) {
          _minutosController.text = '$minutos';
        } else {
          _minutosObjetivo = minutos;
        }
      }
      _programado = widget.objetivoProgramado;
      if (_programado == null) _cargarProgramado();
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
      _unidad = plantilla.unidad;
      final minutos = plantilla.minutos;
      if (_unidad == UnidadHabito.minutos && minutos != null) {
        _minutosLibre = !metasRapidasMinutos.contains(minutos);
        if (_minutosLibre) {
          _minutosController.text = '$minutos';
        } else {
          _minutosObjetivo = minutos;
        }
      }
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
    _minutosController.dispose();
    super.dispose();
  }

  /// Al cambiar de unidad o de frecuencia, la meta se recorta a lo que admite:
  /// un diario de veces de 8 que pasa a minutos semanal se queda en 7 días.
  /// Se llama dentro de un `setState`.
  void _recortarMeta() {
    _meta = metaParaUnidad(_meta, _unidad);
  }

  /// Si falla, no se enseña: editar sigue funcionando sin saberlo, y el aviso
  /// de `aplicaDesde` dirá cuándo vale lo que se guarde.
  Future<void> _cargarProgramado() async {
    try {
      final programado = await HabitoScreen.cargarObjetivoProgramado(
        widget.habito!.habitoId,
      );
      if (mounted && programado != null) {
        setState(() => _programado = programado);
      }
    } catch (_) {}
  }

  Future<void> _anularProgramado() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await HabitoScreen.anularObjetivoProgramado(widget.habito!.habitoId);
      if (!mounted) return;
      setState(() {
        _programado = null;
        _huboCambios = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.habProgramadoAnulado)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = MensajesError.de(context, e, generico: l.habProgramadoError);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    // Minutos por día: obligatorios y entre 1 y 600 en un hábito de minutos.
    final int? minutos = _esMinutos ? _minutosElegidos : null;
    if (_esMinutos && !objetivoMinutosValido(minutos)) {
      setState(() {
        _error = textoMinutosRango(l);
      });
      return;
    }

    final String? diasSemana = _metaDerivada
        ? (_diasSeleccionados.toList()..sort()).join(',')
        : null;
    // Un diario de minutos tiene siempre un día por día: el servidor también
    // lo fuerza.
    // En un semanal de minutos, entre 1 y 7 días por semana.
    final int meta = _metaDerivada
        ? _diasSeleccionados.length
        : (_esMinutos && _frecuencia == 'DIARIO'
              ? 1
              : metaParaUnidad(_meta, _unidad));
    // Un hábito de veces no manda los campos de minutos: el body queda igual
    // que antes de existir los de minutos.
    final String? unidad = _esMinutos ? codigoUnidad(_unidad) : null;
    final String? recordatorioHora = _recordatorioHora == null
        ? null
        : '${_recordatorioHora!.hour.toString().padLeft(2, '0')}:${_recordatorioHora!.minute.toString().padLeft(2, '0')}';

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_esEdicion) {
        final original = widget.habito!;
        final aplicaDesde = await HabitoScreen.actualizarHabito(
          original.habitoId,
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          meta,
          widget.usuarioId,
          _categoriaId,
          diasSemana: diasSemana,
          recordatorioActivo: _recordatorioActivo,
          recordatorioHora: recordatorioHora,
          unidad: unidad,
          minutosObjetivo: minutos,
        );
        if (!mounted) return;
        // Si el cambio no vale hasta otro día, se dice antes de cerrar. El
        // aviso va al ScaffoldMessenger de la app, así que se sigue viendo en
        // la pantalla a la que se vuelve.
        final cambiaMinutos =
            _esMinutos &&
            (original.unidad != UnidadHabito.minutos ||
                original.minutosObjetivo != minutos);
        final aviso = avisoAplicaDesde(
          l,
          aplicaDesde: aplicaDesde,
          hoy: DateTime.now(),
          locale: Localizations.localeOf(context).toLanguageTag(),
          minutosNuevos: cambiaMinutos ? minutos : null,
        );
        if (aviso != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(aviso),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        Navigator.pop(context, true);
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
          unidad: unidad,
          minutosObjetivo: minutos,
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

  /// «Veces» o «Minutos». Editando uno de minutos, «Veces» sale apagado y se
  /// dice por qué.
  Widget _selectorUnidad(AppLocalizations l, TokensContextuales t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.habLabelUnidad,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AyudaCampo(
              texto: l.habAyudaUnidad,
              etiquetaSemantica: l.habAyudaUnidadEtiqueta,
              superindice: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<UnidadHabito>(
          segments: [
            ButtonSegment(
              value: UnidadHabito.veces,
              label: Text(l.habUnidadVeces),
              icon: const Icon(LucideIcons.check),
              enabled: !_sinVueltaAVeces,
            ),
            ButtonSegment(
              value: UnidadHabito.minutos,
              label: Text(l.habUnidadMinutos),
              icon: const Icon(LucideIcons.timer),
            ),
          ],
          selected: {_unidad},
          onSelectionChanged: (nuevo) => setState(() {
            _unidad = nuevo.first;
            _error = null;
            _recortarMeta();
          }),
        ),
        if (_sinVueltaAVeces) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.habUnidadSinVuelta,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }

  /// Los minutos por día: las metas rápidas, una cifra propia y la frase que
  /// dice el objetivo entero («30 min cada día»). Nunca «N×X a la semana»: en
  /// un semanal cada día cuenta por sí solo.
  Widget _selectorMinutos(AppLocalizations l, TokensContextuales t) {
    final minutos = _minutosElegidos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.habMinutosPorDia,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final n in metasRapidasMinutos)
              ChoiceChip(
                label: Text(duracionLegible(l, n)),
                selected: !_minutosLibre && _minutosObjetivo == n,
                onSelected: (_) => setState(() {
                  _minutosLibre = false;
                  _minutosObjetivo = n;
                  _error = null;
                }),
              ),
            ChoiceChip(
              label: Text(textoMinutosOtra(l)),
              selected: _minutosLibre,
              onSelected: (_) => setState(() {
                _minutosLibre = true;
                _error = null;
              }),
            ),
          ],
        ),
        if (_minutosLibre) ...[
          const SizedBox(height: AppSpacing.ms),
          TextField(
            controller: _minutosController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: textoMinutosOtra(l),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (objetivoMinutosValido(minutos)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            etiquetaObjetivoMinutos(
              l,
              minutos!,
              diario: _frecuencia == 'DIARIO',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: t.successText),
          ),
        ],
      ],
    );
  }

  /// El cambio de objetivo que aún no vale, con la opción de anularlo.
  Widget _tarjetaProgramado(
    AppLocalizations l,
    TokensContextuales t,
    ObjetivoProgramado programado,
  ) {
    final texto = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.ms),
      // La figura de la identidad, al radio de las tarjetas de contenido:
      // redondeada en Profundidad, a lápiz en Dulce, achaflanada en Neotokyo+.
      decoration: ShapeDecoration(
        color: t.surface2,
        shape: formaIdentidad(
          identidad(context),
          radio: identidad(context).radioSecundario,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarClock, size: 18, color: t.streakText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.habProgramadoTitulo,
                  style: texto.titleSmall?.copyWith(color: t.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            textoObjetivoProgramado(
              l,
              programado,
              actual: widget.habito!,
              hoy: DateTime.now(),
              locale: Localizations.localeOf(context).toLanguageTag(),
            ),
            style: texto.bodyMedium?.copyWith(color: t.text),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _anularProgramado,
              child: Text(l.habProgramadoAnular),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final programado = _programado;
    // Si se anuló el cambio programado, volver atrás sin guardar también
    // devuelve true, para que quien abrió el formulario recargue.
    return PopScope<bool>(
      canPop: !_huboCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: _formulario(l, t, programado),
    );
  }

  Widget _formulario(
    AppLocalizations l,
    TokensContextuales t,
    ObjetivoProgramado? programado,
  ) {
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
                  if (_esEdicion && programado != null)
                    _tarjetaProgramado(l, t, programado),
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
                  const SizedBox(height: AppSpacing.md),
                  _selectorUnidad(l, t),
                  const SizedBox(height: AppSpacing.md),
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
                      _recortarMeta();
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
                  // Un diario de minutos no tiene objetivo de veces: es un día
                  // por día, y lo que se elige son los minutos.
                  else if (!(_esMinutos && _frecuencia == 'DIARIO'))
                    Row(
                      children: [
                        // `trimRight`: ver la fila de los días marcados.
                        Text(l.habMeta.trimRight()),
                        AyudaCampo(
                          // Diario: veces al día. Semanal sin días marcados:
                          // veces por semana, el día que sea. Con días
                          // marcados no se llega aquí: es la otra fila. En
                          // minutos, días por semana que llegan a sus minutos.
                          texto: _esMinutos
                              ? l.habAyudaMetaSemanalMinutos
                              : _frecuencia == 'DIARIO'
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
                          // En minutos, como mucho 7 días por semana.
                          onPressed: _esMinutos && _meta >= diasMaximosSemana
                              ? null
                              : () => setState(() {
                                  _meta++;
                                }),
                        ),
                      ],
                    ),
                  if (_esMinutos) ...[
                    const SizedBox(height: AppSpacing.md),
                    _selectorMinutos(l, t),
                  ],
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

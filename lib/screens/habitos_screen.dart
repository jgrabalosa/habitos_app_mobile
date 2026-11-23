import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/habitos_refresh.dart';
import '../services/app_refresh.dart';
import '../l10n/catalogos.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';
import '../widgets/hoja_categoria.dart';
import '../widgets/identidad_ui.dart';
import '../widgets/pausa_habito.dart';
import 'habito_screen.dart';
import 'ideas_habito_screen.dart';

enum _Orden { recientes, masCumplidos }

enum _AccionCategoria { cambiar, borrar }

class HabitosScreen extends StatefulWidget {
  final int usuarioId;
  const HabitosScreen({super.key, required this.usuarioId});

  /// Seams de test: de dónde sale lo que se enseña y qué llamadas gestionan
  /// las categorías propias. En producción, la red.
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(int usuarioId)
  cargarResumen = ApiServiceHabitos.getResumenHabitos;

  @visibleForTesting
  static Future<List<dynamic>> Function(int usuarioId) cargarCategorias =
      ApiServiceHabitos.getCategoriasUsuario;

  @visibleForTesting
  static Future<Map<String, dynamic>> Function(String nombre, String? icono)
  crearCategoria = ApiServiceHabitos.crearCategoria;

  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    int categoriaId,
    String nombre,
    String? icono,
  )
  actualizarCategoria = ApiServiceHabitos.actualizarCategoria;

  @visibleForTesting
  static Future<void> Function(int categoriaId) borrarCategoria =
      ApiServiceHabitos.borrarCategoria;

  @override
  State<HabitosScreen> createState() => _HabitosScreenState();
}

class _HabitosScreenState extends State<HabitosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _resumen =
      []; // {habito: Habito, totalCompletados: int}
  List<dynamic> _categorias = [];
  int? _filtroCategoriaId; // null = todas
  _Orden _orden = _Orden.recientes;
  int? _reanudando; // el hábito que se está reanudando, mientras tanto
  int? _pausando; // el hábito que se está pausando, mientras tanto

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    appRefreshNotifier.addListener(_alRefrescoApp);
    // Pausar desde el detalle cambia esta lista: esta pestaña se mantiene viva
    // y no se entera sola.
    habitosCambiadosNotifier.addListener(_alRefrescoApp);
  }

  void _alRefrescoApp() {
    if (mounted) _cargarDatos();
  }

  @override
  void dispose() {
    appRefreshNotifier.removeListener(_alRefrescoApp);
    habitosCambiadosNotifier.removeListener(_alRefrescoApp);
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final resultados = await Future.wait([
        HabitosScreen.cargarResumen(widget.usuarioId),
        HabitosScreen.cargarCategorias(widget.usuarioId),
      ]);
      if (!mounted) return;
      setState(() {
        _resumen = resultados[0] as List<Map<String, dynamic>>;
        _categorias = resultados[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _avisarError(e);
    }
  }

  /// Pausa desde la lista, con la misma ventana que el detalle. La lista se
  /// recarga sola por el aviso de hábitos cambiados.
  Future<void> _pausar(Habito habito) async {
    setState(() => _pausando = habito.habitoId);
    try {
      await pausarHabito(
        context,
        usuarioId: widget.usuarioId,
        habitoId: habito.habitoId,
        nombre: habito.nombre,
      );
    } finally {
      if (mounted) setState(() => _pausando = null);
    }
  }

  /// Reanudar es gratis y sin confirmación. La lista y Hoy se recargan por el
  /// aviso de hábitos cambiados.
  Future<void> _reanudar(Habito habito) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _reanudando = habito.habitoId);
    try {
      await ApiServiceHabitos.activarHabito(habito.habitoId);
      notificarHabitosCambiados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.pausaReanudada(habito.nombre))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MensajesError.de(context, e, generico: l.pausaErrorReanudar),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reanudando = null);
    }
  }

  void _avisarError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          MensajesError.de(
            context,
            e,
            generico: AppLocalizations.of(context)!.habitosErrorEstado,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtradosYOrdenados {
    var lista = _filtroCategoriaId == null
        ? _resumen
        : _resumen
              .where(
                (r) =>
                    (r['habito'] as Habito).categoriaId == _filtroCategoriaId,
              )
              .toList();

    lista = List.of(lista);
    if (_orden == _Orden.recientes) {
      lista.sort(
        (a, b) => (b['habito'] as Habito).habitoId.compareTo(
          (a['habito'] as Habito).habitoId,
        ),
      );
    } else {
      lista.sort(
        (a, b) => (b['totalCompletados'] as int).compareTo(
          a['totalCompletados'] as int,
        ),
      );
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const SkeletonLista();
    }

    final lista = _filtradosYOrdenados;

    return Scaffold(
      // El shell ya pinta el FondoEstelar debajo de esta pestaña. Sin esto, el
      // Scaffold anidado pinta scaffoldBackgroundColor opaco encima y tapa el
      // cielo. Es la misma razón por la que dashboard_screen no lleva Scaffold.
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        shape: formaBotonFlotante(identidad(context), t),
        elevation: elevacionBotonFlotante(identidad(context)),
        onPressed: () async {
          final result = await abrirAltaHabito(
            context,
            usuarioId: widget.usuarioId,
            categoriasIniciales: _categorias,
            nombresHabitosExistentes: _resumen
                .map((r) => (r['habito'] as Habito).nombre)
                .toList(),
          );
          if (result == true) {
            _cargarDatos();
            notificarHabitosCambiados();
          }
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _filtrosCategoria(l, t),
            const SizedBox(height: 12),
            _selectorOrden(l),
            const SizedBox(height: 16),
            if (lista.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    l.habitosSinFiltro,
                    style: TextStyle(color: t.textMuted),
                  ),
                ),
              )
            else
              ...lista.map((r) => _tarjetaHabito(l, r, t)),
          ],
        ),
      ),
    );
  }

  Widget _filtrosCategoria(AppLocalizations l, TokensContextuales t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            l.habitosTodas,
            _filtroCategoriaId == null,
            () => setState(() => _filtroCategoriaId = null),
            t,
          ),
          for (final c in _categorias)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chipCategoria(l, t, c),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _chipNueva(l, t),
          ),
        ],
      ),
    );
  }

  Widget _chipCategoria(AppLocalizations l, TokensContextuales t, dynamic c) {
    final chip = _chip(
      '${c['icono'] ?? ''} ${Catalogos.categoria(context, c['codigo'], c['nombre'])}'
          .trim(),
      _filtroCategoriaId == c['categoriaId'],
      () => setState(() => _filtroCategoriaId = c['categoriaId']),
      t,
    );
    // Las globales no responden al mantener pulsado.
    if (c['esGlobal'] != false) return chip;
    // El ChoiceChip no gasta el mantener pulsado, así que le llega al detector.
    return GestureDetector(
      onLongPress: () => _gestionarCategoria(c),
      // MergeSemantics: el chip hace su propio nodo y, sin fundirlos, la acción
      // y su pista quedarían en otro nodo aparte, que el lector no anuncia.
      child: MergeSemantics(
        child: Semantics(
          onLongPress: () => _gestionarCategoria(c),
          onLongPressHint: l.catPistaMantener,
          child: chip,
        ),
      ),
    );
  }

  /// El «+» al final de la fila: abre la hoja de categoría nueva.
  Widget _chipNueva(AppLocalizations l, TokensContextuales t) {
    final id = identidad(context);
    return Semantics(
      button: true,
      label: l.catNuevaEtiqueta,
      excludeSemantics: true,
      onTap: _crearCategoria,
      child: ActionChip(
        label: Icon(LucideIcons.plus, size: 18, color: t.textMuted),
        onPressed: _crearCategoria,
        tooltip: l.catNuevaEtiqueta,
        shape:
            formaIdentidad(
                  id,
                  radio: 999,
                  lado: BorderSide(color: t.textMuted.withValues(alpha: 0.35)),
                )
                as OutlinedBorder,
      ),
    );
  }

  Future<void> _crearCategoria() async {
    final creada = await mostrarHojaCategoria(
      context,
      guardar: HabitosScreen.crearCategoria,
    );
    if (creada != null && mounted) _cargarDatos();
  }

  /// Mantener pulsada una categoría propia: cambiarle el nombre o el emoji, o
  /// borrarla.
  Future<void> _gestionarCategoria(dynamic c) async {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final accion = await showModalBottomSheet<_AccionCategoria>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.pencil, color: t.text),
              title: Text(l.catCambiar),
              onTap: () => Navigator.pop(ctx, _AccionCategoria.cambiar),
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: tonoError(ctx).texto),
              title: Text(
                l.catBorrar,
                style: TextStyle(color: tonoError(ctx).texto),
              ),
              onTap: () => Navigator.pop(ctx, _AccionCategoria.borrar),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;
    switch (accion) {
      case _AccionCategoria.cambiar:
        await _cambiarCategoria(c);
      case _AccionCategoria.borrar:
        await _borrarCategoria(c);
    }
  }

  Future<void> _cambiarCategoria(dynamic c) async {
    final actualizada = await mostrarHojaCategoria(
      context,
      categoria: Map<String, dynamic>.from(c as Map),
      guardar: (nombre, icono) =>
          HabitosScreen.actualizarCategoria(c['categoriaId'], nombre, icono),
    );
    // Los hábitos de la categoría enseñan su nombre: Hoy también se entera.
    if (actualizada != null && mounted) notificarHabitosCambiados();
  }

  Future<void> _borrarCategoria(dynamic c) async {
    final l = AppLocalizations.of(context)!;
    final nombre = Catalogos.categoria(context, c['codigo'], c['nombre']);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: formaIdentidad(identidad(ctx), radio: identidad(ctx).radioHero),
        title: Text(l.catBorrarTitulo(nombre)),
        content: Text(l.catBorrarCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.catBorrar,
              style: TextStyle(color: tonoError(ctx).texto),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await HabitosScreen.borrarCategoria(c['categoriaId']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MensajesError.de(context, e, generico: l.catErrorBorrar),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    // Sus hábitos pasan a «sin categoría»: se recargan categorías y hábitos
    // (esta pantalla y Hoy, por el aviso) y, si el filtro estaba en ella, vuelve
    // a «Todas».
    if (_filtroCategoriaId == c['categoriaId']) {
      setState(() => _filtroCategoriaId = null);
    }
    notificarHabitosCambiados();
  }

  /// Sigue siendo un `ChoiceChip` de Material —el filtrado no se toca— pero con
  /// la figura de la identidad equipada: en Neotokyo+ corta la esquina como
  /// todo lo demás, en Dulce es píldora completa.
  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap,
    TokensContextuales t,
  ) {
    final id = identidad(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: t.primary.withValues(alpha: 0.2),
      shape:
          formaIdentidad(
                id,
                radio: 999,
                lado: BorderSide(
                  color: selected
                      ? t.primary
                      : t.textMuted.withValues(alpha: 0.35),
                ),
              )
              as OutlinedBorder,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? t.primary : t.textMuted,
      ),
    );
  }

  Widget _selectorOrden(AppLocalizations l) {
    return SegmentedButton<_Orden>(
      segments: [
        ButtonSegment(
          value: _Orden.recientes,
          label: Text(l.habitosOrdenRecientes),
        ),
        ButtonSegment(
          value: _Orden.masCumplidos,
          label: Text(l.habitosOrdenMasCumplidos),
        ),
      ],
      selected: {_orden},
      onSelectionChanged: (nuevo) => setState(() => _orden = nuevo.first),
    );
  }

  /// La misma tarjeta de fila que Hoy: el radio, el corte y la sombra los pone
  /// la identidad equipada; aquí sólo se dice que esto es una fila de hábito.
  ///
  /// Sin chip, a diferencia de Hoy: allí el chip lleva la frecuencia, que es la
  /// dimensión de esa pantalla, y aquí la línea de debajo ya dice categoría y
  /// completados en una sola frase traducida (`habitosSubtitulo`). Meterla en
  /// un chip obligaría a partirla en dos textos nuevos para no decir nada más.
  Widget _tarjetaHabito(
    AppLocalizations l,
    Map<String, dynamic> r,
    TokensContextuales t,
  ) {
    final habito = r['habito'] as Habito;
    final total = r['totalCompletados'] as int;

    return TarjetaIdentidad(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HabitoScreen(
              usuarioId: widget.usuarioId,
              habito: habito,
              categoriasIniciales: _categorias,
            ),
          ),
        );
        if (result == true) {
          _cargarDatos();
          notificarHabitosCambiados();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Como en Hoy: color secundario y el mismo tamaño en las tres
            // identidades; se atenúa con el resto si el hábito está en pausa.
            Opacity(
              opacity: habito.activo ? 1.0 : 0.5,
              child: ExcludeSemantics(
                child: Icon(habito.icono, size: 24, color: t.textMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              // Atenuado solo los textos: el botón «Reanudar» tiene que verse
              // a color, si no parece desactivado.
              child: Opacity(
                opacity: habito.activo ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habito.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: t.text),
                    ),
                    if (!habito.activo) ...[
                      const SizedBox(height: 2),
                      Text(
                        l.pausaEnPausa,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: t.primary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      l.habitosSubtitulo(
                        habito.categoriaNombre == null
                            ? l.habSinCategoria
                            : Catalogos.categoria(
                                context,
                                habito.categoriaCodigo,
                                habito.categoriaNombre!,
                              ),
                        total,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: t.textMuted),
                    ),
                    // Una sola línea: esta pantalla es para encontrar un
                    // hábito, no para leerlo. Quien quiera más entra al
                    // detalle. Si no hay descripción no se reserva espacio.
                    if ((habito.descripcion ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habito.descripcion!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: t.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Con el nombre en la etiqueta: hay varios «Pausar» en la pantalla.
            if (habito.activo)
              Semantics(
                button: true,
                label: l.pausaTitulo(habito.nombre),
                excludeSemantics: true,
                child: TextButton(
                  onPressed: _pausando == habito.habitoId
                      ? null
                      : () => _pausar(habito),
                  child: Text(l.pausaAccion),
                ),
              )
            else
              TextButton(
                onPressed: _reanudando == habito.habitoId
                    ? null
                    : () => _reanudar(habito),
                child: Text(l.pausaReanudar),
              ),
          ],
        ),
      ),
    );
  }
}

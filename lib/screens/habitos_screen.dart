import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../l10n/catalogos.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';
import '../widgets/identidad_ui.dart';
import 'habito_screen.dart';

enum _Orden { recientes, masCumplidos }

class HabitosScreen extends StatefulWidget {
  final int usuarioId;
  const HabitosScreen({super.key, required this.usuarioId});

  @override
  State<HabitosScreen> createState() => _HabitosScreenState();
}

class _HabitosScreenState extends State<HabitosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _resumen = []; // {habito: Habito, totalCompletados: int}
  List<dynamic> _categorias = [];
  int? _filtroCategoriaId; // null = todas
  _Orden _orden = _Orden.recientes;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final resultados = await Future.wait([
        ApiServiceHabitos.getResumenHabitos(widget.usuarioId),
        ApiServiceHabitos.getCategoriasUsuario(widget.usuarioId),
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

  Future<void> _activar(int habitoId) async {
    try {
      await ApiServiceHabitos.activarHabito(habitoId);
      _cargarDatos();
    } catch (e) {
      _avisarError(e);
    }
  }

  Future<void> _desactivar(int habitoId) async {
    try {
      await ApiServiceHabitos.desactivarHabito(habitoId);
      _cargarDatos();
    } catch (e) {
      _avisarError(e);
    }
  }

  void _avisarError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(MensajesError.de(context, e,
            generico: AppLocalizations.of(context)!.habitosErrorEstado)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtradosYOrdenados {
    var lista = _filtroCategoriaId == null
        ? _resumen
        : _resumen
            .where((r) => (r['habito'] as Habito).categoriaId == _filtroCategoriaId)
            .toList();

    lista = List.of(lista);
    if (_orden == _Orden.recientes) {
      lista.sort((a, b) =>
          (b['habito'] as Habito).habitoId.compareTo((a['habito'] as Habito).habitoId));
    } else {
      lista.sort((a, b) =>
          (b['totalCompletados'] as int).compareTo(a['totalCompletados'] as int));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HabitoScreen(
              usuarioId: widget.usuarioId,
              categoriasIniciales: _categorias,
              nombresHabitosExistentes: _resumen.map((r) => (r['habito'] as Habito).nombre).toList(),
            )),
          );
          if (result == true) _cargarDatos();
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
                  child: Text(l.habitosSinFiltro,
                      style: TextStyle(color: t.textMuted)),
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
          _chip(l.habitosTodas, _filtroCategoriaId == null, () => setState(() => _filtroCategoriaId = null), t),
          for (final c in _categorias)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(
                '${c['icono'] ?? ''} ${Catalogos.categoria(context, c['codigo'], c['nombre'])}'.trim(),
                _filtroCategoriaId == c['categoriaId'],
                () => setState(() => _filtroCategoriaId = c['categoriaId']),
                t,
              ),
            ),
        ],
      ),
    );
  }

  /// Sigue siendo un `ChoiceChip` de Material —el filtrado no se toca— pero con
  /// la figura de la identidad equipada: en Neotokyo+ corta la esquina como
  /// todo lo demás, en Dulce es píldora completa.
  Widget _chip(String label, bool selected, VoidCallback onTap, TokensContextuales t) {
    final id = identidad(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: t.primary.withValues(alpha: 0.2),
      shape: formaIdentidad(
        id,
        radio: 999,
        lado: BorderSide(
          color: selected
              ? t.primary
              : t.textMuted.withValues(alpha: 0.35),
        ),
      ) as OutlinedBorder,
      labelStyle: TextStyle(
          color: selected ? t.primary : t.textMuted, fontWeight: FontWeight.w600),
    );
  }

  Widget _selectorOrden(AppLocalizations l) {
    return SegmentedButton<_Orden>(
      segments: [
        ButtonSegment(value: _Orden.recientes, label: Text(l.habitosOrdenRecientes)),
        ButtonSegment(value: _Orden.masCumplidos, label: Text(l.habitosOrdenMasCumplidos)),
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
  Widget _tarjetaHabito(AppLocalizations l, Map<String, dynamic> r, TokensContextuales t) {
    final habito = r['habito'] as Habito;
    final total = r['totalCompletados'] as int;

    return Opacity(
      opacity: habito.activo ? 1.0 : 0.5,
      child: TarjetaIdentidad(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HabitoScreen(usuarioId: widget.usuarioId, habito: habito, categoriasIniciales: _categorias)),
          );
          if (result == true) _cargarDatos();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habito.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: t.text)),
                    const SizedBox(height: 4),
                    Text(
                      l.habitosSubtitulo(
                        habito.categoriaNombre == null
                            ? l.habSinCategoria
                            : Catalogos.categoria(context,
                                habito.categoriaCodigo, habito.categoriaNombre!),
                        total,
                      ),
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: habito.activo,
                onChanged: (v) => v ? _activar(habito.habitoId) : _desactivar(habito.habitoId),
                activeThumbColor: t.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
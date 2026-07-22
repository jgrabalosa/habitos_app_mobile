import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import 'habito_screen.dart';
import '../widgets/skeleton.dart';

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
        ApiService.getResumenHabitos(widget.usuarioId),
        ApiService.getCategoriasUsuario(widget.usuarioId),
      ]);
      setState(() {
        _resumen = resultados[0] as List<Map<String, dynamic>>;
        _categorias = resultados[1] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _activar(int habitoId) async {
    await ApiService.activarHabito(habitoId);
    _cargarDatos();
  }

  Future<void> _desactivar(int habitoId) async {
    await ApiService.desactivarHabito(habitoId);
    _cargarDatos();
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

    if (_loading) {
      return const SkeletonLista();
    }

    final lista = _filtradosYOrdenados;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HabitoScreen(usuarioId: widget.usuarioId, categoriasIniciales: _categorias)),
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
            _filtrosCategoria(t),
            const SizedBox(height: 12),
            _selectorOrden(),
            const SizedBox(height: 16),
            if (lista.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text('No hay hábitos con este filtro',
                      style: TextStyle(color: t.textMuted)),
                ),
              )
            else
              ...lista.map((r) => _tarjetaHabito(r, t)),
          ],
        ),
      ),
    );
  }

  Widget _filtrosCategoria(TokensContextuales t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Todas', _filtroCategoriaId == null, () => setState(() => _filtroCategoriaId = null), t),
          for (final c in _categorias)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(
                '${c['icono'] ?? ''} ${c['nombre']}'.trim(),
                _filtroCategoriaId == c['categoriaId'],
                () => setState(() => _filtroCategoriaId = c['categoriaId']),
                t,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, TokensContextuales t) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: t.primary.withOpacity(0.2),
      labelStyle: TextStyle(
          color: selected ? t.primary : t.textMuted, fontWeight: FontWeight.w600),
    );
  }

  Widget _selectorOrden() {
    return SegmentedButton<_Orden>(
      segments: const [
        ButtonSegment(value: _Orden.recientes, label: Text('Recientes')),
        ButtonSegment(value: _Orden.masCumplidos, label: Text('Más cumplidos')),
      ],
      selected: {_orden},
      onSelectionChanged: (nuevo) => setState(() => _orden = nuevo.first),
    );
  }

  Widget _tarjetaHabito(Map<String, dynamic> r, TokensContextuales t) {
    final habito = r['habito'] as Habito;
    final total = r['totalCompletados'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: habito.activo ? 1.0 : 0.5,
        child: ListTile(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HabitoScreen(usuarioId: widget.usuarioId, habito: habito, categoriasIniciales: _categorias)),
            );
            if (result == true) _cargarDatos();
          },
          title: Text(habito.nombre,
              style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
          subtitle: Text(
            '${habito.categoriaNombre ?? 'Sin categoría'} · $total completados',
            style: TextStyle(color: t.textMuted, fontSize: 12),
          ),
          trailing: Switch(
            value: habito.activo,
            onChanged: (v) => v ? _activar(habito.habitoId) : _desactivar(habito.habitoId),
            activeColor: t.primary,
          ),
        ),
      ),
    );
  }
}
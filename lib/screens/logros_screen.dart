import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/catalogos.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton.dart';

class LogrosScreen extends StatefulWidget {
  final int usuarioId;
  const LogrosScreen({super.key, required this.usuarioId});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  bool _loading = true;
  int _saldo = 0;
  List<dynamic> _catalogo = [];
  Set<int> _idsConseguidos = {};

  static const iconosCategoria = {
    'Inicio': '🌱',
    'Constancia': '🔥',
    'Volumen': '📊',
    'Variedad': '🎨',
    'Exploración': '🧭',
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final saldo = await ApiService.getSaldoPuntos(widget.usuarioId);
      final catalogo = await ApiService.getCatalogoLogros();
      final conseguidos = await ApiService.getLogrosUsuario(widget.usuarioId);

      final ids = conseguidos.map<int>((ul) => ul['logro']['logroId'] as int).toSet();

      setState(() {
        _saldo = saldo;
        _catalogo = catalogo;
        _idsConseguidos = ids;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final total = _catalogo.length;
    final conseguidos = _idsConseguidos.length;
    final pct = total > 0 ? conseguidos / total : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l.logrosTitulo)),
      body: _loading
          ? _skeletonLogros()
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Saldo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(LucideIcons.coins, color: t.points, size: 40),
                          const SizedBox(height: 8),
                          Text('$_saldo',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800, color: t.text)),
                          Text(l.puntos, style: TextStyle(color: t.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progreso global
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.detLogrosDe(conseguidos, total),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                              Text(l.logrosPorcentaje((pct * 100).round()),
                                  style: TextStyle(color: t.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 10,
                              backgroundColor: t.surface2,
                              valueColor: AlwaysStoppedAnimation(t.points),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l.logrosSeccion,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                  const SizedBox(height: 8),
                  ..._catalogo.map((logro) => _logroCard(l, logro, t)),
                ],
              ),
            ),
    );
  }

  Widget _logroCard(AppLocalizations l, dynamic logro, TokensContextuales t) {
    final conseguido = _idsConseguidos.contains(logro['logroId']);
    final icono = iconosCategoria[logro['categoria']] ?? '⭐';
    return Opacity(
      opacity: conseguido ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Text(conseguido ? '🏆' : '🔒', style: const TextStyle(fontSize: 24)),
          title: Text('$icono ${Catalogos.logro(context, logro['codigo'], logro['nombre'])}',
              style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
          subtitle: Text(
              '${logro['descripcion']}\n${logro['categoria']} · ${logro['nivel']}',
              style: TextStyle(color: t.textMuted)),
          isThreeLine: true,
          trailing: Text(l.logrosPuntos(logro['puntos'] as int),
              style: TextStyle(color: t.textMuted)),
        ),
      ),
    );
  }

  Widget _skeletonLogros() {
    return SkeletonPulso(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de saldo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  SkeletonBox(width: 40, height: 40, radius: 20),
                  SizedBox(height: 12),
                  SkeletonBox(width: 80, height: 24),
                  SizedBox(height: 6),
                  SkeletonBox(width: 50, height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 12),
                  SkeletonBox(height: 10, radius: 999),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: 80, height: 18),
          const SizedBox(height: 8),
          ...List.generate(5, (_) => const SkeletonCard(height: 76)),
        ],
      ),
    );
  }
}
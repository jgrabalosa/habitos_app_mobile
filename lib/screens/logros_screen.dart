import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _saldoCard(),
                  const SizedBox(height: 16),
                  const Text('Logros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._catalogo.map((logro) => _logroCard(logro)),
                ],
              ),
            ),
    );
  }

  Widget _saldoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            Text('$_saldo',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('puntos', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _logroCard(dynamic logro) {
    final conseguido = _idsConseguidos.contains(logro['logroId']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: conseguido ? 1.0 : 0.5,
        child: ListTile(
          leading: Text(conseguido ? '🏆' : '🔒', style: const TextStyle(fontSize: 24)),
          title: Text(logro['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${logro['descripcion']}\n${logro['categoria']} · ${logro['nivel']}'),
          isThreeLine: true,
          trailing: Text('+${logro['puntos']} pts',
              style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
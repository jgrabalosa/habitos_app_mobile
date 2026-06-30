import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import 'login_screen.dart';
import 'habito_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Habito> _habitos = [];
  Map<int, bool> _completados = {};
  bool _loading = true;
  String _nombre = '';
  int _usuarioId = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await ApiService.getUsuarioLocal();
    if (usuario == null) return;
    setState(() {
      _nombre = usuario['nombre'] ?? '';
      _usuarioId = usuario['usuarioId'] ?? 0;
    });
    await _cargarHabitos();
  }

  Future<void> _cargarHabitos() async {
    try {
      final habitos = await ApiService.getHabitosActivos(_usuarioId);
      final Map<int, bool> completados = {};
      for (var h in habitos) {
        completados[h.habitoId] = await ApiService.estaCompletadoHoy(h.habitoId);
      }
      setState(() {
        _habitos = habitos;
        _completados = completados;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _completar(int habitoId) async {
    if (_completados[habitoId] == true) return;
    await ApiService.completarHabito(habitoId);
    setState(() { _completados[habitoId] = true; });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _habitos.length;
    final completados = _completados.values.where((v) => v).length;
    final pendientes = total - completados;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Hola, $_nombre 👋',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _logout,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarHabitos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Estadísticas
                  Row(
                    children: [
                      _statCard('Total', total.toString(), Colors.blue),
                      const SizedBox(width: 8),
                      _statCard('Completados', completados.toString(), Colors.green),
                      const SizedBox(width: 8),
                      _statCard('Pendientes', pendientes.toString(), Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Hábitos de hoy',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_habitos.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No tienes hábitos activos')),
                      ),
                    )
                  else
                    ..._habitos.map((h) => _habitoCard(h)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4a6cf7),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitoScreen(usuarioId: _usuarioId),
            ),
          );
          if (result == true) _cargarHabitos();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

    Widget _habitoCard(Habito h) {
      final completado = _completados[h.habitoId] ?? false;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitoScreen(usuarioId: _usuarioId, habito: h),
              ),
            );
            if (result == true) _cargarHabitos();
          },
          leading: Icon(
            completado ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completado ? Colors.green : Colors.grey,
            size: 32,
          ),
          title: Text(h.nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: completado ? TextDecoration.lineThrough : null,
                color: completado ? Colors.grey : Colors.black,
              )),
          subtitle: h.categoriaNombre != null ? Text(h.categoriaNombre!) : null,
          trailing: completado
              ? const Text('✅', style: TextStyle(fontSize: 20))
              : ElevatedButton(
                  onPressed: () => _completar(h.habitoId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4a6cf7),
                  ),
                  child: const Text('Completar',
                      style: TextStyle(color: Colors.white)),
                ),
        ),
      );
    }
  }

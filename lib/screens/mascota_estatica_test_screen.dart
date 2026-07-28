import 'package:flutter/material.dart';

/// Los tres estados de la etapa "huevo". El nombre del valor es el mismo
/// sufijo que lleva el fichero, para que la ruta salga sola.
enum EstadoNori { sonriente, triste, dormido }

/// Prueba minima de la mascota con imagenes estaticas: solo la etapa huevo,
/// para ver como sienta la transicion antes de generalizar a las demas.
/// Pantalla temporal, no entra en el flujo de la app.
class MascotaEstaticaTestScreen extends StatefulWidget {
  const MascotaEstaticaTestScreen({super.key});

  @override
  State<MascotaEstaticaTestScreen> createState() =>
      _MascotaEstaticaTestScreenState();
}

class _MascotaEstaticaTestScreenState extends State<MascotaEstaticaTestScreen> {
  EstadoNori _estado = EstadoNori.sonriente;

  String get _asset => 'assets/mascota/Nori_huevo_${_estado.name}.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nori — huevo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                // Entra creciendo un poco: sin esto el cambio se lee como un
                // corte, no como que la mascota reacciona.
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: Image.asset(
                _asset,
                // La Key es lo que hace que AnimatedSwitcher vea un hijo nuevo.
                // Sin ella cambia el src y no hay transicion.
                key: ValueKey(_estado),
                width: 250,
                height: 250,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final estado in EstadoNori.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _estado = estado),
                      child: Text(_etiqueta(estado)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _etiqueta(EstadoNori estado) => switch (estado) {
        EstadoNori.sonriente => 'Sonriente',
        EstadoNori.triste => 'Triste',
        EstadoNori.dormido => 'Dormido',
      };
}

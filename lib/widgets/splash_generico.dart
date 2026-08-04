import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Splash genérico y exportable al ecosistema Norday: fondo Azul Noche +
/// símbolo + wordmark, con una duración mínima y la posibilidad de esperar
/// una tarea real (sesión, tema...). El punto 6.5 (Estados de carga) ampliará
/// `tarea` para que también espere los datos del Dashboard.
class SplashGenerico<T> extends StatefulWidget {
  final String rutaImagen;
  final Color colorFondo;
  final Duration duracionMinima;
  final Future<T> Function() tarea;
  final void Function(BuildContext context, T resultado) onListo;
  final String? wordmark;

  /// Ancho del símbolo en dp. Cada app del ecosistema tiene su propio
  /// logo, así que el tamaño es del consumidor, no del motor.
  final double anchoImagen;

  /// Tamaño de fuente del wordmark en dp, acompañando a [anchoImagen].
  final double tamanoWordmark;

  const SplashGenerico({
    super.key,
    required this.rutaImagen,
    required this.colorFondo,
    required this.tarea,
    required this.onListo,
    this.duracionMinima = const Duration(milliseconds: 1200),
    this.wordmark,
    this.anchoImagen = 180,
    this.tamanoWordmark = 26,
  });

  @override
  State<SplashGenerico<T>> createState() => _SplashGenericoState<T>();
}

class _SplashGenericoState<T> extends State<SplashGenerico<T>> {
  @override
  void initState() {
    super.initState();
    _ejecutar();
  }

  Future<void> _ejecutar() async {
    final inicio = DateTime.now();
    final resultado = await widget.tarea();
    final transcurrido = DateTime.now().difference(inicio);
    final restante = widget.duracionMinima - transcurrido;
    if (restante > Duration.zero) {
      await Future.delayed(restante);
    }
    if (mounted) widget.onListo(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.colorFondo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(widget.rutaImagen, width: widget.anchoImagen),
            if (widget.wordmark != null) ...[
              const SizedBox(height: 20),
              Text(
                widget.wordmark!,
                style: GoogleFonts.manrope(
                  fontSize: widget.tamanoWordmark,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
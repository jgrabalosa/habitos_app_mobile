import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import 'selector_avatar_gratis.dart';

/// Mini-onboarding de 3 pasos tras un alta nueva. Mismo patrón visual que
/// CelebracionService (showGeneralDialog + transición), pero no se puede
/// cerrar tocando fuera ni con el botón atrás — solo avanza tocando
/// "Siguiente", o eligiendo un avatar en el último paso.
class OnboardingOverlay {
  static Future<void> mostrar(BuildContext context, {required int usuarioId}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _OnboardingContent(usuarioId: usuarioId),
      transitionBuilder: (context, anim, anim2, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curva, child: child),
        );
      },
    );
  }
}

class _OnboardingContent extends StatefulWidget {
  final int usuarioId;
  const _OnboardingContent({required this.usuarioId});

  @override
  State<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<_OnboardingContent> {
  static const _totalPasos = 3;
  int _paso = 0;

  void _siguiente() => setState(() => _paso++);

  Future<void> _alElegirAvatar(String codigo) async {
    // Breve pausa de confirmación visual antes de cerrar el overlay.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                // SingleChildScrollView se ajusta al tamaño real del contenido
                // (como antes) mientras quepa en el maxHeight de arriba; solo si
                // no cabe, hace scroll en vez de desbordar.
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _indicadorProgreso(t),
                      const SizedBox(height: 20),
                      _contenidoPaso(t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicadorProgreso(TokensContextuales t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPasos, (i) {
        final activo = i == _paso;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? t.primary : t.surface2,
          ),
        );
      }),
    );
  }

  Widget _contenidoPaso(TokensContextuales t) {
    switch (_paso) {
      case 0:
        return _paso1(t);
      case 1:
        return _paso2(t);
      default:
        return _paso3(t);
    }
  }

  Widget _paso1(TokensContextuales t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.coins, size: 56, color: t.points),
        const SizedBox(height: 16),
        Text('¡Bienvenido a Norday! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text)),
        const SizedBox(height: 12),
        Text(
          'Cada hábito que completes te da puntos. Úsalos para desbloquear '
          'avatares, temas y más en la tienda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 24),
        _botonSiguiente(),
      ],
    );
  }

  Widget _paso2(TokensContextuales t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Lottie.asset('assets/animations/mascota_placeholder.json'),
        ),
        const SizedBox(height: 16),
        Text('Tu compañero crece contigo 🐣',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text)),
        const SizedBox(height: 12),
        Text(
          'Tienes una mascota que sube de nivel cada vez que completas un '
          'hábito. Cuídala y mira cómo evoluciona.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 24),
        _botonSiguiente(),
      ],
    );
  }

  Widget _paso3(TokensContextuales t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Elige tu primer avatar, ¡es gratis! 👇',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.text)),
        const SizedBox(height: 8),
        Text(
          'Podrás cambiarlo cuando quieras desde la Colección.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 16),
        SelectorAvatarGratis(usuarioId: widget.usuarioId, onElegido: _alElegirAvatar),
      ],
    );
  }

  Widget _botonSiguiente() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _siguiente,
        child: const Text('Siguiente'),
      ),
    );
  }
}
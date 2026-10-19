import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';

/// La bienvenida del alta nueva: una sola tarjeta con Nori en huevo, la
/// promesa, el sonido y el botón que lleva al primer hábito.
///
/// No se cierra tocando fuera ni con el botón atrás: el único camino es el
/// botón, que es el que empieza a crear el hábito.
class Bienvenida {
  static Future<void> mostrar(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const _BienvenidaContenido(),
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

class _BienvenidaContenido extends StatefulWidget {
  const _BienvenidaContenido();

  @override
  State<_BienvenidaContenido> createState() => _BienvenidaContenidoState();
}

class _BienvenidaContenidoState extends State<_BienvenidaContenido> {
  bool _sonidoActivado = SonidoService.activado;

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final tema = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: SuperficieIdentidad(
                    protagonista: true,
                    relleno: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          assetMascota(fase: 'huevo', estado: 'feliz'),
                          package: 'norday_flutter_core',
                          height: 112,
                          width: 112,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.bienvenidaTitulo,
                          textAlign: TextAlign.center,
                          style: tema.headlineMedium?.copyWith(color: t.text),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.bienvenidaCuerpo,
                          textAlign: TextAlign.center,
                          style: tema.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        // Su propio Material: el ListTile pinta el toque sobre el
                        // Material más cercano, y la tarjeta le tapa el suyo.
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              _sonidoActivado
                                  ? LucideIcons.volume2
                                  : LucideIcons.volumeX,
                              color: t.primaryTrazo,
                            ),
                            title: Text(
                              NordayCoreLocalizations.of(context)!.sonido,
                            ),
                            subtitle: Text(l.bienvenidaSonido),
                            value: _sonidoActivado,
                            onChanged: (v) async {
                              setState(() => _sonidoActivado = v);
                              await SonidoService.establecerActivado(v);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l.bienvenidaCrear),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

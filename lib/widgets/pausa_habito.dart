import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/habitos_refresh.dart';
import '../services/pausa.dart';

/// Las dos llamadas de red de la pausa. En producción van al backend; en los
/// tests se cambian por un falso.
class PausaHabito {
  PausaHabito._();

  @visibleForTesting
  static Future<List<dynamic>> Function(int usuarioId) inventario =
      ApiServiceCore.getInventarioProductos;

  @visibleForTesting
  static Future<void> Function(int habitoId) desactivar =
      ApiServiceHabitos.desactivarHabito;
}

enum _AccionPausa { pausar, tienda }

/// Pausa un hábito desde cualquier pantalla que lo muestre. Pausar gasta una
/// «Pausa»: la ventana enseña cuántas quedan y, sin ninguna, lleva a la tienda.
///
/// Devuelve true si el hábito quedó pausado. Quien lo llama no tiene que
/// recargar nada: la lista y Hoy se recargan por el aviso de hábitos cambiados.
Future<bool> pausarHabito(
  BuildContext context, {
  required int usuarioId,
  required int habitoId,
  required String nombre,
}) async {
  final l = AppLocalizations.of(context)!;

  final int pausas;
  try {
    pausas = pausasEn(await PausaHabito.inventario(usuarioId));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e, generico: l.pausaError)),
        ),
      );
    }
    return false;
  }
  if (!context.mounted) return false;

  final accion = await showDialog<_AccionPausa>(
    context: context,
    builder: (context) => AlertDialog(
      shape: formaIdentidad(
        identidad(context),
        radio: identidad(context).radioHero,
      ),
      title: Text(l.pausaTitulo(nombre)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pausaCuerpo),
          const SizedBox(height: 12),
          Text(
            pausas > 0 ? l.pausaTienes(pausas) : l.pausaSinPausas,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelar),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            pausas > 0 ? _AccionPausa.pausar : _AccionPausa.tienda,
          ),
          child: Text(pausas > 0 ? l.pausaBotonPausar : l.pausaBotonTienda),
        ),
      ],
    ),
  );
  if (!context.mounted || accion == null) return false;

  if (accion == _AccionPausa.tienda) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaScreen(usuarioId: usuarioId)),
    );
    return false;
  }

  try {
    await PausaHabito.desactivar(habitoId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e, generico: l.pausaError)),
        ),
      );
    }
    return false;
  }
  notificarHabitosCambiados();
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.pausaHecha(nombre))));
  }
  return true;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/al_volver.dart';
import 'package:habitos_app_mobile/services/app_refresh.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  test('sube en 1 la señal de refresco de la app', () {
    final antes = appRefreshNotifier.value;
    alVolverAPrimerPlano(0, recargarIdentidad: (_) async => null);
    expect(appRefreshNotifier.value - antes, 1);
  });

  test('sube en 1 la señal de refresco de la mascota', () {
    final antes = refrescoMascotaNotifier.value;
    alVolverAPrimerPlano(0, recargarIdentidad: (_) async => null);
    expect(refrescoMascotaNotifier.value - antes, 1);
  });

  test('recarga la identidad solo con un usuario real', () async {
    final pedidos = <int>[];
    Future<bool?> falso(int id) async {
      pedidos.add(id);
      return true;
    }

    alVolverAPrimerPlano(7, recargarIdentidad: falso);
    await Future<void>.delayed(Duration.zero);
    expect(pedidos, [7]);

    alVolverAPrimerPlano(0, recargarIdentidad: falso);
    await Future<void>.delayed(Duration.zero);
    expect(pedidos, [7]);
  });

  test('dos llamadas seguidas suben cada señal en 2', () {
    final app = appRefreshNotifier.value;
    final mascota = refrescoMascotaNotifier.value;
    alVolverAPrimerPlano(0, recargarIdentidad: (_) async => null);
    alVolverAPrimerPlano(0, recargarIdentidad: (_) async => null);
    expect(appRefreshNotifier.value - app, 2);
    expect(refrescoMascotaNotifier.value - mascota, 2);
  });
}

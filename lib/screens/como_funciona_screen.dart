import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';

/// Los apartados de «Cómo funciona». [id] es lo que se mide
/// (`como_funciona_<id>` en `ayuda_abierta`) y lo que usará «Saber más» de los
/// «?» para abrir la pantalla con un apartado ya desplegado.
enum ApartadoComoFunciona {
  hoy('hoy'),
  diarios('diarios_semanales'),
  ritmo('ritmo'),
  puntos('puntos'),
  nori('nori'),
  tienda('tienda');

  const ApartadoComoFunciona(this.id);

  final String id;

  /// El valor de `ayuda` del evento.
  String get idMedicion => 'como_funciona_$id';

  String titulo(AppLocalizations l) => switch (this) {
    hoy => l.comoFuncionaHoyTitulo,
    diarios => l.comoFuncionaDiariosTitulo,
    ritmo => l.comoFuncionaRitmoTitulo,
    puntos => l.comoFuncionaPuntosTitulo,
    nori => l.comoFuncionaNoriTitulo,
    tienda => l.comoFuncionaTiendaTitulo,
  };

  String cuerpo(AppLocalizations l) => switch (this) {
    hoy => l.comoFuncionaHoyCuerpo,
    diarios => l.comoFuncionaDiariosCuerpo,
    ritmo => l.comoFuncionaRitmoCuerpo,
    puntos => l.comoFuncionaPuntosCuerpo,
    nori => l.comoFuncionaNoriCuerpo,
    tienda => l.comoFuncionaTiendaCuerpo,
  };
}

/// Si el usuario tiene algún hábito. Por defecto, del backend.
typedef CargarHayHabitos = Future<bool> Function(int usuarioId);

Future<bool> _hayHabitosEnBackend(int usuarioId) async =>
    (await ApiServiceHabitos.getResumenHabitos(usuarioId)).isNotEmpty;

Future<void> _medirApartado(String id) => AnalyticsCore.ayudaAbierta(id);

/// «Cómo funciona»: las reglas de Norday en seis apartados que se despliegan
/// (uno abierto a la vez), y, abajo, «Ver otra vez la pista».
///
/// Las cifras de los textos salen del backend (`ParametrosPremio`,
/// `MascotaService`): si cambian allí, se cambian en los `comoFunciona…` de
/// los `app_*.arb`.
class ComoFuncionaScreen extends StatefulWidget {
  final int usuarioId;

  /// El apartado que arranca desplegado, o `null` para ninguno.
  final ApartadoComoFunciona? abierto;

  /// Vuelve a Hoy y lanza la pista del primer hábito. Sin él, o sin hábitos,
  /// el botón no sale. Lo llama la pantalla después de cerrarse.
  final VoidCallback? alVerPista;

  final CargarHayHabitos cargarHayHabitos;

  /// Cómo se mide un apartado al desplegarlo. Por defecto, Analytics.
  final Future<void> Function(String id) medir;

  const ComoFuncionaScreen({
    super.key,
    required this.usuarioId,
    this.abierto,
    this.alVerPista,
    this.cargarHayHabitos = _hayHabitosEnBackend,
    this.medir = _medirApartado,
  });

  @override
  State<ComoFuncionaScreen> createState() => _ComoFuncionaScreenState();
}

class _ComoFuncionaScreenState extends State<ComoFuncionaScreen> {
  ApartadoComoFunciona? _abierto;
  bool _hayHabitos = false;

  @override
  void initState() {
    super.initState();
    _abierto = widget.abierto;
    if (widget.alVerPista != null) _comprobarHabitos();
  }

  Future<void> _comprobarHabitos() async {
    var hay = false;
    try {
      hay = await widget.cargarHayHabitos(widget.usuarioId);
    } catch (e) {
      // Sin red no se sabe: mejor sin botón que una pista sin hábito.
      debugPrint('Cómo funciona: no se pudo saber si hay hábitos: $e');
    }
    if (mounted && hay) setState(() => _hayHabitos = true);
  }

  void _alternar(ApartadoComoFunciona a) {
    final abre = _abierto != a;
    setState(() => _abierto = abre ? a : null);
    if (abre) widget.medir(a.idMedicion);
  }

  void _verPista() {
    final alVerPista = widget.alVerPista;
    Navigator.pop(context);
    if (alVerPista != null) {
      // Cuando Hoy ya está a la vista.
      WidgetsBinding.instance.addPostFrameCallback((_) => alVerPista());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.comoFuncionaTitulo)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: FondoIdentidad()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: NoriVestida(
                    fase: 'cria',
                    estado: 'exultante',
                    tamano: 96,
                    prendas: prendasEquipadasNotifier,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final a in ApartadoComoFunciona.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _Apartado(
                      apartado: a,
                      abierto: _abierto == a,
                      alPulsar: () => _alternar(a),
                    ),
                  ),
                if (widget.alVerPista != null && _hayHabitos) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _verPista,
                      icon: const Icon(LucideIcons.lightbulb),
                      label: Text(l.comoFuncionaVerPista),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Apartado extends StatelessWidget {
  final ApartadoComoFunciona apartado;
  final bool abierto;
  final VoidCallback alPulsar;

  const _Apartado({
    required this.apartado,
    required this.abierto,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final id = identidad(context);
    final tema = Theme.of(context).textTheme;
    final reducir = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(id.radioSecundario),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        expanded: abierto,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: alPulsar,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        apartado.titulo(l),
                        style: tema.titleMedium?.copyWith(color: t.text),
                      ),
                    ),
                    Icon(
                      abierto ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 20,
                      color: t.points,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: reducir
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: abierto
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Text(
                        apartado.cuerpo(l),
                        style: tema.bodyMedium?.copyWith(color: t.text),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../widgets/pausa_habito.dart';
import '../services/descubrimiento_detalle.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/textos_minutos.dart';
import '../l10n/textos_objetivo.dart';
import '../models/habito.dart';
import '../models/hoy.dart';
import '../models/minutos.dart';
import '../models/objetivo_programado.dart';
import '../models/ritmo_reciente.dart';
import '../widgets/estrellas_registro.dart';
import '../widgets/panel_ritmo.dart';
import '../widgets/identidad_ui.dart';
import '../widgets/resumen_detalle.dart';
import 'habito_screen.dart';

class HabitoDetalleScreen extends StatefulWidget {
  final int habitoId;
  final int usuarioId;
  final String? nombre; // para el Hero: título visible desde el primer frame

  /// Llega por parámetro porque `HabitoDetalleDTO` no la trae: quien abre
  /// esta pantalla ya tiene el hábito entero en la mano.
  final String? descripcion;

  /// Día del alta. Igual que `descripcion`: no la trae el DTO del detalle.
  final DateTime? fechaInicio;
  const HabitoDetalleScreen({
    super.key,
    required this.habitoId,
    required this.usuarioId,
    this.nombre,
    this.descripcion,
    this.fechaInicio,
  });

  @override
  State<HabitoDetalleScreen> createState() => _HabitoDetalleScreenState();
}

class _HabitoDetalleScreenState extends State<HabitoDetalleScreen> {
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, dynamic>? _diaSeleccionado; // día tocado en el heatmap (tooltip)
  bool _pausando = false;

  @override
  void initState() {
    super.initState();
    // Basta con entrar una vez para que el chevron de Hoy deje de empujar.
    marcarDetalleDescubierto();
    _cargarDetalle();
  }

  /// La del backend en cuanto llega, para que se refresque al volver de
  /// editar; mientras tanto, o si el backend aún no la manda, la que trajo la
  /// pantalla.
  String? get _descripcion =>
      _detalle != null && _detalle!.containsKey('descripcion')
      ? _detalle!['descripcion'] as String?
      : widget.descripcion;

  Future<void> _cargarDetalle() async {
    setState(() {
      _loading = true;
    });
    try {
      final mesParam =
          '${_mesActual.year}-${_mesActual.month.toString().padLeft(2, '0')}';
      final detalle = await ApiServiceHabitos.getHabitoDetalle(
        widget.habitoId,
        mes: mesParam,
      );
      if (!mounted) return;
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MensajesError.de(
              context,
              e,
              generico: AppLocalizations.of(context)!.detErrorCargarDetalle,
            ),
          ),
        ),
      );
    }
  }

  bool get _esMinutos =>
      _detalle != null && unidadDe(_detalle!['unidad']) == UnidadHabito.minutos;

  int? get _minutosObjetivo => (_detalle?['minutosObjetivo'] as num?)?.toInt();

  /// El hábito tal como está hoy, con lo que trae el detalle: es contra lo
  /// que se compara el cambio programado para decir solo lo que cambia.
  Habito _habitoDelDetalle() => Habito(
    habitoId: widget.habitoId,
    nombre: (_detalle!['nombre'] as String?) ?? widget.nombre ?? '',
    frecuencia: (_detalle!['frecuencia'] as String?) ?? 'DIARIO',
    meta: (_detalle!['meta'] as num?)?.toInt() ?? 1,
    activo: true,
    diasSemana: _detalle!['diasSemana'] as String?,
    unidad: unidadDe(_detalle!['unidad']),
    minutosObjetivo: _minutosObjetivo,
  );

  Future<void> _abrirEdicion() async {
    try {
      final Habito habito = await ApiServiceHabitos.getHabito(widget.habitoId);
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HabitoScreen(
            usuarioId: widget.usuarioId,
            habito: habito,
            objetivoProgramado: ObjetivoProgramado.deJson(
              _detalle?['objetivoProgramado'],
            ),
          ),
        ),
      );
      if (result == true) _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MensajesError.de(
                context,
                e,
                generico: AppLocalizations.of(context)!.detErrorCargar,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Pausar desde el icono de la barra: la misma ventana que en la lista de
  /// Hábitos. Si el hábito queda en pausa, se vuelve a Hoy, donde ya no sale.
  Future<void> _abrirPausa() async {
    final nombre = (_detalle?['nombre'] as String?) ?? widget.nombre ?? '';
    setState(() => _pausando = true);
    final pausado = await pausarHabito(
      context,
      usuarioId: widget.usuarioId,
      habitoId: widget.habitoId,
      nombre: nombre,
    );
    if (!mounted) return;
    if (pausado) {
      Navigator.pop(context);
    } else {
      setState(() => _pausando = false);
    }
  }

  void _cambiarMes(int direccion) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + direccion, 1);
      _diaSeleccionado = null;
    });
    _cargarDetalle();
  }

  bool get _esMesActual {
    final hoy = DateTime.now();
    return _mesActual.year == hoy.year && _mesActual.month == hoy.month;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // El Hero envuelve al condicional del texto
        title: Hero(
          tag: 'habito-nombre-${widget.habitoId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              _detalle != null ? _detalle!['nombre'] : (widget.nombre ?? ''),
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        elevation: 1,
        actions: [
          if (_detalle != null)
            IconButton(
              icon: const Icon(LucideIcons.pause),
              tooltip: l.pausaTooltip,
              // Desactivado mientras pausa: un segundo toque no gasta otra.
              onPressed: _pausando ? null : _abrirPausa,
            ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: l.habTituloEditar,
            onPressed: _abrirEdicion,
          ),
        ],
      ),
      // Los últimos registros quedaban debajo de los botones de Android.
      // Arriba ya se encarga el AppBar.
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _detalle == null
            ? Center(child: Text(l.detErrorCargarDetalle))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if ((_descripcion ?? '').trim().isNotEmpty) ...[
                    Text(
                      _descripcion!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens(context).textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildLineaFrecuencia(),
                  _buildObjetivoProgramado(),
                  _buildRitmo(),
                  _buildStatCards(),
                  _buildValoracionMedia(),
                  const SizedBox(height: 16),
                  _buildHeatmap(),
                  const SizedBox(height: 16),
                  _buildUltimosRegistros(),
                  const SizedBox(height: 48),
                ],
              ),
      ),
    );
  }

  Widget _buildLineaFrecuencia() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    final int meta = _detalle!['meta'] ?? 1;
    final String? diasSemana = _detalle!['diasSemana'];

    const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D']; // 1=lunes..7=domingo

    final String texto;
    final minutos = _minutosObjetivo;
    if (_esMinutos && minutos != null) {
      // «Diario · 30 min cada día» o «Semanal · 3 días por semana · 60 min
      // cada día que lo hagas»: nunca «N×X a la semana».
      final locale = Localizations.localeOf(context).toLanguageTag();
      final dias = _habitoDelDetalle().diasPlanificados;
      texto = etiquetaMinutosDetalle(
        l,
        minutos,
        semanal: esDiario
            ? null
            : (dias.isNotEmpty
                  ? diasFijosLegibles(dias, locale)
                  : l.objDiasSemana(meta)),
      );
    } else if (esDiario) {
      texto = textoFrecuenciaVeces(l, diario: true, meta: meta);
    } else if (diasSemana != null && diasSemana.trim().isNotEmpty) {
      // Semanal con días planificados: "Semanal · M · J · S"
      final dias = diasSemana
          .split(',')
          .map((d) => etiquetas[int.parse(d.trim()) - 1])
          .join(' · ');
      texto = l.detSemanalDias(dias);
    } else {
      texto = textoFrecuenciaVeces(l, diario: false, meta: meta);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, size: 14, color: t.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  /// El cambio de objetivo que aún no vale: «Desde el lunes: 4 días por
  /// semana». No sale si no hay ninguno o si el backend no lo manda.
  Widget _buildObjetivoProgramado() {
    final programado = ObjetivoProgramado.deJson(
      _detalle!['objetivoProgramado'],
    );
    if (programado == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.ms),
      child: Row(
        children: [
          Icon(LucideIcons.calendarClock, size: 14, color: t.streakText),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              textoObjetivoProgramado(
                l,
                programado,
                actual: _habitoDelDetalle(),
                hoy: DateTime.now(),
                locale: Localizations.localeOf(context).toLanguageTag(),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.streakText),
            ),
          ),
        ],
      ),
    );
  }

  /// [dia] leído como día de minutos, o null si no lo es: un hábito de
  /// veces, o un día en que este hábito era de veces (sin `minutos`), que se
  /// pinta como siempre.
  DiaCalendarioMinutos? _diaMinutos(Map<String, dynamic> dia) => _esMinutos
      ? leerDiaCalendarioMinutos(dia, objetivoActual: _minutosObjetivo)
      : null;

  /// Las veces de [dia], como siempre se han leído.
  int _vecesDe(Map<String, dynamic> dia) =>
      dia['veces'] ?? (dia['completado'] == true ? 1 : 0);

  /// Lo que lleva el hábito, en dos plazos: siempre («Lo que llevas», que
  /// sólo sube) y este mes. Las dos tarjetas de racha (ahora / récord) salen
  /// con el rediseño de rachas (F4): el ritmo ocupa su sitio, arriba.
  ///
  /// Los iconos son Lucide y ya no emoji, por lo mismo que en la tienda y en
  /// logros: el emoji lo pinta la fuente del sistema y cambia de dibujo, color
  /// y peso entre plataformas, así que no se alinea con la identidad equipada.
  Widget _buildStatCards() {
    // En minutos, el tiempo total que manda el backend. Si no lo manda, la
    // tarjeta de siempre.
    final int? totalMinutos = _esMinutos
        ? (_detalle!['totalMinutos'] as num?)?.toInt()
        : null;
    return ResumenDetalle(
      totalCompletados: ((_detalle!['totalCompletados'] ?? 0) as num).toInt(),
      diasMes: ((_detalle!['completadosMesActual'] ?? 0) as num).toInt(),
      mesActual: _esMesActual,
      totalMinutos: totalMinutos,
    );
  }

  /// El ritmo de este hábito: la palabra, el dibujo de la identidad, la
  /// causa y la frase que lo explica, que también va detrás del «?». No sale
  /// si el backend no lo manda (un backend anterior al rediseño).
  Widget _buildRitmo() {
    final nivel = _detalle!['ritmoNivel'] as int?;
    if (nivel == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final palabra = palabraRitmo(l, nivel);
    final causa = causaRitmo(
      l,
      tendenciaDe(_detalle!['ritmoTendencia']),
      recienEmpezado: esRecienEmpezado(widget.fechaInicio, DateTime.now()),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.detRitmoTitulo,
                    style: texto.labelSmall?.copyWith(
                      color: t.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  AyudaCampo(
                    texto: l.ritmoExplicacionHabito,
                    etiquetaSemantica: l.detAyudaRitmoEtiqueta,
                    superindice: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Semantics(
                container: true,
                label: l.a11yRitmoHabito(palabra),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          palabra,
                          style: texto.titleLarge?.copyWith(
                            color: t.points,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IndicadorNivel(nivel: nivel, tamano: 20),
                    ],
                  ),
                ),
              ),
              if (causa != null) ...[
                const SizedBox(height: 6),
                Text(causa, style: texto.bodyMedium?.copyWith(color: t.text)),
              ],
              const SizedBox(height: 4),
              Text(
                l.ritmoExplicacionHabito,
                style: texto.bodySmall?.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValoracionMedia() {
    final l = AppLocalizations.of(context)!;
    final media = _detalle!['valoracionMedia'];
    if (media == null) return const SizedBox.shrink();

    final t = tokens(context);
    final valor = (media as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Es la misma estrella de la valoración: a lápiz en Dulce y con el
              // icono de siempre en las otras dos identidades.
              const EstrellaValoracion(marcada: true, tamano: 20),
              const SizedBox(width: 6),
              Text(
                valor.toStringAsFixed(1).replaceAll('.', ','),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: t.text),
              ),
              const SizedBox(width: 6),
              Text(
                l.detSatisfaccion,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
              AyudaCampo(
                texto: l.detAyudaSatisfaccion,
                etiquetaSemantica: l.detAyudaSatisfaccionEtiqueta,
                superindice: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final l = AppLocalizations.of(context)!;
    final List<dynamic> heatmap = _detalle!['heatmap'];
    final int meta = _detalle!['meta'] ?? 1;
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    // Los días de veces, con su escalón «a medias» si es un diario de varias.
    // En minutos siempre hay días a medias en la leyenda: los que tienen
    // minutos sin llegar a su objetivo.
    final bool conNivelesVeces = esDiario && meta > 1;
    final bool conNiveles = _esMinutos || conNivelesVeces;

    final primerDia = DateTime.parse(heatmap[0]['fecha']);
    final diaSemana = (primerDia.weekday - 1); // Lunes = 0
    final t = tokens(context);
    final id = identidad(context);

    // El cuarto escalón —meta superada— sale con el rediseño de rachas (F4):
    // pasarse del objetivo no da nada. Quedan vacío, a medias y completo.
    // // El cuarto escalón —meta superada— se mezcla hacia `t.text`, no hacia
    // // negro ni hacia blanco: en Profundidad y Neotokyo+ el texto es claro
    // // sobre fondo oscuro, así que sale MÁS CLARO que el primario; en Dulce y
    // // Alba es oscuro sobre fondo claro, así que sale MÁS OSCURO. La dirección
    // // se corrige sola y no hace falta un token nuevo. Al 50% la separación
    // // frente al primario va de 1.37 (Profundidad) a 2.07 (Dulce).
    // final superada = Color.lerp(t.primary, t.text, 0.5)!;

    // Un día de minutos, con el mismo escalón «a medias» que un diario de
    // varias veces. Si está hecho lo dice el servidor (`completado`, con el
    // objetivo de ese día).
    Color colorDiaMinutos(DiaCalendarioMinutos dia) => switch (dia.nivel) {
      NivelDiaMinutos.vacio => Colors.transparent,
      NivelDiaMinutos.parcial => t.success.withValues(alpha: 0.35),
      NivelDiaMinutos.hecho => t.success,
    };

    Color colorDia(int veces) {
      if (veces == 0) return Colors.transparent;
      if (!conNivelesVeces) return t.success;
      if (veces < meta) return t.success.withValues(alpha: 0.35);
      return t.success;
      // if (veces == meta) return t.success;
      // return superada;
    }

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => _cambiarMes(-1),
                ),
                Text(
                  DateFormat.yMMMM(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(_mesActual),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: _esMesActual ? null : () => _cambiarMes(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Etiquetas de días de la semana
            Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map(
                    (d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: t.textMuted),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: diaSemana + heatmap.length,
              itemBuilder: (context, index) {
                if (index < diaSemana) return const SizedBox();
                final dia = heatmap[index - diaSemana];
                // Un día sin minutos (de veces, o backend anterior) se pinta
                // como un día de veces, aunque el hábito sea hoy de minutos.
                final diaMinutos = _diaMinutos(dia);
                final int veces = _vecesDe(dia);
                final bool lleno = diaMinutos != null
                    ? diaMinutos.nivel != NivelDiaMinutos.vacio
                    : veces > 0;
                final esHoy =
                    dia['fecha'] ==
                    DateTime.now().toIso8601String().split('T')[0];
                final seleccionado = _diaSeleccionado?['fecha'] == dia['fecha'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _diaSeleccionado = seleccionado ? null : dia;
                  }),
                  // La celda es exactamente la misma que la de los diez días de
                  // Hoy: LED con halo en Neotokyo+, puntito hueco en Alba,
                  // circulito pastel en Dulce y celda con brillo verde en
                  // Profundidad. Lo único distinto aquí es el layout —un mes
                  // entero en rejilla de siete— y que un día se puede tocar.
                  child: Container(
                    decoration: celdaHeatmap(
                      id,
                      t,
                      color: diaMinutos != null
                          ? colorDiaMinutos(diaMinutos)
                          : colorDia(veces),
                      llena: lleno,
                      esHoy: esHoy,
                      seleccionada: seleccionado,
                      vacia: !lleno,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Info del día seleccionado (tooltip) o leyenda
            if (_diaSeleccionado != null)
              Text(
                _infoDia(_diaSeleccionado!, meta, conNivelesVeces),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: t.text),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l.detMenos} ',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: t.textMuted),
                  ),
                  ...[
                    Colors.transparent,
                    if (conNiveles) t.success.withValues(alpha: 0.35),
                    t.success,
                    // if (conNiveles) superada,
                  ].map(
                    (c) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      // La leyenda son celdas en pequeño, así que se pintan
                      // con la misma función: si la rejilla son puntos y la
                      // leyenda cuadraditos, la leyenda deja de explicarla.
                      decoration: celdaHeatmap(
                        id,
                        t,
                        color: c,
                        llena: c != Colors.transparent,
                        esHoy: false,
                        vacia: c == Colors.transparent,
                      ),
                    ),
                  ),
                  Text(
                    ' ${l.detMas}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: t.textMuted),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _infoDia(Map<String, dynamic> dia, int meta, bool conNiveles) {
    final fecha = DateTime.parse(dia['fecha']);
    final base = DateFormat.MMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(fecha);
    final l = AppLocalizations.of(context)!;
    final diaMinutos = _diaMinutos(dia);
    if (diaMinutos != null) {
      // «20 / 30 min» o «45 min / 1 h 30 min», con el objetivo que valía ese
      // día.
      if (diaMinutos.nivel == NivelDiaMinutos.vacio) {
        return '$base · ${l.detSinCompletar}';
      }
      return '$base · '
          '${progresoMinutos(l, diaMinutos.minutos, diaMinutos.objetivo ?? 0)}';
    }
    final int veces = _vecesDe(dia);
    if (veces == 0) return '$base · ${l.detSinCompletar}';
    if (conNiveles) return '$base · ${l.detProgresoDia(veces, meta)}';
    return '$base · ${l.detCompletado}';
  }

  Widget _buildUltimosRegistros() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final List<dynamic> registros = _detalle!['ultimosRegistros'];

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.detUltimosRegistros,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: t.text),
            ),
            const SizedBox(height: 8),
            if (registros.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarHeart,
                        size: 36,
                        color: tokens(context).textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.detVacioTitulo,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: tokens(context).text),
                      ),
                      Text(
                        l.detVacioRegistro,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...registros.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['fecha'],
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(color: t.text),
                            ),
                            // En minutos, lo que sumó ese registro, si el
                            // backend lo manda.
                            if (_esMinutos && r['cantidad'] is num)
                              Text(
                                textoRegistroMinutos(
                                  l,
                                  (r['cantidad'] as num).toInt(),
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: t.successText),
                              ),
                            if (r['valoracion'] != null)
                              EstrellasRegistro(
                                valoracion: r['valoracion'] as int,
                              ),
                            if (r['nota'] != null &&
                                r['nota'].toString().isNotEmpty)
                              Text(
                                r['nota'],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: t.textMuted),
                              ),
                          ],
                        ),
                      ),
                      // Sin aspa (rediseño de rachas, F4): el fallo no se pinta.
                      // Un registro sin completar deja el hueco del icono.
                      // Icon(
                      //   r['completado']
                      //       ? LucideIcons.circleCheck
                      //       : LucideIcons.circleX,
                      //   // Como icono basta el verde de relleno; el que hace
                      //   // falta oscurecer es el que se escribe.
                      //   color: r['completado'] ? t.success : t.textMuted,
                      // ),
                      if (r['completado'] == true)
                        Icon(LucideIcons.circleCheck, color: t.success)
                      else
                        const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          LucideIcons.pencil,
                          size: 18,
                          color: t.textMuted,
                        ),
                        onPressed: () => _editarValoracion(
                          r['registroId'],
                          r['valoracion'] as int?,
                          r['nota'] as String?,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarValoracion(
    int registroId,
    int? valoracionActual,
    String? notaActual,
  ) async {
    final respuesta = await ValoracionSheet.mostrar(
      context,
      valoracionInicial: valoracionActual,
      notaInicial: notaActual,
    );

    if (respuesta == null) return; // descartó sin guardar

    // Se envían dos cosas seguidas. Si la primera se guarda y la segunda falla,
    // la pantalla enseñaría datos viejos: el catch recarga sólo en ese caso.
    var guardadoAlgo = false;
    try {
      final int? valoracion = respuesta['valoracion'];
      final String? nota = respuesta['nota'];

      // Solo se envía la valoración si hay una elegida
      // (el backend no admite borrar una valoración existente)
      if (valoracion != null && valoracion != valoracionActual) {
        await ApiServiceHabitos.valorarRegistro(registroId, valoracion);
        guardadoAlgo = true;
      }
      // La nota sí se puede vaciar: enviamos '' si la borró
      if ((nota ?? '') != (notaActual ?? '')) {
        await ApiServiceHabitos.actualizarNotaRegistro(registroId, nota ?? '');
        guardadoAlgo = true;
      }
      _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MensajesError.de(
                context,
                e,
                generico: AppLocalizations.of(context)!.errorGuardar,
              ),
            ),
          ),
        );
        if (guardadoAlgo) _cargarDetalle();
      }
    }
  }
}

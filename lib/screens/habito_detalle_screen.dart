import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/habitos_refresh.dart';
import '../services/pausa.dart';
import '../services/descubrimiento_detalle.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';
import '../models/hoy.dart';
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
  const HabitoDetalleScreen({
    super.key,
    required this.habitoId,
    required this.usuarioId,
    this.nombre,
    this.descripcion,
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

  Future<void> _abrirEdicion() async {
    try {
      final Habito habito = await ApiServiceHabitos.getHabito(widget.habitoId);
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HabitoScreen(usuarioId: widget.usuarioId, habito: habito),
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

  /// Pausar gasta una «Pausa». La ventana enseña cuántas quedan; sin
  /// ninguna, lleva a la tienda. Al pausar se vuelve a Hoy, donde el hábito
  /// ya no sale.
  Future<void> _abrirPausa() async {
    final l = AppLocalizations.of(context)!;
    final nombre = (_detalle?['nombre'] as String?) ?? widget.nombre ?? '';

    final int pausas;
    try {
      pausas = pausasEn(
        await ApiServiceCore.getInventarioProductos(widget.usuarioId),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(MensajesError.de(context, e, generico: l.pausaError)),
          ),
        );
      }
      return;
    }
    if (!mounted) return;

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
    if (!mounted || accion == null) return;

    if (accion == _AccionPausa.tienda) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TiendaScreen(usuarioId: widget.usuarioId),
        ),
      );
      return;
    }

    setState(() => _pausando = true);
    try {
      await ApiServiceHabitos.desactivarHabito(widget.habitoId);
      notificarHabitosCambiados();
      if (!mounted) return;
      final mensajero = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      mensajero.showSnackBar(SnackBar(content: Text(l.pausaHecha(nombre))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _pausando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e, generico: l.pausaError)),
        ),
      );
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
    if (esDiario) {
      texto = meta > 1 ? l.detDiarioMeta(meta) : l.frecDiario;
    } else if (diasSemana != null && diasSemana.trim().isNotEmpty) {
      // Semanal con días planificados: "Semanal · M · J · S"
      final dias = diasSemana
          .split(',')
          .map((d) => etiquetas[int.parse(d.trim()) - 1])
          .join(' · ');
      texto = l.detSemanalDias(dias);
    } else {
      texto = meta > 1
          ? l.detSemanalMeta(meta)
          : '${l.frecSemanal} · ${l.detSemanalUnDia}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, size: 14, color: t.textMuted),
          const SizedBox(width: 6),
          Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }

  /// Lo que lleva el hábito, en dos plazos: siempre («Lo que llevas», que
  /// sólo sube) y este mes. Las dos tarjetas de racha (ahora / récord) salen
  /// con el rediseño de rachas (F4): el ritmo ocupa su sitio, arriba.
  ///
  /// Los iconos son Lucide y ya no emoji, por lo mismo que en la tienda y en
  /// logros: el emoji lo pinta la fuente del sistema y cambia de dibujo, color
  /// y peso entre plataformas, así que no se alinea con la identidad equipada.
  Widget _buildStatCards() {
    return ResumenDetalle(
      totalCompletados: ((_detalle!['totalCompletados'] ?? 0) as num).toInt(),
      diasMes: ((_detalle!['completadosMesActual'] ?? 0) as num).toInt(),
      mesActual: _esMesActual,
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
    final causa = causaRitmo(l, tendenciaDe(_detalle!['ritmoTendencia']));

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
    final bool conNiveles = esDiario && meta > 1;

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

    Color colorDia(int veces) {
      if (veces == 0) return Colors.transparent;
      if (!conNiveles) return t.success;
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
                final int veces =
                    dia['veces'] ?? (dia['completado'] == true ? 1 : 0);
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
                      color: colorDia(veces),
                      llena: veces > 0,
                      esHoy: esHoy,
                      seleccionada: seleccionado,
                      vacia: veces == 0,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Info del día seleccionado (tooltip) o leyenda
            if (_diaSeleccionado != null)
              Text(
                _infoDia(_diaSeleccionado!, meta, conNiveles),
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
    final int veces = dia['veces'] ?? (dia['completado'] == true ? 1 : 0);
    final base = DateFormat.MMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(fecha);
    final l = AppLocalizations.of(context)!;
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

enum _AccionPausa { pausar, tienda }

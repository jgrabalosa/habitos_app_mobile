import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Las tres piezas de la pantalla Hoy que cambian con la identidad equipada:
/// la tarjeta de un hábito, el chip de frecuencia y la celda del mini-heatmap.
///
/// Viven aquí y no en el paquete porque hablan de hábitos —una tarjeta de
/// hábito, un chip de frecuencia— aunque no lo digan en el nombre. Lo que sí
/// sale del paquete es el idioma: se despacha por [FormaIdentidad] con un
/// `switch` exhaustivo, igual que el halo, el terrario, el aro y el check, y
/// los radios salen de [IdentidadPaleta], nunca de un número suelto.
///
/// El corte de esquina de Neotokyo+ y la figura de una superficie según la
/// identidad ([formaIdentidad]) ya no se duplican aquí: son las del core
/// (`superficie_identidad.dart`), que es donde vive el sistema de estratos.

/// La tarjeta de una fila de la lista.
///
/// El aspecto lo decide ahora el core —[SuperficieIdentidad]—: esta clase
/// sólo existe para nombrar en lenguaje de hábitos lo que el motor llama
/// superficie, y para que las nueve llamadas repartidas por las pantallas no
/// tengan que cambiar.
class TarjetaIdentidad extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margen;

  const TarjetaIdentidad({
    super.key,
    required this.child,
    this.onTap,
    this.margen = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) => SuperficieIdentidad(
        margen: margen,
        // TarjetaIdentidad no metía padding ninguno; el default de
        // SuperficieIdentidad es EdgeInsets.all(16), así que hace falta
        // anularlo explícitamente o se desmaquetan las nueve tarjetas.
        relleno: EdgeInsets.zero,
        protagonista: false,
        // Lo que conserva el comportamiento de Alba: línea fina debajo en vez
        // de tarjeta.
        esFila: true,
        onTap: onTap,
        child: child,
      );
}

/// El chip de frecuencia. Mismo criterio que la tarjeta, en pequeño.
class ChipIdentidad extends StatelessWidget {
  final String texto;

  const ChipIdentidad({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    // Alba no rellena: un chip de color sería la única mancha de la fila.
    final relleno = id.forma == FormaIdentidad.hairline
        ? null
        : t.primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: relleno,
        shape: formaIdentidad(
          id,
          // Píldora completa salvo en Neotokyo+, que corta.
          radio: 999,
          lado: switch (id.forma) {
            FormaIdentidad.chamfer => BorderSide(color: t.primary, width: 1),
            FormaIdentidad.hairline => BorderSide(
                color: t.primary.withValues(alpha: 0.45), width: 1),
            _ => BorderSide.none,
          },
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          // Aquí el primario va como TEXTO, así que en las identidades claras
          // manda la variante que contrasta.
          color: id.forma == FormaIdentidad.pill ? t.successText : t.primary,
          letterSpacing: id.forma == FormaIdentidad.chamfer ? 0.6 : null,
        ),
      ),
    );
  }
}

/// El tema de la barra de navegación inferior en esta identidad.
///
/// Es lo único de la app que se ve en todo momento, así que es donde más se
/// nota si se queda genérica. Lo que cambia es la forma del indicador de la
/// pestaña activa y el color de lo seleccionado; la barra en sí sigue siendo
/// una `NavigationBar` de Material, con su comportamiento y su accesibilidad.
NavigationBarThemeData barraNavegacionIdentidad(
  IdentidadPaleta id,
  TokensContextuales t,
) {
  final ({ShapeBorder forma, Color color}) indicador = switch (id.forma) {
    // Profundidad — pastilla redondeada con el radio de la identidad.
    FormaIdentidad.glass => (
        forma: formaIdentidad(id, radio: id.radioSecundario),
        color: t.primary.withValues(alpha: 0.18),
      ),
    // Neotokyo+ — el mismo corte de esquina de las tarjetas, con filo.
    FormaIdentidad.chamfer => (
        forma: BordeChaflan(
          chaflan: id.chaflan,
          side: BorderSide(color: t.primary, width: 1.2),
        ),
        color: t.primary.withValues(alpha: 0.20),
      ),
    // Alba no rellena nada: la pestaña activa se marca con un contorno fino,
    // igual que sus tarjetas se marcan con una línea y no con una superficie.
    FormaIdentidad.hairline => (
        forma: StadiumBorder(
          side: BorderSide(color: t.primary.withValues(alpha: 0.55)),
        ),
        color: Colors.transparent,
      ),
    // Dulce — píldora completa y de color, que es su forma en todo.
    FormaIdentidad.pill => (
        forma: const StadiumBorder(),
        color: t.primary.withValues(alpha: 0.22),
      ),
  };

  return NavigationBarThemeData(
    backgroundColor: t.surface,
    indicatorColor: indicador.color,
    indicatorShape: indicador.forma,
    iconTheme: WidgetStateProperty.resolveWith(
      (estados) => IconThemeData(
        size: 24,
        color: estados.contains(WidgetState.selected) ? t.primary : t.textMuted,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (estados) => TextStyle(
        fontSize: 12,
        fontWeight: estados.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w500,
        // El primario va aquí como TEXTO pequeño, así que en las identidades
        // claras manda la variante que contrasta.
        color: estados.contains(WidgetState.selected)
            ? t.successText
            : t.textMuted,
      ),
    ),
  );
}

/// Cómo se pinta una celda de heatmap en esta identidad.
///
/// La misma celda en los dos sitios donde hay heatmap: los diez días de Hoy y
/// el mes entero del detalle de un hábito. El layout es cosa de cada pantalla
/// —una fila o una rejilla de siete—; la celda es esto.
///
/// Sólo decora: cuándo una celda está llena, cuándo es descanso, cuándo es hoy
/// y cuándo está seleccionada lo decide quien la llama, que es el único que
/// sabe de días planificados y de metas.
BoxDecoration celdaHeatmap(
  IdentidadPaleta id,
  TokensContextuales t, {
  required Color color,
  required bool llena,
  required bool esHoy,
  bool seleccionada = false,
}) {
  // La selección manda sobre el hoy: si el usuario ha tocado justo el día de
  // hoy, lo que tiene que verse es que lo ha tocado. Va en el color de texto
  // porque el primario ya está diciendo otra cosa a su lado.
  final borde = seleccionada
      ? Border.all(color: t.text, width: 2)
      : esHoy
          ? Border.all(color: t.primary, width: 1.5)
          : null;

  return switch (id.forma) {
    // Profundidad — celda redondeada con brillo verde cuando está hecha.
    FormaIdentidad.glass => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: borde,
        boxShadow: llena
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6)]
            : null,
      ),

    // Neotokyo+ — LED: esquina viva y halo cuando enciende.
    FormaIdentidad.chamfer => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
        border: borde,
        boxShadow: llena
            ? [
                BoxShadow(color: color.withValues(alpha: 0.85), blurRadius: 8),
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
              ]
            : null,
      ),

    // Alba — puntitos huecos: el día hecho se rellena, el resto es contorno.
    // Aquí el contorno nunca falta, así que el de reposo es el del propio
    // color en vez de nada.
    FormaIdentidad.hairline => BoxDecoration(
        shape: BoxShape.circle,
        color: llena ? color : Colors.transparent,
        border: borde ?? Border.all(color: color, width: 1),
      ),

    // Dulce — circulitos pastel, sin filo.
    FormaIdentidad.pill => BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: borde,
        boxShadow: llena
            ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 7)]
            : null,
      ),
  };
}

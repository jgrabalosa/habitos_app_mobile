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

/// Rectángulo con las cuatro esquinas cortadas en recto, como [ShapeBorder]
/// para que Material sepa recortarlo: así el `InkWell` de dentro moja la
/// figura buena y no un rectángulo que se sale por las esquinas.
class BordeChaflan extends OutlinedBorder {
  final double chaflan;

  const BordeChaflan({required this.chaflan, super.side = BorderSide.none});

  /// El corte no puede comerse el lado entero: en un chip de 20px de alto, los
  /// 10px de la identidad serían la mitad por arriba y por abajo.
  double _corte(Rect rect) => chaflan.clamp(0.0, rect.shortestSide / 2);

  Path _camino(Rect rect, double desplazamiento) {
    final r = rect.deflate(desplazamiento);
    final c = _corte(r);
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect, side.width);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      _camino(rect, side.width / 2),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BordeChaflan(chaflan: chaflan * t, side: side.scale(t));

  @override
  BordeChaflan copyWith({BorderSide? side, double? chaflan}) =>
      BordeChaflan(chaflan: chaflan ?? this.chaflan, side: side ?? this.side);

  @override
  bool operator ==(Object other) =>
      other is BordeChaflan &&
      other.chaflan == chaflan &&
      other.side == side;

  @override
  int get hashCode => Object.hash(chaflan, side);
}

/// La figura de una superficie de esta identidad, al radio que se le pida.
/// Sale de aquí y no de cada sitio para que la tarjeta, el chip y lo que venga
/// después no puedan acabar cortando la esquina de formas distintas.
ShapeBorder formaDe(
  IdentidadPaleta id, {
  required double radio,
  BorderSide lado = BorderSide.none,
}) =>
    switch (id.forma) {
      FormaIdentidad.chamfer => BordeChaflan(chaflan: id.chaflan, side: lado),
      _ => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: lado,
        ),
    };

/// La tarjeta de una fila de la lista.
///
/// Alba no la encajona: en su identidad el contenido secundario no vive dentro
/// de cards en ningún sitio, así que aquí tampoco — una línea fina debajo y se
/// acabó. Las otras tres sí son superficie, cada una con la suya.
class TarjetaIdentidad extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margen;

  const TarjetaIdentidad({
    super.key,
    required this.child,
    this.onTap,
    this.margen = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    if (id.forma == FormaIdentidad.hairline) {
      return Container(
        margin: margen,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: t.textMuted.withValues(alpha: 0.20)),
          ),
        ),
        child: InkWell(onTap: onTap, child: child),
      );
    }

    final forma = formaDe(
      id,
      radio: id.radioSecundario,
      lado: switch (id.forma) {
        // El filo claro es lo que hace que el cristal tenga canto.
        FormaIdentidad.glass =>
          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        FormaIdentidad.chamfer =>
          BorderSide(color: t.primary.withValues(alpha: 0.55), width: 1.2),
        _ => BorderSide.none,
      },
    );

    return Container(
      margin: margen,
      decoration: ShapeDecoration(
        shape: forma,
        // Profundidad es un degradado entre sus dos superficies; las otras dos
        // son superficie plana. Un degradado y un color sólido no caben en el
        // mismo campo, de ahí el reparto.
        gradient: id.forma == FormaIdentidad.glass
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.surface, t.surface2],
              )
            : null,
        color: id.forma == FormaIdentidad.glass ? null : t.surface,
        shadows: switch (id.forma) {
          FormaIdentidad.glass => [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          // Dulce: la sombra es del color de la identidad, no negra. Es lo que
          // convierte una sombra en un resplandor.
          FormaIdentidad.pill => [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          // Neotokyo+ no proyecta sombra: su relieve es el corte y el borde.
          _ => const [],
        },
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: forma,
          child: child,
        ),
      ),
    );
  }
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
        shape: formaDe(
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

/// Cómo se pinta una celda del mini-heatmap en esta identidad.
///
/// Sólo decora: cuándo una celda está llena, cuándo es descanso y cuándo es
/// hoy lo decide quien la llama, que es el único que sabe de días planificados
/// y de metas.
BoxDecoration celdaHeatmap(
  IdentidadPaleta id,
  TokensContextuales t, {
  required Color color,
  required bool llena,
  required bool esHoy,
}) {
  final borde =
      esHoy ? Border.all(color: t.primary, width: 1.5) : null;

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
    FormaIdentidad.hairline => BoxDecoration(
        shape: BoxShape.circle,
        color: llena ? color : Colors.transparent,
        border: esHoy
            ? Border.all(color: t.primary, width: 1.5)
            : Border.all(color: color, width: 1),
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

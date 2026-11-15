/// El origen de un registro hecho a mano, desde Hoy.
const String origenManual = 'MANUAL';

/// Un registro de un hábito, tal como lo manda `/registros/habito/{id}`.
class Registro {
  final int registroId;

  /// El día al que cuenta, `AAAA-MM-DD`.
  final String fecha;

  /// Minutos en un hábito de minutos; 1 en uno de veces, y también si el
  /// backend todavía no manda el campo.
  final int cantidad;

  /// De dónde salió: `MANUAL` o `ENFOQUE`. `MANUAL` si no viene.
  final String origen;

  /// Cuándo se marcó, en UTC. No es [fecha]: un día pasado de la semana se
  /// puede marcar hoy. Null si el backend no lo manda o no se entiende.
  final DateTime? creadoEn;

  const Registro({
    required this.registroId,
    required this.fecha,
    this.cantidad = 1,
    this.origen = origenManual,
    this.creadoEn,
  });

  factory Registro.fromJson(Map<String, dynamic> json) => Registro(
    registroId: (json['registroId'] as num).toInt(),
    fecha: json['fecha'] as String,
    cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
    origen: (json['origen'] as String?) ?? origenManual,
    creadoEn: instanteUtcDe(json['creadoEn']),
  );

  /// Lee una lista cruda del backend.
  static List<Registro> deLista(List<dynamic> lista) =>
      lista.map((r) => Registro.fromJson(r as Map<String, dynamic>)).toList();
}

/// Un instante del backend, en UTC. El backend guarda `creadoEn` en UTC y lo
/// manda sin zona («2026-11-15T13:05:07.123456»): sin zona se lee como UTC, no
/// como hora local. Con zona, se respeta. Cualquier otra cosa es null.
DateTime? instanteUtcDe(Object? valor) {
  if (valor is! String) return null;
  final conZona = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(valor)
      ? valor
      : '${valor}Z';
  return DateTime.tryParse(conZona)?.toUtc();
}

/// El último registro de [fecha], el de id más alto, o null si ese día no
/// hay ninguno. Es el único que el backend deja deshacer.
Registro? ultimoRegistroDe(List<Registro> registros, String fecha) {
  Registro? ultimo;
  for (final r in registros) {
    if (r.fecha != fecha) continue;
    if (ultimo == null || r.registroId > ultimo.registroId) ultimo = r;
  }
  return ultimo;
}

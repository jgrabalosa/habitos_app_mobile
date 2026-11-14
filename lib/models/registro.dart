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

  const Registro({
    required this.registroId,
    required this.fecha,
    this.cantidad = 1,
    this.origen = origenManual,
  });

  factory Registro.fromJson(Map<String, dynamic> json) => Registro(
    registroId: (json['registroId'] as num).toInt(),
    fecha: json['fecha'] as String,
    cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
    origen: (json['origen'] as String?) ?? origenManual,
  );

  /// Lee una lista cruda del backend.
  static List<Registro> deLista(List<dynamic> lista) =>
      lista.map((r) => Registro.fromJson(r as Map<String, dynamic>)).toList();
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

/// La suma de [Registro.cantidad] de cada día.
Map<String, int> minutosPorDia(List<Registro> registros) {
  final porDia = <String, int>{};
  for (final r in registros) {
    porDia[r.fecha] = (porDia[r.fecha] ?? 0) + r.cantidad;
  }
  return porDia;
}

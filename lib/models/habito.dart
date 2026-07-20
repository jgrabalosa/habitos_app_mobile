class Habito {
  final int habitoId;
  final String nombre;
  final String? descripcion;
  final String frecuencia;
  final int meta;
  final bool activo;
  final String? categoriaNombre;
  final int? categoriaId;
  final String? diasSemana; // "2,4,6" = martes, jueves, sábado (1=lunes..7=domingo)

  Habito({
    required this.habitoId,
    required this.nombre,
    this.descripcion,
    required this.frecuencia,
    required this.meta,
    required this.activo,
    this.categoriaNombre,
    this.categoriaId,
    this.diasSemana,
  });

  factory Habito.fromJson(Map<String, dynamic> json) {
    return Habito(
      habitoId: json['habitoId'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      frecuencia: json['frecuencia'],
      meta: json['meta'] ?? 1,
      activo: json['activo'],
      categoriaNombre: json['tipo'] != null ? json['tipo']['nombre'] : null,
      categoriaId: json['tipo'] != null ? json['tipo']['categoriaId'] : null,
      diasSemana: json['diasSemana'],
    );
  }
  /// Días planificados como enteros ISO (1=lunes..7=domingo), coincide con
  /// DateTime.weekday. Lista vacía = semanal flexible o hábito diario.
  List<int> get diasPlanificados =>
      (diasSemana == null || diasSemana!.trim().isEmpty)
          ? const []
          : diasSemana!.split(',').map((d) => int.parse(d.trim())).toList();
}
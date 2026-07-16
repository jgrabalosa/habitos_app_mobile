class Habito {
  final int habitoId;
  final String nombre;
  final String? descripcion;
  final String frecuencia;
  final int meta;
  final bool activo;
  final String? categoriaNombre;
  final int? categoriaId;

  Habito({
    required this.habitoId,
    required this.nombre,
    this.descripcion,
    required this.frecuencia,
    required this.meta,
    required this.activo,
    this.categoriaNombre,
    this.categoriaId,
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
    );
  }
}
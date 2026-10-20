import 'package:flutter/material.dart';

class Habito {
  final int habitoId;
  final String nombre;
  final String? descripcion;
  final String frecuencia;
  final int meta;
  final bool activo;
  final String? categoriaNombre;

  /// Código del catálogo; null si la categoría la creó el usuario.
  final String? categoriaCodigo;
  final int? categoriaId;
  final String?
  diasSemana; // "2,4,6" = martes, jueves, sábado (1=lunes..7=domingo)
  final bool recordatorioActivo;
  final String?
  recordatorioHora; // "HH:mm:ss" tal cual llega del backend, o null si no se ha elegido

  /// Día del alta, solo fecha. Null si el backend no la manda.
  final DateTime? fechaInicio;

  Habito({
    required this.habitoId,
    required this.nombre,
    this.descripcion,
    required this.frecuencia,
    required this.meta,
    required this.activo,
    this.categoriaNombre,
    this.categoriaCodigo,
    this.categoriaId,
    this.diasSemana,
    this.recordatorioActivo = true,
    this.recordatorioHora,
    this.fechaInicio,
  });

  /// «AAAA-MM-DD» a fecha sin hora. Cualquier otra cosa es null.
  static DateTime? _fechaSinHora(Object? valor) {
    if (valor is! String) return null;
    final fecha = DateTime.tryParse(valor);
    return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
  }

  factory Habito.fromJson(Map<String, dynamic> json) {
    return Habito(
      habitoId: json['habitoId'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      frecuencia: json['frecuencia'],
      meta: json['meta'] ?? 1,
      activo: json['activo'],
      categoriaNombre: json['categoriaNombre'],
      categoriaCodigo: json['categoriaCodigo'],
      categoriaId: json['categoriaId'],
      diasSemana: json['diasSemana'],
      recordatorioActivo: json['recordatorioActivo'] ?? true,
      recordatorioHora: json['recordatorioHora'],
      fechaInicio: _fechaSinHora(json['fechaInicio']),
    );
  }

  /// Hora del recordatorio como TimeOfDay, o null si no hay elegida.
  /// Parsea "HH:mm:ss" o "HH:mm" indistintamente.
  TimeOfDay? get recordatorioHoraTimeOfDay {
    if (recordatorioHora == null || recordatorioHora!.isEmpty) return null;
    final partes = recordatorioHora!.split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Días planificados como enteros ISO (1=lunes..7=domingo), coincide con
  /// DateTime.weekday. Lista vacía = semanal flexible o hábito diario.
  List<int> get diasPlanificados =>
      (diasSemana == null || diasSemana!.trim().isEmpty)
      ? const []
      : diasSemana!.split(',').map((d) => int.parse(d.trim())).toList();
}

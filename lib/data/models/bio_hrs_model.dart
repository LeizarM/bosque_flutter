import 'package:bosque_flutter/domain/entities/bio_hrs_entity.dart';

/// Origen: tabla `dbo.tbio_bioHrs`, via `p_list_BioHrs`.
class BioHrsModel {
  final BigInt idHrs;
  final String nombre;
  final DateTime? ingreso;
  final DateTime? salida;
  final double cantDias;
  final double cantMinutos;
  final String estado;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrsModel({
    required this.idHrs,
    required this.nombre,
    this.ingreso,
    this.salida,
    required this.cantDias,
    required this.cantMinutos,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioHrsModel.fromJson(Map<String, dynamic> json) => BioHrsModel(
    idHrs: json['idHrs'] != null ? BigInt.from(json['idHrs']) : BigInt.zero,
    nombre: json['nombre'] ?? '',
    ingreso: json['ingreso'] != null ? DateTime.tryParse(json['ingreso']) : null,
    salida: json['salida'] != null ? DateTime.tryParse(json['salida']) : null,
    cantDias: (json['cantDias'] ?? 0).toDouble(),
    cantMinutos: (json['cantMinutos'] ?? 0).toDouble(),
    estado: json['estado'] ?? '',
    audUsuario: json['audUsuario'] ?? 0,
    audFecha:
        json['audFecha'] != null ? DateTime.tryParse(json['audFecha']) : null,
  );

  factory BioHrsModel.fromEntity(BioHrsEntity e) => BioHrsModel(
    idHrs: e.idHrs,
    nombre: e.nombre,
    ingreso: e.ingreso,
    salida: e.salida,
    cantDias: e.cantDias,
    cantMinutos: e.cantMinutos,
    estado: e.estado,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );

  Map<String, dynamic> toJson() => {
    'idHrs': idHrs.toInt(),
    'nombre': nombre,
    'ingreso': ingreso?.toIso8601String(),
    'salida': salida?.toIso8601String(),
    'cantDias': cantDias,
    'cantMinutos': cantMinutos,
    'estado': estado,
    'audUsuario': audUsuario,
  };

  BioHrsEntity toEntity() => BioHrsEntity(
    idHrs: idHrs,
    nombre: nombre,
    ingreso: ingreso,
    salida: salida,
    cantDias: cantDias,
    cantMinutos: cantMinutos,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

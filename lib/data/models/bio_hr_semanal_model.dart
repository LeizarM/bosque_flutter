import 'package:bosque_flutter/domain/entities/bio_hr_semanal_entity.dart';

/// Origen: tabla `dbo.tbio_bioHrSemanal`, via `p_list_BioHrSemanal`.
class BioHrSemanalModel {
  final BigInt idHrSemanal;
  final String nombre;
  final String estado;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrSemanalModel({
    required this.idHrSemanal,
    required this.nombre,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioHrSemanalModel.fromJson(Map<String, dynamic> json) =>
      BioHrSemanalModel(
        idHrSemanal:
            json['idHrSemanal'] != null
                ? BigInt.from(json['idHrSemanal'])
                : BigInt.zero,
        nombre: json['nombre'] ?? '',
        estado: json['estado'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioHrSemanalModel.fromEntity(BioHrSemanalEntity e) =>
      BioHrSemanalModel(
        idHrSemanal: e.idHrSemanal,
        nombre: e.nombre,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );

  Map<String, dynamic> toJson() => {
    'idHrSemanal': idHrSemanal.toInt(),
    'nombre': nombre,
    'estado': estado,
    'audUsuario': audUsuario,
  };

  BioHrSemanalEntity toEntity() => BioHrSemanalEntity(
    idHrSemanal: idHrSemanal,
    nombre: nombre,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

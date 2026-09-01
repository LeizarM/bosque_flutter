import 'package:bosque_flutter/domain/entities/bio_hr_semanal_detalle_entity.dart';

/// Origen: tabla `dbo.tbio_bioHrSemanalDetalle`, via
/// `p_list_BioHrSemanalDetalle`.
class BioHrSemanalDetalleModel {
  final BigInt idHrDet;
  final BigInt idHrSemanal;
  final BigInt idHrs;
  final int dia;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrSemanalDetalleModel({
    required this.idHrDet,
    required this.idHrSemanal,
    required this.idHrs,
    required this.dia,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioHrSemanalDetalleModel.fromJson(Map<String, dynamic> json) =>
      BioHrSemanalDetalleModel(
        idHrDet:
            json['idHrDet'] != null
                ? BigInt.from(json['idHrDet'])
                : BigInt.zero,
        idHrSemanal:
            json['idHrSemanal'] != null
                ? BigInt.from(json['idHrSemanal'])
                : BigInt.zero,
        idHrs: json['idHrs'] != null ? BigInt.from(json['idHrs']) : BigInt.zero,
        dia: json['dia'] ?? 0,
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioHrSemanalDetalleModel.fromEntity(
    BioHrSemanalDetalleEntity e,
  ) => BioHrSemanalDetalleModel(
    idHrDet: e.idHrDet,
    idHrSemanal: e.idHrSemanal,
    idHrs: e.idHrs,
    dia: e.dia,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );

  Map<String, dynamic> toJson() => {
    'idHrDet': idHrDet.toInt(),
    'idHrSemanal': idHrSemanal.toInt(),
    'idHrs': idHrs.toInt(),
    'dia': dia,
    'audUsuario': audUsuario,
  };

  BioHrSemanalDetalleEntity toEntity() => BioHrSemanalDetalleEntity(
    idHrDet: idHrDet,
    idHrSemanal: idHrSemanal,
    idHrs: idHrs,
    dia: dia,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

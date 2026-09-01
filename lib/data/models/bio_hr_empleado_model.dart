import 'package:bosque_flutter/domain/entities/bio_hr_empleado_entity.dart';

/// Origen: tabla `dbo.tbio_bioHrEmpleado`, via `p_list_BioHrEmpleado`.
class BioHrEmpleadoModel {
  final BigInt idHrEmpleado;
  final BigInt idHrSemanal;
  final BigInt idEmplead;
  final DateTime? inicio;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrEmpleadoModel({
    required this.idHrEmpleado,
    required this.idHrSemanal,
    required this.idEmplead,
    this.inicio,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioHrEmpleadoModel.fromJson(Map<String, dynamic> json) =>
      BioHrEmpleadoModel(
        idHrEmpleado:
            json['idHrEmpleado'] != null
                ? BigInt.from(json['idHrEmpleado'])
                : BigInt.zero,
        idHrSemanal:
            json['idHrSemanal'] != null
                ? BigInt.from(json['idHrSemanal'])
                : BigInt.zero,
        idEmplead:
            json['idEmplead'] != null
                ? BigInt.from(json['idEmplead'])
                : BigInt.zero,
        inicio: json['inicio'] != null ? DateTime.tryParse(json['inicio']) : null,
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioHrEmpleadoModel.fromEntity(BioHrEmpleadoEntity e) =>
      BioHrEmpleadoModel(
        idHrEmpleado: e.idHrEmpleado,
        idHrSemanal: e.idHrSemanal,
        idEmplead: e.idEmplead,
        inicio: e.inicio,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );

  Map<String, dynamic> toJson() => {
    'idHrEmpleado': idHrEmpleado.toInt(),
    'idHrSemanal': idHrSemanal.toInt(),
    'idEmplead': idEmplead.toInt(),
    'inicio': inicio?.toIso8601String(),
    'audUsuario': audUsuario,
  };

  BioHrEmpleadoEntity toEntity() => BioHrEmpleadoEntity(
    idHrEmpleado: idHrEmpleado,
    idHrSemanal: idHrSemanal,
    idEmplead: idEmplead,
    inicio: inicio,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

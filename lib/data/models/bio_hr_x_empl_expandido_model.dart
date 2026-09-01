import 'package:bosque_flutter/domain/entities/bio_hr_x_empl_expandido_entity.dart';

/// Origen: tabla `dbo.tbio_bioHrXEmplExpandido`, via
/// `p_list_BioHrXEmplExpandido`.
class BioHrXEmplExpandidoModel {
  final BigInt idHrEmpleado;
  final BigInt idHrs;
  final DateTime? jornada;
  final int dia;
  final DateTime? hrIngreso;
  final DateTime? hrSalida;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrXEmplExpandidoModel({
    required this.idHrEmpleado,
    required this.idHrs,
    this.jornada,
    required this.dia,
    this.hrIngreso,
    this.hrSalida,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioHrXEmplExpandidoModel.fromJson(Map<String, dynamic> json) =>
      BioHrXEmplExpandidoModel(
        idHrEmpleado:
            json['idHrEmpleado'] != null
                ? BigInt.from(json['idHrEmpleado'])
                : BigInt.zero,
        idHrs: json['idHrs'] != null ? BigInt.from(json['idHrs']) : BigInt.zero,
        jornada:
            json['jornada'] != null ? DateTime.tryParse(json['jornada']) : null,
        dia: json['dia'] ?? 0,
        hrIngreso:
            json['hrIngreso'] != null
                ? DateTime.tryParse(json['hrIngreso'])
                : null,
        hrSalida:
            json['hrSalida'] != null
                ? DateTime.tryParse(json['hrSalida'])
                : null,
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioHrXEmplExpandidoModel.fromEntity(
    BioHrXEmplExpandidoEntity e,
  ) => BioHrXEmplExpandidoModel(
    idHrEmpleado: e.idHrEmpleado,
    idHrs: e.idHrs,
    jornada: e.jornada,
    dia: e.dia,
    hrIngreso: e.hrIngreso,
    hrSalida: e.hrSalida,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );

  Map<String, dynamic> toJson() => {
    'idHrEmpleado': idHrEmpleado.toInt(),
    'idHrs': idHrs.toInt(),
    'jornada': jornada?.toIso8601String(),
    'dia': dia,
    'hrIngreso': hrIngreso?.toIso8601String(),
    'hrSalida': hrSalida?.toIso8601String(),
    'audUsuario': audUsuario,
  };

  BioHrXEmplExpandidoEntity toEntity() => BioHrXEmplExpandidoEntity(
    idHrEmpleado: idHrEmpleado,
    idHrs: idHrs,
    jornada: jornada,
    dia: dia,
    hrIngreso: hrIngreso,
    hrSalida: hrSalida,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

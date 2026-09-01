import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';

/// Origen: tabla `dbo.tbio_bioEmplBosqEmpl`, via `p_list_BioEmplBosqEmpl`.
class BioEmplBosqEmplModel {
  final BigInt idEmpleadBio;
  final String datoNombreBiom;
  final BigInt idEmpleado;
  final String datoNombreBosq;
  final int audUsuario;
  final DateTime? audFecha;

  const BioEmplBosqEmplModel({
    required this.idEmpleadBio,
    required this.datoNombreBiom,
    required this.idEmpleado,
    required this.datoNombreBosq,
    required this.audUsuario,
    this.audFecha,
  });

  factory BioEmplBosqEmplModel.fromJson(Map<String, dynamic> json) =>
      BioEmplBosqEmplModel(
        idEmpleadBio:
            json['idEmpleadBio'] != null
                ? BigInt.from(json['idEmpleadBio'])
                : BigInt.zero,
        datoNombreBiom: json['datoNombreBiom'] ?? '',
        idEmpleado:
            json['idEmpleado'] != null
                ? BigInt.from(json['idEmpleado'])
                : BigInt.zero,
        datoNombreBosq: json['datoNombreBosq'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  factory BioEmplBosqEmplModel.fromEntity(BioEmplBosqEmplEntity e) =>
      BioEmplBosqEmplModel(
        idEmpleadBio: e.idEmpleadBio,
        datoNombreBiom: e.datoNombreBiom,
        idEmpleado: e.idEmpleado,
        datoNombreBosq: e.datoNombreBosq,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );

  Map<String, dynamic> toJson() => {
    'idEmpleadBio': idEmpleadBio.toInt(),
    'datoNombreBiom': datoNombreBiom,
    'idEmpleado': idEmpleado.toInt(),
    'datoNombreBosq': datoNombreBosq,
    'audUsuario': audUsuario,
  };

  BioEmplBosqEmplEntity toEntity() => BioEmplBosqEmplEntity(
    idEmpleadBio: idEmpleadBio,
    datoNombreBiom: datoNombreBiom,
    idEmpleado: idEmpleado,
    datoNombreBosq: datoNombreBosq,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

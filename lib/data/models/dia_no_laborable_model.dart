import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';

class DiaNoLaborableModel {
  BigInt idDiaNoLaborable;
  DateTime fecha;
  String motivo;
  String alcance;
  int audUsuario;

  DiaNoLaborableModel({
    required this.idDiaNoLaborable,
    required this.fecha,
    required this.motivo,
    required this.alcance,
    required this.audUsuario,
  });

  factory DiaNoLaborableModel.fromJson(Map<String, dynamic> json) =>
      DiaNoLaborableModel(
        idDiaNoLaborable: json['idDiaNoLaborable'] != null
            ? BigInt.from(json['idDiaNoLaborable'])
            : BigInt.zero,
        fecha: json['fecha'] != null
            ? DateTime.parse(json['fecha'])
            : DateTime.now(),
        motivo: json['motivo'] ?? '',
        alcance: json['alcance'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
      );

  DiaNoLaborableEntity toEntity() => DiaNoLaborableEntity(
    idDiaNoLaborable: idDiaNoLaborable,
    fecha: fecha,
    motivo: motivo,
    alcance: alcance,
    audUsuario: audUsuario,
  );
}

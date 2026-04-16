import 'dart:convert';

import 'package:bosque_flutter/domain/entities/resmado_entity.dart';

ResmadoModel resmadoModelFromJson(String str) =>
    ResmadoModel.fromJson(json.decode(str));

String resmadoModelToJson(ResmadoModel data) => json.encode(data.toJson());

class ResmadoModel {
  final int idRes;
  final int idGrupo;
  final int codEmpleado;
  final DateTime fecha;
  final double total;
  final String hraInicio;
  final String hraFin;
  final int codEmpresa;
  final int docNumOrdFab;
  final int audUsuario;

  ResmadoModel({
    required this.idRes,
    required this.idGrupo,
    required this.codEmpleado,
    required this.fecha,
    required this.total,
    required this.hraInicio,
    required this.hraFin,
    required this.codEmpresa,
    required this.docNumOrdFab,
    required this.audUsuario,
  });

  factory ResmadoModel.fromJson(Map<String, dynamic> json) => ResmadoModel(
    idRes: json["idRes"] ?? 0,
    idGrupo: json["idGrupo"] ?? 0,
    codEmpleado: json["codEmpleado"] ?? 0,
    fecha:
        json["fecha"] != null && json["fecha"] != ''
            ? DateTime.parse(json["fecha"])
            : DateTime.now(),
    total: (json["total"] ?? 0).toDouble(),
    hraInicio: json["hraInicio"] ?? '',
    hraFin: json["hraFin"] ?? '',
    codEmpresa: json["codEmpresa"] ?? 0,
    docNumOrdFab: json["docNumOrdFab"] ?? 0,
    audUsuario: json["audUsuario"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "idRes": idRes,
    "idGrupo": idGrupo,
    "codEmpleado": codEmpleado,
    "fecha": fecha.toIso8601String(),
    "total": total,
    "hraInicio": hraInicio,
    "hraFin": hraFin,
    "codEmpresa": codEmpresa,
    "docNumOrdFab": docNumOrdFab,
    "audUsuario": audUsuario,
  };

  ResmadoEntity toEntity() => ResmadoEntity(
    idRes: idRes,
    idGrupo: idGrupo,
    codEmpleado: codEmpleado,
    fecha: fecha,
    total: total,
    hraInicio: hraInicio,
    hraFin: hraFin,
    codEmpresa: codEmpresa,
    docNumOrdFab: docNumOrdFab,
    audUsuario: audUsuario,
  );

  factory ResmadoModel.fromEntity(ResmadoEntity entity) => ResmadoModel(
    idRes: entity.idRes,
    idGrupo: entity.idGrupo,
    codEmpleado: entity.codEmpleado,
    fecha: entity.fecha,
    total: entity.total,
    hraInicio: entity.hraInicio,
    hraFin: entity.hraFin,
    codEmpresa: entity.codEmpresa,
    docNumOrdFab: entity.docNumOrdFab,
    audUsuario: entity.audUsuario,
  );
}

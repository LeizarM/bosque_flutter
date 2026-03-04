// To parse this JSON data, do
//
//     final afiliacionSeguroModel = afiliacionSeguroModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/data/models/seguro_model.dart';
import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';

AfiliacionSeguroModel afiliacionSeguroModelFromJson(String str) => AfiliacionSeguroModel.fromJson(json.decode(str));

String afiliacionSeguroModelToJson(AfiliacionSeguroModel data) => json.encode(data.toJson());

class AfiliacionSeguroModel {
    int codAfiliacion;
    int codEmpleado;
    int codSeguro;
    DateTime? fechaAfiliacion;
    DateTime? fechaBaja;
    String nroAfiliacion;
    int audUsuarioI;
    int codPersona;
    String nombreCompleto;
    SeguroModel seguro;

    AfiliacionSeguroModel({
        required this.codAfiliacion,
        required this.codEmpleado,
        required this.codSeguro,
        required this.fechaAfiliacion,
        this.fechaBaja,
        required this.nroAfiliacion,
        required this.audUsuarioI,
        required this.codPersona,
        required this.nombreCompleto,
        required this.seguro,
    });

    factory AfiliacionSeguroModel.fromJson(Map<String, dynamic> json) => AfiliacionSeguroModel(
        codAfiliacion: json["codAfiliacion"]??0,
        codEmpleado: json["codEmpleado"]??0,
        codSeguro: json["codSeguro"]??0,
        //fechaAfiliacion: DateTime.parse(json["fechaAfiliacion"]),
        fechaAfiliacion: json["fechaAfiliacion"]!= null ? DateTime.parse(json["fechaAfiliacion"]) : null,
        //fechaBaja: DateTime.parse(json["fechaBaja"]),
        fechaBaja: json["fechaBaja"]!= null ? DateTime.parse(json["fechaBaja"]) : null,
        nroAfiliacion: json["nroAfiliacion"]??'',
        audUsuarioI: json["audUsuarioI"]??0,
        codPersona: json["codPersona"]??0,
        nombreCompleto: json["nombreCompleto"]??'',
        seguro: SeguroModel.fromJson(json["seguro"]),
    );

    Map<String, dynamic> toJson() => {
        "codAfiliacion": codAfiliacion,
        "codEmpleado": codEmpleado,
        "codSeguro": codSeguro,
        "fechaAfiliacion": fechaAfiliacion?.toIso8601String(),
        "fechaBaja": fechaBaja?.toIso8601String(),
        "nroAfiliacion": nroAfiliacion,
        "audUsuarioI": audUsuarioI,
        "codPersona": codPersona,
        "nombreCompleto": nombreCompleto,
        "seguro": seguro.toJson(),
    };
    AfiliacionSeguroEntity toEntity() => AfiliacionSeguroEntity(
        codAfiliacion: codAfiliacion,
        codEmpleado: codEmpleado,
        codSeguro: codSeguro,
        fechaAfiliacion: fechaAfiliacion,
        fechaBaja: fechaBaja,
        nroAfiliacion: nroAfiliacion,
        audUsuarioI: audUsuarioI,
        codPersona: codPersona,
        nombreCompleto: nombreCompleto,
        seguro: seguro.toEntity(),
    );
    factory AfiliacionSeguroModel.fromEntity(AfiliacionSeguroEntity entity) => AfiliacionSeguroModel(
        codAfiliacion: entity.codAfiliacion,
        codEmpleado: entity.codEmpleado,
        codSeguro: entity.codSeguro,
        fechaAfiliacion: entity.fechaAfiliacion,
        fechaBaja: entity.fechaBaja,
        nroAfiliacion: entity.nroAfiliacion,
        audUsuarioI: entity.audUsuarioI,
        codPersona: entity.codPersona,
        nombreCompleto: entity.nombreCompleto,
        seguro: SeguroModel.fromEntity(entity.seguro),
    );
}



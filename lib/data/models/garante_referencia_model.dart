// To parse this JSON data, do
//
//     final garanteReferenciaModel = garanteReferenciaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/garante_referencia.dart';

List<GaranteReferenciaModel> garanteReferenciaModelFromJson(String str) => List<GaranteReferenciaModel>.from(json.decode(str).map((x) => GaranteReferenciaModel.fromJson(x)));

String garanteReferenciaModelToJson(List<GaranteReferenciaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GaranteReferenciaModel {
    final int codGarante;
    final int codPersona;
    final int codEmpleado;
    final String direccionTrabajo;
    final String empresaTrabajo;
    final String tipo;
    final String observacion;
    final int audUsuario;
    final String? esEmpleado;
    final String? nombreCompleto;
    final String? direccionDomicilio;
    final String? telefonos;

    GaranteReferenciaModel({
        required this.codGarante,
        required this.codPersona,
        required this.codEmpleado,
        required this.direccionTrabajo,
        required this.empresaTrabajo,
        required this.tipo,
        required this.observacion,
        required this.audUsuario,
         this.esEmpleado,
         this.nombreCompleto,
         this.direccionDomicilio,
         this.telefonos,
    });

    factory GaranteReferenciaModel.fromJson(Map<String, dynamic> json) => GaranteReferenciaModel(
        codGarante: json["codGarante"]?? 0,
        codPersona: json["codPersona"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        direccionTrabajo: json["direccionTrabajo"]?? '',
        empresaTrabajo: json["empresaTrabajo"]?? '',
        tipo: json["tipo"]?? '',
        observacion: json["observacion"]?? '',
        audUsuario: json["audUsuario"]?? 0,
        esEmpleado: json["esEmpleado"]?? '',
        nombreCompleto: json["nombreCompleto"]?? '',
        direccionDomicilio: json["direccionDomicilio"]?? '',
        telefonos: json["telefonos"]?? '',
    );

    Map<String, dynamic> toJson() => {
        "codGarante": codGarante,
        "codPersona": codPersona,
        "codEmpleado": codEmpleado,
        "direccionTrabajo": direccionTrabajo,
        "empresaTrabajo": empresaTrabajo,
        "tipo": tipo,
        "observacion": observacion,
        "audUsuario": audUsuario,
        "esEmpleado": esEmpleado,
        "nombreCompleto": nombreCompleto,
        "direccionDomicilio": direccionDomicilio,
        "telefonos": telefonos,
    };
    GaranteReferenciaEntity toEntity() => GaranteReferenciaEntity(
        codGarante: codGarante,
        codPersona: codPersona,
        codEmpleado: codEmpleado,
        direccionTrabajo: direccionTrabajo,
        empresaTrabajo: empresaTrabajo,
        tipo: tipo,
        observacion: observacion,
        audUsuario: audUsuario,
        esEmpleado: esEmpleado,
        nombreCompleto: nombreCompleto,
        direccionDomicilio: direccionDomicilio,
        telefonos: telefonos,
    );
    factory GaranteReferenciaModel.fromEntity(GaranteReferenciaEntity entity) => GaranteReferenciaModel(
        codGarante: entity.codGarante,
        codPersona: entity.codPersona,
        codEmpleado: entity.codEmpleado,
        direccionTrabajo: entity.direccionTrabajo,
        empresaTrabajo: entity.empresaTrabajo,
        tipo: entity.tipo,
        observacion: entity.observacion,
        audUsuario: entity.audUsuario,
        esEmpleado: entity.esEmpleado,
        nombreCompleto: entity.nombreCompleto,
        direccionDomicilio: entity.direccionDomicilio,
        telefonos: entity.telefonos,
    );
}

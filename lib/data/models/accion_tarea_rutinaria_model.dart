// Destino final: lib/data/models/accion_tarea_rutinaria_model.dart
// "accion" (columna real de tac_accionTareaRutinaria) se expone como
// "descripcionAccion" para no colisionar con el parámetro @ACCION del SP
// (ver tac_accionTareaRutinaria.sql) — la clave JSON debe coincidir con el
// campo del modelo Java (AccionTareaRutinaria.descripcionAccion).
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';

AccionTareaRutinariaResponse accionTareaRutinariaResponseFromJson(
  String str,
) => AccionTareaRutinariaResponse.fromJson(json.decode(str));
String accionTareaRutinariaResponseToJson(
  AccionTareaRutinariaResponse data,
) => json.encode(data.toJson());

class AccionTareaRutinariaResponse {
  String message;
  List<AccionTareaRutinariaModel> data;
  int status;
  int? idGenerado;

  AccionTareaRutinariaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory AccionTareaRutinariaResponse.fromJson(Map<String, dynamic> json) {
    List<AccionTareaRutinariaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<AccionTareaRutinariaModel>.from(
          (json["data"] as List).map(
            (x) => AccionTareaRutinariaModel.fromJson(x),
          ),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return AccionTareaRutinariaResponse(
      message: json["message"] ?? '',
      data: listaData,
      status: json["status"] ?? 0,
      idGenerado: json["idGenerado"] ?? idGen,
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status": status,
    "idGenerado": idGenerado,
  };
}

class AccionTareaRutinariaModel {
  int idATR;
  String descripcionAccion;
  int? estado;
  int audUsuario;
  DateTime? audFecha;

  AccionTareaRutinariaModel({
    required this.idATR,
    required this.descripcionAccion,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory AccionTareaRutinariaModel.fromJson(Map<String, dynamic> json) {
    return AccionTareaRutinariaModel(
      idATR: json["idATR"] ?? 0,
      descripcionAccion: json["descripcionAccion"] ?? '',
      estado: json["estado"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idATR": idATR,
    "descripcionAccion": descripcionAccion,
    "estado": estado,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  AccionTareaRutinariaEntity toEntity() {
    return AccionTareaRutinariaEntity(
      idATR: idATR,
      descripcionAccion: descripcionAccion,
      estado: estado,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory AccionTareaRutinariaModel.fromEntity(
    AccionTareaRutinariaEntity entity,
  ) {
    return AccionTareaRutinariaModel(
      idATR: entity.idATR,
      descripcionAccion: entity.descripcionAccion,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

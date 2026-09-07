// Destino final: lib/data/models/frecuencia_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/frecuencia_entity.dart';

FrecuenciaResponse frecuenciaResponseFromJson(String str) =>
    FrecuenciaResponse.fromJson(json.decode(str));
String frecuenciaResponseToJson(FrecuenciaResponse data) =>
    json.encode(data.toJson());

class FrecuenciaResponse {
  String message;
  List<FrecuenciaModel> data;
  int status;
  int? idGenerado;

  FrecuenciaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory FrecuenciaResponse.fromJson(Map<String, dynamic> json) {
    List<FrecuenciaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<FrecuenciaModel>.from(
          (json["data"] as List).map((x) => FrecuenciaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return FrecuenciaResponse(
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

class FrecuenciaModel {
  int idFrec;
  String? descripcion;
  int? estado;
  int audUsuario;
  DateTime? audFecha;

  FrecuenciaModel({
    required this.idFrec,
    this.descripcion,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory FrecuenciaModel.fromJson(Map<String, dynamic> json) {
    return FrecuenciaModel(
      idFrec: json["idFrec"] ?? 0,
      descripcion: json["descripcion"],
      estado: json["estado"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idFrec": idFrec,
    "descripcion": descripcion,
    "estado": estado,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  FrecuenciaEntity toEntity() {
    return FrecuenciaEntity(
      idFrec: idFrec,
      descripcion: descripcion,
      estado: estado,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory FrecuenciaModel.fromEntity(FrecuenciaEntity entity) {
    return FrecuenciaModel(
      idFrec: entity.idFrec,
      descripcion: entity.descripcion,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

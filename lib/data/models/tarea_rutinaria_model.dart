// Destino final: lib/data/models/tarea_rutinaria_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';

TareaRutinariaResponse tareaRutinariaResponseFromJson(String str) =>
    TareaRutinariaResponse.fromJson(json.decode(str));
String tareaRutinariaResponseToJson(TareaRutinariaResponse data) =>
    json.encode(data.toJson());

class TareaRutinariaResponse {
  String message;
  List<TareaRutinariaModel> data;
  int status;
  int? idGenerado;

  TareaRutinariaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory TareaRutinariaResponse.fromJson(Map<String, dynamic> json) {
    List<TareaRutinariaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<TareaRutinariaModel>.from(
          (json["data"] as List).map((x) => TareaRutinariaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return TareaRutinariaResponse(
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

class TareaRutinariaModel {
  int idTarRuti;
  int? idFrec;
  int? idArea;
  DateTime? fechaPartida;
  int? IniFin;
  int? idATR;
  String descripcion;
  int audUsuario;
  DateTime? audFecha;

  TareaRutinariaModel({
    required this.idTarRuti,
    this.idFrec,
    this.idArea,
    this.fechaPartida,
    this.IniFin,
    this.idATR,
    required this.descripcion,
    required this.audUsuario,
    this.audFecha,
  });

  factory TareaRutinariaModel.fromJson(Map<String, dynamic> json) {
    return TareaRutinariaModel(
      idTarRuti: json["idTarRuti"] ?? 0,
      idFrec: json["idFrec"],
      idArea: json["idArea"],
      fechaPartida: json["fechaPartida"] != null
          ? DateTime.tryParse(json["fechaPartida"])
          : null,
      IniFin: json["IniFin"],
      idATR: json["idATR"],
      descripcion: json["descripcion"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idTarRuti": idTarRuti,
    "idFrec": idFrec,
    "idArea": idArea,
    "fechaPartida": fechaPartida?.toIso8601String(),
    "IniFin": IniFin,
    "idATR": idATR,
    "descripcion": descripcion,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  TareaRutinariaEntity toEntity() {
    return TareaRutinariaEntity(
      idTarRuti: idTarRuti,
      idFrec: idFrec,
      idArea: idArea,
      fechaPartida: fechaPartida,
      IniFin: IniFin,
      idATR: idATR,
      descripcion: descripcion,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory TareaRutinariaModel.fromEntity(TareaRutinariaEntity entity) {
    return TareaRutinariaModel(
      idTarRuti: entity.idTarRuti,
      idFrec: entity.idFrec,
      idArea: entity.idArea,
      fechaPartida: entity.fechaPartida,
      IniFin: entity.IniFin,
      idATR: entity.idATR,
      descripcion: entity.descripcion,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

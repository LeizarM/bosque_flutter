// Destino final: lib/data/models/corte_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/corte_entity.dart';

CorteResponse corteResponseFromJson(String str) =>
    CorteResponse.fromJson(json.decode(str));
String corteResponseToJson(CorteResponse data) =>
    json.encode(data.toJson());

class CorteResponse {
  String message;
  List<CorteModel> data;
  int status;
  int? idGenerado;

  CorteResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory CorteResponse.fromJson(Map<String, dynamic> json) {
    List<CorteModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<CorteModel>.from(
          (json["data"] as List).map((x) => CorteModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return CorteResponse(
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

class CorteModel {
  int idCorte;
  String? descripcion;
  double? corte;
  String? tipoCorte;
  int audUsuario;
  DateTime? audFecha;

  CorteModel({
    required this.idCorte,
    this.descripcion,
    this.corte,
    this.tipoCorte,
    required this.audUsuario,
    this.audFecha,
  });

  factory CorteModel.fromJson(Map<String, dynamic> json) {
    return CorteModel(
      idCorte: json["idCorte"] ?? 0,
      descripcion: json["descripcion"],
      corte: json["corte"],
      tipoCorte: json["tipoCorte"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idCorte": idCorte,
    "descripcion": descripcion,
    "corte": corte,
    "tipoCorte": tipoCorte,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  CorteEntity toEntity() {
    return CorteEntity(
      idCorte: idCorte,
      descripcion: descripcion,
      corte: corte,
      tipoCorte: tipoCorte,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory CorteModel.fromEntity(CorteEntity entity) {
    return CorteModel(
      idCorte: entity.idCorte,
      descripcion: entity.descripcion,
      corte: entity.corte,
      tipoCorte: entity.tipoCorte,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

// Destino final: lib/data/models/mov_caja_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/mov_caja_entity.dart';

MovCajaResponse movCajaResponseFromJson(String str) =>
    MovCajaResponse.fromJson(json.decode(str));
String movCajaResponseToJson(MovCajaResponse data) =>
    json.encode(data.toJson());

class MovCajaResponse {
  String message;
  List<MovCajaModel> data;
  int status;
  int? idGenerado;

  MovCajaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory MovCajaResponse.fromJson(Map<String, dynamic> json) {
    List<MovCajaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<MovCajaModel>.from(
          (json["data"] as List).map((x) => MovCajaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return MovCajaResponse(
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

class MovCajaModel {
  int idMC;
  int? idAC;
  int? idSxMC;
  int? codSucursal;
  double? montoBs;
  int audUsuario;
  DateTime? audFecha;

  MovCajaModel({
    required this.idMC,
    this.idAC,
    this.idSxMC,
    this.codSucursal,
    this.montoBs,
    required this.audUsuario,
    this.audFecha,
  });

  factory MovCajaModel.fromJson(Map<String, dynamic> json) {
    return MovCajaModel(
      idMC: json["idMC"] ?? 0,
      idAC: json["idAC"],
      idSxMC: json["idSxMC"],
      codSucursal: json["codSucursal"],
      montoBs: json["montoBs"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idMC": idMC,
    "idAC": idAC,
    "idSxMC": idSxMC,
    "codSucursal": codSucursal,
    "montoBs": montoBs,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  MovCajaEntity toEntity() {
    return MovCajaEntity(
      idMC: idMC,
      idAC: idAC,
      idSxMC: idSxMC,
      codSucursal: codSucursal,
      montoBs: montoBs,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory MovCajaModel.fromEntity(MovCajaEntity entity) {
    return MovCajaModel(
      idMC: entity.idMC,
      idAC: entity.idAC,
      idSxMC: entity.idSxMC,
      codSucursal: entity.codSucursal,
      montoBs: entity.montoBs,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

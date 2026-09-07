// Destino final: lib/data/models/coche_llegadas_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/coche_llegadas_entity.dart';

CocheLlegadasResponse cocheLlegadasResponseFromJson(String str) =>
    CocheLlegadasResponse.fromJson(json.decode(str));
String cocheLlegadasResponseToJson(CocheLlegadasResponse data) =>
    json.encode(data.toJson());

class CocheLlegadasResponse {
  String message;
  List<CocheLlegadasModel> data;
  int status;
  int? idGenerado;

  CocheLlegadasResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory CocheLlegadasResponse.fromJson(Map<String, dynamic> json) {
    List<CocheLlegadasModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<CocheLlegadasModel>.from(
          (json["data"] as List).map((x) => CocheLlegadasModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return CocheLlegadasResponse(
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

class CocheLlegadasModel {
  int idCo;
  int? idTarRuti;
  int? idCoche;
  int? idBitTarRuti;
  String? descripcion;
  DateTime? fecha;
  int? llego;
  String? obs;
  int audUsuario;
  DateTime? audFecha;

  CocheLlegadasModel({
    required this.idCo,
    this.idTarRuti,
    this.idCoche,
    this.idBitTarRuti,
    this.descripcion,
    this.fecha,
    this.llego,
    this.obs,
    required this.audUsuario,
    this.audFecha,
  });

  factory CocheLlegadasModel.fromJson(Map<String, dynamic> json) {
    return CocheLlegadasModel(
      idCo: json["idCo"] ?? 0,
      idTarRuti: json["idTarRuti"],
      idCoche: json["idCoche"],
      idBitTarRuti: json["idBitTarRuti"],
      descripcion: json["descripcion"],
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      llego: json["llego"],
      obs: json["obs"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idCo": idCo,
    "idTarRuti": idTarRuti,
    "idCoche": idCoche,
    "idBitTarRuti": idBitTarRuti,
    "descripcion": descripcion,
    "fecha": fecha?.toIso8601String(),
    "llego": llego,
    "obs": obs,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  CocheLlegadasEntity toEntity() {
    return CocheLlegadasEntity(
      idCo: idCo,
      idTarRuti: idTarRuti,
      idCoche: idCoche,
      idBitTarRuti: idBitTarRuti,
      descripcion: descripcion,
      fecha: fecha,
      llego: llego,
      obs: obs,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory CocheLlegadasModel.fromEntity(CocheLlegadasEntity entity) {
    return CocheLlegadasModel(
      idCo: entity.idCo,
      idTarRuti: entity.idTarRuti,
      idCoche: entity.idCoche,
      idBitTarRuti: entity.idBitTarRuti,
      descripcion: entity.descripcion,
      fecha: entity.fecha,
      llego: entity.llego,
      obs: entity.obs,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

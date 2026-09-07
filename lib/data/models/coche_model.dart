// Destino final: lib/data/models/coche_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';

CocheResponse cocheResponseFromJson(String str) =>
    CocheResponse.fromJson(json.decode(str));
String cocheResponseToJson(CocheResponse data) => json.encode(data.toJson());

class CocheResponse {
  String message;
  List<CocheModel> data;
  int status;
  int? idGenerado;

  CocheResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory CocheResponse.fromJson(Map<String, dynamic> json) {
    List<CocheModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<CocheModel>.from(
          (json["data"] as List).map((x) => CocheModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return CocheResponse(
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

class CocheModel {
  int idCoche;
  String? marca;
  String? clase;
  String? placa;
  int? anio;
  String? color;
  int? codSucursal;
  int? estado;
  int audUsuario;
  DateTime? audFecha;

  CocheModel({
    required this.idCoche,
    this.marca,
    this.clase,
    this.placa,
    this.anio,
    this.color,
    this.codSucursal,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory CocheModel.fromJson(Map<String, dynamic> json) {
    return CocheModel(
      idCoche: json["idCoche"] ?? 0,
      marca: json["marca"],
      clase: json["clase"],
      placa: json["placa"],
      anio: json["anio"],
      color: json["color"],
      codSucursal: json["codSucursal"],
      estado: json["estado"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idCoche": idCoche,
    "marca": marca,
    "clase": clase,
    "placa": placa,
    "anio": anio,
    "color": color,
    "codSucursal": codSucursal,
    "estado": estado,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  CocheEntity toEntity() {
    return CocheEntity(
      idCoche: idCoche,
      marca: marca,
      clase: clase,
      placa: placa,
      anio: anio,
      color: color,
      codSucursal: codSucursal,
      estado: estado,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory CocheModel.fromEntity(CocheEntity entity) {
    return CocheModel(
      idCoche: entity.idCoche,
      marca: entity.marca,
      clase: entity.clase,
      placa: entity.placa,
      anio: entity.anio,
      color: entity.color,
      codSucursal: entity.codSucursal,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

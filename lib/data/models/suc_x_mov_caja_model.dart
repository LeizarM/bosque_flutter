// Destino final: lib/data/models/suc_x_mov_caja_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/suc_x_mov_caja_entity.dart';

SucXMovCajaResponse sucXMovCajaResponseFromJson(String str) =>
    SucXMovCajaResponse.fromJson(json.decode(str));
String sucXMovCajaResponseToJson(SucXMovCajaResponse data) =>
    json.encode(data.toJson());

class SucXMovCajaResponse {
  String message;
  List<SucXMovCajaModel> data;
  int status;
  int? idGenerado;

  SucXMovCajaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory SucXMovCajaResponse.fromJson(Map<String, dynamic> json) {
    List<SucXMovCajaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<SucXMovCajaModel>.from(
          (json["data"] as List).map((x) => SucXMovCajaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return SucXMovCajaResponse(
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

class SucXMovCajaModel {
  int idSxMC;
  int? codSucursal;
  String? codigoCuentaCajaSap;
  String? nombre;
  String? bd;
  int audUsuario;
  DateTime? audFecha;

  SucXMovCajaModel({
    required this.idSxMC,
    this.codSucursal,
    this.codigoCuentaCajaSap,
    this.nombre,
    this.bd,
    required this.audUsuario,
    this.audFecha,
  });

  factory SucXMovCajaModel.fromJson(Map<String, dynamic> json) {
    return SucXMovCajaModel(
      idSxMC: json["idSxMC"] ?? 0,
      codSucursal: json["codSucursal"],
      codigoCuentaCajaSap: json["codigoCuentaCajaSap"],
      nombre: json["nombre"],
      bd: json["bd"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idSxMC": idSxMC,
    "codSucursal": codSucursal,
    "codigoCuentaCajaSap": codigoCuentaCajaSap,
    "nombre": nombre,
    "bd": bd,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  SucXMovCajaEntity toEntity() {
    return SucXMovCajaEntity(
      idSxMC: idSxMC,
      codSucursal: codSucursal,
      codigoCuentaCajaSap: codigoCuentaCajaSap,
      nombre: nombre,
      bd: bd,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory SucXMovCajaModel.fromEntity(SucXMovCajaEntity entity) {
    return SucXMovCajaModel(
      idSxMC: entity.idSxMC,
      codSucursal: entity.codSucursal,
      codigoCuentaCajaSap: entity.codigoCuentaCajaSap,
      nombre: entity.nombre,
      bd: entity.bd,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

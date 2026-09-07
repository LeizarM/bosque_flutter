// Destino final: lib/data/models/vale_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/vale_entity.dart';

ValeResponse valeResponseFromJson(String str) =>
    ValeResponse.fromJson(json.decode(str));
String valeResponseToJson(ValeResponse data) => json.encode(data.toJson());

class ValeResponse {
  String message;
  List<ValeModel> data;
  int status;
  int? idGenerado;

  ValeResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory ValeResponse.fromJson(Map<String, dynamic> json) {
    List<ValeModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<ValeModel>.from(
          (json["data"] as List).map((x) => ValeModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return ValeResponse(
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

class ValeModel {
  int idVale;
  int? idAC;
  int? numVale;
  String? nombre;
  double? monto;
  DateTime? fecha;
  String? obs;
  int? codEmpresa;
  int audUsuario;
  DateTime? audFecha;

  ValeModel({
    required this.idVale,
    this.idAC,
    this.numVale,
    this.nombre,
    this.monto,
    this.fecha,
    this.obs,
    this.codEmpresa,
    required this.audUsuario,
    this.audFecha,
  });

  factory ValeModel.fromJson(Map<String, dynamic> json) {
    return ValeModel(
      idVale: json["idVale"] ?? 0,
      idAC: json["idAC"],
      numVale: json["numVale"],
      nombre: json["nombre"],
      monto: (json["monto"] as num?)?.toDouble(),
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      obs: json["obs"],
      codEmpresa: json["codEmpresa"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idVale": idVale,
    "idAC": idAC,
    "numVale": numVale,
    "nombre": nombre,
    "monto": monto,
    "fecha": fecha?.toIso8601String(),
    "obs": obs,
    "codEmpresa": codEmpresa,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  ValeEntity toEntity() {
    return ValeEntity(
      idVale: idVale,
      idAC: idAC,
      numVale: numVale,
      nombre: nombre,
      monto: monto,
      fecha: fecha,
      obs: obs,
      codEmpresa: codEmpresa,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory ValeModel.fromEntity(ValeEntity entity) {
    return ValeModel(
      idVale: entity.idVale,
      idAC: entity.idAC,
      numVale: entity.numVale,
      nombre: entity.nombre,
      monto: entity.monto,
      fecha: entity.fecha,
      obs: entity.obs,
      codEmpresa: entity.codEmpresa,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

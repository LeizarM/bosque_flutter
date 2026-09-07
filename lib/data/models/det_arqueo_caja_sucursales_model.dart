// Destino final: lib/data/models/det_arqueo_caja_sucursales_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/det_arqueo_caja_sucursales_entity.dart';

DetArqueoCajaSucursalesResponse detArqueoCajaSucursalesResponseFromJson(
  String str,
) => DetArqueoCajaSucursalesResponse.fromJson(json.decode(str));
String detArqueoCajaSucursalesResponseToJson(
  DetArqueoCajaSucursalesResponse data,
) => json.encode(data.toJson());

class DetArqueoCajaSucursalesResponse {
  String message;
  List<DetArqueoCajaSucursalesModel> data;
  int status;
  int? idGenerado;

  DetArqueoCajaSucursalesResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory DetArqueoCajaSucursalesResponse.fromJson(Map<String, dynamic> json) {
    List<DetArqueoCajaSucursalesModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<DetArqueoCajaSucursalesModel>.from(
          (json["data"] as List).map(
            (x) => DetArqueoCajaSucursalesModel.fromJson(x),
          ),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return DetArqueoCajaSucursalesResponse(
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

class DetArqueoCajaSucursalesModel {
  int idDetAS;
  int? idAC;
  int? idCorte;
  int? cantidad;
  double? subTotal;
  int audUsuario;
  DateTime? audFecha;

  DetArqueoCajaSucursalesModel({
    required this.idDetAS,
    this.idAC,
    this.idCorte,
    this.cantidad,
    this.subTotal,
    required this.audUsuario,
    this.audFecha,
  });

  factory DetArqueoCajaSucursalesModel.fromJson(Map<String, dynamic> json) {
    return DetArqueoCajaSucursalesModel(
      idDetAS: json["idDetAS"] ?? 0,
      idAC: json["idAC"],
      idCorte: json["idCorte"],
      cantidad: json["cantidad"],
      subTotal: (json["subTotal"] as num?)?.toDouble(),
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idDetAS": idDetAS,
    "idAC": idAC,
    "idCorte": idCorte,
    "cantidad": cantidad,
    "subTotal": subTotal,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  DetArqueoCajaSucursalesEntity toEntity() {
    return DetArqueoCajaSucursalesEntity(
      idDetAS: idDetAS,
      idAC: idAC,
      idCorte: idCorte,
      cantidad: cantidad,
      subTotal: subTotal,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory DetArqueoCajaSucursalesModel.fromEntity(
    DetArqueoCajaSucursalesEntity entity,
  ) {
    return DetArqueoCajaSucursalesModel(
      idDetAS: entity.idDetAS,
      idAC: entity.idAC,
      idCorte: entity.idCorte,
      cantidad: entity.cantidad,
      subTotal: entity.subTotal,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

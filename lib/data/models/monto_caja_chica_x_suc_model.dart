// Destino final: lib/data/models/monto_caja_chica_x_suc_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/monto_caja_chica_x_suc_entity.dart';

MontoCajaChicaXSucResponse montoCajaChicaXSucResponseFromJson(String str) =>
    MontoCajaChicaXSucResponse.fromJson(json.decode(str));
String montoCajaChicaXSucResponseToJson(MontoCajaChicaXSucResponse data) =>
    json.encode(data.toJson());

class MontoCajaChicaXSucResponse {
  String message;
  List<MontoCajaChicaXSucModel> data;
  int status;
  int? idGenerado;

  MontoCajaChicaXSucResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory MontoCajaChicaXSucResponse.fromJson(Map<String, dynamic> json) {
    List<MontoCajaChicaXSucModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<MontoCajaChicaXSucModel>.from(
          (json["data"] as List).map(
            (x) => MontoCajaChicaXSucModel.fromJson(x),
          ),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return MontoCajaChicaXSucResponse(
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

class MontoCajaChicaXSucModel {
  int idCS;
  int? codSucursal;
  double? montoIng;
  int audUsuario;
  DateTime? audFecha;

  MontoCajaChicaXSucModel({
    required this.idCS,
    this.codSucursal,
    this.montoIng,
    required this.audUsuario,
    this.audFecha,
  });

  factory MontoCajaChicaXSucModel.fromJson(Map<String, dynamic> json) {
    return MontoCajaChicaXSucModel(
      idCS: json["idCS"] ?? 0,
      codSucursal: json["codSucursal"],
      montoIng: json["montoIng"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idCS": idCS,
    "codSucursal": codSucursal,
    "montoIng": montoIng,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  MontoCajaChicaXSucEntity toEntity() {
    return MontoCajaChicaXSucEntity(
      idCS: idCS,
      codSucursal: codSucursal,
      montoIng: montoIng,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory MontoCajaChicaXSucModel.fromEntity(MontoCajaChicaXSucEntity entity) {
    return MontoCajaChicaXSucModel(
      idCS: entity.idCS,
      codSucursal: entity.codSucursal,
      montoIng: entity.montoIng,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

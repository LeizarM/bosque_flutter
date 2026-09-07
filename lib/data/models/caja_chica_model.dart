// Destino final: lib/data/models/caja_chica_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';

CajaChicaResponse cajaChicaResponseFromJson(String str) =>
    CajaChicaResponse.fromJson(json.decode(str));
String cajaChicaResponseToJson(CajaChicaResponse data) =>
    json.encode(data.toJson());

class CajaChicaResponse {
  String message;
  List<CajaChicaModel> data;
  int status;
  int? idGenerado;

  CajaChicaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory CajaChicaResponse.fromJson(Map<String, dynamic> json) {
    List<CajaChicaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<CajaChicaModel>.from(
          (json["data"] as List).map((x) => CajaChicaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return CajaChicaResponse(
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

class CajaChicaModel {
  int idCC;
  int? idBitTarRuti;
  String? persona;
  double? montoIng;
  double? montoEg;
  double? saldo;
  int? numFactura;
  int? numVale;
  String? moneda;
  String? descripcion;
  int? codEmpDestino;
  DateTime? fecha;
  int? codSucursal;
  int? lote;
  int audUsuario;
  DateTime? audFecha;

  CajaChicaModel({
    required this.idCC,
    this.idBitTarRuti,
    this.persona,
    this.montoIng,
    this.montoEg,
    this.saldo,
    this.numFactura,
    this.numVale,
    this.moneda,
    this.descripcion,
    this.codEmpDestino,
    this.fecha,
    this.codSucursal,
    this.lote,
    required this.audUsuario,
    this.audFecha,
  });

  factory CajaChicaModel.fromJson(Map<String, dynamic> json) {
    return CajaChicaModel(
      idCC: json["idCC"] ?? 0,
      idBitTarRuti: json["idBitTarRuti"],
      persona: json["persona"],
      montoIng: json["montoIng"],
      montoEg: json["montoEg"],
      saldo: json["saldo"],
      numFactura: json["numFactura"],
      numVale: json["numVale"],
      moneda: json["moneda"],
      descripcion: json["descripcion"],
      codEmpDestino: json["codEmpDestino"],
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      codSucursal: json["codSucursal"],
      lote: json["lote"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idCC": idCC,
    "idBitTarRuti": idBitTarRuti,
    "persona": persona,
    "montoIng": montoIng,
    "montoEg": montoEg,
    "saldo": saldo,
    "numFactura": numFactura,
    "numVale": numVale,
    "moneda": moneda,
    "descripcion": descripcion,
    "codEmpDestino": codEmpDestino,
    "fecha": fecha?.toIso8601String(),
    "codSucursal": codSucursal,
    "lote": lote,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  CajaChicaEntity toEntity() {
    return CajaChicaEntity(
      idCC: idCC,
      idBitTarRuti: idBitTarRuti,
      persona: persona,
      montoIng: montoIng,
      montoEg: montoEg,
      saldo: saldo,
      numFactura: numFactura,
      numVale: numVale,
      moneda: moneda,
      descripcion: descripcion,
      codEmpDestino: codEmpDestino,
      fecha: fecha,
      codSucursal: codSucursal,
      lote: lote,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory CajaChicaModel.fromEntity(CajaChicaEntity entity) {
    return CajaChicaModel(
      idCC: entity.idCC,
      idBitTarRuti: entity.idBitTarRuti,
      persona: entity.persona,
      montoIng: entity.montoIng,
      montoEg: entity.montoEg,
      saldo: entity.saldo,
      numFactura: entity.numFactura,
      numVale: entity.numVale,
      moneda: entity.moneda,
      descripcion: entity.descripcion,
      codEmpDestino: entity.codEmpDestino,
      fecha: entity.fecha,
      codSucursal: entity.codSucursal,
      lote: entity.lote,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

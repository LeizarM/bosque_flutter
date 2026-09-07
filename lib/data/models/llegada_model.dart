// Destino final: lib/data/models/llegada_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/llegada_entity.dart';

LlegadaResponse llegadaResponseFromJson(String str) =>
    LlegadaResponse.fromJson(json.decode(str));
String llegadaResponseToJson(LlegadaResponse data) =>
    json.encode(data.toJson());

class LlegadaResponse {
  String message;
  List<LlegadaModel> data;
  int status;
  int? idGenerado;

  LlegadaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory LlegadaResponse.fromJson(Map<String, dynamic> json) {
    List<LlegadaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<LlegadaModel>.from(
          (json["data"] as List).map((x) => LlegadaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return LlegadaResponse(
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

class LlegadaModel {
  int idRp;
  int? idTarRuti;
  DateTime? fecha;
  DateTime? horallegada;
  String? persona;
  String? cliente;
  String? moneda;
  double? importe;
  String? destino;
  String? tipo;
  String? obs;
  int? idBitTarRuti;
  int? fueVerificado;
  int? codEmpVerificado;
  int? codSucursal;
  int audUsuario;
  DateTime? audFecha;

  LlegadaModel({
    required this.idRp,
    this.idTarRuti,
    this.fecha,
    this.horallegada,
    this.persona,
    this.cliente,
    this.moneda,
    this.importe,
    this.destino,
    this.tipo,
    this.obs,
    this.idBitTarRuti,
    this.fueVerificado,
    this.codEmpVerificado,
    this.codSucursal,
    required this.audUsuario,
    this.audFecha,
  });

  factory LlegadaModel.fromJson(Map<String, dynamic> json) {
    return LlegadaModel(
      idRp: json["idRp"] ?? 0,
      idTarRuti: json["idTarRuti"],
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      horallegada: json["horallegada"] != null
          ? DateTime.tryParse(json["horallegada"])
          : null,
      persona: json["persona"],
      cliente: json["cliente"],
      moneda: json["moneda"],
      importe: json["importe"],
      destino: json["destino"],
      tipo: json["tipo"],
      obs: json["obs"],
      idBitTarRuti: json["idBitTarRuti"],
      fueVerificado: json["fueVerificado"],
      codEmpVerificado: json["codEmpVerificado"],
      codSucursal: json["codSucursal"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idRp": idRp,
    "idTarRuti": idTarRuti,
    "fecha": fecha?.toIso8601String(),
    "horallegada": horallegada?.toIso8601String(),
    "persona": persona,
    "cliente": cliente,
    "moneda": moneda,
    "importe": importe,
    "destino": destino,
    "tipo": tipo,
    "obs": obs,
    "idBitTarRuti": idBitTarRuti,
    "fueVerificado": fueVerificado,
    "codEmpVerificado": codEmpVerificado,
    "codSucursal": codSucursal,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  LlegadaEntity toEntity() {
    return LlegadaEntity(
      idRp: idRp,
      idTarRuti: idTarRuti,
      fecha: fecha,
      horallegada: horallegada,
      persona: persona,
      cliente: cliente,
      moneda: moneda,
      importe: importe,
      destino: destino,
      tipo: tipo,
      obs: obs,
      idBitTarRuti: idBitTarRuti,
      fueVerificado: fueVerificado,
      codEmpVerificado: codEmpVerificado,
      codSucursal: codSucursal,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory LlegadaModel.fromEntity(LlegadaEntity entity) {
    return LlegadaModel(
      idRp: entity.idRp,
      idTarRuti: entity.idTarRuti,
      fecha: entity.fecha,
      horallegada: entity.horallegada,
      persona: entity.persona,
      cliente: entity.cliente,
      moneda: entity.moneda,
      importe: entity.importe,
      destino: entity.destino,
      tipo: entity.tipo,
      obs: entity.obs,
      idBitTarRuti: entity.idBitTarRuti,
      fueVerificado: entity.fueVerificado,
      codEmpVerificado: entity.codEmpVerificado,
      codSucursal: entity.codSucursal,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

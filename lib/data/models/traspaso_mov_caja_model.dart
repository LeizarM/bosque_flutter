// Destino final: lib/data/models/traspaso_mov_caja_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

TraspasoMovCajaResponse traspasoMovCajaResponseFromJson(String str) =>
    TraspasoMovCajaResponse.fromJson(json.decode(str));
String traspasoMovCajaResponseToJson(TraspasoMovCajaResponse data) =>
    json.encode(data.toJson());

class TraspasoMovCajaResponse {
  String message;
  List<TraspasoMovCajaModel> data;
  int status;
  int? idGenerado;

  TraspasoMovCajaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory TraspasoMovCajaResponse.fromJson(Map<String, dynamic> json) {
    List<TraspasoMovCajaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<TraspasoMovCajaModel>.from(
          (json["data"] as List).map((x) => TraspasoMovCajaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return TraspasoMovCajaResponse(
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

class TraspasoMovCajaModel {
  int idTrasp;
  String? bd;
  DateTime? fecha;
  String? account;
  String? contraAct;
  String? acctName;
  String? tipoTransaccion;
  double? dolares;
  double? bs;
  int? fueVerificado;
  int? idBitTarRuti;
  int audUsuario;
  DateTime? audFecha;

  TraspasoMovCajaModel({
    required this.idTrasp,
    this.bd,
    this.fecha,
    this.account,
    this.contraAct,
    this.acctName,
    this.tipoTransaccion,
    this.dolares,
    this.bs,
    this.fueVerificado,
    this.idBitTarRuti,
    required this.audUsuario,
    this.audFecha,
  });

  factory TraspasoMovCajaModel.fromJson(Map<String, dynamic> json) {
    return TraspasoMovCajaModel(
      idTrasp: json["idTrasp"] ?? 0,
      bd: json["bd"],
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      account: json["account"],
      contraAct: json["contraAct"],
      acctName: json["acctName"],
      tipoTransaccion: json["tipoTransaccion"],
      dolares: json["dolares"],
      bs: json["bs"],
      fueVerificado: json["fueVerificado"],
      idBitTarRuti: json["idBitTarRuti"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idTrasp": idTrasp,
    "bd": bd,
    "fecha": fecha?.toIso8601String(),
    "account": account,
    "contraAct": contraAct,
    "acctName": acctName,
    "tipoTransaccion": tipoTransaccion,
    "dolares": dolares,
    "bs": bs,
    "fueVerificado": fueVerificado,
    "idBitTarRuti": idBitTarRuti,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  TraspasoMovCajaEntity toEntity() {
    return TraspasoMovCajaEntity(
      idTrasp: idTrasp,
      bd: bd,
      fecha: fecha,
      account: account,
      contraAct: contraAct,
      acctName: acctName,
      tipoTransaccion: tipoTransaccion,
      dolares: dolares,
      bs: bs,
      fueVerificado: fueVerificado,
      idBitTarRuti: idBitTarRuti,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory TraspasoMovCajaModel.fromEntity(TraspasoMovCajaEntity entity) {
    return TraspasoMovCajaModel(
      idTrasp: entity.idTrasp,
      bd: entity.bd,
      fecha: entity.fecha,
      account: entity.account,
      contraAct: entity.contraAct,
      acctName: entity.acctName,
      tipoTransaccion: entity.tipoTransaccion,
      dolares: entity.dolares,
      bs: entity.bs,
      fueVerificado: entity.fueVerificado,
      idBitTarRuti: entity.idBitTarRuti,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

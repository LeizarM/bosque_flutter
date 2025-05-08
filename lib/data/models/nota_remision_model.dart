// To parse this JSON data, do
//
//     final notaRemisionModel = notaRemisionModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';

NotaRemisionModel notaRemisionModelFromJson(String str) =>
    NotaRemisionModel.fromJson(json.decode(str));

String notaRemisionModelToJson(NotaRemisionModel data) =>
    json.encode(data.toJson());

class NotaRemisionModel {
  final int idNr;
  final int idDeposito;
  final int docNum;
  final DateTime fecha;
  final int numFact;
  final int totalMonto;
  final int saldoPendiente;
  final int audUsuario;
  final String codCliente;
  final String nombreCliente;
  final String db;
  final int codEmpresaBosque;

  NotaRemisionModel({
    required this.idNr,
    required this.idDeposito,
    required this.docNum,
    required this.fecha,
    required this.numFact,
    required this.totalMonto,
    required this.saldoPendiente,
    required this.audUsuario,
    required this.codCliente,
    required this.nombreCliente,
    required this.db,
    required this.codEmpresaBosque,
  });

  factory NotaRemisionModel.fromJson(Map<String, dynamic> json) =>
      NotaRemisionModel(
        idNr: json["idNR"],
        idDeposito: json["idDeposito"],
        docNum: json["docNum"],
        fecha: DateTime.parse(json["fecha"]),
        numFact: json["numFact"],
        totalMonto: json["totalMonto"],
        saldoPendiente: json["saldoPendiente"],
        audUsuario: json["audUsuario"],
        codCliente: json["codCliente"],
        nombreCliente: json["nombreCliente"],
        db: json["db"],
        codEmpresaBosque: json["codEmpresaBosque"],
      );

  Map<String, dynamic> toJson() => {
    "idNR": idNr,
    "idDeposito": idDeposito,
    "docNum": docNum,
    "fecha": fecha.toIso8601String(),
    "numFact": numFact,
    "totalMonto": totalMonto,
    "saldoPendiente": saldoPendiente,
    "audUsuario": audUsuario,
    "codCliente": codCliente,
    "nombreCliente": nombreCliente,
    "db": db,
    "codEmpresaBosque": codEmpresaBosque,
  };

  NotaRemisionEntity toEntity() => NotaRemisionEntity(
    idNr: idNr,
    idDeposito: idDeposito,
    docNum: docNum,
    fecha: fecha,
    numFact: numFact,
    totalMonto: totalMonto,
    saldoPendiente: saldoPendiente,
    audUsuario: audUsuario,
    codCliente: codCliente,
    nombreCliente: nombreCliente,
    db: db,
    codEmpresaBosque: codEmpresaBosque,
  );

  // Método factory para convertir de Entity a Model
  factory NotaRemisionModel.fromEntity(NotaRemisionEntity entity) =>
      NotaRemisionModel(
        idNr: entity.idNr,
        idDeposito: entity.idDeposito,
        docNum: entity.docNum,
        fecha: entity.fecha,
        numFact: entity.numFact,
        totalMonto: entity.totalMonto,
        saldoPendiente: entity.saldoPendiente,
        audUsuario: entity.audUsuario,
        codCliente: entity.codCliente,
        nombreCliente: entity.nombreCliente,
        db: entity.db,
        codEmpresaBosque: entity.codEmpresaBosque,
      );
}

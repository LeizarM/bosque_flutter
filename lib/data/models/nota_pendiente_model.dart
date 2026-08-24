import 'dart:convert';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';

NotaPendienteModel notaPendienteModelFromJson(String str) =>
    NotaPendienteModel.fromJson(json.decode(str));

String notaPendienteModelToJson(NotaPendienteModel data) =>
    json.encode(data.toJson());

class NotaPendienteModel {
  int fila;
  int? idNoPagado;
  int? codVendedor;
  String nombreVen;
  DateTime? fechaDoc;
  int? mes;
  int? anio;
  int? docNum;
  String valido;
  String indicador;
  String estado;
  double montoTotalBs;
  double montoCerradoBs;
  String origen;
  double saldoPendiente;

  NotaPendienteModel({
    required this.fila,
    this.idNoPagado,
    this.codVendedor,
    required this.nombreVen,
    this.fechaDoc,
    this.mes,
    this.anio,
    this.docNum,
    required this.valido,
    required this.indicador,
    required this.estado,
    required this.montoTotalBs,
    required this.montoCerradoBs,
    required this.origen,
    required this.saldoPendiente,
  });

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  factory NotaPendienteModel.fromJson(Map<String, dynamic> json) =>
      NotaPendienteModel(
        fila: json["fila"] ?? 0,
        // Nulo real: identifica a las filas de total.
        idNoPagado: json["idNoPagado"],
        codVendedor: json["codVendedor"],
        nombreVen: json["nombreVen"] ?? '',
        fechaDoc:
            json["fechaDoc"] != null ? DateTime.parse(json["fechaDoc"]) : null,
        mes: json["mes"],
        anio: json["anio"],
        docNum: json["docNum"],
        valido: json["valido"] ?? '',
        indicador: json["indicador"] ?? '',
        estado: json["estado"] ?? '',
        montoTotalBs: _num(json["montoTotalBS"]),
        montoCerradoBs: _num(json["montoCerradoBS"]),
        origen: json["origen"] ?? '',
        saldoPendiente: _num(json["saldoPendiente"]),
      );

  Map<String, dynamic> toJson() => {
    "fila": fila,
    "idNoPagado": idNoPagado,
    "codVendedor": codVendedor,
    "nombreVen": nombreVen,
    "mes": mes,
    "anio": anio,
    "docNum": docNum,
    "valido": valido,
    "indicador": indicador,
    "estado": estado,
    "montoTotalBS": montoTotalBs,
    "montoCerradoBS": montoCerradoBs,
    "origen": origen,
    "saldoPendiente": saldoPendiente,
  };

  NotaPendienteEntity toEntity() => NotaPendienteEntity(
    fila: fila,
    idNoPagado: idNoPagado,
    codVendedor: codVendedor,
    nombreVen: nombreVen,
    fechaDoc: fechaDoc,
    mes: mes,
    anio: anio,
    docNum: docNum,
    valido: valido,
    indicador: indicador,
    estado: estado,
    montoTotalBs: montoTotalBs,
    montoCerradoBs: montoCerradoBs,
    origen: origen,
    saldoPendiente: saldoPendiente,
  );
}

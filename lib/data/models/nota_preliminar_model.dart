import 'dart:convert';

import 'package:bosque_flutter/domain/entities/nota_preliminar_entity.dart';

NotaPreliminarModel notaPreliminarModelFromJson(String str) =>
    NotaPreliminarModel.fromJson(json.decode(str));

String notaPreliminarModelToJson(NotaPreliminarModel data) =>
    json.encode(data.toJson());

/// Mapea la rama G1 de p_list_paraPagar.
///
/// El backend serializa con @JsonInclude(NON_NULL), asi que la fila de total
/// llega con casi todas las claves ausentes: todo lo que no sea el monto es
/// nullable a proposito.
class NotaPreliminarModel {
  NotaPreliminarModel({
    required this.idVendedor,
    required this.nombreVen,
    this.fechaDoc,
    this.mes,
    this.anio,
    required this.docNum,
    this.valido,
    this.indicador,
    this.estado,
    required this.montoCerradoBs,
    this.origen,
    this.tc,
    this.fechaUltimoPago,
    this.diferenciaDias,
  });

  final int idVendedor;
  final String nombreVen;
  final DateTime? fechaDoc;
  final int? mes;
  final int? anio;
  final int docNum;
  final String? valido;
  final String? indicador;
  final String? estado;
  final double montoCerradoBs;
  final String? origen;
  final double? tc;
  final DateTime? fechaUltimoPago;
  final int? diferenciaDias;

  static double? _num(dynamic v) => (v as num?)?.toDouble();

  /// Las fechas llegan como ISO-8601 o como epoch en milisegundos segun como
  /// Jackson serialice el java.util.Date, asi que se aceptan las dos formas.
  static DateTime? _fecha(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.tryParse(v.toString());
  }

  factory NotaPreliminarModel.fromJson(Map<String, dynamic> json) =>
      NotaPreliminarModel(
        idVendedor: json['idVendedor'] ?? 0,
        nombreVen: json['nombreVen'] ?? '',
        fechaDoc: _fecha(json['fechaDoc']),
        mes: json['mes'],
        anio: json['anio'],
        docNum: json['docNum'] ?? 0,
        valido: json['valido'],
        indicador: json['indicador'],
        estado: json['estado'],
        // La clave va en BS mayuscula: es el alias de la columna del SP y el
        // backend serializa el campo con ese mismo nombre, igual que
        // PreliminarComision.
        montoCerradoBs: _num(json['montoCerradoBS']) ?? 0.0,
        origen: json['origen'],
        tc: _num(json['tc']),
        fechaUltimoPago: _fecha(json['fechaUltimoPago']),
        diferenciaDias: json['diferenciaDias'],
      );

  Map<String, dynamic> toJson() => {
    'idVendedor': idVendedor,
    'nombreVen': nombreVen,
    'fechaDoc': fechaDoc?.toIso8601String(),
    'mes': mes,
    'anio': anio,
    'docNum': docNum,
    'valido': valido,
    'indicador': indicador,
    'estado': estado,
    'montoCerradoBS': montoCerradoBs,
    'origen': origen,
    'tc': tc,
    'fechaUltimoPago': fechaUltimoPago?.toIso8601String(),
    'diferenciaDias': diferenciaDias,
  };

  NotaPreliminarEntity toEntity() => NotaPreliminarEntity(
    idVendedor: idVendedor,
    nombreVen: nombreVen,
    fechaDoc: fechaDoc,
    mes: mes,
    anio: anio,
    docNum: docNum,
    valido: valido,
    indicador: indicador,
    estado: estado,
    montoCerradoBs: montoCerradoBs,
    origen: origen,
    tc: tc,
    fechaUltimoPago: fechaUltimoPago,
    diferenciaDias: diferenciaDias,
  );
}

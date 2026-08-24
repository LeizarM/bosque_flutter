import 'dart:convert';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';

PreliminarComisionModel preliminarComisionModelFromJson(String str) =>
    PreliminarComisionModel.fromJson(json.decode(str));

String preliminarComisionModelToJson(PreliminarComisionModel data) =>
    json.encode(data.toJson());

/// Mapea el resultado de p_list_paraPagar, que llega con alias distintos segun
/// la rama. El backend serializa con @JsonInclude(NON_NULL), asi que las claves
/// que la rama no devuelve directamente no vienen en el JSON.
class PreliminarComisionModel {
  int ord;

  // idVendedor en las ramas F, I y J; idv en la K.
  int? idVendedor;
  int? idv;

  int? mes;
  int? anio;

  // grupo en F, I y J; tipo en la K.
  String? grupo;
  String? tipo;

  String nombreVen;
  double comision;
  int ignoraComision;

  // El alias del monto base cambia por rama.
  double? montoPagadoBs; // F, I
  double? montoCerradoBs; // J, K
  double? montoTotalBs; // solo K
  double? ventaTotalMesUsd; // solo J

  double bsAPagar;

  // usd en F e I; usdAPagar en J y K.
  double? usd;
  double? usdAPagar;

  PreliminarComisionModel({
    required this.ord,
    this.idVendedor,
    this.idv,
    this.mes,
    this.anio,
    this.grupo,
    this.tipo,
    required this.nombreVen,
    required this.comision,
    required this.ignoraComision,
    this.montoPagadoBs,
    this.montoCerradoBs,
    this.montoTotalBs,
    this.ventaTotalMesUsd,
    required this.bsAPagar,
    this.usd,
    this.usdAPagar,
  });

  static double? _num(dynamic v) => (v as num?)?.toDouble();

  factory PreliminarComisionModel.fromJson(Map<String, dynamic> json) =>
      PreliminarComisionModel(
        ord: json["ord"] ?? 0,
        idVendedor: json["idVendedor"],
        idv: json["idv"],
        mes: json["mes"],
        anio: json["anio"],
        grupo: json["grupo"],
        tipo: json["tipo"],
        nombreVen: json["nombreVen"] ?? '',
        comision: _num(json["comision"]) ?? 0.0,
        ignoraComision: json["ignoraComision"] ?? 0,
        montoPagadoBs: _num(json["montoPagadoBS"]),
        montoCerradoBs: _num(json["montoCerradoBS"]),
        montoTotalBs: _num(json["montoTotalBS"]),
        ventaTotalMesUsd: _num(json["ventaTotalMesUSD"]),
        bsAPagar: _num(json["bsAPagar"]) ?? 0.0,
        usd: _num(json["usd"]),
        usdAPagar: _num(json["usdAPagar"]),
      );

  Map<String, dynamic> toJson() => {
    "ord": ord,
    "idVendedor": idVendedor,
    "idv": idv,
    "mes": mes,
    "anio": anio,
    "grupo": grupo,
    "tipo": tipo,
    "nombreVen": nombreVen,
    "comision": comision,
    "ignoraComision": ignoraComision,
    "montoPagadoBS": montoPagadoBs,
    "montoCerradoBS": montoCerradoBs,
    "montoTotalBS": montoTotalBs,
    "ventaTotalMesUSD": ventaTotalMesUsd,
    "bsAPagar": bsAPagar,
    "usd": usd,
    "usdAPagar": usdAPagar,
  };

  PreliminarComisionEntity toEntity() => PreliminarComisionEntity(
    ord: ord,
    idVendedor: idVendedor ?? idv,
    mes: mes,
    anio: anio,
    // Las filas de total llegan sin etiqueta en algunas ramas.
    etiqueta: grupo ?? tipo ?? '',
    nombreVen: nombreVen,
    comision: comision,
    ignoraComision: ignoraComision,
    montoBase: montoPagadoBs ?? montoCerradoBs ?? montoTotalBs ?? 0.0,
    montoTotalBs: montoTotalBs,
    ventaTotalMesUsd: ventaTotalMesUsd,
    bsAPagar: bsAPagar,
    usdAPagar: usd ?? usdAPagar ?? 0.0,
  );
}

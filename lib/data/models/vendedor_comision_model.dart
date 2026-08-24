import 'dart:convert';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';

VendedorComisionModel vendedorComisionModelFromJson(String str) =>
    VendedorComisionModel.fromJson(json.decode(str));

String vendedorComisionModelToJson(VendedorComisionModel data) =>
    json.encode(data.toJson());

class VendedorComisionModel {
  BigInt idVendedor;
  String nomVenSap;
  double comision;
  int esInterno;
  int activo;
  BigInt audUsuario;

  int? codVenPapirus;
  int? codVenImpexpap;
  int? codVenPapelbol;
  int? codVenEsppapel;
  int? codVenProdpap;

  VendedorComisionModel({
    required this.idVendedor,
    required this.nomVenSap,
    required this.comision,
    required this.esInterno,
    required this.activo,
    required this.audUsuario,
    this.codVenPapirus,
    this.codVenImpexpap,
    this.codVenPapelbol,
    this.codVenEsppapel,
    this.codVenProdpap,
  });

  factory VendedorComisionModel.fromJson(Map<String, dynamic> json) =>
      VendedorComisionModel(
        idVendedor:
            json["idVendedor"] != null
                ? BigInt.from(json["idVendedor"])
                : BigInt.zero,
        nomVenSap: json["nomVenSap"] ?? '',
        comision: (json["comision"] as num?)?.toDouble() ?? 0.0,
        esInterno: json["esInterno"] ?? 0,
        activo: json["activo"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        codVenPapirus: json["codVenPAPIRUS"],
        codVenImpexpap: json["codVenIMPEXPAP"],
        codVenPapelbol: json["codVenPAPELBOL"],
        codVenEsppapel: json["codVenESPPAPEL"],
        codVenProdpap: json["codVenPRODPAP"],
      );

  Map<String, dynamic> toJson() => {
    "idVendedor": idVendedor.toInt(),
    "nomVenSap": nomVenSap,
    "comision": comision,
    "esInterno": esInterno,
    "activo": activo,
    "audUsuario": audUsuario.toInt(),
    // El backend arma el XML de codigos por empresa a partir de este mapa.
    "empresasXml": _construirEmpresasXml(),
  };

  /// SQL Server 2008 no tiene JSON: los codigos por empresa viajan como XML.
  /// Formato esperado por p_abm_tcom_Vendedor: `<e><i c="1" v="1234"/></e>`
  String? _construirEmpresasXml() {
    // bd real de cada empresa, segun tcom_empresaSap. El orden NO coincide
    // con el de las columnas codVen* de la tabla.
    const bdPorSigla = <String, int>{
      'IMPEXPAP': 1,
      'PAPELBOL': 2,
      'PAPIRUS': 3,
      'ESPPAPEL': 4,
      'PRODPAP': 5,
    };
    final valores = <String, int?>{
      'PAPIRUS': codVenPapirus,
      'IMPEXPAP': codVenImpexpap,
      'PAPELBOL': codVenPapelbol,
      'ESPPAPEL': codVenEsppapel,
      'PRODPAP': codVenProdpap,
    };

    final items = StringBuffer();
    valores.forEach((sigla, codVen) {
      if (codVen != null && codVen > 0) {
        items.write('<i c="${bdPorSigla[sigla]}" v="$codVen"/>');
      }
    });

    if (items.isEmpty) return null;
    return '<e>$items</e>';
  }

  VendedorComisionEntity toEntity() => VendedorComisionEntity(
    idVendedor: idVendedor,
    nomVenSap: nomVenSap,
    comision: comision,
    esInterno: esInterno,
    activo: activo,
    audUsuario: audUsuario,
    codVenPapirus: codVenPapirus,
    codVenImpexpap: codVenImpexpap,
    codVenPapelbol: codVenPapelbol,
    codVenEsppapel: codVenEsppapel,
    codVenProdpap: codVenProdpap,
  );

  factory VendedorComisionModel.fromEntity(VendedorComisionEntity entity) =>
      VendedorComisionModel(
        idVendedor: entity.idVendedor,
        nomVenSap: entity.nomVenSap,
        comision: entity.comision,
        esInterno: entity.esInterno,
        activo: entity.activo,
        audUsuario: entity.audUsuario,
        codVenPapirus: entity.codVenPapirus,
        codVenImpexpap: entity.codVenImpexpap,
        codVenPapelbol: entity.codVenPapelbol,
        codVenEsppapel: entity.codVenEsppapel,
        codVenProdpap: entity.codVenProdpap,
      );
}

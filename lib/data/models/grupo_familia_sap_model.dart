import 'dart:convert';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';

GrupoFamiliaSapModel grupoFamiliaSapModelFromJson(String str) =>
    GrupoFamiliaSapModel.fromJson(json.decode(str));

String grupoFamiliaSapModelToJson(GrupoFamiliaSapModel data) =>
    json.encode(data.toJson());

class GrupoFamiliaSapModel {
  BigInt idGrpFamiliaSap;
  String codGrpFamSap;
  String codGrpFamSapEpp;
  String codGrpFamSapProdPap;
  String grpFam;
  String alias;
  BigInt audUsuario;
  DateTime? audFecha;

  GrupoFamiliaSapModel({
    required this.idGrpFamiliaSap,
    required this.codGrpFamSap,
    required this.codGrpFamSapEpp,
    required this.codGrpFamSapProdPap,
    required this.grpFam,
    required this.alias,
    required this.audUsuario,
    this.audFecha,
  });

  // Los tres codigos SAP son varchar(20) en la tabla, no numericos: se leen con
  // toString() porque el SP legacy todavia puede devolverlos como numero en
  // registros viejos, y parsearlos a int perderia los alfanumericos.
  factory GrupoFamiliaSapModel.fromJson(Map<String, dynamic> json) =>
      GrupoFamiliaSapModel(
        idGrpFamiliaSap:
            json["idGrpFamiliaSap"] != null
                ? BigInt.from(json["idGrpFamiliaSap"])
                : BigInt.zero,
        codGrpFamSap: json["codGrpFamSap"]?.toString() ?? '',
        codGrpFamSapEpp: json["codGrpFamSapEpp"]?.toString() ?? '',
        codGrpFamSapProdPap: json["codGrpFamSapProdPap"]?.toString() ?? '',
        grpFam: json["grpFam"] ?? '',
        alias: json["alias"] ?? '',
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // audFecha no se envia: el procedimiento la pisa con GETDATE() cuando llega
  // en null, asi que mandarla desde el cliente solo genera desfases de reloj.
  //
  // codGrpFamSapProdPap si se envia siempre. El proc lo graba con
  // ISNULL(@codGrpFamSapProdPap, codGrpFamSapProdPap) para proteger al JSF
  // viejo; al mandarlo siempre, esta app deja lo que muestra la pantalla y una
  // cadena vacia limpia la columna a proposito.
  Map<String, dynamic> toJson() => {
    "idGrpFamiliaSap": idGrpFamiliaSap.toInt(),
    "codGrpFamSap": codGrpFamSap,
    "codGrpFamSapEpp": codGrpFamSapEpp,
    "codGrpFamSapProdPap": codGrpFamSapProdPap,
    "grpFam": grpFam,
    "alias": alias,
    "audUsuario": audUsuario.toInt(),
  };

  GrupoFamiliaSapEntity toEntity() => GrupoFamiliaSapEntity(
    idGrpFamiliaSap: idGrpFamiliaSap,
    codGrpFamSap: codGrpFamSap,
    codGrpFamSapEpp: codGrpFamSapEpp,
    codGrpFamSapProdPap: codGrpFamSapProdPap,
    grpFam: grpFam,
    alias: alias,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory GrupoFamiliaSapModel.fromEntity(GrupoFamiliaSapEntity e) =>
      GrupoFamiliaSapModel(
        idGrpFamiliaSap: e.idGrpFamiliaSap,
        codGrpFamSap: e.codGrpFamSap,
        codGrpFamSapEpp: e.codGrpFamSapEpp,
        codGrpFamSapProdPap: e.codGrpFamSapProdPap,
        grpFam: e.grpFam,
        alias: e.alias,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

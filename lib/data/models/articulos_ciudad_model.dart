import 'dart:convert';

import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';

List<ArticulosxCiudadModel> articulosxCiudadModelFromJson(String str) => List<ArticulosxCiudadModel>.from(json.decode(str).map((x) => ArticulosxCiudadModel.fromJson(x)));

String articulosxCiudadModelToJson(List<ArticulosxCiudadModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ArticulosxCiudadModel {
    final String codArticulo;
    final String datoArt;
    final int listaPrecio;
    final double precio;
    final String? moneda;
    final double gramaje;
    final int codigoFamilia;
    final int disponible;
    final String? unidadMedida;
    final int codCiudad;
    final int codGrpFamiliaSap;
    final String ruta;
    final int audUsuario;
    final String db;
    final dynamic whsCode;
    final dynamic whsName;
    final String condicionPrecio;
    final dynamic ciudad;
    final double utm;

    ArticulosxCiudadModel({
        required this.codArticulo,
        required this.datoArt,
        required this.listaPrecio,
        required this.precio,
        required this.moneda,
        required this.gramaje,
        required this.codigoFamilia,
        required this.disponible,
        required this.unidadMedida,
        required this.codCiudad,
        required this.codGrpFamiliaSap,
        required this.ruta,
        required this.audUsuario,
        required this.db,
        required this.whsCode,
        required this.whsName,
        required this.condicionPrecio,
        required this.ciudad,
        required this.utm,
    });

    factory ArticulosxCiudadModel.fromJson(Map<String, dynamic> json) => ArticulosxCiudadModel(
        codArticulo: json["codArticulo"],
        datoArt: json["datoArt"],
        listaPrecio: json["listaPrecio"],
        precio: json["precio"]?.toDouble(),
        moneda: json["moneda"],
        gramaje: json["gramaje"],
        codigoFamilia: json["codigoFamilia"],
        disponible: json["disponible"],
        unidadMedida: json["unidadMedida"],
        codCiudad: json["codCiudad"],
        codGrpFamiliaSap: json["codGrpFamiliaSap"],
        ruta: json["ruta"],
        audUsuario: json["audUsuario"],
        db: json["db"],
        whsCode: json["whsCode"],
        whsName: json["whsName"],
        condicionPrecio: json["condicionPrecio"],
        ciudad: json["ciudad"],
        utm: json["utm"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "codArticulo": codArticulo,
        "datoArt": datoArt,
        "listaPrecio": listaPrecio,
        "precio": precio,
        "moneda": moneda,
        "gramaje": gramaje,
        "codigoFamilia": codigoFamilia,
        "disponible": disponible,
        "unidadMedida": unidadMedida,
        "codCiudad": codCiudad,
        "codGrpFamiliaSap": codGrpFamiliaSap,
        "ruta": ruta,
        "audUsuario": audUsuario,
        "db": db,
        "whsCode": whsCode,
        "whsName": whsName,
        "condicionPrecio": condicionPrecio,
        "ciudad": ciudad,
        "utm": utm,
    };

  ArticulosxCiudadEntity toEntity() {
    return (
      ArticulosxCiudadEntity(
          codArticulo: codArticulo,
          datoArt: datoArt,
          listaPrecio: listaPrecio,
          precio: precio,
          moneda: moneda,
          gramaje: gramaje,
          codigoFamilia: codigoFamilia,
          disponible: disponible,
          unidadMedida: unidadMedida,
          codCiudad: codCiudad,
          codGrpFamiliaSap: codGrpFamiliaSap,
          ruta: ruta,
          audUsuario: audUsuario,
          db: db,
          whsCode: whsCode,
          whsName: whsName,
          condicionPrecio: condicionPrecio,
          ciudad: ciudad,
          utm: utm)
    );
  }
}

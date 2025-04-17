// To parse this JSON data, do
//
//     final articulosxAlmacenModel = articulosxAlmacenModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';

List<ArticulosxAlmacenModel> articulosxAlmacenModelFromJson(String str) => List<ArticulosxAlmacenModel>.from(json.decode(str).map((x) => ArticulosxAlmacenModel.fromJson(x)));

String articulosxAlmacenModelToJson(List<ArticulosxAlmacenModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ArticulosxAlmacenModel {
    final String codArticulo;
    final String datoArt;
    final int listaPrecio;
    final double precio;
    final dynamic moneda;
    final double gramaje;
    final int codigoFamilia;
    final int disponible;
    final dynamic unidadMedida;
    final int codCiudad;
    final int codGrpFamiliaSap;
    final dynamic ruta;
    final int audUsuario;
    final String db;
    final String whsCode;
    final String whsName;
    final dynamic condicionPrecio;
    final String ciudad;
    final double utm;

    ArticulosxAlmacenModel({
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

    factory ArticulosxAlmacenModel.fromJson(Map<String, dynamic> json) => ArticulosxAlmacenModel(
        codArticulo: json["codArticulo"],
        datoArt: json["datoArt"],
        listaPrecio: json["listaPrecio"],
        precio: json["precio"],
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
        utm: json["utm"],
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

    ArticulosxAlmacenEntity toEntity() {
      return ArticulosxAlmacenEntity(
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
        utm: utm,
      );
    }

}

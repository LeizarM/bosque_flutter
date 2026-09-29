import 'dart:convert';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';

ArticuloPrecioModel articuloPrecioModelFromJson(String str) =>
    ArticuloPrecioModel.fromJson(json.decode(str));

String articuloPrecioModelToJson(ArticuloPrecioModel data) =>
    json.encode(data.toJson());

class ArticuloPrecioModel {
  // codArticulo es varchar(50) y NO es autonumerico: la PK es texto y la
  // entrega el usuario o SAP. No inventar un id numerico para esta tabla.
  String codArticulo;
  int codigoFamilia;
  String datoArt;
  String datoArtExt;
  double stock;
  double utm;
  String unidadMedida;
  double gramajeSap;
  BigInt audUsuario;
  DateTime? audFecha;

  ArticuloPrecioModel({
    required this.codArticulo,
    required this.codigoFamilia,
    required this.datoArt,
    required this.datoArtExt,
    required this.stock,
    required this.utm,
    required this.unidadMedida,
    required this.gramajeSap,
    required this.audUsuario,
    required this.audFecha,
  });

  // Las nueve columnas que no son la PK admiten NULL en la tabla, y ademas el
  // listado principal (rama 'L') ni siquiera devuelve unidadMedida ni
  // gramajeSap. Por eso cada lectura lleva su valor por defecto.
  factory ArticuloPrecioModel.fromJson(Map<String, dynamic> json) =>
      ArticuloPrecioModel(
        codArticulo: json["codArticulo"] ?? '',
        codigoFamilia: json["codigoFamilia"] ?? 0,
        datoArt: json["datoArt"] ?? '',
        datoArtExt: json["datoArtExt"] ?? '',
        // BigDecimal en el backend; Dart no tiene BigDecimal y va como double.
        stock: (json["stock"] as num?)?.toDouble() ?? 0.0,
        utm: (json["utm"] as num?)?.toDouble() ?? 0.0,
        unidadMedida: json["unidadMedida"] ?? '',
        // Numerico, no texto: el model viejo lo declaraba String y eso rompia
        // cualquier comparacion de gramaje.
        gramajeSap: (json["gramajeSap"] as num?)?.toDouble() ?? 0.0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // audFecha no se envia: la sella el SP con GETDATE() y es de solo lectura.
  //
  // unidadMedida y gramajeSap las alimenta la sincronizacion con SAP y el
  // listado 'L' no las devuelve. El SP las conserva con ISNULL(@param, columna),
  // o sea que solo respeta NULL: si mandaramos '' o 0.0 pisariamos el valor de
  // SAP con basura. Por eso viajan como null cuando estan vacias o en cero.
  Map<String, dynamic> toJson() => {
    "codArticulo": codArticulo,
    "codigoFamilia": codigoFamilia,
    "datoArt": datoArt,
    "datoArtExt": datoArtExt,
    "stock": stock,
    "utm": utm,
    "unidadMedida": unidadMedida.trim().isEmpty ? null : unidadMedida.trim(),
    "gramajeSap": gramajeSap > 0 ? gramajeSap : null,
    "audUsuario": audUsuario.toInt(),
  };

  ArticuloPrecioEntity toEntity() => ArticuloPrecioEntity(
    codArticulo: codArticulo,
    codigoFamilia: codigoFamilia,
    datoArt: datoArt,
    datoArtExt: datoArtExt,
    stock: stock,
    utm: utm,
    unidadMedida: unidadMedida,
    gramajeSap: gramajeSap,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ArticuloPrecioModel.fromEntity(ArticuloPrecioEntity e) =>
      ArticuloPrecioModel(
        codArticulo: e.codArticulo,
        codigoFamilia: e.codigoFamilia,
        datoArt: e.datoArt,
        datoArtExt: e.datoArtExt,
        stock: e.stock,
        utm: e.utm,
        unidadMedida: e.unidadMedida,
        gramajeSap: e.gramajeSap,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

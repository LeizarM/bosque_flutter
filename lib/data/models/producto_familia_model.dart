import 'dart:convert';
import 'package:bosque_flutter/domain/entities/producto_familia_entity.dart';

ProductoFamiliaModel productoFamiliaModelFromJson(String str) =>
    ProductoFamiliaModel.fromJson(json.decode(str));

String productoFamiliaModelToJson(ProductoFamiliaModel data) =>
    json.encode(data.toJson());

class ProductoFamiliaModel {
  int codigoFamilia;
  BigInt idGrpFamiliaSap;
  BigInt idProveedorSap;
  BigInt idPresentacion;
  BigInt idTipo;
  BigInt idRangoGram;
  String formato;
  String gramaje;
  BigInt idColor;
  int estado;
  double costoTM;
  BigInt idPropuestaAprobada;
  BigInt audUsuario;
  DateTime? audFecha;

  ProductoFamiliaModel({
    required this.codigoFamilia,
    required this.idGrpFamiliaSap,
    required this.idProveedorSap,
    required this.idPresentacion,
    required this.idTipo,
    required this.idRangoGram,
    required this.formato,
    required this.gramaje,
    required this.idColor,
    required this.estado,
    required this.costoTM,
    required this.idPropuestaAprobada,
    required this.audUsuario,
    this.audFecha,
  });

  // Casi todas las columnas de tpr_producto son NULL en la base, por eso cada
  // campo lleva default. formato y gramaje llegan siempre vacios: hoy no hay
  // una sola fila cargada en esas dos columnas.
  factory ProductoFamiliaModel.fromJson(
    Map<String, dynamic> json,
  ) => ProductoFamiliaModel(
    codigoFamilia: json["codigoFamilia"] ?? 0,
    idGrpFamiliaSap:
        json["idGrpFamiliaSap"] != null
            ? BigInt.from(json["idGrpFamiliaSap"])
            : BigInt.zero,
    idProveedorSap:
        json["idProveedorSap"] != null
            ? BigInt.from(json["idProveedorSap"])
            : BigInt.zero,
    idPresentacion:
        json["idPresentacion"] != null
            ? BigInt.from(json["idPresentacion"])
            : BigInt.zero,
    idTipo: json["idTipo"] != null ? BigInt.from(json["idTipo"]) : BigInt.zero,
    // El backend lo llama idRangoGram, no idRangoGramaje.
    idRangoGram:
        json["idRangoGram"] != null
            ? BigInt.from(json["idRangoGram"])
            : BigInt.zero,
    formato: json["formato"] ?? '',
    gramaje: json["gramaje"] ?? '',
    idColor:
        json["idColor"] != null ? BigInt.from(json["idColor"]) : BigInt.zero,
    estado: json["estado"] ?? 0,
    // Dinero en double: Dart no tiene BigDecimal. Redondear a 2 decimales
    // recien al mostrarlo.
    costoTM: (json["costoTM"] as num?)?.toDouble() ?? 0.0,
    idPropuestaAprobada:
        json["idPropuestaAprobada"] != null
            ? BigInt.from(json["idPropuestaAprobada"])
            : BigInt.zero,
    audUsuario:
        json["audUsuario"] != null
            ? BigInt.from(json["audUsuario"])
            : BigInt.zero,
    audFecha:
        json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
  );

  // No se envian tres campos porque ninguna rama del ABM los escribe:
  //   costoTM             -> el alta lo fuerza a 0 y la modificacion no lo toca;
  //                          lo mueven las propuestas de precio.
  //   idPropuestaAprobada -> el alta lo deja en null y la modificacion no lo toca.
  //   audFecha            -> el SP la pisa siempre con GETDATE().
  // codigoFamilia SI se envia: es la PK, no es autogenerada y el ABM la exige
  // tanto en el alta como en la modificacion.
  Map<String, dynamic> toJson() => {
    "codigoFamilia": codigoFamilia,
    "idGrpFamiliaSap": idGrpFamiliaSap.toInt(),
    "idProveedorSap": idProveedorSap.toInt(),
    "idPresentacion": idPresentacion.toInt(),
    "idTipo": idTipo.toInt(),
    "idRangoGram": idRangoGram.toInt(),
    "formato": formato,
    "gramaje": gramaje,
    "idColor": idColor.toInt(),
    "estado": estado,
    "audUsuario": audUsuario.toInt(),
  };

  ProductoFamiliaEntity toEntity() => ProductoFamiliaEntity(
    codigoFamilia: codigoFamilia,
    idGrpFamiliaSap: idGrpFamiliaSap,
    idProveedorSap: idProveedorSap,
    idPresentacion: idPresentacion,
    idTipo: idTipo,
    idRangoGram: idRangoGram,
    formato: formato,
    gramaje: gramaje,
    idColor: idColor,
    estado: estado,
    costoTM: costoTM,
    idPropuestaAprobada: idPropuestaAprobada,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ProductoFamiliaModel.fromEntity(ProductoFamiliaEntity e) =>
      ProductoFamiliaModel(
        codigoFamilia: e.codigoFamilia,
        idGrpFamiliaSap: e.idGrpFamiliaSap,
        idProveedorSap: e.idProveedorSap,
        idPresentacion: e.idPresentacion,
        idTipo: e.idTipo,
        idRangoGram: e.idRangoGram,
        formato: e.formato,
        gramaje: e.gramaje,
        idColor: e.idColor,
        estado: e.estado,
        costoTM: e.costoTM,
        idPropuestaAprobada: e.idPropuestaAprobada,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

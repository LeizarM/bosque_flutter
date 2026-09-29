import 'dart:convert';
import 'package:bosque_flutter/domain/entities/precio_propuesta_entity.dart';

PrecioPropuestaModel precioPropuestaModelFromJson(String str) =>
    PrecioPropuestaModel.fromJson(json.decode(str));

String precioPropuestaModelToJson(PrecioPropuestaModel data) =>
    json.encode(data.toJson());

/// Espejo de bo.bosque.com.impexpap.model.PrecioPropuesta: las 13 columnas de
/// tpr_precioPropuesta y nada mas. Los campos de display que vienen por JOIN
/// (los DTOs A, B y D del backend) no van aca.
class PrecioPropuestaModel {
  /// PK, bigint IDENTITY. La clave JSON es "idPrecioPropuesto" (terminada en "o").
  BigInt idPrecioPropuesto;
  BigInt idPropuesta;
  BigInt idPrecio;

  /// varchar(15) en esta tabla, int en el resto del modulo. Se conserva String.
  String codigoFamilia;

  /// float(53) en BD, BigDecimal en Java. Dart no tiene BigDecimal: va en double.
  double precioActual;

  /// float(53) en BD, BigDecimal en Java. Dart no tiene BigDecimal: va en double.
  double precioPropuesto;

  /// float(53) en BD, BigDecimal en Java. Dart no tiene BigDecimal: va en double.
  double porcentaje;

  /// Denormalizado y corrupto: se envia porque el proc lo recibe, no se muestra.
  BigInt codSucursal;

  /// Denormalizado y corrupto: se envia porque el proc lo recibe, no se muestra.
  BigInt listNum;

  /// Denormalizado: copia posiblemente desfasada del nombre de la lista.
  String nombrePrecio;

  /// Denormalizado y corrupto (4013 filas mal cargadas): se envia porque el proc
  /// lo recibe, pero para mostrar hay que usar tpr_clasificacionPrecio.vpp.
  int vpp;

  BigInt audUsuario;

  /// Solo lectura: la rama L la devuelve, pero el proc la pisa con GETDATE().
  DateTime? audFecha;

  PrecioPropuestaModel({
    required this.idPrecioPropuesto,
    required this.idPropuesta,
    required this.idPrecio,
    required this.codigoFamilia,
    required this.precioActual,
    required this.precioPropuesto,
    required this.porcentaje,
    required this.codSucursal,
    required this.listNum,
    required this.nombrePrecio,
    required this.vpp,
    required this.audUsuario,
    this.audFecha,
  });

  factory PrecioPropuestaModel.fromJson(
    Map<String, dynamic> json,
  ) => PrecioPropuestaModel(
    idPrecioPropuesto:
        json["idPrecioPropuesto"] != null
            ? BigInt.from(json["idPrecioPropuesto"])
            : BigInt.zero,
    idPropuesta:
        json["idPropuesta"] != null
            ? BigInt.from(json["idPropuesta"])
            : BigInt.zero,
    idPrecio:
        json["idPrecio"] != null ? BigInt.from(json["idPrecio"]) : BigInt.zero,
    // toString() defensivo: la columna es varchar pero en el resto del modulo
    // el mismo nombre es int, asi que un SP puede devolverlo como numero.
    codigoFamilia: json["codigoFamilia"]?.toString() ?? '',
    precioActual: (json["precioActual"] as num?)?.toDouble() ?? 0.0,
    precioPropuesto: (json["precioPropuesto"] as num?)?.toDouble() ?? 0.0,
    porcentaje: (json["porcentaje"] as num?)?.toDouble() ?? 0.0,
    codSucursal:
        json["codSucursal"] != null
            ? BigInt.from(json["codSucursal"])
            : BigInt.zero,
    listNum:
        json["listNum"] != null ? BigInt.from(json["listNum"]) : BigInt.zero,
    nombrePrecio: json["nombrePrecio"] ?? '',
    vpp: json["vpp"] ?? 0,
    audUsuario:
        json["audUsuario"] != null
            ? BigInt.from(json["audUsuario"])
            : BigInt.zero,
    audFecha:
        json["audFecha"] != null ? DateTime.tryParse(json["audFecha"]) : null,
  );

  // audFecha no se envia: el proc la pisa con GETDATE() en I y en U, asi que lo
  // que se mande desde el cliente se ignora. Es un campo de solo lectura.
  // Los denormalizados (codSucursal, listNum, nombrePrecio, vpp) SI se envian:
  // el proc p_abm_precioPropuesta los recibe e inserta, aunque no sirvan para mostrar.
  Map<String, dynamic> toJson() => {
    "idPrecioPropuesto": idPrecioPropuesto.toInt(),
    "idPropuesta": idPropuesta.toInt(),
    "idPrecio": idPrecio.toInt(),
    "codigoFamilia": codigoFamilia,
    "precioActual": precioActual,
    "precioPropuesto": precioPropuesto,
    "porcentaje": porcentaje,
    "codSucursal": codSucursal.toInt(),
    "listNum": listNum.toInt(),
    "nombrePrecio": nombrePrecio,
    "vpp": vpp,
    "audUsuario": audUsuario.toInt(),
  };

  PrecioPropuestaEntity toEntity() => PrecioPropuestaEntity(
    idPrecioPropuesto: idPrecioPropuesto,
    idPropuesta: idPropuesta,
    idPrecio: idPrecio,
    codigoFamilia: codigoFamilia,
    precioActual: precioActual,
    precioPropuesto: precioPropuesto,
    porcentaje: porcentaje,
    codSucursal: codSucursal,
    listNum: listNum,
    nombrePrecio: nombrePrecio,
    vpp: vpp,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory PrecioPropuestaModel.fromEntity(PrecioPropuestaEntity e) =>
      PrecioPropuestaModel(
        idPrecioPropuesto: e.idPrecioPropuesto,
        idPropuesta: e.idPropuesta,
        idPrecio: e.idPrecio,
        codigoFamilia: e.codigoFamilia,
        precioActual: e.precioActual,
        precioPropuesto: e.precioPropuesto,
        porcentaje: e.porcentaje,
        codSucursal: e.codSucursal,
        listNum: e.listNum,
        nombrePrecio: e.nombrePrecio,
        vpp: e.vpp,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

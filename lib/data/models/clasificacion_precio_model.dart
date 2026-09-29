import 'dart:convert';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';

ClasificacionPrecioModel clasificacionPrecioModelFromJson(String str) =>
    ClasificacionPrecioModel.fromJson(json.decode(str));

String clasificacionPrecioModelToJson(ClasificacionPrecioModel data) =>
    json.encode(data.toJson());

class ClasificacionPrecioModel {
  BigInt idClasificacion;
  BigInt codSucursal;
  BigInt listNum;
  String nombrePrecio;
  int vpp;
  int estado;
  BigInt audUsuario;
  DateTime? audFecha;

  ClasificacionPrecioModel({
    required this.idClasificacion,
    required this.codSucursal,
    required this.listNum,
    required this.nombrePrecio,
    required this.vpp,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  // Todas las columnas menos la PK admiten NULL en la tabla, por eso cada
  // lectura lleva su valor por defecto.
  factory ClasificacionPrecioModel.fromJson(Map<String, dynamic> json) =>
      ClasificacionPrecioModel(
        idClasificacion:
            json["idClasificacion"] != null
                ? BigInt.from(json["idClasificacion"])
                : BigInt.zero,
        codSucursal:
            json["codSucursal"] != null
                ? BigInt.from(json["codSucursal"])
                : BigInt.zero,
        listNum:
            json["listNum"] != null
                ? BigInt.from(json["listNum"])
                : BigInt.zero,
        nombrePrecio: json["nombrePrecio"] ?? '',
        vpp: json["vpp"] ?? 0,
        estado: json["estado"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // audFecha no se envia: la sella el SP con GETDATE() y es de solo lectura.
  Map<String, dynamic> toJson() => {
    "idClasificacion": idClasificacion.toInt(),
    "codSucursal": codSucursal.toInt(),
    "listNum": listNum.toInt(),
    "nombrePrecio": nombrePrecio,
    "vpp": vpp,
    "estado": estado,
    "audUsuario": audUsuario.toInt(),
  };

  ClasificacionPrecioEntity toEntity() => ClasificacionPrecioEntity(
    idClasificacion: idClasificacion,
    codSucursal: codSucursal,
    listNum: listNum,
    nombrePrecio: nombrePrecio,
    vpp: vpp,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ClasificacionPrecioModel.fromEntity(ClasificacionPrecioEntity e) =>
      ClasificacionPrecioModel(
        idClasificacion: e.idClasificacion,
        codSucursal: e.codSucursal,
        listNum: e.listNum,
        nombrePrecio: e.nombrePrecio,
        vpp: e.vpp,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

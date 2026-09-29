import 'dart:convert';
import 'package:bosque_flutter/domain/entities/precio_entity.dart';

PrecioModel precioModelFromJson(String str) =>
    PrecioModel.fromJson(json.decode(str));

String precioModelToJson(PrecioModel data) => json.encode(data.toJson());

class PrecioModel {
  BigInt idPrecio;
  int codigoFamilia;
  BigInt idClasificacion;
  double precio;
  BigInt audUsuario;
  DateTime? audFecha;

  PrecioModel({
    required this.idPrecio,
    required this.codigoFamilia,
    required this.idClasificacion,
    required this.precio,
    required this.audUsuario,
    this.audFecha,
  });

  factory PrecioModel.fromJson(Map<String, dynamic> json) => PrecioModel(
    idPrecio:
        json["idPrecio"] != null ? BigInt.from(json["idPrecio"]) : BigInt.zero,
    codigoFamilia: json["codigoFamilia"] ?? 0,
    idClasificacion:
        json["idClasificacion"] != null
            ? BigInt.from(json["idClasificacion"])
            : BigInt.zero,
    // Llega como BigDecimal desde Java; en Dart es double.
    precio: (json["precio"] as num?)?.toDouble() ?? 0.0,
    audUsuario:
        json["audUsuario"] != null
            ? BigInt.from(json["audUsuario"])
            : BigInt.zero,
    audFecha:
        json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
  );

  // audFecha no se envia: el ABM la pisa con GETDATE() en alta y en
  // modificacion, asi que es de solo lectura para el cliente.
  Map<String, dynamic> toJson() => {
    "idPrecio": idPrecio.toInt(),
    "codigoFamilia": codigoFamilia,
    "idClasificacion": idClasificacion.toInt(),
    "precio": precio,
    "audUsuario": audUsuario.toInt(),
  };

  PrecioEntity toEntity() => PrecioEntity(
    idPrecio: idPrecio,
    codigoFamilia: codigoFamilia,
    idClasificacion: idClasificacion,
    precio: precio,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory PrecioModel.fromEntity(PrecioEntity e) => PrecioModel(
    idPrecio: e.idPrecio,
    codigoFamilia: e.codigoFamilia,
    idClasificacion: e.idClasificacion,
    precio: e.precio,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}

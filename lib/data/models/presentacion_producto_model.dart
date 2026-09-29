import 'dart:convert';
import 'package:bosque_flutter/domain/entities/presentacion_producto_entity.dart';

PresentacionProductoModel presentacionProductoModelFromJson(String str) =>
    PresentacionProductoModel.fromJson(json.decode(str));

String presentacionProductoModelToJson(PresentacionProductoModel data) =>
    json.encode(data.toJson());

class PresentacionProductoModel {
  BigInt idPresentacion;
  String presentacion;
  int estado;
  BigInt audUsuario;
  DateTime? audFecha;

  PresentacionProductoModel({
    required this.idPresentacion,
    required this.presentacion,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  // Todas las columnas menos la PK admiten NULL en la tabla, por eso cada
  // lectura lleva su valor por defecto.
  factory PresentacionProductoModel.fromJson(Map<String, dynamic> json) =>
      PresentacionProductoModel(
        idPresentacion:
            json["idPresentacion"] != null
                ? BigInt.from(json["idPresentacion"])
                : BigInt.zero,
        presentacion: json["presentacion"] ?? '',
        estado: json["estado"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // audFecha no se envia: la sella el SP con GETDATE() y es de solo lectura.
  // estado si viaja, pero en el alta el SP lo ignora y graba 1.
  Map<String, dynamic> toJson() => {
    "idPresentacion": idPresentacion.toInt(),
    "presentacion": presentacion,
    "estado": estado,
    "audUsuario": audUsuario.toInt(),
  };

  PresentacionProductoEntity toEntity() => PresentacionProductoEntity(
    idPresentacion: idPresentacion,
    presentacion: presentacion,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory PresentacionProductoModel.fromEntity(PresentacionProductoEntity e) =>
      PresentacionProductoModel(
        idPresentacion: e.idPresentacion,
        presentacion: e.presentacion,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

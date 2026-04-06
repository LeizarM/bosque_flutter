import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipos_transaccion_entity.dart';

TiposTransaccionModel tiposTransaccionModelFromJson(String str) =>
    TiposTransaccionModel.fromJson(json.decode(str));

String tiposTransaccionModelToJson(TiposTransaccionModel data) =>
    json.encode(data.toJson());

class TiposTransaccionModel {
  BigInt idTipoTransaccion;
  String codigo;
  String nombre;
  String descripcion;
  int requiereForward;
  int requiereBanco;
  int activo;
  int audUsuario;

  TiposTransaccionModel({
    required this.idTipoTransaccion,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.requiereForward,
    required this.requiereBanco,
    required this.activo,
    required this.audUsuario,
  });

  factory TiposTransaccionModel.fromJson(Map<String, dynamic> json) =>
      TiposTransaccionModel(
        idTipoTransaccion:
            json["idTipoTransaccion"] != null
                ? BigInt.from(json["idTipoTransaccion"])
                : BigInt.zero,
        codigo: json["codigo"] ?? '',
        nombre: json["nombre"] ?? '',
        descripcion: json["descripcion"] ?? '',
        requiereForward: json["requiereForward"] ?? 0,
        requiereBanco: json["requiereBanco"] ?? 0,
        activo: json["activo"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idTipoTransaccion": idTipoTransaccion.toInt(),
    "codigo": codigo,
    "nombre": nombre,
    "descripcion": descripcion,
    "requiereForward": requiereForward,
    "requiereBanco": requiereBanco,
    "activo": activo,
    "audUsuario": audUsuario,
  };

  TiposTransaccionEntity toEntity() => TiposTransaccionEntity(
    idTipoTransaccion: idTipoTransaccion,
    codigo: codigo,
    nombre: nombre,
    descripcion: descripcion,
    requiereForward: requiereForward,
    requiereBanco: requiereBanco,
    activo: activo,
    audUsuario: audUsuario,
  );

  factory TiposTransaccionModel.fromEntity(TiposTransaccionEntity entity) =>
      TiposTransaccionModel(
        idTipoTransaccion: entity.idTipoTransaccion,
        codigo: entity.codigo,
        nombre: entity.nombre,
        descripcion: entity.descripcion,
        requiereForward: entity.requiereForward,
        requiereBanco: entity.requiereBanco,
        activo: entity.activo,
        audUsuario: entity.audUsuario,
      );
}

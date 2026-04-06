import 'dart:convert';
import 'package:bosque_flutter/domain/entities/canales_pago_entity.dart';

CanalesPagoModel canalesPagoModelFromJson(String str) =>
    CanalesPagoModel.fromJson(json.decode(str));

String canalesPagoModelToJson(CanalesPagoModel data) =>
    json.encode(data.toJson());

class CanalesPagoModel {
  int idCanal;
  String nombre;
  String tipo;
  String contacto;
  int activo;
  int audUsuario;

  CanalesPagoModel({
    required this.idCanal,
    required this.nombre,
    required this.tipo,
    required this.contacto,
    required this.activo,
    required this.audUsuario,
  });

  factory CanalesPagoModel.fromJson(Map<String, dynamic> json) =>
      CanalesPagoModel(
        idCanal: json["idCanal"] ?? 0,
        nombre: json["nombre"] ?? '',
        tipo: json["tipo"] ?? '',
        contacto: json["contacto"] ?? '',
        activo: json["activo"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idCanal": idCanal,
    "nombre": nombre,
    "tipo": tipo,
    "contacto": contacto,
    "activo": activo,
    "audUsuario": audUsuario,
  };

  CanalesPagoEntity toEntity() => CanalesPagoEntity(
    idCanal: idCanal,
    nombre: nombre,
    tipo: tipo,
    contacto: contacto,
    activo: activo,
    audUsuario: audUsuario,
  );

  factory CanalesPagoModel.fromEntity(CanalesPagoEntity entity) =>
      CanalesPagoModel(
        idCanal: entity.idCanal,
        nombre: entity.nombre,
        tipo: entity.tipo,
        contacto: entity.contacto,
        activo: entity.activo,
        audUsuario: entity.audUsuario,
      );
}

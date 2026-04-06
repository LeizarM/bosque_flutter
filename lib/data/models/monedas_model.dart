import 'dart:convert';
import 'package:bosque_flutter/domain/entities/monedas_entity.dart';

MonedasModel monedasModelFromJson(String str) =>
    MonedasModel.fromJson(json.decode(str));

String monedasModelToJson(MonedasModel data) => json.encode(data.toJson());

class MonedasModel {
  int idMoneda;
  String codigo;
  String nombre;
  String simbolo;
  int decimales;
  int activo;
  int audUsuario;

  MonedasModel({
    required this.idMoneda,
    required this.codigo,
    required this.nombre,
    required this.simbolo,
    required this.decimales,
    required this.activo,
    required this.audUsuario,
  });

  factory MonedasModel.fromJson(Map<String, dynamic> json) => MonedasModel(
    idMoneda: json["idMoneda"] ?? 0,
    codigo: json["codigo"] ?? '',
    nombre: json["nombre"] ?? '',
    simbolo: json["simbolo"] ?? '',
    decimales: json["decimales"] ?? 0,
    activo: json["activo"] ?? 0,
    audUsuario: json["audUsuario"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "idMoneda": idMoneda,
    "codigo": codigo,
    "nombre": nombre,
    "simbolo": simbolo,
    "decimales": decimales,
    "activo": activo,
    "audUsuario": audUsuario,
  };

  MonedasEntity toEntity() => MonedasEntity(
    idMoneda: idMoneda,
    codigo: codigo,
    nombre: nombre,
    simbolo: simbolo,
    decimales: decimales,
    activo: activo,
    audUsuario: audUsuario,
  );

  factory MonedasModel.fromEntity(MonedasEntity entity) => MonedasModel(
    idMoneda: entity.idMoneda,
    codigo: entity.codigo,
    nombre: entity.nombre,
    simbolo: entity.simbolo,
    decimales: entity.decimales,
    activo: entity.activo,
    audUsuario: entity.audUsuario,
  );
}

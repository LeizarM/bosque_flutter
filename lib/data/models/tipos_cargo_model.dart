import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipos_cargo_entity.dart';

TiposCargoModel tiposCargoModelFromJson(String str) =>
    TiposCargoModel.fromJson(json.decode(str));

String tiposCargoModelToJson(TiposCargoModel data) =>
    json.encode(data.toJson());

class TiposCargoModel {
  BigInt idTipoCargo;
  String nombre;
  int esPorcentaje;
  int activo;
  int audUsuario;

  TiposCargoModel({
    required this.idTipoCargo,
    required this.nombre,
    required this.esPorcentaje,
    required this.activo,
    required this.audUsuario,
  });

  factory TiposCargoModel.fromJson(Map<String, dynamic> json) =>
      TiposCargoModel(
        idTipoCargo:
            json["idTipoCargo"] != null
                ? BigInt.from(json["idTipoCargo"])
                : BigInt.zero,
        nombre: json["nombre"] ?? '',
        esPorcentaje: json["esPorcentaje"] ?? 0,
        activo: json["activo"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idTipoCargo": idTipoCargo.toInt(),
    "nombre": nombre,
    "esPorcentaje": esPorcentaje,
    "activo": activo,
    "audUsuario": audUsuario,
  };

  TiposCargoEntity toEntity() => TiposCargoEntity(
    idTipoCargo: idTipoCargo,
    nombre: nombre,
    esPorcentaje: esPorcentaje,
    activo: activo,
    audUsuario: audUsuario,
  );

  factory TiposCargoModel.fromEntity(TiposCargoEntity entity) =>
      TiposCargoModel(
        idTipoCargo: entity.idTipoCargo,
        nombre: entity.nombre,
        esPorcentaje: entity.esPorcentaje,
        activo: entity.activo,
        audUsuario: entity.audUsuario,
      );
}

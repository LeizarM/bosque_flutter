// To parse this JSON data, do
//
//     final compraGarrafaModel = compraGarrafaModelFromJson(jsonString);
import 'dart:convert';

import 'package:bosque_flutter/domain/entities/compra_garrafa_entity.dart';

CompraGarrafaModel compraGarrafaModelFromJson(String str) =>
    CompraGarrafaModel.fromJson(json.decode(str));

String compraGarrafaModelToJson(CompraGarrafaModel data) =>
    json.encode(data.toJson());

class CompraGarrafaModel {
  int idCG;
  int codSucursal;
  String descripcion;
  int cantidad;
  double monto;
  int audUsuario;

  CompraGarrafaModel({
    required this.idCG,
    required this.codSucursal,
    required this.descripcion,
    required this.cantidad,
    required this.monto,
    required this.audUsuario,
  });

  factory CompraGarrafaModel.fromJson(Map<String, dynamic> json) =>
      CompraGarrafaModel(
        idCG: json["idCG"],
        codSucursal: json["codSucursal"],
        descripcion: json["descripcion"],
        cantidad: json["cantidad"],
        monto: json["monto"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idCG": idCG,
    "codSucursal": codSucursal,
    "descripcion": descripcion,
    "cantidad": cantidad,
    "monto": monto,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  CompraGarrafaEntity toEntity() => CompraGarrafaEntity(
    idCG: idCG,
    codSucursal: codSucursal,
    descripcion: descripcion,
    cantidad: cantidad,
    monto: monto,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory CompraGarrafaModel.fromEntity(CompraGarrafaEntity entity) =>
      CompraGarrafaModel(
        idCG: entity.idCG,
        codSucursal: entity.codSucursal,
        descripcion: entity.descripcion,
        cantidad: entity.cantidad,
        monto: entity.monto,
        audUsuario: entity.audUsuario,
      );
}

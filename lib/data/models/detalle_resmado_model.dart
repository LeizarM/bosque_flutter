import 'dart:convert';

import 'package:bosque_flutter/domain/entities/detalle_resmando_entity.dart';

DetalleResmadoModel detalleResmadoModelFromJson(String str) =>
    DetalleResmadoModel.fromJson(json.decode(str));

String detalleResmadoModelToJson(DetalleResmadoModel data) =>
    json.encode(data.toJson());

class DetalleResmadoModel {
  final int idRetRes;
  final int idRes;
  final String codArticulo;
  final String descripcion;
  final int cantResma;
  final int audUsuario;

  DetalleResmadoModel({
    required this.idRetRes,
    required this.idRes,
    required this.codArticulo,
    required this.descripcion,
    required this.cantResma,
    required this.audUsuario,
  });

  factory DetalleResmadoModel.fromJson(Map<String, dynamic> json) =>
      DetalleResmadoModel(
        idRetRes: json["idRetRes"] ?? 0,
        idRes: json["idRes"] ?? 0,
        codArticulo: json["codArticulo"] ?? '',
        descripcion: json["descripcion"] ?? '',
        cantResma: json["cantResma"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idRetRes": idRetRes,
    "idRes": idRes,
    "codArticulo": codArticulo,
    "descripcion": descripcion,
    "cantResma": cantResma,
    "audUsuario": audUsuario,
  };

  DetalleResmadoEntity toEntity() => DetalleResmadoEntity(
    idRetRes: idRetRes,
    idRes: idRes,
    codArticulo: codArticulo,
    descripcion: descripcion,
    cantResma: cantResma,
    audUsuario: audUsuario,
  );

  factory DetalleResmadoModel.fromEntity(DetalleResmadoEntity entity) =>
      DetalleResmadoModel(
        idRetRes: entity.idRetRes,
        idRes: entity.idRes,
        codArticulo: entity.codArticulo,
        descripcion: entity.descripcion,
        cantResma: entity.cantResma,
        audUsuario: entity.audUsuario,
      );
}

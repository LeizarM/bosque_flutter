import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_contenedor_entity.dart';

TipoContenedorModel tipoContenedorModelFromJson(String str) =>
    TipoContenedorModel.fromJson(json.decode(str));

String tipoContenedorModelToJson(TipoContenedorModel data) =>
    json.encode(data.toJson());

class TipoContenedorModel {
  int idTipo;
  String tipo;
  int audUsuario;

  TipoContenedorModel({
    required this.idTipo,
    required this.tipo,
    required this.audUsuario,
  });

  factory TipoContenedorModel.fromJson(Map<String, dynamic> json) =>
      TipoContenedorModel(
        idTipo: json["idTipo"],
        tipo: json["tipo"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idTipo": idTipo,
    "tipo": tipo,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  TipoContenedorEntity toEntity() =>
      TipoContenedorEntity(idTipo: idTipo, tipo: tipo, audUsuario: audUsuario);

  // Método factory para convertir de Entity a Model
  factory TipoContenedorModel.fromEntity(TipoContenedorEntity entity) =>
      TipoContenedorModel(
        idTipo: entity.idTipo,
        tipo: entity.tipo,
        audUsuario: entity.audUsuario,
      );
}

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';

MaquinaProduccionModel maquinaProduccionModelFromJson(String str) =>
    MaquinaProduccionModel.fromJson(json.decode(str));

String maquinaProduccionModelToJson(MaquinaProduccionModel data) =>
    json.encode(data.toJson());

class MaquinaProduccionModel {
  final int idMa;
  final String descripcion;
  final int numero;
  final int audUsuario;

  MaquinaProduccionModel({
    required this.idMa,
    required this.descripcion,
    required this.numero,
    required this.audUsuario,
  });

  factory MaquinaProduccionModel.fromJson(Map<String, dynamic> json) =>
      MaquinaProduccionModel(
        idMa: json['idMa'] ?? 0,
        descripcion: json['descripcion'] ?? '',
        numero: json['numero'] ?? 0,
        audUsuario: json['audUsuario'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'idMa': idMa,
    'descripcion': descripcion,
    'numero': numero,
    'audUsuario': audUsuario,
  };

  MaquinaProduccionEntity toEntity() => MaquinaProduccionEntity(
    idMa: idMa,
    descripcion: descripcion,
    numero: numero,
    audUsuario: audUsuario,
  );

  factory MaquinaProduccionModel.fromEntity(MaquinaProduccionEntity entity) =>
      MaquinaProduccionModel(
        idMa: entity.idMa,
        descripcion: entity.descripcion,
        numero: entity.numero,
        audUsuario: entity.audUsuario,
      );
}

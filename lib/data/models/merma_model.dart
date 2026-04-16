import 'dart:convert';

import 'package:bosque_flutter/domain/entities/merma_entity.dart';

MermaModel mermaModelFromJson(String str) =>
    MermaModel.fromJson(json.decode(str));

String mermaModelToJson(MermaModel data) => json.encode(data.toJson());

class MermaModel {
  final int idMe;
  final int idLp;
  final String codArticulo;
  final String descripcion;
  final double peso;
  final int audUsuario;

  MermaModel({
    required this.idMe,
    required this.idLp,
    required this.codArticulo,
    required this.descripcion,
    required this.peso,
    required this.audUsuario,
  });

  factory MermaModel.fromJson(Map<String, dynamic> json) => MermaModel(
    idMe: json['idMe'] ?? 0,
    idLp: json['idLp'] ?? 0,
    codArticulo: json['codArticulo'] ?? '',
    descripcion: json['descripcion'] ?? '',
    peso: (json['peso'] ?? 0).toDouble(),
    audUsuario: json['audUsuario'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'idMe': idMe,
    'idLp': idLp,
    'codArticulo': codArticulo,
    'descripcion': descripcion,
    'peso': peso,
    'audUsuario': audUsuario,
  };

  MermaEntity toEntity() => MermaEntity(
    idMe: idMe,
    idLp: idLp,
    codArticulo: codArticulo,
    descripcion: descripcion,
    peso: peso,
    audUsuario: audUsuario,
  );

  factory MermaModel.fromEntity(MermaEntity entity) => MermaModel(
    idMe: entity.idMe,
    idLp: entity.idLp,
    codArticulo: entity.codArticulo,
    descripcion: entity.descripcion,
    peso: entity.peso,
    audUsuario: entity.audUsuario,
  );
}

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';

MaterialIngresoModel materialIngresoModelFromJson(String str) =>
    MaterialIngresoModel.fromJson(json.decode(str));

String materialIngresoModelToJson(MaterialIngresoModel data) =>
    json.encode(data.toJson());

class MaterialIngresoModel {
  final int idMi;
  final int idLp;
  final String codArticulo;
  final String descripcion;
  final double pesoKilos;
  final double balanza;
  final String numImportacion;
  final int audUsuario;

  MaterialIngresoModel({
    required this.idMi,
    required this.idLp,
    required this.codArticulo,
    required this.descripcion,
    required this.pesoKilos,
    required this.balanza,
    required this.numImportacion,
    required this.audUsuario,
  });

  factory MaterialIngresoModel.fromJson(Map<String, dynamic> json) =>
      MaterialIngresoModel(
        idMi: json['idMi'] ?? 0,
        idLp: json['idLp'] ?? 0,
        codArticulo: json['codArticulo'] ?? '',
        descripcion: json['descripcion'] ?? '',
        pesoKilos: (json['pesoKilos'] ?? 0).toDouble(),
        balanza: (json['balanza'] ?? 0).toDouble(),
        numImportacion: json['numImportacion'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'idMi': idMi,
    'idLp': idLp,
    'codArticulo': codArticulo,
    'descripcion': descripcion,
    'pesoKilos': pesoKilos,
    'balanza': balanza,
    'numImportacion': numImportacion,
    'audUsuario': audUsuario,
  };

  MaterialIngresoEntity toEntity() => MaterialIngresoEntity(
    idMi: idMi,
    idLp: idLp,
    codArticulo: codArticulo,
    descripcion: descripcion,
    pesoKilos: pesoKilos,
    balanza: balanza,
    numImportacion: numImportacion,
    audUsuario: audUsuario,
  );

  factory MaterialIngresoModel.fromEntity(MaterialIngresoEntity entity) =>
      MaterialIngresoModel(
        idMi: entity.idMi,
        idLp: entity.idLp,
        codArticulo: entity.codArticulo,
        descripcion: entity.descripcion,
        pesoKilos: entity.pesoKilos,
        balanza: entity.balanza,
        numImportacion: entity.numImportacion,
        audUsuario: entity.audUsuario,
      );
}

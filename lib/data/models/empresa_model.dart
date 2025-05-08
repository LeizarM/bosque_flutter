import 'dart:convert';

import 'package:bosque_flutter/domain/entities/empresa_entity.dart';

EmpresaModel empresaModelFromJson(String str) =>
    EmpresaModel.fromJson(json.decode(str));

String empresaModelToJson(EmpresaModel data) => json.encode(data.toJson());

class EmpresaModel {
  final int codEmpresa;
  final String nombre;
  final int codPadre;
  final String sigla;
  final int audUsuario;

  EmpresaModel({
    required this.codEmpresa,
    required this.nombre,
    required this.codPadre,
    required this.sigla,
    required this.audUsuario,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) => EmpresaModel(
    codEmpresa: json["codEmpresa"],
    nombre: json["nombre"],
    codPadre: json["codPadre"],
    sigla: json["sigla"] ?? "",
    audUsuario: json["audUsuario"],
  );

  Map<String, dynamic> toJson() => {
    "codEmpresa": codEmpresa,
    "nombre": nombre,
    "codPadre": codPadre,
    "sigla": sigla,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  EmpresaEntity toEntity() => EmpresaEntity(
    codEmpresa: codEmpresa,
    nombre: nombre,
    codPadre: codPadre,
    sigla: sigla,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory EmpresaModel.fromEntity(EmpresaEntity entity) => EmpresaModel(
    codEmpresa: entity.codEmpresa,
    nombre: entity.nombre,
    codPadre: entity.codPadre,
    sigla: entity.sigla,
    audUsuario: entity.audUsuario,
  );
}

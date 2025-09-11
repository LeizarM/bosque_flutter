// To parse this JSON data, do
//
//     final contenedorModel = contenedorModelFromJson(jsonString);

import 'dart:convert';
import 'package:bosque_flutter/domain/entities/contenedor_entity.dart';

ContenedorModel contenedorModelFromJson(String str) =>
    ContenedorModel.fromJson(json.decode(str));

String contenedorModelToJson(ContenedorModel data) =>
    json.encode(data.toJson());

class ContenedorModel {
  int idContenedor;
  String codigo;
  int idTipo;
  int codSucursal;
  String descripcion;
  String unidadMedida;
  int audUsuario;
  String clase;
  double saldoActualCombustible;
  String nombreSucursal;
  int codCiudad;

  ContenedorModel({
    required this.idContenedor,
    required this.codigo,
    required this.idTipo,
    required this.codSucursal,
    required this.descripcion,
    required this.unidadMedida,
    required this.audUsuario,
    required this.clase,
    required this.saldoActualCombustible,
    required this.nombreSucursal,
    required this.codCiudad,
  });

  factory ContenedorModel.fromJson(Map<String, dynamic> json) =>
      ContenedorModel(
        idContenedor: json["idContenedor"],
        codigo: json["codigo"],
        idTipo: json["idTipo"],
        codSucursal: json["codSucursal"],
        descripcion: json["descripcion"],
        unidadMedida: json["unidadMedida"],
        audUsuario: json["audUsuario"],
        clase: json["clase"],
        saldoActualCombustible: json["saldoActualCombustible"],
        nombreSucursal: json["nombreSucursal"],
        codCiudad: json["codCiudad"],
      );

  Map<String, dynamic> toJson() => {
    "idContenedor": idContenedor,
    "codigo": codigo,
    "idTipo": idTipo,
    "codSucursal": codSucursal,
    "descripcion": descripcion,
    "unidadMedida": unidadMedida,
    "audUsuario": audUsuario,
    "clase": clase,
    "saldoActualCombustible": saldoActualCombustible,
    "nombreSucursal": nombreSucursal,
    "codCiudad": codCiudad,
  };

  // Método para convertir de Model a Entity
  ContenedorEntity toEntity() => ContenedorEntity(
    idContenedor: idContenedor,
    codigo: codigo,
    idTipo: idTipo,
    codSucursal: codSucursal,
    descripcion: descripcion,
    unidadMedida: unidadMedida,
    audUsuario: audUsuario,
    clase: clase,
    saldoActualCombustible: saldoActualCombustible,
    nombreSucursal: nombreSucursal,
    codCiudad: codCiudad,
  );

  // Método factory para convertir de Entity a Model
  factory ContenedorModel.fromEntity(ContenedorEntity entity) =>
      ContenedorModel(
        idContenedor: entity.idContenedor,
        codigo: entity.codigo,
        idTipo: entity.idTipo,
        codSucursal: entity.codSucursal,
        descripcion: entity.descripcion,
        unidadMedida: entity.unidadMedida,
        audUsuario: entity.audUsuario,
        clase: entity.clase,
        saldoActualCombustible: entity.saldoActualCombustible,
        nombreSucursal: entity.nombreSucursal,
        codCiudad: entity.codCiudad,
      );
}

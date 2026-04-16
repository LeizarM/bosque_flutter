import 'dart:convert';

import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';

MaterialSalidaModel materialSalidaModelFromJson(String str) =>
    MaterialSalidaModel.fromJson(json.decode(str));

String materialSalidaModelToJson(MaterialSalidaModel data) =>
    json.encode(data.toJson());

class MaterialSalidaModel {
  final int idMs;
  final int idLp;
  final String codArticulo;
  final String descripcion;
  final int nroPaleta;
  final double pesoResma;
  final double pesoPaleta;
  final double pesoMaterial;
  final int cantidadResma;
  final int cantidadHojas;
  final int audUsuario;

  MaterialSalidaModel({
    required this.idMs,
    required this.idLp,
    required this.codArticulo,
    required this.descripcion,
    required this.nroPaleta,
    required this.pesoResma,
    required this.pesoPaleta,
    required this.pesoMaterial,
    required this.cantidadResma,
    required this.cantidadHojas,
    required this.audUsuario,
  });

  factory MaterialSalidaModel.fromJson(Map<String, dynamic> json) =>
      MaterialSalidaModel(
        idMs: json['idMs'] ?? 0,
        idLp: json['idLp'] ?? 0,
        codArticulo: json['codArticulo'] ?? '',
        descripcion: json['descripcion'] ?? '',
        nroPaleta: json['nroPaleta'] ?? 0,
        pesoResma: (json['pesoResma'] ?? 0).toDouble(),
        pesoPaleta: (json['pesoPaleta'] ?? 0).toDouble(),
        pesoMaterial: (json['pesoMaterial'] ?? 0).toDouble(),
        cantidadResma: json['cantidadResma'] ?? 0,
        cantidadHojas: json['cantidadHojas'] ?? 0,
        audUsuario: json['audUsuario'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'idMs': idMs,
    'idLp': idLp,
    'codArticulo': codArticulo,
    'descripcion': descripcion,
    'nroPaleta': nroPaleta,
    'pesoResma': pesoResma,
    'pesoPaleta': pesoPaleta,
    'pesoMaterial': pesoMaterial,
    'cantidadResma': cantidadResma,
    'cantidadHojas': cantidadHojas,
    'audUsuario': audUsuario,
  };

  MaterialSalidaEntity toEntity() => MaterialSalidaEntity(
    idMs: idMs,
    idLp: idLp,
    codArticulo: codArticulo,
    descripcion: descripcion,
    nroPaleta: nroPaleta,
    pesoResma: pesoResma,
    pesoPaleta: pesoPaleta,
    pesoMaterial: pesoMaterial,
    cantidadResma: cantidadResma,
    cantidadHojas: cantidadHojas,
    audUsuario: audUsuario,
  );

  factory MaterialSalidaModel.fromEntity(MaterialSalidaEntity entity) =>
      MaterialSalidaModel(
        idMs: entity.idMs,
        idLp: entity.idLp,
        codArticulo: entity.codArticulo,
        descripcion: entity.descripcion,
        nroPaleta: entity.nroPaleta,
        pesoResma: entity.pesoResma,
        pesoPaleta: entity.pesoPaleta,
        pesoMaterial: entity.pesoMaterial,
        cantidadResma: entity.cantidadResma,
        cantidadHojas: entity.cantidadHojas,
        audUsuario: entity.audUsuario,
      );
}

// To parse this JSON data, do
//
//     final licenciaConducirModel = licenciaConducirModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';

List<LicenciaConducirModel> licenciaConducirModelFromJson(String str) => List<LicenciaConducirModel>.from(json.decode(str).map((x) => LicenciaConducirModel.fromJson(x)));

String licenciaConducirModelToJson(List<LicenciaConducirModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LicenciaConducirModel {
    final int codLicencia;
    final int codPersona;
    final String categoria;
    final DateTime fechaCaducidad;
    final int audUsuario;

    LicenciaConducirModel({
        required this.codLicencia,
        required this.codPersona,
        required this.categoria,
        required this.fechaCaducidad,
        required this.audUsuario,
    });

    factory LicenciaConducirModel.fromJson(Map<String, dynamic> json) => LicenciaConducirModel(
        codLicencia: json["codLicencia"]?? 0,
        codPersona: json["codPersona"]?? 0,
        categoria: json["categoria"]?? '',
        fechaCaducidad: DateTime.parse(json["fechaCaducidad"]?? DateTime.now().toIso8601String()),
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codLicencia": codLicencia,
        "codPersona": codPersona,
        "categoria": categoria,
        "fechaCaducidad": "${fechaCaducidad.year.toString().padLeft(4, '0')}-${fechaCaducidad.month.toString().padLeft(2, '0')}-${fechaCaducidad.day.toString().padLeft(2, '0')}",
        "audUsuario": audUsuario,
    };
    //metodo para convertir de Model a Entity
    LicenciaConducirEntity toEntity() => LicenciaConducirEntity(
      codLicencia: codLicencia,
      codPersona: codPersona,
      categoria: categoria,
      fechaCaducidad: fechaCaducidad,
      audUsuario: audUsuario,
    );
    //metodo para convertir de Entity a Model
    factory LicenciaConducirModel.fromEntity(LicenciaConducirEntity entity) => LicenciaConducirModel(
      codLicencia:  entity.codLicencia,
      codPersona: entity.codPersona,
      categoria: entity.categoria,
      fechaCaducidad: entity.fechaCaducidad,
      audUsuario: entity.audUsuario,
    );
}

import 'dart:convert';
import 'package:bosque_flutter/domain/entities/area_entity.dart';

// Funciones de ayuda para conversión
AreaResponse areaResponseFromJson(String str) =>
    AreaResponse.fromJson(json.decode(str));
String areaResponseToJson(AreaResponse data) => json.encode(data.toJson());

class AreaResponse {
  String message;
  List<AreaModel> data;
  int status;
  int? idGenerado;

  AreaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory AreaResponse.fromJson(Map<String, dynamic> json) {
    List<AreaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<AreaModel>.from(
          (json["data"] as List).map((x) => AreaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return AreaResponse(
      message: json["message"] ?? '',
      data: listaData,
      status: json["status"] ?? 0,
      idGenerado: json["idGenerado"] ?? idGen,
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status": status,
    "idGenerado": idGenerado,
  };
}

class AreaModel {
  int codArea;
  int codEmpresa;
  String nombreArea;
  String descripcion;
  int estado;
  int audUsuario;

  AreaModel({
    required this.codArea,
    required this.codEmpresa,
    required this.nombreArea,
    required this.descripcion,
    required this.estado,
    required this.audUsuario,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
    codArea: json["codArea"] ?? 0,
    codEmpresa: json["codEmpresa"] ?? 0,
    nombreArea: json["nombreArea"] ?? '',
    descripcion: json["descripcion"] ?? '',
    estado: json["estado"] ?? 0,
    audUsuario: json["audUsuario"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "codArea": codArea,
    "codEmpresa": codEmpresa,
    "nombreArea": nombreArea,
    "descripcion": descripcion,
    "estado": estado,
    "audUsuario": audUsuario,
  };
  AreaEntity toEntity() => AreaEntity(
    codArea: codArea,
    codEmpresa: codEmpresa,
    nombreArea: nombreArea,
    descripcion: descripcion,
    estado: estado,
    audUsuario: audUsuario,
  );
  factory AreaModel.fromEntity(AreaEntity entity) => AreaModel(
    codArea: entity.codArea,
    codEmpresa: entity.codEmpresa,
    nombreArea: entity.nombreArea,
    descripcion: entity.descripcion,
    estado: entity.estado,
    audUsuario: entity.audUsuario,
  );
}

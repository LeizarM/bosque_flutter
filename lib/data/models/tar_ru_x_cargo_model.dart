// Destino final: lib/data/models/tar_ru_x_cargo_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';

TarRuXCargoResponse tarRuXCargoResponseFromJson(String str) =>
    TarRuXCargoResponse.fromJson(json.decode(str));
String tarRuXCargoResponseToJson(TarRuXCargoResponse data) =>
    json.encode(data.toJson());

class TarRuXCargoResponse {
  String message;
  List<TarRuXCargoModel> data;
  int status;
  int? idGenerado;

  TarRuXCargoResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory TarRuXCargoResponse.fromJson(Map<String, dynamic> json) {
    List<TarRuXCargoModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<TarRuXCargoModel>.from(
          (json["data"] as List).map((x) => TarRuXCargoModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return TarRuXCargoResponse(
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

class TarRuXCargoModel {
  int idTarXCargo;
  int? idTarRuti;
  int? codCargo;
  int? estado;
  int audUsuario;
  DateTime? audFecha;
  int? codCargoSucursal;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  TarRuXCargoModel({
    required this.idTarXCargo,
    this.idTarRuti,
    this.codCargo,
    this.estado,
    required this.audUsuario,
    this.audFecha,
    this.codCargoSucursal,
    this.fechaInicio,
    this.fechaFin,
  });

  factory TarRuXCargoModel.fromJson(Map<String, dynamic> json) {
    return TarRuXCargoModel(
      idTarXCargo: json["idTarXCargo"] ?? 0,
      idTarRuti: json["idTarRuti"],
      codCargo: json["codCargo"],
      estado: json["estado"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
      codCargoSucursal: json["codCargoSucursal"],
      fechaInicio: json["fechaInicio"] != null
          ? DateTime.tryParse(json["fechaInicio"])
          : null,
      fechaFin: json["fechaFin"] != null
          ? DateTime.tryParse(json["fechaFin"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idTarXCargo": idTarXCargo,
    "idTarRuti": idTarRuti,
    "codCargo": codCargo,
    "estado": estado,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
    "codCargoSucursal": codCargoSucursal,
    "fechaInicio": fechaInicio?.toIso8601String(),
    "fechaFin": fechaFin?.toIso8601String(),
  };

  TarRuXCargoEntity toEntity() {
    return TarRuXCargoEntity(
      idTarXCargo: idTarXCargo,
      idTarRuti: idTarRuti,
      codCargo: codCargo,
      estado: estado,
      audUsuario: audUsuario,
      audFecha: audFecha,
      codCargoSucursal: codCargoSucursal,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  factory TarRuXCargoModel.fromEntity(TarRuXCargoEntity entity) {
    return TarRuXCargoModel(
      idTarXCargo: entity.idTarXCargo,
      idTarRuti: entity.idTarRuti,
      codCargo: entity.codCargo,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
      codCargoSucursal: entity.codCargoSucursal,
      fechaInicio: entity.fechaInicio,
      fechaFin: entity.fechaFin,
    );
  }
}

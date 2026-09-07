// Destino final: lib/data/models/bit_tarea_ruti_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';

BitTareaRutiResponse bitTareaRutiResponseFromJson(String str) =>
    BitTareaRutiResponse.fromJson(json.decode(str));
String bitTareaRutiResponseToJson(BitTareaRutiResponse data) =>
    json.encode(data.toJson());

class BitTareaRutiResponse {
  String message;
  List<BitTareaRutiModel> data;
  int status;
  int? idGenerado;

  BitTareaRutiResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory BitTareaRutiResponse.fromJson(Map<String, dynamic> json) {
    List<BitTareaRutiModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<BitTareaRutiModel>.from(
          (json["data"] as List).map((x) => BitTareaRutiModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return BitTareaRutiResponse(
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

class BitTareaRutiModel {
  int idBitTarea;
  DateTime? fechaActivo;
  DateTime? fechaPresentacion;
  int? idTarRuti;
  String? nombreTareaRutinaria;
  int? codEmpleado;
  String? descripCargo;
  DateTime? fechaCompletado;
  int? fueRealizado;
  String? obs;
  int? estado;
  int audUsuario;
  DateTime? audFecha;
  int? idATR;
  int? idFrec;

  BitTareaRutiModel({
    required this.idBitTarea,
    this.fechaActivo,
    this.fechaPresentacion,
    this.idTarRuti,
    this.nombreTareaRutinaria,
    this.codEmpleado,
    this.descripCargo,
    this.fechaCompletado,
    this.fueRealizado,
    this.obs,
    this.estado,
    required this.audUsuario,
    this.audFecha,
    this.idATR,
    this.idFrec,
  });

  factory BitTareaRutiModel.fromJson(Map<String, dynamic> json) {
    return BitTareaRutiModel(
      idBitTarea: json["idBitTarea"] ?? 0,
      fechaActivo: json["fechaActivo"] != null
          ? DateTime.tryParse(json["fechaActivo"])
          : null,
      fechaPresentacion: json["fechaPresentacion"] != null
          ? DateTime.tryParse(json["fechaPresentacion"])
          : null,
      idTarRuti: json["idTarRuti"],
      nombreTareaRutinaria: json["nombreTareaRutinaria"],
      codEmpleado: json["codEmpleado"],
      descripCargo: json["descripCargo"],
      fechaCompletado: json["fechaCompletado"] != null
          ? DateTime.tryParse(json["fechaCompletado"])
          : null,
      fueRealizado: json["fueRealizado"],
      obs: json["obs"],
      estado: json["estado"],
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
      idATR: json["idATR"],
      idFrec: json["idFrec"],
    );
  }

  Map<String, dynamic> toJson() => {
    "idBitTarea": idBitTarea,
    "fechaActivo": fechaActivo?.toIso8601String(),
    "fechaPresentacion": fechaPresentacion?.toIso8601String(),
    "idTarRuti": idTarRuti,
    "nombreTareaRutinaria": nombreTareaRutinaria,
    "codEmpleado": codEmpleado,
    "descripCargo": descripCargo,
    "fechaCompletado": fechaCompletado?.toIso8601String(),
    "fueRealizado": fueRealizado,
    "obs": obs,
    "estado": estado,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  BitTareaRutiEntity toEntity() {
    return BitTareaRutiEntity(
      idBitTarea: idBitTarea,
      fechaActivo: fechaActivo,
      fechaPresentacion: fechaPresentacion,
      idTarRuti: idTarRuti,
      nombreTareaRutinaria: nombreTareaRutinaria,
      codEmpleado: codEmpleado,
      descripCargo: descripCargo,
      fechaCompletado: fechaCompletado,
      fueRealizado: fueRealizado,
      obs: obs,
      estado: estado,
      audUsuario: audUsuario,
      audFecha: audFecha,
      idATR: idATR,
      idFrec: idFrec,
    );
  }

  factory BitTareaRutiModel.fromEntity(BitTareaRutiEntity entity) {
    return BitTareaRutiModel(
      idBitTarea: entity.idBitTarea,
      fechaActivo: entity.fechaActivo,
      fechaPresentacion: entity.fechaPresentacion,
      idTarRuti: entity.idTarRuti,
      nombreTareaRutinaria: entity.nombreTareaRutinaria,
      codEmpleado: entity.codEmpleado,
      descripCargo: entity.descripCargo,
      fechaCompletado: entity.fechaCompletado,
      fueRealizado: entity.fueRealizado,
      obs: entity.obs,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
      idATR: entity.idATR,
      idFrec: entity.idFrec,
    );
  }
}

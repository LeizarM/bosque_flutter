// Destino final: lib/data/models/det_documentacion_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/det_documentacion_entity.dart';

DetDocumentacionResponse detDocumentacionResponseFromJson(String str) =>
    DetDocumentacionResponse.fromJson(json.decode(str));
String detDocumentacionResponseToJson(DetDocumentacionResponse data) =>
    json.encode(data.toJson());

class DetDocumentacionResponse {
  String message;
  List<DetDocumentacionModel> data;
  int status;
  int? idGenerado;

  DetDocumentacionResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory DetDocumentacionResponse.fromJson(Map<String, dynamic> json) {
    List<DetDocumentacionModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<DetDocumentacionModel>.from(
          (json["data"] as List).map((x) => DetDocumentacionModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return DetDocumentacionResponse(
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

class DetDocumentacionModel {
  int idDetDoc;
  int? idAC;
  int? idDoc;
  double? monto;
  int audUsuario;
  DateTime? audFecha;

  DetDocumentacionModel({
    required this.idDetDoc,
    this.idAC,
    this.idDoc,
    this.monto,
    required this.audUsuario,
    this.audFecha,
  });

  factory DetDocumentacionModel.fromJson(Map<String, dynamic> json) {
    return DetDocumentacionModel(
      idDetDoc: json["idDetDoc"] ?? 0,
      idAC: json["idAC"],
      idDoc: json["idDoc"],
      monto: (json["monto"] as num?)?.toDouble(),
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idDetDoc": idDetDoc,
    "idAC": idAC,
    "idDoc": idDoc,
    "monto": monto,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  DetDocumentacionEntity toEntity() {
    return DetDocumentacionEntity(
      idDetDoc: idDetDoc,
      idAC: idAC,
      idDoc: idDoc,
      monto: monto,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory DetDocumentacionModel.fromEntity(DetDocumentacionEntity entity) {
    return DetDocumentacionModel(
      idDetDoc: entity.idDetDoc,
      idAC: entity.idAC,
      idDoc: entity.idDoc,
      monto: entity.monto,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

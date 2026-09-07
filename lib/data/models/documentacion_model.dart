// Destino final: lib/data/models/documentacion_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/documentacion_entity.dart';

DocumentacionResponse documentacionResponseFromJson(String str) =>
    DocumentacionResponse.fromJson(json.decode(str));
String documentacionResponseToJson(DocumentacionResponse data) =>
    json.encode(data.toJson());

class DocumentacionResponse {
  String message;
  List<DocumentacionModel> data;
  int status;
  int? idGenerado;

  DocumentacionResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory DocumentacionResponse.fromJson(Map<String, dynamic> json) {
    List<DocumentacionModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<DocumentacionModel>.from(
          (json["data"] as List).map((x) => DocumentacionModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return DocumentacionResponse(
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

class DocumentacionModel {
  int idDoc;
  String nombre;
  int audUsuario;
  DateTime? audFecha;

  DocumentacionModel({
    required this.idDoc,
    required this.nombre,
    required this.audUsuario,
    this.audFecha,
  });

  factory DocumentacionModel.fromJson(Map<String, dynamic> json) {
    return DocumentacionModel(
      idDoc: json["idDoc"] ?? 0,
      nombre: json["nombre"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idDoc": idDoc,
    "nombre": nombre,
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  DocumentacionEntity toEntity() {
    return DocumentacionEntity(
      idDoc: idDoc,
      nombre: nombre,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory DocumentacionModel.fromEntity(DocumentacionEntity entity) {
    return DocumentacionModel(
      idDoc: entity.idDoc,
      nombre: entity.nombre,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}

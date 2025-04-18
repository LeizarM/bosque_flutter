import 'dart:convert';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';

List<ChoferModel> choferModelFromJson(String str) => 
    List<ChoferModel>.from(json.decode(str).map((x) => ChoferModel.fromJson(x)));

String choferModelToJson(List<ChoferModel> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ChoferModel {
  final int codEmpleado;
  final String nombreCompleto;
  final String cargo;

  ChoferModel({
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.cargo,
  });

  factory ChoferModel.fromJson(Map<String, dynamic> json) => ChoferModel(
    codEmpleado: json["codEmpleado"] ?? 0,
    nombreCompleto: json["nombreCompleto"] ?? "Sin nombre",
    cargo: json["cargo"] ?? "Sin cargo",
  );

  Map<String, dynamic> toJson() => {
    "codEmpleado": codEmpleado,
    "nombreCompleto": nombreCompleto,
    "cargo": cargo,
  };

  // Convertir el modelo a entidad
  ChoferEntity toEntity() => ChoferEntity(
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    cargo: cargo,
  );
  
  // Convertir entidad a modelo
  factory ChoferModel.fromEntity(ChoferEntity entity) => ChoferModel(
    codEmpleado: entity.codEmpleado,
    nombreCompleto: entity.nombreCompleto,
    cargo: entity.cargo,
  );
}
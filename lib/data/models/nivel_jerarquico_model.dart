import 'dart:convert';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';

NivelJerarquicoModel nivelJerarquicoModelFromJson(String str) =>
    NivelJerarquicoModel.fromJson(json.decode(str));

String nivelJerarquicoModelToJson(NivelJerarquicoModel data) =>
    json.encode(data.toJson());

class NivelJerarquicoModel {
  int codNivel;
  int nivel;
  int haberBasico;
  int bonoProduccion;
  DateTime fecha;
  int audUsuario;
  int activo;

  NivelJerarquicoModel({
    required this.codNivel,
    required this.nivel,
    required this.haberBasico,
    required this.bonoProduccion,
    required this.fecha,
    required this.audUsuario,
    required this.activo,
  });

  factory NivelJerarquicoModel.fromJson(Map<String, dynamic> json) =>
      NivelJerarquicoModel(
        codNivel: json["codNivel"] ?? 0,
        nivel: json["nivel"] ?? 0,
        haberBasico: json["haberBasico"] ?? 0,
        bonoProduccion: json["bonoProduccion"] ?? 0,
        fecha: DateTime.parse(
          json["fecha"] ?? DateTime.now().toIso8601String(),
        ),
        audUsuario: json["audUsuario"] ?? 0,
        activo: json["activo"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "codNivel": codNivel,
    "nivel": nivel,
    "haberBasico": haberBasico,
    "bonoProduccion": bonoProduccion,
    "fecha": fecha.toIso8601String(),
    "audUsuario": audUsuario,
    "activo": activo,
  };

  // Método para convertir de Model a Entity
  NivelJerarquicoEntity toEntity() => NivelJerarquicoEntity(
    codNivel: codNivel,
    nivel: nivel,
    haberBasico: haberBasico,
    bonoProduccion: bonoProduccion,
    fecha: fecha,
    audUsuario: audUsuario,
    activo: activo,
  );

  // Método factory para convertir de Entity a Model
  factory NivelJerarquicoModel.fromEntity(NivelJerarquicoEntity entity) =>
      NivelJerarquicoModel(
        codNivel: entity.codNivel,
        nivel: entity.nivel,
        haberBasico: entity.haberBasico,
        bonoProduccion: entity.bonoProduccion,
        fecha: entity.fecha,
        audUsuario: entity.audUsuario,
        activo: entity.activo,
      );
}

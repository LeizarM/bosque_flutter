import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tc_ancla_entity.dart';

TcAnclaModel tcAnclaModelFromJson(String str) =>
    TcAnclaModel.fromJson(json.decode(str));

String tcAnclaModelToJson(TcAnclaModel data) => json.encode(data.toJson());

/// Espeja 1:1 la tabla tpr_tcAncla y el POJO TcAncla del backend: las 6
/// columnas, ni una mas. Cualquier campo de display que venga de un JOIN vive
/// en un DTO aparte, nunca aca.
///
/// ALCANCE: consulta. La configuracion que guarda esta fila la consume el
/// reprecio nocturno automatico, que esta FUERA DEL ALCANCE de esta migracion.
///
/// La PK es companyDB, un String (nvarchar(100)) y NO una identidad: la tabla
/// no tiene columna IDENTITY, asi que el ABM nunca devuelve SCOPE_IDENTITY()
/// y el idGenerado del backend siempre llega en 0.
///
/// Los tipos de cambio son BigDecimal en Java sobre columnas float(53). Dart
/// no tiene BigDecimal: viajan en double y hay que redondearlos al mostrarlos.
class TcAnclaModel {
  /// PK. nvarchar(100) NOT NULL, no identity. Base de datos SAP de la empresa.
  String companyDB;

  /// Tipo de cambio del ultimo reprecio. Ojo: en el procedimiento almacenado
  /// el parametro se llama @tc, no @tcAncla; el backend hace esa traduccion,
  /// el JSON viaja con el nombre del campo Java.
  double tcAncla;

  /// Fecha en que se fijo el ancla. En un alta nueva el backend la siembra con
  /// 1900-01-01 a proposito, no con la fecha del dia.
  DateTime? fechaAncla;

  /// Ultimo tipo de cambio observado. La columna admite NULL: por eso el
  /// default defensivo 0.0, que se lee como "todavia no hubo lectura".
  double tcUltimo;

  /// Fecha de la ultima lectura del tipo de cambio. Columna NULL.
  DateTime? fechaUltimo;

  /// Variacion minima que habilita un nuevo reprecio. Proporcion, no
  /// porcentaje: 0.10 es 10 %. La base tiene DEFAULT 0.10.
  double umbral;

  TcAnclaModel({
    required this.companyDB,
    required this.tcAncla,
    required this.fechaAncla,
    required this.tcUltimo,
    required this.fechaUltimo,
    required this.umbral,
  });

  factory TcAnclaModel.fromJson(Map<String, dynamic> json) => TcAnclaModel(
    companyDB: json["companyDB"] ?? '',
    tcAncla: (json["tcAncla"] as num?)?.toDouble() ?? 0.0,
    fechaAncla:
        json["fechaAncla"] != null ? DateTime.parse(json["fechaAncla"]) : null,
    tcUltimo: (json["tcUltimo"] as num?)?.toDouble() ?? 0.0,
    fechaUltimo:
        json["fechaUltimo"] != null
            ? DateTime.parse(json["fechaUltimo"])
            : null,
    // Default 0.10 igual al DEFAULT de la columna: es el umbral con el que
    // nace la fila si el backend no lo manda.
    umbral: (json["umbral"] as num?)?.toDouble() ?? 0.10,
  );

  // Solo se mandan los cuatro campos que el ABM acepta como parametro:
  // @companyDB, @tc (llega como tcAncla), @fechaAncla y @umbral.
  // tcUltimo y fechaUltimo son de SOLO LECTURA para el cliente: los escribe el
  // propio procedimiento en sus ramas 'M' (mover ancla) y 'S' (registrar tc
  // visto). Mandarlos armaria un EXEC con parametros que no existen y SQL
  // Server lo rechazaria.
  Map<String, dynamic> toJson() => {
    "companyDB": companyDB,
    "tcAncla": tcAncla,
    "fechaAncla": fechaAncla?.toIso8601String(),
    "umbral": umbral,
  };

  TcAnclaEntity toEntity() => TcAnclaEntity(
    companyDB: companyDB,
    tcAncla: tcAncla,
    fechaAncla: fechaAncla,
    tcUltimo: tcUltimo,
    fechaUltimo: fechaUltimo,
    umbral: umbral,
  );

  factory TcAnclaModel.fromEntity(TcAnclaEntity e) => TcAnclaModel(
    companyDB: e.companyDB,
    tcAncla: e.tcAncla,
    fechaAncla: e.fechaAncla,
    tcUltimo: e.tcUltimo,
    fechaUltimo: e.fechaUltimo,
    umbral: e.umbral,
  );
}

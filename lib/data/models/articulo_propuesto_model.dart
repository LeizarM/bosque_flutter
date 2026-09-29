import 'dart:convert';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';

ArticuloPropuestoModel articuloPropuestoModelFromJson(String str) =>
    ArticuloPropuestoModel.fromJson(json.decode(str));

String articuloPropuestoModelToJson(ArticuloPropuestoModel data) =>
    json.encode(data.toJson());

class ArticuloPropuestoModel {
  BigInt idArticulo;
  BigInt idPropuesta;
  String codArticulo;
  int codigoFamilia;
  String datoArticulo;
  double stock;
  double utm;
  BigInt audUsuario;
  DateTime? audFecha;

  ArticuloPropuestoModel({
    required this.idArticulo,
    required this.idPropuesta,
    required this.codArticulo,
    required this.codigoFamilia,
    required this.datoArticulo,
    required this.stock,
    required this.utm,
    required this.audUsuario,
    this.audFecha,
  });

  // Ocho de las nueve columnas son NULL-ables en la base: todos los campos
  // llevan valor por defecto, ninguno confia en que el backend mande el dato.
  factory ArticuloPropuestoModel.fromJson(Map<String, dynamic> json) =>
      ArticuloPropuestoModel(
        idArticulo:
            json["idArticulo"] != null
                ? BigInt.from(json["idArticulo"])
                : BigInt.zero,
        idPropuesta:
            json["idPropuesta"] != null
                ? BigInt.from(json["idPropuesta"])
                : BigInt.zero,
        codArticulo: json["codArticulo"] ?? '',
        codigoFamilia: json["codigoFamilia"] ?? 0,
        datoArticulo: json["datoArticulo"] ?? '',
        // BigDecimal en el backend; en Dart no existe, va como double.
        stock: (json["stock"] as num?)?.toDouble() ?? 0.0,
        utm: (json["utm"] as num?)?.toDouble() ?? 0.0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // Nulo real: fila sin sello de auditoria todavia.
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // Van las nueve columnas, ninguna se omite: el backend serializa el POJO
  // completo y cada campo viaja como parametro de p_abm_ArticuloProp. Un campo
  // de menos deja el parametro en null; uno de mas hace fallar el EXEC. Los
  // campos de display (titulo, obs, proveedor, familia, precios calculados)
  // nunca pasan por aca, viven en los DTO de lectura.
  Map<String, dynamic> toJson() => {
    // En el alta el id viaja en null: lo genera el IDENTITY de la base.
    "idArticulo": idArticulo == BigInt.zero ? null : idArticulo.toInt(),
    "idPropuesta": idPropuesta.toInt(),
    "codArticulo": codArticulo,
    "codigoFamilia": codigoFamilia,
    // Maximo 150 caracteres: mas largo lo trunca el procedimiento.
    "datoArticulo": datoArticulo,
    "stock": stock,
    "utm": utm,
    "audUsuario": audUsuario.toInt(),
    // Solo lectura en la escritura: el procedimiento la pisa con GETDATE() en
    // I/U/C/G. Se manda igual porque el parametro existe y la accion 'L' la
    // usa como filtro.
    "audFecha": audFecha != null ? _fecha(audFecha!) : null,
  };

  static String _fecha(DateTime f) =>
      f.toIso8601String().substring(0, 19).replaceAll('T', ' ');

  ArticuloPropuestoEntity toEntity() => ArticuloPropuestoEntity(
    idArticulo: idArticulo,
    idPropuesta: idPropuesta,
    codArticulo: codArticulo,
    codigoFamilia: codigoFamilia,
    datoArticulo: datoArticulo,
    stock: stock,
    utm: utm,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ArticuloPropuestoModel.fromEntity(ArticuloPropuestoEntity entity) =>
      ArticuloPropuestoModel(
        idArticulo: entity.idArticulo,
        idPropuesta: entity.idPropuesta,
        codArticulo: entity.codArticulo,
        codigoFamilia: entity.codigoFamilia,
        datoArticulo: entity.datoArticulo,
        stock: entity.stock,
        utm: entity.utm,
        audUsuario: entity.audUsuario,
        audFecha: entity.audFecha,
      );
}

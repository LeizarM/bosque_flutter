import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';

TipoProductoModel tipoProductoModelFromJson(String str) =>
    TipoProductoModel.fromJson(json.decode(str));

String tipoProductoModelToJson(TipoProductoModel data) =>
    json.encode(data.toJson());

/// Espejo de la clase Java Tipo: exactamente las 5 columnas de la tabla
/// tpr_tipo, sin campos de despliegue.
///
/// Las llaves del JSON son las de la clase Java, en camelCase tal cual las
/// serializa Jackson y tal cual las devuelve el SELECT de p_list_tipo.
///
/// Salvo idTipo, todas las columnas admiten NULL en la base, por eso cada
/// lectura de fromJson lleva default defensivo.
class TipoProductoModel {
  BigInt idTipo;
  String tipo;
  int estado;
  BigInt audUsuario;
  DateTime? audFecha;

  TipoProductoModel({
    required this.idTipo,
    required this.tipo,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory TipoProductoModel.fromJson(Map<String, dynamic> json) =>
      TipoProductoModel(
        idTipo:
            json["idTipo"] != null ? BigInt.from(json["idTipo"]) : BigInt.zero,
        tipo: json["tipo"] ?? '',
        // Default 0 = inactivo y no 1: la columna es int NULL y ante un NULL
        // conviene mostrar el tipo como deshabilitado antes que habilitarlo
        // por accidente. En el alta el SP fuerza 1 de todos modos.
        estado: json["estado"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // tryParse sobre el texto: la columna es datetime NULL y segun la
        // configuracion de Jackson puede llegar como cadena ISO o como otro
        // formato. Si no se puede parsear queda null en vez de reventar.
        audFecha:
            json["audFecha"] != null
                ? DateTime.tryParse(json["audFecha"].toString())
                : null,
      );

  // audFecha no se envia: p_abm_tipo declara el parametro pero lo ignora y
  // siempre estampa GETDATE(). Es un campo de solo lectura para la aplicacion.
  //
  // estado si se envia: en la modificacion el SP lo usa. En el alta lo ignora
  // y graba 1 literal, asi que un tipo nuevo siempre nace activo.
  Map<String, dynamic> toJson() => {
    "idTipo": idTipo.toInt(),
    "tipo": tipo,
    "estado": estado,
    "audUsuario": audUsuario.toInt(),
  };

  TipoProductoEntity toEntity() => TipoProductoEntity(
    idTipo: idTipo,
    tipo: tipo,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory TipoProductoModel.fromEntity(TipoProductoEntity e) =>
      TipoProductoModel(
        idTipo: e.idTipo,
        tipo: e.tipo,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

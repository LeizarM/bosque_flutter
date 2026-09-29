import 'dart:convert';
import 'package:bosque_flutter/domain/entities/color_producto_entity.dart';

ColorProductoModel colorProductoModelFromJson(String str) =>
    ColorProductoModel.fromJson(json.decode(str));

String colorProductoModelToJson(ColorProductoModel data) =>
    json.encode(data.toJson());

/// Espejo de la clase Java Color: exactamente las cinco columnas de tpr_color
/// y ninguna mas. SpHelper serializa el POJO con Jackson y manda cada campo
/// como parametro del SP, asi que un campo de display extra haria fallar el
/// EXEC de p_abm_color.
///
/// Todas las columnas menos idColor admiten NULL en la base, y el listado de
/// colores activos (ACCION 'A') devuelve unicamente idColor y color: por eso
/// cada lectura de fromJson lleva default defensivo.
class ColorProductoModel {
  BigInt idColor;
  String color;
  int estado;
  BigInt audUsuario;
  DateTime? audFecha;

  ColorProductoModel({
    required this.idColor,
    required this.color,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  factory ColorProductoModel.fromJson(Map<String, dynamic> json) =>
      ColorProductoModel(
        idColor:
            json["idColor"] != null
                ? BigInt.from(json["idColor"])
                : BigInt.zero,
        color: json["color"] ?? '',
        // Default 1 y no 0: la columna es int NULL y el propio SP interpreta
        // el null como activo, con ISNULL(estado, 1) = 1. Ademas el listado de
        // activos no devuelve la columna y todas esas filas son activas.
        estado: json["estado"] ?? 1,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // tryParse sobre el texto: el backend serializa con el formato
        // "yyyy-MM-dd HH:mm:ss", pero si llegara otra cosa preferimos null
        // antes que una excepcion en medio del listado.
        audFecha:
            json["audFecha"] != null
                ? DateTime.tryParse(json["audFecha"].toString())
                : null,
      );

  // audFecha no se envia: el SP ignora el valor recibido y siempre estampa
  // GETDATE(), tanto en el alta como en la modificacion. Es de solo lectura.
  //
  // estado si se envia, aunque en el alta el SP lo ignora y graba 1 fijo; en la
  // modificacion es el unico camino para activar o desactivar el color.
  Map<String, dynamic> toJson() => {
    "idColor": idColor.toInt(),
    "color": color,
    "estado": estado,
    "audUsuario": audUsuario.toInt(),
  };

  ColorProductoEntity toEntity() => ColorProductoEntity(
    idColor: idColor,
    color: color,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ColorProductoModel.fromEntity(ColorProductoEntity e) =>
      ColorProductoModel(
        idColor: e.idColor,
        color: e.color,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

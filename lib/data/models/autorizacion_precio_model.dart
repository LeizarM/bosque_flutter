import 'dart:convert';
import 'package:bosque_flutter/domain/entities/autorizacion_precio_entity.dart';

AutorizacionPrecioModel autorizacionPrecioModelFromJson(String str) =>
    AutorizacionPrecioModel.fromJson(json.decode(str));

String autorizacionPrecioModelToJson(AutorizacionPrecioModel data) =>
    json.encode(data.toJson());

/// Espeja 1:1 la tabla tpr_autorizacion y el POJO Autorizacion del backend.
///
/// El ABM p_abm_autorizacion recibe los campos del POJO tal cual, por eso el
/// toJson manda las mismas cinco claves y ninguna mas: un parametro que no
/// exista en el procedimiento hace fallar el EXEC. Los datos de JOIN (titulo
/// de la propuesta, nombre del autorizador, descripcion del estado) viajan en
/// el DTO, no aca.
class AutorizacionPrecioModel {
  BigInt idAutorizacion;
  BigInt idPropuesta;

  /// Cuatro estados: 0 Pendiente, 1 Aprobada, 2 No Aprobada, 3 En Espera.
  /// Es int a proposito, el nombre enganya pero nunca es bool.
  int esAprobada;

  BigInt audUsuario;

  /// Null mientras no hubo decision: el ABM la deja NULL si esAprobada es 0 o 3.
  DateTime? audFecha;

  AutorizacionPrecioModel({
    required this.idAutorizacion,
    required this.idPropuesta,
    required this.esAprobada,
    required this.audUsuario,
    required this.audFecha,
  });

  factory AutorizacionPrecioModel.fromJson(Map<String, dynamic> json) =>
      AutorizacionPrecioModel(
        idAutorizacion:
            json["idAutorizacion"] != null
                ? BigInt.from(json["idAutorizacion"])
                : BigInt.zero,
        idPropuesta:
            json["idPropuesta"] != null
                ? BigInt.from(json["idPropuesta"])
                : BigInt.zero,
        // Default 0 = Pendiente, que es el estado con el que nace el registro.
        esAprobada: json["esAprobada"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // Se mandan los cinco campos porque el SP los espera a todos como parametro.
  // idAutorizacion va en 0 al insertar: el ABM devuelve el valor en @idGenerado.
  Map<String, dynamic> toJson() => {
    "idAutorizacion": idAutorizacion.toInt(),
    "idPropuesta": idPropuesta.toInt(),
    "esAprobada": esAprobada,
    "audUsuario": audUsuario.toInt(),
    "audFecha": audFecha?.toIso8601String(),
  };

  AutorizacionPrecioEntity toEntity() => AutorizacionPrecioEntity(
    idAutorizacion: idAutorizacion,
    idPropuesta: idPropuesta,
    esAprobada: esAprobada,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory AutorizacionPrecioModel.fromEntity(AutorizacionPrecioEntity e) =>
      AutorizacionPrecioModel(
        idAutorizacion: e.idAutorizacion,
        idPropuesta: e.idPropuesta,
        esAprobada: e.esAprobada,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}

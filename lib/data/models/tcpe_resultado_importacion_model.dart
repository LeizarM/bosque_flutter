import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_importacion_entity.dart';

/// El sobre de `/examenes/banco/importar`: `message` es el `errormsg` del SP y
/// `data` el `idGenerado` (preguntas insertadas).
class TcpeResultadoImportacionModel {
  final int insertadas;
  final String? mensaje;

  const TcpeResultadoImportacionModel({this.insertadas = 0, this.mensaje});

  factory TcpeResultadoImportacionModel.fromJson(Map<String, dynamic> json) {
    final m = tcpeTexto(json['message'])?.trim();
    return TcpeResultadoImportacionModel(
      insertadas: tcpeInt(json['data']) ?? 0,
      mensaje: (m == null || m.isEmpty) ? null : m,
    );
  }

  Map<String, dynamic> toJson() => {'message': mensaje, 'data': insertadas};

  TcpeResultadoImportacionEntity toEntity() => TcpeResultadoImportacionEntity(insertadas: insertadas, mensaje: mensaje);

  factory TcpeResultadoImportacionModel.fromEntity(TcpeResultadoImportacionEntity e) =>
      TcpeResultadoImportacionModel(insertadas: e.insertadas, mensaje: e.mensaje);
}

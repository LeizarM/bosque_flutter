import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';

/// El cuerpo de `/cheque/verificacion/listar`: `{ fechaBanco?, pagina, tamanio }`.
/// Una fecha ausente no viaja: el servidor la toma como «todas».
class VerificacionFiltroModel {
  final DateTime? fechaBanco;
  final int pagina;
  final int tamanio;

  const VerificacionFiltroModel({
    required this.fechaBanco,
    required this.pagina,
    required this.tamanio,
  });

  factory VerificacionFiltroModel.fromJson(Map<String, dynamic> json) =>
      VerificacionFiltroModel(
        fechaBanco: soloFecha(json['fechaBanco']),
        pagina: (json['pagina'] as num?)?.toInt() ?? 1,
        tamanio:
            (json['tamanio'] as num?)?.toInt() ??
            VerificacionFiltroEntity.tamanioPorDefecto,
      );

  Map<String, dynamic> toJson() => {
    if (fechaBanco != null) 'fechaBanco': fechaParaSql(fechaBanco!),
    'pagina': pagina,
    'tamanio': tamanio,
  };

  VerificacionFiltroEntity toEntity() => VerificacionFiltroEntity(
    fechaBanco: fechaBanco,
    pagina: pagina,
    tamanio: tamanio,
  );

  factory VerificacionFiltroModel.fromEntity(VerificacionFiltroEntity e) =>
      VerificacionFiltroModel(
        fechaBanco: e.fechaBanco,
        pagina: e.pagina,
        tamanio: e.tamanio,
      );
}

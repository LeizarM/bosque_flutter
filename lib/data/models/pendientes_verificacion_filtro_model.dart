import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';

/// El cuerpo de `/cheque/verificacion/pendientes`: `{ estado?, soloCobranzaHoy,
/// pagina, tamanio }`. «Todos los estados» no manda `estado`.
class PendientesVerificacionFiltroModel {
  final String? estado;
  final bool soloCobranzaHoy;
  final int pagina;
  final int tamanio;

  const PendientesVerificacionFiltroModel({
    required this.estado,
    required this.soloCobranzaHoy,
    required this.pagina,
    required this.tamanio,
  });

  factory PendientesVerificacionFiltroModel.fromJson(
    Map<String, dynamic> json,
  ) => PendientesVerificacionFiltroModel(
    estado: json['estado'] as String?,
    soloCobranzaHoy: json['soloCobranzaHoy'] != false,
    pagina: (json['pagina'] as num?)?.toInt() ?? 1,
    tamanio:
        (json['tamanio'] as num?)?.toInt() ??
        PendientesVerificacionFiltroEntity.tamanioPorDefecto,
  );

  Map<String, dynamic> toJson() => {
    if (estado != null && estado!.trim().isNotEmpty) 'estado': estado!.trim(),
    'soloCobranzaHoy': soloCobranzaHoy,
    'pagina': pagina,
    'tamanio': tamanio,
  };

  PendientesVerificacionFiltroEntity toEntity() =>
      PendientesVerificacionFiltroEntity(
        estado: estado,
        soloCobranzaHoy: soloCobranzaHoy,
        pagina: pagina,
        tamanio: tamanio,
      );

  factory PendientesVerificacionFiltroModel.fromEntity(
    PendientesVerificacionFiltroEntity e,
  ) => PendientesVerificacionFiltroModel(
    estado: e.estado,
    soloCobranzaHoy: e.soloCobranzaHoy,
    pagina: e.pagina,
    tamanio: e.tamanio,
  );
}

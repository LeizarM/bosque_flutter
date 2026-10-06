import 'package:bosque_flutter/domain/entities/pagina_verificacion_entity.dart';

/// La pagina `{ total, pagina, tamanio, filas }` de `/cheque/verificacion/listar`
/// y de `/cheque/verificacion/pendientes`. [M] es el modelo de cada fila y [E]
/// su entidad.
class PaginaVerificacionModel<M, E> {
  final int total;
  final int pagina;
  final int tamanio;
  final List<M> filas;

  const PaginaVerificacionModel({
    required this.total,
    required this.pagina,
    required this.tamanio,
    required this.filas,
  });

  factory PaginaVerificacionModel.fromJson(
    Map<String, dynamic> json, {
    required M Function(Map<String, dynamic>) fila,
  }) => PaginaVerificacionModel(
    total: (json['total'] as num?)?.toInt() ?? 0,
    pagina: (json['pagina'] as num?)?.toInt() ?? 1,
    tamanio: (json['tamanio'] as num?)?.toInt() ?? 20,
    filas: [
      for (final f in (json['filas'] as List<dynamic>?) ?? const [])
        fila(f as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson(Map<String, dynamic> Function(M) fila) => {
    'total': total,
    'pagina': pagina,
    'tamanio': tamanio,
    'filas': [for (final f in filas) fila(f)],
  };

  PaginaVerificacionEntity<E> toEntity(E Function(M) fila) =>
      PaginaVerificacionEntity<E>(
        total: total,
        pagina: pagina,
        tamanio: tamanio,
        filas: [for (final f in filas) fila(f)],
      );

  static PaginaVerificacionModel<M, E> fromEntity<M, E>(
    PaginaVerificacionEntity<E> e,
    M Function(E) fila,
  ) => PaginaVerificacionModel<M, E>(
    total: e.total,
    pagina: e.pagina,
    tamanio: e.tamanio,
    filas: [for (final f in e.filas) fila(f)],
  );
}

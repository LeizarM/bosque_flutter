import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';

/// ChequePaginaDto del backend: `{ total, pagina, tamanio, filas }`.
class ChequePaginaModel {
  final int total;
  final int pagina;
  final int tamanio;
  final List<ChequeFilaModel> filas;

  const ChequePaginaModel({
    required this.total,
    required this.pagina,
    required this.tamanio,
    required this.filas,
  });

  factory ChequePaginaModel.fromJson(Map<String, dynamic> json) =>
      ChequePaginaModel(
        total: (json['total'] as num?)?.toInt() ?? 0,
        pagina: (json['pagina'] as num?)?.toInt() ?? 1,
        tamanio: (json['tamanio'] as num?)?.toInt() ?? 20,
        filas: [
          for (final f in (json['filas'] as List<dynamic>?) ?? const [])
            ChequeFilaModel.fromJson(f as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'total': total,
    'pagina': pagina,
    'tamanio': tamanio,
    'filas': [for (final f in filas) f.toJson()],
  };

  ChequePaginaEntity toEntity() => ChequePaginaEntity(
    total: total,
    pagina: pagina,
    tamanio: tamanio,
    filas: [for (final f in filas) f.toEntity()],
  );

  factory ChequePaginaModel.fromEntity(ChequePaginaEntity e) =>
      ChequePaginaModel(
        total: e.total,
        pagina: e.pagina,
        tamanio: e.tamanio,
        filas: [for (final f in e.filas) ChequeFilaModel.fromEntity(f)],
      );
}

import 'package:bosque_flutter/domain/entities/pdf_cheque_subida_entity.dart';

/// Respuesta de `/cheque/pdf/subir`:
/// `{ nombreArchivo, tamanoBytes, reemplazo }`. DTO de apoyo del backend, no una
/// tabla.
class PdfChequeSubidaModel {
  final String nombreArchivo;
  final int tamanoBytes;
  final bool reemplazo;

  const PdfChequeSubidaModel({
    required this.nombreArchivo,
    required this.tamanoBytes,
    required this.reemplazo,
  });

  factory PdfChequeSubidaModel.fromJson(Map<String, dynamic> json) =>
      PdfChequeSubidaModel(
        nombreArchivo: (json['nombreArchivo'] ?? '').toString().trim(),
        tamanoBytes: (json['tamanoBytes'] as num?)?.toInt() ?? 0,
        reemplazo: _leerBool(json['reemplazo']),
      );

  static bool _leerBool(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.trim().toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() => {
    'nombreArchivo': nombreArchivo,
    'tamanoBytes': tamanoBytes,
    'reemplazo': reemplazo,
  };

  PdfChequeSubidaEntity toEntity() => PdfChequeSubidaEntity(
    nombreArchivo: nombreArchivo,
    tamanoBytes: tamanoBytes,
    reemplazo: reemplazo,
  );

  factory PdfChequeSubidaModel.fromEntity(PdfChequeSubidaEntity e) =>
      PdfChequeSubidaModel(
        nombreArchivo: e.nombreArchivo,
        tamanoBytes: e.tamanoBytes,
        reemplazo: e.reemplazo,
      );
}

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';

/// Respuesta de `/cheque/pdf/estado`:
/// `{ existe, nombreArchivo, tamanoBytes, fechaModificacion }`. DTO de apoyo del
/// backend, no una tabla.
///
/// Lectura tolerante: solo un `true` explicito (booleano o texto) cuenta como
/// archivo; un tamano o una fecha ausentes o ilegibles quedan en null y no
/// tumban la consulta.
class PdfChequeEstadoModel {
  final bool existe;
  final String nombreArchivo;
  final int? tamanoBytes;
  final DateTime? fechaModificacion;

  const PdfChequeEstadoModel({
    required this.existe,
    required this.nombreArchivo,
    this.tamanoBytes,
    this.fechaModificacion,
  });

  factory PdfChequeEstadoModel.fromJson(Map<String, dynamic> json) =>
      PdfChequeEstadoModel(
        existe: _leerExiste(json['existe']),
        nombreArchivo: (json['nombreArchivo'] ?? '').toString().trim(),
        tamanoBytes: (json['tamanoBytes'] as num?)?.toInt(),
        fechaModificacion: fechaHora(json['fechaModificacion']),
      );

  static bool _leerExiste(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.trim().toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() => {
    'existe': existe,
    'nombreArchivo': nombreArchivo,
    'tamanoBytes': tamanoBytes,
    'fechaModificacion': fechaModificacion?.toIso8601String(),
  };

  PdfChequeEstadoEntity toEntity() => PdfChequeEstadoEntity(
    existe: existe,
    nombreArchivo: nombreArchivo,
    tamanoBytes: tamanoBytes,
    fechaModificacion: fechaModificacion,
  );

  factory PdfChequeEstadoModel.fromEntity(PdfChequeEstadoEntity e) =>
      PdfChequeEstadoModel(
        existe: e.existe,
        nombreArchivo: e.nombreArchivo,
        tamanoBytes: e.tamanoBytes,
        fechaModificacion: e.fechaModificacion,
      );
}

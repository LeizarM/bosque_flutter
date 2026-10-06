import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';

/// Espeja la tabla `tch_chPostergacion` y el POJO `ChPostergacion` del backend,
/// mas `fila` y `tienePdf`, que agrega el DTO del listado
/// (`/cheque/postergacion/listar`).
///
/// `tienePdf` es un booleano **o null** (no se pudo comprobar): un null no se
/// convierte en `false`, porque «sin PDF» y «no se sabe» no se dicen igual.
class PostergacionModel {
  static final DateFormat _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final BigInt codPostergacion;
  final BigInt codCheque;
  final DateTime? fecha;
  final String observacion;
  final String nombreArchivo;
  final int? audUsuario;
  final DateTime? audFecha;
  final bool? tienePdf;
  final int fila;

  const PostergacionModel({
    required this.codPostergacion,
    required this.codCheque,
    required this.fecha,
    required this.observacion,
    required this.nombreArchivo,
    required this.audUsuario,
    required this.audFecha,
    required this.tienePdf,
    required this.fila,
  });

  factory PostergacionModel.fromJson(Map<String, dynamic> json) =>
      PostergacionModel(
        codPostergacion: BigInt.from((json['codPostergacion'] as num?) ?? 0),
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        fecha: soloFecha(json['fecha']),
        observacion: (json['observacion'] ?? '').toString(),
        nombreArchivo: (json['nombreArchivo'] ?? '').toString().trim(),
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
        tienePdf: _leerBoolONulo(json['tienePdf']),
        fila: (json['fila'] as num?)?.toInt() ?? 0,
      );

  static bool? _leerBoolONulo(Object? v) {
    if (v is bool) return v;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true') return true;
      if (t == 'false') return false;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'codPostergacion': codPostergacion.toInt(),
    'codCheque': codCheque.toInt(),
    'fecha': fecha == null ? null : fechaParaSql(fecha!),
    'observacion': observacion,
    'nombreArchivo': nombreArchivo,
    'audUsuario': audUsuario,
    'audFecha': audFecha == null ? null : _iso.format(audFecha!),
    'tienePdf': tienePdf,
    'fila': fila,
  };

  /// Lo que viaja a `/cheque/postergacion/registrar`: cheque, fecha y
  /// observacion. Nunca el usuario, ni el codigo (el alta lo genera el
  /// servidor), ni el nombre del archivo (el procedimiento lo deja vacio).
  Map<String, dynamic> toCuerpoRegistro() => {
    'codCheque': codCheque.toInt(),
    if (fecha != null) 'fecha': fechaParaSql(fecha!),
    'observacion': observacion,
  };

  PostergacionEntity toEntity() => PostergacionEntity(
    codPostergacion: codPostergacion,
    codCheque: codCheque,
    fecha: fecha,
    observacion: observacion,
    nombreArchivo: nombreArchivo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    tienePdf: tienePdf,
    fila: fila,
  );

  factory PostergacionModel.fromEntity(PostergacionEntity e) =>
      PostergacionModel(
        codPostergacion: e.codPostergacion,
        codCheque: e.codCheque,
        fecha: e.fecha,
        observacion: e.observacion,
        nombreArchivo: e.nombreArchivo,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        tienePdf: e.tienePdf,
        fila: e.fila,
      );
}

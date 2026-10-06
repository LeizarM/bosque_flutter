import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';

/// Espeja la tabla tch_accion y el POJO ChAccion del backend, mas `descripcion`
/// y `nro` que agrega el DTO del detalle. **No es AccionCbrModel** (garantias).
///
/// Las fechas de la accion llegan como `yyyy-MM-dd'T'HH:mm:ss`, con hora.
class AccionChequeModel {
  static final DateFormat _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final BigInt codAccion;
  final BigInt codCheque;
  final DateTime? fecha;
  final String estado;
  final int? codEmpleado;
  final String? nroSAP;
  final String? observacion;
  final int? audUsuario;
  final DateTime? audFecha;
  final String descripcion;
  final int nro;

  const AccionChequeModel({
    required this.codAccion,
    required this.codCheque,
    required this.fecha,
    required this.estado,
    required this.codEmpleado,
    required this.nroSAP,
    required this.observacion,
    required this.audUsuario,
    required this.audFecha,
    required this.descripcion,
    required this.nro,
  });

  factory AccionChequeModel.fromJson(Map<String, dynamic> json) =>
      AccionChequeModel(
        codAccion: BigInt.from((json['codAccion'] as num?) ?? 0),
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        fecha: fechaHora(json['fecha']),
        estado: (json['estado'] ?? '').toString().trim(),
        codEmpleado: (json['codEmpleado'] as num?)?.toInt(),
        nroSAP: json['nroSAP'] as String?,
        observacion: json['observacion'] as String?,
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
        descripcion: (json['descripcion'] ?? '').toString(),
        nro: (json['nro'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'codAccion': codAccion.toInt(),
    'codCheque': codCheque.toInt(),
    'fecha': fecha == null ? null : _iso.format(fecha!),
    'estado': estado,
    'codEmpleado': codEmpleado,
    'nroSAP': nroSAP,
    'observacion': observacion,
    'audUsuario': audUsuario,
    'audFecha': audFecha == null ? null : _iso.format(audFecha!),
    'descripcion': descripcion,
    'nro': nro,
  };

  AccionChequeEntity toEntity() => AccionChequeEntity(
    codAccion: codAccion,
    codCheque: codCheque,
    fecha: fecha,
    estado: estado,
    codEmpleado: codEmpleado,
    nroSAP: nroSAP,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    descripcion: descripcion,
    nro: nro,
  );

  factory AccionChequeModel.fromEntity(AccionChequeEntity e) =>
      AccionChequeModel(
        codAccion: e.codAccion,
        codCheque: e.codCheque,
        fecha: e.fecha,
        estado: e.estado,
        codEmpleado: e.codEmpleado,
        nroSAP: e.nroSAP,
        observacion: e.observacion,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        descripcion: e.descripcion,
        nro: e.nro,
      );
}

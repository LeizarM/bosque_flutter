import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';

/// Espeja la tabla `tch_notaRemision` y el POJO `ChNotaRemision` del backend,
/// mas `fila`, que agrega el DTO del listado (`/cheque/nota-remision/listar`).
/// **No es `NotaRemisionModel`** (Depositos, `tdep_NotaRemision`).
///
/// `fechaFactura` llega como `yyyy-MM-dd` y `audFecha` como
/// `yyyy-MM-dd'T'HH:mm:ss`. Lectura tolerante: una clave ausente no tumba la
/// lista entera.
class NotaRemisionChequeModel {
  static final DateFormat _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final BigInt codCheque;
  final String notaRemision;
  final int nroFactura;
  final DateTime? fechaFactura;
  final int? audUsuario;
  final DateTime? audFecha;
  final int fila;

  const NotaRemisionChequeModel({
    required this.codCheque,
    required this.notaRemision,
    required this.nroFactura,
    required this.fechaFactura,
    required this.audUsuario,
    required this.audFecha,
    required this.fila,
  });

  factory NotaRemisionChequeModel.fromJson(Map<String, dynamic> json) =>
      NotaRemisionChequeModel(
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        notaRemision: (json['notaRemision'] ?? '').toString(),
        nroFactura: (json['nroFactura'] as num?)?.toInt() ?? 0,
        fechaFactura: soloFecha(json['fechaFactura']),
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
        fila: (json['fila'] as num?)?.toInt() ?? 0,
      );

  /// La fila completa, espejo de la tabla mas `fila`.
  Map<String, dynamic> toJson() => {
    'codCheque': codCheque.toInt(),
    'notaRemision': notaRemision,
    'nroFactura': nroFactura,
    'fechaFactura': fechaFactura == null ? null : fechaParaSql(fechaFactura!),
    'audUsuario': audUsuario,
    'audFecha': audFecha == null ? null : _iso.format(audFecha!),
    'fila': fila,
  };

  /// Lo que viaja a `/cheque/nota-remision/registrar`. **Nunca lleva el usuario
  /// de auditoria** (lo toma el servidor del token) ni la fila.
  Map<String, dynamic> toCuerpoRegistro() => {
    'codCheque': codCheque.toInt(),
    'notaRemision': notaRemision,
    'nroFactura': nroFactura,
    if (fechaFactura != null) 'fechaFactura': fechaParaSql(fechaFactura!),
  };

  NotaRemisionChequeEntity toEntity() => NotaRemisionChequeEntity(
    codCheque: codCheque,
    notaRemision: notaRemision,
    nroFactura: nroFactura,
    fechaFactura: fechaFactura,
    audUsuario: audUsuario,
    audFecha: audFecha,
    fila: fila,
  );

  factory NotaRemisionChequeModel.fromEntity(NotaRemisionChequeEntity e) =>
      NotaRemisionChequeModel(
        codCheque: e.codCheque,
        notaRemision: e.notaRemision,
        nroFactura: e.nroFactura,
        fechaFactura: e.fechaFactura,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        fila: e.fila,
      );
}

import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';

/// Espeja la tabla `tch_chTransaccionBancaria` y el POJO
/// `ChTransaccionBancaria` del backend, mas `fila` y `datoBanco`, que agrega el
/// DTO del listado (`/cheque/transaccion/listar`, que no devuelve `audUsuario`
/// ni `audFecha`).
class TransaccionBancariaModel {
  static final DateFormat _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final BigInt codCheque;
  final String nroTransaccion;
  final int codBanco;
  final DateTime? fechaTransaccion;
  final String datoBanco;
  final int? audUsuario;
  final DateTime? audFecha;
  final int fila;

  const TransaccionBancariaModel({
    required this.codCheque,
    required this.nroTransaccion,
    required this.codBanco,
    required this.fechaTransaccion,
    required this.datoBanco,
    required this.audUsuario,
    required this.audFecha,
    required this.fila,
  });

  factory TransaccionBancariaModel.fromJson(Map<String, dynamic> json) =>
      TransaccionBancariaModel(
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        nroTransaccion: (json['nroTransaccion'] ?? '').toString(),
        codBanco: (json['codBanco'] as num?)?.toInt() ?? 0,
        fechaTransaccion: soloFecha(json['fechaTransaccion']),
        datoBanco: (json['datoBanco'] ?? '').toString(),
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
        fila: (json['fila'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'codCheque': codCheque.toInt(),
    'nroTransaccion': nroTransaccion,
    'codBanco': codBanco,
    'fechaTransaccion':
        fechaTransaccion == null ? null : fechaParaSql(fechaTransaccion!),
    'datoBanco': datoBanco,
    'audUsuario': audUsuario,
    'audFecha': audFecha == null ? null : _iso.format(audFecha!),
    'fila': fila,
  };

  /// Lo que viaja a `/cheque/transaccion/registrar`: sin usuario, sin fila y sin
  /// el nombre del banco (el servidor lo busca por su codigo).
  Map<String, dynamic> toCuerpoRegistro() => {
    'codCheque': codCheque.toInt(),
    'nroTransaccion': nroTransaccion,
    'codBanco': codBanco,
    if (fechaTransaccion != null)
      'fechaTransaccion': fechaParaSql(fechaTransaccion!),
  };

  TransaccionBancariaEntity toEntity() => TransaccionBancariaEntity(
    codCheque: codCheque,
    nroTransaccion: nroTransaccion,
    codBanco: codBanco,
    fechaTransaccion: fechaTransaccion,
    datoBanco: datoBanco,
    audUsuario: audUsuario,
    audFecha: audFecha,
    fila: fila,
  );

  factory TransaccionBancariaModel.fromEntity(TransaccionBancariaEntity e) =>
      TransaccionBancariaModel(
        codCheque: e.codCheque,
        nroTransaccion: e.nroTransaccion,
        codBanco: e.codBanco,
        fechaTransaccion: e.fechaTransaccion,
        datoBanco: e.datoBanco,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        fila: e.fila,
      );
}

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';

/// Las claves del cheque que comparten `VerificacionFila` y
/// `ChequePendienteFila` del backend. El JSON de cada fila es plano: este modelo
/// lee solo estas claves.
///
/// `nroCheque` llega como texto; `montoCheque`, como `double`.
class DatosChequeVerificacionModel {
  final BigInt codCheque;
  final String nroCheque;
  final double? montoCheque;
  final String datoBancoCheque;
  final String datoEstadoCheque;
  final DateTime? fechaCobrarCheque;
  final bool chequeCerrado;
  final String? moneda;
  final String? descMoneda;

  const DatosChequeVerificacionModel({
    required this.codCheque,
    required this.nroCheque,
    required this.montoCheque,
    required this.datoBancoCheque,
    required this.datoEstadoCheque,
    required this.fechaCobrarCheque,
    required this.chequeCerrado,
    required this.moneda,
    required this.descMoneda,
  });

  factory DatosChequeVerificacionModel.fromJson(Map<String, dynamic> json) =>
      DatosChequeVerificacionModel(
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        nroCheque: (json['nroCheque'] ?? '').toString().trim(),
        montoCheque: (json['montoCheque'] as num?)?.toDouble(),
        datoBancoCheque: (json['datoBancoCheque'] ?? '').toString(),
        datoEstadoCheque: (json['datoEstadoCheque'] ?? '').toString(),
        fechaCobrarCheque: soloFecha(json['fechaCobrarCheque']),
        chequeCerrado: json['chequeCerrado'] == true,
        moneda: (json['moneda'] as String?)?.trim(),
        descMoneda: (json['descMoneda'] as String?)?.trim(),
      );

  Map<String, dynamic> toJson() => {
    'codCheque': codCheque.toInt(),
    'nroCheque': nroCheque,
    'montoCheque': montoCheque,
    'datoBancoCheque': datoBancoCheque,
    'datoEstadoCheque': datoEstadoCheque,
    'fechaCobrarCheque':
        fechaCobrarCheque == null ? null : fechaParaSql(fechaCobrarCheque!),
    'chequeCerrado': chequeCerrado,
    'moneda': moneda,
    'descMoneda': descMoneda,
  };

  DatosChequeVerificacionEntity toEntity() => DatosChequeVerificacionEntity(
    codCheque: codCheque,
    nroCheque: nroCheque,
    montoCheque: montoCheque,
    datoBancoCheque: datoBancoCheque,
    datoEstadoCheque: datoEstadoCheque,
    fechaCobrarCheque: fechaCobrarCheque,
    chequeCerrado: chequeCerrado,
    moneda: moneda,
    descMoneda: descMoneda,
  );

  factory DatosChequeVerificacionModel.fromEntity(
    DatosChequeVerificacionEntity e,
  ) => DatosChequeVerificacionModel(
    codCheque: e.codCheque,
    nroCheque: e.nroCheque,
    montoCheque: e.montoCheque,
    datoBancoCheque: e.datoBancoCheque,
    datoEstadoCheque: e.datoEstadoCheque,
    fechaCobrarCheque: e.fechaCobrarCheque,
    chequeCerrado: e.chequeCerrado,
    moneda: e.moneda,
    descMoneda: e.descMoneda,
  );
}

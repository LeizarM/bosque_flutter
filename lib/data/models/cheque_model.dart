import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cheque_entity.dart';

/// Espeja 1:1 la tabla tch_cheque y el POJO ChCheque del backend.
///
/// Los nombres del JSON son los de la columna: `nrocheque` en minuscula y
/// `aOrdenDe`. Las fechas DATE llegan como `yyyy-MM-dd` y se leen sin hora
/// ([soloFecha]) para que un corrimiento de zona no las mueva de dia.
/// `audFecha` es un datetimeoffset en texto, no ISO: se guarda como viene.
class ChequeModel {
  final BigInt codCheque;
  final String nrocheque;
  final String? codCliente;
  final String? aOrdenDe;
  final DateTime? fechaCheque;
  final DateTime? fechaCobrar;
  final double? monto;
  final String? moneda;
  final String? tipo;
  final String? estado;
  final int? codBanco;
  final int? codEmpleado;
  final String? reciboManual;
  final int? codSucursal;
  final int? nroRecibo;
  final String? nroTalonario;
  final int? codEmpresa;
  final int? audUsuario;
  final String? audFecha;

  const ChequeModel({
    required this.codCheque,
    required this.nrocheque,
    required this.codCliente,
    required this.aOrdenDe,
    required this.fechaCheque,
    required this.fechaCobrar,
    required this.monto,
    required this.moneda,
    required this.tipo,
    required this.estado,
    required this.codBanco,
    required this.codEmpleado,
    required this.reciboManual,
    required this.codSucursal,
    required this.nroRecibo,
    required this.nroTalonario,
    required this.codEmpresa,
    required this.audUsuario,
    required this.audFecha,
  });

  factory ChequeModel.fromJson(Map<String, dynamic> json) => ChequeModel(
    codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
    nrocheque: (json['nrocheque'] ?? '').toString(),
    codCliente: json['codCliente'] as String?,
    aOrdenDe: json['aOrdenDe'] as String?,
    fechaCheque: soloFecha(json['fechaCheque']),
    fechaCobrar: soloFecha(json['fechaCobrar']),
    monto: (json['monto'] as num?)?.toDouble(),
    moneda: json['moneda'] as String?,
    tipo: json['tipo'] as String?,
    estado: json['estado'] as String?,
    codBanco: (json['codBanco'] as num?)?.toInt(),
    codEmpleado: (json['codEmpleado'] as num?)?.toInt(),
    reciboManual: json['reciboManual'] as String?,
    codSucursal: (json['codSucursal'] as num?)?.toInt(),
    nroRecibo: (json['nroRecibo'] as num?)?.toInt(),
    nroTalonario: json['nroTalonario'] as String?,
    codEmpresa: (json['codEmpresa'] as num?)?.toInt(),
    audUsuario: (json['audUsuario'] as num?)?.toInt(),
    audFecha: json['audFecha'] as String?,
  );

  /// La fila completa, con los mismos nombres. No es el cuerpo de
  /// `/cheque/registrar`: ese lo arma [ChequeRegistroModel] sin `estado`,
  /// `nroRecibo`, `audUsuario` ni `audFecha`.
  Map<String, dynamic> toJson() => {
    'codCheque': codCheque.toInt(),
    'nrocheque': nrocheque,
    'codCliente': codCliente,
    'aOrdenDe': aOrdenDe,
    'fechaCheque': fechaCheque == null ? null : fechaParaSql(fechaCheque!),
    'fechaCobrar': fechaCobrar == null ? null : fechaParaSql(fechaCobrar!),
    'monto': monto,
    'moneda': moneda,
    'tipo': tipo,
    'estado': estado,
    'codBanco': codBanco,
    'codEmpleado': codEmpleado,
    'reciboManual': reciboManual,
    'codSucursal': codSucursal,
    'nroRecibo': nroRecibo,
    'nroTalonario': nroTalonario,
    'codEmpresa': codEmpresa,
    'audUsuario': audUsuario,
    'audFecha': audFecha,
  };

  ChequeEntity toEntity() => ChequeEntity(
    codCheque: codCheque,
    nrocheque: nrocheque,
    codCliente: codCliente,
    aOrdenDe: aOrdenDe,
    fechaCheque: fechaCheque,
    fechaCobrar: fechaCobrar,
    monto: monto,
    moneda: moneda,
    tipo: tipo,
    estado: estado,
    codBanco: codBanco,
    codEmpleado: codEmpleado,
    reciboManual: reciboManual,
    codSucursal: codSucursal,
    nroRecibo: nroRecibo,
    nroTalonario: nroTalonario,
    codEmpresa: codEmpresa,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ChequeModel.fromEntity(ChequeEntity e) => ChequeModel(
    codCheque: e.codCheque,
    nrocheque: e.nrocheque,
    codCliente: e.codCliente,
    aOrdenDe: e.aOrdenDe,
    fechaCheque: e.fechaCheque,
    fechaCobrar: e.fechaCobrar,
    monto: e.monto,
    moneda: e.moneda,
    tipo: e.tipo,
    estado: e.estado,
    codBanco: e.codBanco,
    codEmpleado: e.codEmpleado,
    reciboManual: e.reciboManual,
    codSucursal: e.codSucursal,
    nroRecibo: e.nroRecibo,
    nroTalonario: e.nroTalonario,
    codEmpresa: e.codEmpresa,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}

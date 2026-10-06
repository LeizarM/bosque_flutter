import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:intl/intl.dart';

/// JSON de `tac_planillaIncapacidad`. `fueRevisado` viaja como 0/1 y en la
/// entidad es `bool`. `desde`/`hasta` son DATETIME con la hora del permiso.
class PlanillaIncapacidadModel {
  final int idPIT;
  final int? codPermiso;
  final String numSeguro;
  final String motivo;
  final String datoEmpleado;
  final double salarioMensual;
  final double salarioDiario;
  final double porcentajeAl75;
  final int nroBaja;
  final DateTime? desde;
  final DateTime? hasta;
  final int diasBaja;
  final int diasAsumidosCordes;
  final double totalDescuento;
  final int fueRevisado;
  final DateTime? fechaRevisado;
  final int? audUsuario;
  final DateTime? audFecha;

  // Del JOIN con trh_afiliacion / trh_seguro (ACCION A).
  final int? codSeguro;
  final String seguro;

  const PlanillaIncapacidadModel({
    required this.idPIT,
    this.codPermiso,
    required this.numSeguro,
    required this.motivo,
    required this.datoEmpleado,
    required this.salarioMensual,
    required this.salarioDiario,
    required this.porcentajeAl75,
    required this.nroBaja,
    this.desde,
    this.hasta,
    required this.diasBaja,
    required this.diasAsumidosCordes,
    required this.totalDescuento,
    required this.fueRevisado,
    this.fechaRevisado,
    this.audUsuario,
    this.audFecha,
    this.codSeguro,
    this.seguro = '',
  });

  static final DateFormat _fechaHoraSql = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static double _dec(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static int _ent(dynamic v) => (v as num?)?.toInt() ?? 0;
  static String _txt(dynamic v) => (v as String?)?.trim() ?? '';
  static String? _sql(DateTime? f) => f == null ? null : _fechaHoraSql.format(f);

  factory PlanillaIncapacidadModel.fromJson(Map<String, dynamic> json) =>
      PlanillaIncapacidadModel(
        idPIT: _ent(json['idPIT']),
        codPermiso: (json['codPermiso'] as num?)?.toInt(),
        numSeguro: _txt(json['numSeguro']),
        motivo: _txt(json['motivo']),
        datoEmpleado: _txt(json['datoEmpleado']),
        salarioMensual: _dec(json['salarioMensual']),
        salarioDiario: _dec(json['salarioDiario']),
        porcentajeAl75: _dec(json['porcentajeAl75']),
        nroBaja: _ent(json['nroBaja']),
        desde: fechaHora(json['desde']),
        hasta: fechaHora(json['hasta']),
        diasBaja: _ent(json['diasBaja']),
        diasAsumidosCordes: _ent(json['diasAsumidosCordes']),
        totalDescuento: _dec(json['totalDescuento']),
        fueRevisado: _ent(json['fueRevisado']),
        fechaRevisado: fechaHora(json['fechaRevisado']),
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
        codSeguro: (json['codSeguro'] as num?)?.toInt(),
        seguro: _txt(json['seguro']),
      );

  Map<String, dynamic> toJson() => {
    'idPIT': idPIT,
    'codPermiso': codPermiso,
    'numSeguro': numSeguro,
    'motivo': motivo,
    'datoEmpleado': datoEmpleado,
    'salarioMensual': salarioMensual,
    'salarioDiario': salarioDiario,
    'porcentajeAl75': porcentajeAl75,
    'nroBaja': nroBaja,
    'desde': _sql(desde),
    'hasta': _sql(hasta),
    'diasBaja': diasBaja,
    'diasAsumidosCordes': diasAsumidosCordes,
    'totalDescuento': totalDescuento,
    'fueRevisado': fueRevisado,
    'fechaRevisado': _sql(fechaRevisado),
    'audUsuario': audUsuario,
    'audFecha': _sql(audFecha),
    'codSeguro': codSeguro,
    'seguro': seguro,
  };

  PlanillaIncapacidadEntity toEntity() => PlanillaIncapacidadEntity(
    idPIT: idPIT,
    codPermiso: codPermiso,
    numSeguro: numSeguro,
    motivo: motivo,
    datoEmpleado: datoEmpleado,
    salarioMensual: salarioMensual,
    salarioDiario: salarioDiario,
    porcentajeAl75: porcentajeAl75,
    nroBaja: nroBaja,
    desde: desde,
    hasta: hasta,
    diasBaja: diasBaja,
    diasAsumidosCordes: diasAsumidosCordes,
    totalDescuento: totalDescuento,
    fueRevisado: fueRevisado == 1,
    fechaRevisado: fechaRevisado,
    audUsuario: audUsuario,
    audFecha: audFecha,
    codSeguro: codSeguro,
    seguro: seguro,
  );

  factory PlanillaIncapacidadModel.fromEntity(PlanillaIncapacidadEntity e) =>
      PlanillaIncapacidadModel(
        idPIT: e.idPIT,
        codPermiso: e.codPermiso,
        numSeguro: e.numSeguro,
        motivo: e.motivo,
        datoEmpleado: e.datoEmpleado,
        salarioMensual: e.salarioMensual,
        salarioDiario: e.salarioDiario,
        porcentajeAl75: e.porcentajeAl75,
        nroBaja: e.nroBaja,
        desde: e.desde,
        hasta: e.hasta,
        diasBaja: e.diasBaja,
        diasAsumidosCordes: e.diasAsumidosCordes,
        totalDescuento: e.totalDescuento,
        fueRevisado: e.fueRevisado ? 1 : 0,
        fechaRevisado: e.fechaRevisado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        codSeguro: e.codSeguro,
        seguro: e.seguro,
      );
}

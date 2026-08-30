import 'dart:convert';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

TalonarioModel talonarioModelFromJson(String str) =>
    TalonarioModel.fromJson(json.decode(str));

String talonarioModelToJson(TalonarioModel data) => json.encode(data.toJson());

BigInt _big(dynamic v) =>
    v == null ? BigInt.zero : BigInt.from((v as num).toInt());
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());
double _dbl(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

class TalonarioModel {
  BigInt codTalonario;
  BigInt codTipoRecibo;
  String nroTalonario;
  double costoBs;
  int numeracionInicial;
  int numeracionFinal;
  String estado;
  BigInt codEmpresa;
  String observacion;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  String sigla;
  String datoTipoNombre;
  String datoTipo;
  String datoEmpresa;
  String datoTalonario;
  int entregas;
  int devoluciones;
  int cierres;
  int codEstadoActual;
  String estadoActual;
  bool puedeEntregar;
  bool puedeDevolver;
  bool puedeCerrar;
  String datoDestinatario;

  TalonarioModel({
    required this.codTalonario,
    required this.codTipoRecibo,
    required this.nroTalonario,
    required this.costoBs,
    required this.numeracionInicial,
    required this.numeracionFinal,
    required this.estado,
    required this.codEmpresa,
    required this.observacion,
    required this.audUsuario,
    this.audFecha,
    this.sigla = '',
    this.datoTipoNombre = '',
    this.datoTipo = '',
    this.datoEmpresa = '',
    this.datoTalonario = '',
    this.entregas = 0,
    this.devoluciones = 0,
    this.cierres = 0,
    this.codEstadoActual = 1,
    this.estadoActual = '',
    this.puedeEntregar = false,
    this.puedeDevolver = false,
    this.puedeCerrar = false,
    this.datoDestinatario = '',
  });

  factory TalonarioModel.fromJson(Map<String, dynamic> json) => TalonarioModel(
    codTalonario: _big(json["codTalonario"]),
    codTipoRecibo: _big(json["codTipoRecibo"]),
    nroTalonario: json["nroTalonario"] ?? '',
    costoBs: _dbl(json["costoBs"]),
    numeracionInicial: json["numeracionInicial"] ?? 0,
    numeracionFinal: json["numeracionFinal"] ?? 0,
    estado: json["estado"] ?? '1',
    codEmpresa: _big(json["codEmpresa"]),
    observacion: json["observacion"] ?? '',
    audUsuario: _big(json["audUsuario"]),
    audFecha: _fecha(json["audFecha"]),
    sigla: json["sigla"] ?? '',
    datoTipoNombre: json["datoTipoNombre"] ?? '',
    datoTipo: json["datoTipo"] ?? '',
    datoEmpresa: json["datoEmpresa"] ?? '',
    datoTalonario: json["datoTalonario"] ?? '',
    entregas: json["entregas"] ?? 0,
    devoluciones: json["devoluciones"] ?? 0,
    cierres: json["cierres"] ?? 0,
    codEstadoActual: json["codEstadoActual"] ?? 1,
    estadoActual: json["estadoActual"] ?? '',
    puedeEntregar: json["puedeEntregar"] ?? false,
    puedeDevolver: json["puedeDevolver"] ?? false,
    puedeCerrar: json["puedeCerrar"] ?? false,
    datoDestinatario: json["datoDestinatario"] ?? '',
  );

  /// Solo los campos que el SP de ABM acepta. Los derivados
  /// (estadoActual, puede*, dato*) los calcula el backend y no se envían.
  Map<String, dynamic> toJson() => {
    "codTalonario": codTalonario.toInt(),
    "codTipoRecibo": codTipoRecibo.toInt(),
    "nroTalonario": nroTalonario,
    "costoBs": costoBs,
    "numeracionInicial": numeracionInicial,
    "numeracionFinal": numeracionFinal,
    "estado": estado,
    "codEmpresa": codEmpresa.toInt(),
    "observacion": observacion,
    "audUsuario": audUsuario.toInt(),
  };

  TalonarioEntity toEntity() => TalonarioEntity(
    codTalonario: codTalonario,
    codTipoRecibo: codTipoRecibo,
    nroTalonario: nroTalonario,
    costoBs: costoBs,
    numeracionInicial: numeracionInicial,
    numeracionFinal: numeracionFinal,
    estado: estado,
    codEmpresa: codEmpresa,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    sigla: sigla,
    datoTipoNombre: datoTipoNombre,
    datoTipo: datoTipo,
    datoEmpresa: datoEmpresa,
    datoTalonario: datoTalonario,
    entregas: entregas,
    devoluciones: devoluciones,
    cierres: cierres,
    codEstadoActual: codEstadoActual,
    estadoActual: estadoActual,
    puedeEntregar: puedeEntregar,
    puedeDevolver: puedeDevolver,
    puedeCerrar: puedeCerrar,
    datoDestinatario: datoDestinatario,
  );

  factory TalonarioModel.fromEntity(TalonarioEntity e) => TalonarioModel(
    codTalonario: e.codTalonario,
    codTipoRecibo: e.codTipoRecibo,
    nroTalonario: e.nroTalonario,
    costoBs: e.costoBs,
    numeracionInicial: e.numeracionInicial,
    numeracionFinal: e.numeracionFinal,
    estado: e.estado,
    codEmpresa: e.codEmpresa,
    observacion: e.observacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    sigla: e.sigla,
    datoTipoNombre: e.datoTipoNombre,
    datoTipo: e.datoTipo,
    datoEmpresa: e.datoEmpresa,
    datoTalonario: e.datoTalonario,
    entregas: e.entregas,
    devoluciones: e.devoluciones,
    cierres: e.cierres,
    codEstadoActual: e.codEstadoActual,
    estadoActual: e.estadoActual,
    puedeEntregar: e.puedeEntregar,
    puedeDevolver: e.puedeDevolver,
    puedeCerrar: e.puedeCerrar,
    datoDestinatario: e.datoDestinatario,
  );
}

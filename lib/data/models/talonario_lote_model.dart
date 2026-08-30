import 'package:bosque_flutter/data/models/talonario_model.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

/// Alta masiva de talonarios. Espeja TalonarioLoteDto del backend.
///
/// No es una de las 5 entidades de tabla: es la forma del request/response
/// de simular-lote y aplicar-lote.
///
/// Flujo: [simular] devuelve [talonarios] con los [duplicados] marcados y no
/// escribe nada; recién [aplicar] los graba, todo o nada.
class TalonarioLoteModel {
  /// Cada talonario cubre 50 recibos. Es fijo.
  static const int recibosPorTalonario = 50;

  static const int costoIndividual = 1;
  static const int costoTotal = 2;

  BigInt codTipoRecibo;
  BigInt codEmpresa;

  /// Cuántos talonarios generar.
  int cantidad;

  /// Bloque de folios desde donde arrancar, 1-based.
  /// El folio inicial sale de (bloqueInicial - 1) * 50 + 1.
  int bloqueInicial;

  /// Correlativo inicial del nroTalonario, se completa con ceros a 3 dígitos.
  int correlativoInicial;

  /// [costoIndividual]: el costo es por talonario.
  /// [costoTotal]: se divide entre [cantidad].
  int tipoCosto;
  double costo;

  /// Si es true el prefijo es año + sigla; si no, solo la sigla.
  bool porGestion;
  int anio;

  String observacion;
  BigInt audUsuario;

  /// Salida de simular y entrada de aplicar.
  List<TalonarioEntity> talonarios;

  /// nroTalonario que ya existen. Si no está vacío, aplicar va a fallar.
  List<String> duplicados;

  TalonarioLoteModel({
    required this.codTipoRecibo,
    required this.codEmpresa,
    required this.cantidad,
    this.bloqueInicial = 1,
    this.correlativoInicial = 1,
    this.tipoCosto = costoIndividual,
    this.costo = 0.0,
    this.porGestion = false,
    this.anio = 0,
    this.observacion = '',
    required this.audUsuario,
    List<TalonarioEntity>? talonarios,
    List<String>? duplicados,
  }) : talonarios = talonarios ?? <TalonarioEntity>[],
       duplicados = duplicados ?? <String>[];

  factory TalonarioLoteModel.fromJson(Map<String, dynamic> json) =>
      TalonarioLoteModel(
        codTipoRecibo: BigInt.from((json["codTipoRecibo"] ?? 0) as int),
        codEmpresa: BigInt.from((json["codEmpresa"] ?? 0) as int),
        cantidad: json["cantidad"] ?? 0,
        bloqueInicial: json["bloqueInicial"] ?? 1,
        correlativoInicial: json["correlativoInicial"] ?? 1,
        tipoCosto: json["tipoCosto"] ?? costoIndividual,
        costo: (json["costo"] ?? 0).toDouble(),
        porGestion: json["porGestion"] ?? false,
        anio: json["anio"] ?? 0,
        observacion: json["observacion"] ?? '',
        audUsuario: BigInt.from((json["audUsuario"] ?? 0) as int),
        talonarios:
            ((json["talonarios"] as List<dynamic>?) ?? <dynamic>[])
                .map(
                  (e) =>
                      TalonarioModel.fromJson(
                        e as Map<String, dynamic>,
                      ).toEntity(),
                )
                .toList(),
        duplicados:
            ((json["duplicados"] as List<dynamic>?) ?? <dynamic>[])
                .map((e) => e.toString())
                .toList(),
      );

  Map<String, dynamic> toJson() => {
    "codTipoRecibo": codTipoRecibo.toInt(),
    "codEmpresa": codEmpresa.toInt(),
    "cantidad": cantidad,
    "bloqueInicial": bloqueInicial,
    "correlativoInicial": correlativoInicial,
    "tipoCosto": tipoCosto,
    "costo": costo,
    "porGestion": porGestion,
    "anio": anio,
    "observacion": observacion,
    "audUsuario": audUsuario.toInt(),
    "talonarios":
        talonarios.map((e) => TalonarioModel.fromEntity(e).toJson()).toList(),
  };

  bool get tieneDuplicados => duplicados.isNotEmpty;
}

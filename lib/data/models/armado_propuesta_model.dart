/// Los models de `/price/armado/*`. Ver `armado_propuesta_entity.dart` para
/// por que estan juntos: son las formas de respuesta del asistente, no tablas.
///
/// Los montos llegan como numero JSON (BigDecimal en el backend) y los ids como
/// entero; un entero sin decimales puede llegar como `int` aunque sea un
/// importe, asi que todo se lee con los lectores de abajo y nunca con `as`.
library;

import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';

class LineaArmadoModel {
  LineaArmadoModel({
    required this.idPrecio,
    required this.idClasificacion,
    required this.codSucursal,
    required this.nombreSucursal,
    required this.nombrePrecio,
    required this.vpp,
    required this.listNum,
    required this.porcentaje,
    required this.iva,
    required this.it,
    required this.flete,
    required this.precioActual,
    required this.estado,
    required this.fueraDeOrden,
    this.idPrecioPropuesto,
    this.precioPropuestoGuardado,
    this.precioCalculado,
    this.porcentajeVigente,
    this.porcentajeCambiado = false,
  });

  BigInt idPrecio;
  BigInt idClasificacion;
  BigInt codSucursal;
  String nombreSucursal;
  String nombrePrecio;
  int vpp;
  BigInt listNum;
  double porcentaje;
  double iva;
  double it;
  double flete;
  double precioActual;
  BigInt? idPrecioPropuesto;
  double? precioPropuestoGuardado;
  double? precioCalculado;
  String estado;
  bool fueraDeOrden;

  /// Null si el backend no lo manda: la entity usa entonces [porcentaje].
  double? porcentajeVigente;
  bool porcentajeCambiado;

  factory LineaArmadoModel.fromJson(Map<String, dynamic> json) =>
      LineaArmadoModel(
        idPrecio: _id(json['idPrecio']) ?? BigInt.zero,
        idClasificacion: _id(json['idClasificacion']) ?? BigInt.zero,
        codSucursal: _id(json['codSucursal']) ?? BigInt.zero,
        nombreSucursal: _texto(json['nombreSucursal']),
        nombrePrecio: _texto(json['nombrePrecio']),
        vpp: _entero(json['vpp']),
        listNum: _id(json['listNum']) ?? BigInt.zero,
        porcentaje: _monto(json['porcentaje']) ?? 0,
        iva: _monto(json['iva']) ?? 0,
        it: _monto(json['it']) ?? 0,
        flete: _monto(json['flete']) ?? 0,
        precioActual: _monto(json['precioActual']) ?? 0,
        idPrecioPropuesto: _id(json['idPrecioPropuesto']),
        precioPropuestoGuardado: _monto(json['precioPropuestoGuardado']),
        precioCalculado: _monto(json['precioCalculado']),
        estado: _texto(json['estado']),
        fueraDeOrden: json['fueraDeOrden'] == true,
        porcentajeVigente: _monto(json['porcentajeVigente']),
        porcentajeCambiado: json['porcentajeCambiado'] == true,
      );

  LineaArmadoEntity toEntity() => LineaArmadoEntity(
    idPrecio: idPrecio,
    idClasificacion: idClasificacion,
    codSucursal: codSucursal,
    nombreSucursal: nombreSucursal,
    nombrePrecio: nombrePrecio,
    vpp: vpp,
    listNum: listNum,
    porcentaje: porcentaje,
    iva: iva,
    it: it,
    flete: flete,
    precioActual: precioActual,
    idPrecioPropuesto: idPrecioPropuesto,
    precioPropuestoGuardado: precioPropuestoGuardado,
    precioCalculado: precioCalculado,
    estado: EstadoLineaArmado.desdeCodigo(estado),
    fueraDeOrden: fueraDeOrden,
    porcentajeVigente: porcentajeVigente,
    porcentajeCambiado: porcentajeCambiado,
  );
}

class CalculoFamiliaModel {
  CalculoFamiliaModel({
    required this.codigoFamilia,
    required this.grupoFamilia,
    required this.proveedor,
    required this.presentacion,
    required this.tipo,
    required this.rangoGramaje,
    required this.color,
    required this.costoActual,
    required this.enPropuesta,
    required this.lineas,
    required this.errores,
    required this.lineasNuevas,
    required this.lineasActualizadas,
    required this.lineasSinCambio,
    required this.guardado,
    this.lineasInactivas = 0,
    this.listasInactivas = const <String>[],
    this.porcentajesCambiados = 0,
    this.idPropuesta,
    this.costo,
    this.costoGuardado,
    this.impedimento,
  });

  BigInt? idPropuesta;
  int codigoFamilia;
  String grupoFamilia;
  String proveedor;
  String presentacion;
  String tipo;
  String rangoGramaje;
  String color;
  double? costo;
  double costoActual;
  double? costoGuardado;
  bool enPropuesta;
  List<LineaArmadoModel> lineas;
  List<String> errores;
  int lineasNuevas;
  int lineasActualizadas;
  int lineasSinCambio;
  int lineasInactivas;
  List<String> listasInactivas;
  int porcentajesCambiados;
  bool guardado;
  String? impedimento;

  factory CalculoFamiliaModel.fromJson(Map<String, dynamic> json) =>
      CalculoFamiliaModel(
        idPropuesta: _idPositivo(json['idPropuesta']),
        codigoFamilia: _entero(json['codigoFamilia']),
        grupoFamilia: _texto(json['grupoFamilia']),
        proveedor: _texto(json['proveedor']),
        presentacion: _texto(json['presentacion']),
        tipo: _texto(json['tipo']),
        rangoGramaje: _texto(json['rangoGramaje']),
        color: _texto(json['color']),
        costo: _monto(json['costo']),
        costoActual: _monto(json['costoActual']) ?? 0,
        costoGuardado: _monto(json['costoGuardado']),
        enPropuesta: json['enPropuesta'] == true,
        lineas: [
          for (final l in (json['lineas'] as List<dynamic>? ?? const []))
            LineaArmadoModel.fromJson(Map<String, dynamic>.from(l as Map)),
        ],
        errores: [
          for (final e in (json['errores'] as List<dynamic>? ?? const []))
            e.toString(),
        ],
        lineasNuevas: _entero(json['lineasNuevas']),
        lineasActualizadas: _entero(json['lineasActualizadas']),
        lineasSinCambio: _entero(json['lineasSinCambio']),
        lineasInactivas: _entero(json['lineasInactivas']),
        listasInactivas: [
          for (final l
              in (json['listasInactivas'] as List<dynamic>? ?? const []))
            l.toString(),
        ],
        porcentajesCambiados: _entero(json['porcentajesCambiados']),
        guardado: json['guardado'] == true,
        impedimento: _textoONulo(json['impedimento']),
      );

  CalculoFamiliaEntity toEntity() => CalculoFamiliaEntity(
    idPropuesta: idPropuesta,
    codigoFamilia: codigoFamilia,
    grupoFamilia: grupoFamilia,
    proveedor: proveedor,
    presentacion: presentacion,
    tipo: tipo,
    rangoGramaje: rangoGramaje,
    color: color,
    costo: costo,
    costoActual: costoActual,
    costoGuardado: costoGuardado,
    enPropuesta: enPropuesta,
    lineas: List.unmodifiable(lineas.map((l) => l.toEntity())),
    errores: List.unmodifiable(errores),
    lineasNuevas: lineasNuevas,
    lineasActualizadas: lineasActualizadas,
    lineasSinCambio: lineasSinCambio,
    lineasInactivas: lineasInactivas,
    listasInactivas: List.unmodifiable(listasInactivas),
    porcentajesCambiados: porcentajesCambiados,
    guardado: guardado,
    impedimento: impedimento,
  );
}

class FleteArmadoModel {
  FleteArmadoModel({
    required this.codSucursal,
    required this.nombreSucursal,
    required this.valor,
    this.idIncre,
  });

  BigInt? idIncre;
  BigInt codSucursal;
  String nombreSucursal;
  double valor;

  /// El backend reutiliza `CostoIncreSucursalDto`, cuyo nombre de sucursal se
  /// llama `nombre` (la columna de tb_sucursal).
  factory FleteArmadoModel.fromJson(Map<String, dynamic> json) =>
      FleteArmadoModel(
        idIncre: _idPositivo(json['idIncre']),
        codSucursal: _id(json['codSucursal']) ?? BigInt.zero,
        nombreSucursal: _texto(json['nombre']),
        valor: _monto(json['valor']) ?? 0,
      );

  factory FleteArmadoModel.fromEntity(FleteArmadoEntity e) => FleteArmadoModel(
    idIncre: e.idIncre,
    codSucursal: e.codSucursal,
    nombreSucursal: e.nombreSucursal,
    valor: e.valor,
  );

  Map<String, dynamic> toJson() => {
    if (idIncre != null) 'idIncre': idIncre!.toInt(),
    'codSucursal': codSucursal.toInt(),
    'nombre': nombreSucursal,
    'valor': valor,
  };

  FleteArmadoEntity toEntity() => FleteArmadoEntity(
    idIncre: idIncre,
    codSucursal: codSucursal,
    nombreSucursal: nombreSucursal,
    valor: valor,
  );
}

class FletesArmadoModel {
  FletesArmadoModel({
    required this.deLaPropuesta,
    required this.fletes,
    this.idPropuestaReferencia,
  });

  BigInt? idPropuestaReferencia;
  bool deLaPropuesta;
  List<FleteArmadoModel> fletes;

  factory FletesArmadoModel.fromJson(Map<String, dynamic> json) =>
      FletesArmadoModel(
        idPropuestaReferencia: _idPositivo(json['idPropuestaReferencia']),
        deLaPropuesta: json['deLaPropuesta'] == true,
        fletes: [
          for (final f in (json['fletes'] as List<dynamic>? ?? const []))
            FleteArmadoModel.fromJson(Map<String, dynamic>.from(f as Map)),
        ],
      );

  FletesArmadoEntity toEntity() => FletesArmadoEntity(
    idPropuestaReferencia: idPropuestaReferencia,
    deLaPropuesta: deLaPropuesta,
    fletes: List.unmodifiable(fletes.map((f) => f.toEntity())),
  );
}

class FamiliaArmadaModel {
  FamiliaArmadaModel({
    required this.codigoFamilia,
    required this.lineas,
    this.costoSug,
  });

  int codigoFamilia;
  double? costoSug;
  int lineas;

  factory FamiliaArmadaModel.fromJson(Map<String, dynamic> json) =>
      FamiliaArmadaModel(
        codigoFamilia: _entero(json['codigoFamilia']),
        costoSug: _monto(json['costoSug']),
        lineas: _entero(json['lineas']),
      );

  FamiliaArmadaEntity toEntity() => FamiliaArmadaEntity(
    codigoFamilia: codigoFamilia,
    costoSug: costoSug,
    lineas: lineas,
  );
}

class ResultadoArmadoModel {
  ResultadoArmadoModel({
    required this.idPropuesta,
    required this.articulos,
    required this.omitidos,
    required this.familiasRecalculadas,
    required this.lineasEscritas,
  });

  BigInt idPropuesta;
  int articulos;
  int omitidos;
  int familiasRecalculadas;
  int lineasEscritas;

  factory ResultadoArmadoModel.fromJson(Map<String, dynamic> json) =>
      ResultadoArmadoModel(
        idPropuesta: _id(json['idPropuesta']) ?? BigInt.zero,
        articulos: _entero(json['articulos']),
        omitidos: _entero(json['omitidos']),
        familiasRecalculadas: _entero(json['familiasRecalculadas']),
        lineasEscritas: _entero(json['lineasEscritas']),
      );

  ResultadoArmadoEntity toEntity() => ResultadoArmadoEntity(
    idPropuesta: idPropuesta,
    articulos: articulos,
    omitidos: omitidos,
    familiasRecalculadas: familiasRecalculadas,
    lineasEscritas: lineasEscritas,
  );
}

/// El cuerpo de calcularFamilia y guardarFamilia. Los campos del alta
/// -titulo, obs, fletes- solo viajan cuando la propuesta todavia no existe.
///
/// [porcentajes] son los margenes cambiados en el editor, por lista
/// (idClasificacion). Las listas que no estan usan el de tpr_porcentaje; al
/// guardar, los que llegan distintos quedan registrados para la familia.
class PedidoFamiliaArmadoModel {
  PedidoFamiliaArmadoModel({
    required this.codigoFamilia,
    this.idPropuesta,
    this.titulo,
    this.obs,
    this.fletes,
    this.costo,
    this.porcentajes,
  });

  BigInt? idPropuesta;
  String? titulo;
  String? obs;
  List<FleteArmadoEntity>? fletes;
  int codigoFamilia;
  double? costo;
  Map<BigInt, double>? porcentajes;

  bool get _esAlta => idPropuesta == null || idPropuesta! <= BigInt.zero;

  Map<String, dynamic> toJson() => {
    if (!_esAlta) 'idPropuesta': idPropuesta!.toInt(),
    if (_esAlta && titulo != null) 'titulo': titulo,
    if (_esAlta && obs != null) 'obs': obs,
    if (_esAlta && fletes != null)
      'fletes': [
        for (final f in fletes!) FleteArmadoModel.fromEntity(f).toJson(),
      ],
    'codigoFamilia': codigoFamilia,
    if (costo != null) 'costo': costo,
    if (porcentajes != null && porcentajes!.isNotEmpty)
      'porcentajes': [
        for (final p in porcentajes!.entries)
          {'idClasificacion': p.key.toInt(), 'porcentaje': p.value},
      ],
  };
}

/// El cuerpo de calcularFamilias y guardarFamilias: varias familias, cada una
/// con su costo. Como en [PedidoFamiliaArmadoModel], titulo, obs y fletes solo
/// viajan cuando la propuesta todavia no existe.
class PedidoLoteArmadoModel {
  PedidoLoteArmadoModel({
    required this.costos,
    this.idPropuesta,
    this.titulo,
    this.obs,
    this.fletes,
  });

  BigInt? idPropuesta;
  String? titulo;
  String? obs;
  List<FleteArmadoEntity>? fletes;

  /// Costo propuesto por codigo de familia, en USD por tonelada.
  Map<int, double> costos;

  bool get _esAlta => idPropuesta == null || idPropuesta! <= BigInt.zero;

  Map<String, dynamic> toJson() => {
    if (!_esAlta) 'idPropuesta': idPropuesta!.toInt(),
    if (_esAlta && titulo != null) 'titulo': titulo,
    if (_esAlta && obs != null) 'obs': obs,
    if (_esAlta && fletes != null)
      'fletes': [
        for (final f in fletes!) FleteArmadoModel.fromEntity(f).toJson(),
      ],
    'familias': [
      for (final c in costos.entries)
        {'codigoFamilia': c.key, 'costo': c.value},
    ],
  };
}

// ── Lectura defensiva ────────────────────────────────────────────────────────

BigInt? _id(Object? v) => switch (v) {
  final BigInt n => n,
  final int n => BigInt.from(n),
  final num n => BigInt.from(n.toInt()),
  final String s => BigInt.tryParse(s.trim()),
  _ => null,
};

/// Cero no es un id: es lo que manda el backend cuando no hay.
BigInt? _idPositivo(Object? v) {
  final id = _id(v);
  return (id == null || id <= BigInt.zero) ? null : id;
}

int _entero(Object? v) => switch (v) {
  final int n => n,
  final num n => n.toInt(),
  final String s => int.tryParse(s.trim()) ?? 0,
  _ => 0,
};

double? _monto(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s.trim()),
  _ => null,
};

String _texto(Object? v) => v == null ? '' : v.toString().trim();

String? _textoONulo(Object? v) {
  final t = _texto(v);
  return t.isEmpty ? null : t;
}

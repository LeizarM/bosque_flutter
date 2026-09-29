import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';

/// La respuesta de `/price/vistaPropuesta` (`VistaPropuestaDto` del backend).
/// Las cifras son BigDecimal en Java y viajan como numero: aca van en double,
/// solo para mostrar.
class VistaPropuestaModel {
  final int tipo;
  final bool conComparacion;
  final bool preciosPorUnidad;
  final double? tipoCambio;
  final String? avisoPreciosPorUnidad;
  final List<ListaVistaPropuestaModel> listas;
  final List<FilaVistaPropuestaModel> filas;

  const VistaPropuestaModel({
    required this.tipo,
    required this.conComparacion,
    this.preciosPorUnidad = false,
    this.tipoCambio,
    this.avisoPreciosPorUnidad,
    required this.listas,
    required this.filas,
  });

  factory VistaPropuestaModel.fromJson(Map<String, dynamic> json) =>
      VistaPropuestaModel(
        tipo: (json['tipo'] as num?)?.toInt() ?? 1,
        conComparacion: json['conComparacion'] == true,
        preciosPorUnidad: json['preciosPorUnidad'] == true,
        tipoCambio: (json['tipoCambio'] as num?)?.toDouble(),
        avisoPreciosPorUnidad: json['avisoPreciosPorUnidad'] as String?,
        listas: [
          for (final l in (json['listas'] as List? ?? const []))
            ListaVistaPropuestaModel.fromJson(l as Map<String, dynamic>),
        ],
        filas: [
          for (final f in (json['filas'] as List? ?? const []))
            FilaVistaPropuestaModel.fromJson(f as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'conComparacion': conComparacion,
    'preciosPorUnidad': preciosPorUnidad,
    'tipoCambio': tipoCambio,
    'avisoPreciosPorUnidad': avisoPreciosPorUnidad,
    'listas': [for (final l in listas) l.toJson()],
    'filas': [for (final f in filas) f.toJson()],
  };

  VistaPropuestaEntity toEntity() => VistaPropuestaEntity(
    tipo: tipo,
    conComparacion: conComparacion,
    preciosPorUnidad: preciosPorUnidad,
    tipoCambio: tipoCambio,
    avisoPreciosPorUnidad: avisoPreciosPorUnidad,
    listas: [for (final l in listas) l.toEntity()],
    filas: [for (final f in filas) f.toEntity()],
  );

  factory VistaPropuestaModel.fromEntity(VistaPropuestaEntity e) =>
      VistaPropuestaModel(
        tipo: e.tipo,
        conComparacion: e.conComparacion,
        preciosPorUnidad: e.preciosPorUnidad,
        tipoCambio: e.tipoCambio,
        avisoPreciosPorUnidad: e.avisoPreciosPorUnidad,
        listas: [
          for (final l in e.listas) ListaVistaPropuestaModel.fromEntity(l),
        ],
        filas: [for (final f in e.filas) FilaVistaPropuestaModel.fromEntity(f)],
      );
}

class ListaVistaPropuestaModel {
  final int vpp;
  final String sucursal;

  const ListaVistaPropuestaModel({required this.vpp, required this.sucursal});

  factory ListaVistaPropuestaModel.fromJson(Map<String, dynamic> json) =>
      ListaVistaPropuestaModel(
        vpp: (json['vpp'] as num?)?.toInt() ?? 0,
        sucursal: (json['sucursal'] as String? ?? '').trim(),
      );

  Map<String, dynamic> toJson() => {'vpp': vpp, 'sucursal': sucursal};

  ListaVistaPropuestaEntity toEntity() =>
      ListaVistaPropuestaEntity(vpp: vpp, sucursal: sucursal);

  factory ListaVistaPropuestaModel.fromEntity(ListaVistaPropuestaEntity e) =>
      ListaVistaPropuestaModel(vpp: e.vpp, sucursal: e.sucursal);
}

class FilaVistaPropuestaModel {
  final int codigoFamilia;
  final String descripcionFamilia;
  final BigInt? ultimaPropuesta;
  final String codArticulo;
  final String descripcion;
  final double utm;
  final double costoTM;
  final bool conFilaActual;
  final List<double?> porcentajes;
  final List<double?> actuales;
  final List<double?> propuestos;
  final List<int?> cambios;
  final List<double?> unidadUsd;
  final List<double?> unidadBs;
  final List<double?> unidadBsProductiva;

  const FilaVistaPropuestaModel({
    required this.codigoFamilia,
    this.descripcionFamilia = '',
    this.ultimaPropuesta,
    required this.codArticulo,
    required this.descripcion,
    required this.utm,
    required this.costoTM,
    required this.conFilaActual,
    required this.porcentajes,
    required this.actuales,
    required this.propuestos,
    required this.cambios,
    this.unidadUsd = const [],
    this.unidadBs = const [],
    this.unidadBsProductiva = const [],
  });

  static List<double?> _cifras(Object? v) => [
    for (final x in (v as List? ?? const [])) (x as num?)?.toDouble(),
  ];

  factory FilaVistaPropuestaModel.fromJson(Map<String, dynamic> json) =>
      FilaVistaPropuestaModel(
        codigoFamilia: (json['codigoFamilia'] as num?)?.toInt() ?? 0,
        descripcionFamilia:
            (json['descripcionFamilia'] as String? ?? '').trim(),
        ultimaPropuesta:
            json['ultimaPropuesta'] == null
                ? null
                : BigInt.from(json['ultimaPropuesta'] as num),
        codArticulo: (json['codArticulo'] as String? ?? '').trim(),
        descripcion: (json['descripcion'] as String? ?? '').trim(),
        utm: (json['utm'] as num?)?.toDouble() ?? 0,
        costoTM: (json['costoTM'] as num?)?.toDouble() ?? 0,
        conFilaActual: json['conFilaActual'] == true,
        porcentajes: _cifras(json['porcentajes']),
        actuales: _cifras(json['actuales']),
        propuestos: _cifras(json['propuestos']),
        cambios: [
          for (final x in (json['cambios'] as List? ?? const []))
            (x as num?)?.toInt(),
        ],
        unidadUsd: _cifras(json['unidadUsd']),
        unidadBs: _cifras(json['unidadBs']),
        unidadBsProductiva: _cifras(json['unidadBsProductiva']),
      );

  Map<String, dynamic> toJson() => {
    'codigoFamilia': codigoFamilia,
    'descripcionFamilia': descripcionFamilia,
    'ultimaPropuesta': ultimaPropuesta?.toInt(),
    'codArticulo': codArticulo,
    'descripcion': descripcion,
    'utm': utm,
    'costoTM': costoTM,
    'conFilaActual': conFilaActual,
    'porcentajes': porcentajes,
    'actuales': actuales,
    'propuestos': propuestos,
    'cambios': cambios,
    'unidadUsd': unidadUsd,
    'unidadBs': unidadBs,
    'unidadBsProductiva': unidadBsProductiva,
  };

  FilaVistaPropuestaEntity toEntity() => FilaVistaPropuestaEntity(
    codigoFamilia: codigoFamilia,
    descripcionFamilia: descripcionFamilia,
    ultimaPropuesta: ultimaPropuesta,
    codArticulo: codArticulo,
    descripcion: descripcion,
    utm: utm,
    costoTM: costoTM,
    conFilaActual: conFilaActual,
    porcentajes: porcentajes,
    actuales: actuales,
    propuestos: propuestos,
    cambios: cambios,
    unidadUsd: unidadUsd,
    unidadBs: unidadBs,
    unidadBsProductiva: unidadBsProductiva,
  );

  factory FilaVistaPropuestaModel.fromEntity(FilaVistaPropuestaEntity e) =>
      FilaVistaPropuestaModel(
        codigoFamilia: e.codigoFamilia,
        descripcionFamilia: e.descripcionFamilia,
        ultimaPropuesta: e.ultimaPropuesta,
        codArticulo: e.codArticulo,
        descripcion: e.descripcion,
        utm: e.utm,
        costoTM: e.costoTM,
        conFilaActual: e.conFilaActual,
        porcentajes: e.porcentajes,
        actuales: e.actuales,
        propuestos: e.propuestos,
        cambios: e.cambios,
        unidadUsd: e.unidadUsd,
        unidadBs: e.unidadBs,
        unidadBsProductiva: e.unidadBsProductiva,
      );
}

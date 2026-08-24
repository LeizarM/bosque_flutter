import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';

/// Mapeo de las tres tablas de politica del descuento por familia.
///
/// Las fechas llegan como ISO-8601 o como epoch en milisegundos segun como
/// Jackson serialice el java.util.Date, asi que se aceptan las dos formas.
DateTime? _fecha(dynamic v) {
  if (v == null) return null;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.tryParse(v.toString());
}

double? _num(dynamic v) => (v as num?)?.toDouble();

/// Solo la fecha, sin hora: es lo que espera un `date` de SQL Server y evita
/// que un desfase de zona horaria corra la vigencia un dia.
String? _soloFecha(DateTime? f) =>
    f == null
        ? null
        : '${f.year.toString().padLeft(4, '0')}-'
            '${f.month.toString().padLeft(2, '0')}-'
            '${f.day.toString().padLeft(2, '0')}';

class FamiliaPoliticaModel {
  FamiliaPoliticaModel({
    required this.idFamPolitica,
    required this.idGrpFamiliaSap,
    required this.grpFam,
    this.alias,
    required this.porcentajePago,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.audFecha,
    this.audUsuario,
  });

  final int idFamPolitica;
  final int idGrpFamiliaSap;
  final String grpFam;
  final String? alias;
  final double porcentajePago;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final DateTime? audFecha;
  final int? audUsuario;

  factory FamiliaPoliticaModel.fromJson(Map<String, dynamic> json) =>
      FamiliaPoliticaModel(
        idFamPolitica: json['idFamPolitica'] ?? 0,
        idGrpFamiliaSap: json['idGrpFamiliaSap'] ?? 0,
        grpFam: json['grpFam'] ?? '',
        alias: json['alias'],
        porcentajePago: _num(json['porcentajePago']) ?? 100.0,
        vigenteDesde: _fecha(json['vigenteDesde']),
        vigenteHasta: _fecha(json['vigenteHasta']),
        activo: json['activo'] ?? 1,
        audFecha: _fecha(json['audFecha']),
        audUsuario: json['audUsuario'],
      );

  Map<String, dynamic> toJson() => {
    'idFamPolitica': idFamPolitica,
    'idGrpFamiliaSap': idGrpFamiliaSap,
    'porcentajePago': porcentajePago,
    'vigenteDesde': _soloFecha(vigenteDesde),
    'vigenteHasta': _soloFecha(vigenteHasta),
    'activo': activo,
    'audUsuario': audUsuario ?? 0,
  };

  factory FamiliaPoliticaModel.fromEntity(
    FamiliaPoliticaEntity e,
    int codUsuario,
  ) => FamiliaPoliticaModel(
    idFamPolitica: e.idFamPolitica,
    idGrpFamiliaSap: e.idGrpFamiliaSap,
    grpFam: e.grpFam,
    alias: e.alias,
    porcentajePago: e.porcentajePago,
    vigenteDesde: e.vigenteDesde,
    vigenteHasta: e.vigenteHasta,
    activo: e.activo,
    audUsuario: codUsuario,
  );

  FamiliaPoliticaEntity toEntity() => FamiliaPoliticaEntity(
    idFamPolitica: idFamPolitica,
    idGrpFamiliaSap: idGrpFamiliaSap,
    grpFam: grpFam,
    alias: alias,
    porcentajePago: porcentajePago,
    vigenteDesde: vigenteDesde ?? DateTime.now(),
    vigenteHasta: vigenteHasta,
    activo: activo,
    audFecha: audFecha,
  );
}

class VendedorExentoModel {
  VendedorExentoModel({
    required this.idVenExento,
    required this.idVendedor,
    this.nomVenSAP,
    this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.motivo,
    this.audUsuario,
  });

  final int idVenExento;
  final int idVendedor;
  final String? nomVenSAP;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final String? motivo;
  final int? audUsuario;

  factory VendedorExentoModel.fromJson(Map<String, dynamic> json) =>
      VendedorExentoModel(
        idVenExento: json['idVenExento'] ?? 0,
        idVendedor: json['idVendedor'] ?? 0,
        nomVenSAP: json['nomVenSAP'],
        vigenteDesde: _fecha(json['vigenteDesde']),
        vigenteHasta: _fecha(json['vigenteHasta']),
        activo: json['activo'] ?? 1,
        motivo: json['motivo'],
        audUsuario: json['audUsuario'],
      );

  Map<String, dynamic> toJson() => {
    'idVenExento': idVenExento,
    'idVendedor': idVendedor,
    'vigenteDesde': _soloFecha(vigenteDesde),
    'vigenteHasta': _soloFecha(vigenteHasta),
    'activo': activo,
    'motivo': motivo,
    'audUsuario': audUsuario ?? 0,
  };

  factory VendedorExentoModel.fromEntity(
    VendedorExentoEntity e,
    int codUsuario,
  ) => VendedorExentoModel(
    idVenExento: e.idVenExento,
    idVendedor: e.idVendedor,
    nomVenSAP: e.nomVenSAP,
    vigenteDesde: e.vigenteDesde,
    vigenteHasta: e.vigenteHasta,
    activo: e.activo,
    motivo: e.motivo,
    audUsuario: codUsuario,
  );

  VendedorExentoEntity toEntity() => VendedorExentoEntity(
    idVenExento: idVenExento,
    idVendedor: idVendedor,
    nomVenSAP: nomVenSAP,
    vigenteDesde: vigenteDesde ?? DateTime.now(),
    vigenteHasta: vigenteHasta,
    activo: activo,
    motivo: motivo,
  );
}

class ClienteExcluidoModel {
  ClienteExcluidoModel({
    required this.idVenCliExc,
    required this.idVendedor,
    this.nomVenSAP,
    required this.cardCode,
    this.origen,
    this.vigenteDesde,
    this.vigenteHasta,
    required this.activo,
    this.motivo,
    this.audUsuario,
  });

  final int idVenCliExc;
  final int idVendedor;
  final String? nomVenSAP;
  final String cardCode;
  final String? origen;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final int activo;
  final String? motivo;
  final int? audUsuario;

  factory ClienteExcluidoModel.fromJson(Map<String, dynamic> json) =>
      ClienteExcluidoModel(
        idVenCliExc: json['idVenCliExc'] ?? 0,
        idVendedor: json['idVendedor'] ?? 0,
        nomVenSAP: json['nomVenSAP'],
        cardCode: json['cardCode'] ?? '',
        origen: json['origen'],
        vigenteDesde: _fecha(json['vigenteDesde']),
        vigenteHasta: _fecha(json['vigenteHasta']),
        activo: json['activo'] ?? 1,
        motivo: json['motivo'],
        audUsuario: json['audUsuario'],
      );

  Map<String, dynamic> toJson() => {
    'idVenCliExc': idVenCliExc,
    'idVendedor': idVendedor,
    'cardCode': cardCode,
    'origen': origen,
    'vigenteDesde': _soloFecha(vigenteDesde),
    'vigenteHasta': _soloFecha(vigenteHasta),
    'activo': activo,
    'motivo': motivo,
    'audUsuario': audUsuario ?? 0,
  };

  factory ClienteExcluidoModel.fromEntity(
    ClienteExcluidoEntity e,
    int codUsuario,
  ) => ClienteExcluidoModel(
    idVenCliExc: e.idVenCliExc,
    idVendedor: e.idVendedor,
    nomVenSAP: e.nomVenSAP,
    cardCode: e.cardCode,
    origen: e.origen,
    vigenteDesde: e.vigenteDesde,
    vigenteHasta: e.vigenteHasta,
    activo: e.activo,
    motivo: e.motivo,
    audUsuario: codUsuario,
  );

  ClienteExcluidoEntity toEntity() => ClienteExcluidoEntity(
    idVenCliExc: idVenCliExc,
    idVendedor: idVendedor,
    nomVenSAP: nomVenSAP,
    cardCode: cardCode,
    origen: origen,
    vigenteDesde: vigenteDesde ?? DateTime.now(),
    vigenteHasta: vigenteHasta,
    activo: activo,
    motivo: motivo,
  );
}

class FamiliaSapOpcionModel {
  FamiliaSapOpcionModel({
    required this.idGrpFamiliaSap,
    required this.grpFam,
    this.alias,
    this.codIpx,
    this.codEpp,
    this.codPrp,
    required this.tienePolitica,
  });

  final int idGrpFamiliaSap;
  final String grpFam;
  final String? alias;
  final String? codIpx;
  final String? codEpp;
  final String? codPrp;
  final int tienePolitica;

  factory FamiliaSapOpcionModel.fromJson(Map<String, dynamic> json) =>
      FamiliaSapOpcionModel(
        idGrpFamiliaSap: json['idGrpFamiliaSap'] ?? 0,
        grpFam: json['grpFam'] ?? '',
        alias: json['alias'],
        codIpx: json['codGrpFamSap']?.toString(),
        codEpp: json['codGrpFamSapEpp']?.toString(),
        codPrp: json['codGrpFamSapProdPap']?.toString(),
        tienePolitica: json['tienePolitica'] ?? 0,
      );

  FamiliaSapOpcionEntity toEntity() => FamiliaSapOpcionEntity(
    idGrpFamiliaSap: idGrpFamiliaSap,
    grpFam: grpFam,
    alias: alias,
    codIpx: codIpx,
    codEpp: codEpp,
    codPrp: codPrp,
    tienePolitica: tienePolitica == 1,
  );
}

/// Mapeo del detalle de lo descontado.
///
/// Se guarda el mapa crudo en vez de declarar treinta campos: el SP devuelve
/// tres formas distintas segun la accion -detalle abierto, historico y
/// resumen- y declarar cada una por separado triplicaria el archivo sin
/// agregar nada. La entidad si es explicita, que es donde importa.
class DescuentoDetalleModel {
  DescuentoDetalleModel(this._j);
  final Map<String, dynamic> _j;

  factory DescuentoDetalleModel.fromJson(Map<String, dynamic> json) =>
      DescuentoDetalleModel(json);

  DescuentoDetalleEntity toEntity() => DescuentoDetalleEntity(
    docNum: _j['docNum'],
    empresa: _j['empresa'],
    fechaDoc: _fecha(_j['fechaDoc']),
    idVendedor: _j['idVendedor'],
    nombreVen: _j['nombreVen'],
    cardCode: _j['cardCode'],
    grupoFamilia: _j['grupoFamilia'],
    codGrupoSap: _j['codGrupoSap'],
    itemCode: _j['itemCode'],
    itemName: _j['itemName'],
    cantidad: _num(_j['cantidad']),
    montoItemBs: _num(_j['montoItemBS']),
    porcentajePago: _num(_j['porcentajePago']),
    porcentajeDescuento: _num(_j['porcentajeDescuento']),
    descuentoBs: _num(_j['descuentoBS']) ?? _num(_j['descuentoNotaBS']),
    montoBaseNotaBs: _num(_j['montoBaseNotaBS']),
    montoNotaAjustadoBs: _num(_j['montoNotaAjustadoBS']),
    comisionBs: _num(_j['comisionBS']),
    detalleBond: _j['detalleBond'],
    vendedorExento: (_j['vendedorExento'] ?? 0) == 1,
    esHistorico: (_j['esHistorico'] ?? 0) == 1,
    notas: _j['notas'],
    items: _j['items'],
    unidades: _num(_j['unidades']),
    montoItemsBs: _num(_j['montoItemsBS']),
  );
}

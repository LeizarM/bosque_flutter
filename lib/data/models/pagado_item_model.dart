import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';

/// Las fechas llegan como ISO-8601 o como epoch en milisegundos segun como
/// Jackson serialice el java.util.Date, asi que se aceptan las dos formas.
DateTime? _fecha(dynamic v) {
  if (v == null) return null;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.tryParse(v.toString());
}

double? _num(dynamic v) => (v as num?)?.toDouble();

int? _entero(dynamic v) => (v as num?)?.toInt();

/// Los importes vienen con el alias del SP, que lleva BS en mayuscula
/// (`montoLineaBS`). Se acepta tambien la forma camel por si el DTO de Spring
/// renombra el campo: es el mismo criterio que ya usa DescuentoDetalleModel,
/// donde una clave equivocada no da error sino un cero silencioso.
double? _importe(Map<String, dynamic> j, String base) =>
    _num(j['${base}BS']) ?? _num(j['${base}Bs']);

/// Mapea la rama 'L' de p_list_tcom_PagadoItem.
///
/// Campos explicitos y no el mapa crudo: a diferencia de DescuentoDetalle, esta
/// rama devuelve UNA sola forma, asi que declararla cuesta poco y deja el
/// contrato a la vista.
class PagadoItemModel {
  PagadoItemModel(this._j);
  final Map<String, dynamic> _j;

  factory PagadoItemModel.fromJson(Map<String, dynamic> json) =>
      PagadoItemModel(json);

  PagadoItemEntity toEntity() => PagadoItemEntity(
    idPagadoItem: _entero(_j['idPagadoItem']) ?? 0,
    idPagado: _entero(_j['idPagado']) ?? 0,
    mesPago: _entero(_j['mesPago']),
    anioPago: _entero(_j['anioPago']),
    esInterno: _entero(_j['esInterno']),
    docNum: _entero(_j['docNum']),
    origen: _j['origen'],
    bd: _entero(_j['bd']),
    fechaDoc: _fecha(_j['fechaDoc']),
    idVendedor: _entero(_j['idVendedor']),
    itemCode: _j['itemCode'],
    itemName: _j['itemName'],
    itmsGrpCod: _entero(_j['itmsGrpCod']),
    idGrpFamiliaSap: _entero(_j['idGrpFamiliaSap']),
    grpFam: _j['grpFam'],
    cantidad: _num(_j['cantidad']),
    montoLineaBs: _importe(_j, 'montoLinea'),
    // La columna es INT NOT NULL en la tabla. El default 1 solo cubre el caso
    // de que el backend no mande la clave; con 0 por defecto una linea que si
    // descontó se pintaria como excluida, que es el error mas caro de los dos.
    aplicaDescuento: (_entero(_j['aplicaDescuento']) ?? 1) == 1,
    porcentajePago: _num(_j['porcentajePago']),
    descuentoBs: _importe(_j, 'descuento') ?? 0,
    motivoExclusion: _j['motivoExclusion'],
    audFecha: _fecha(_j['audFecha']),
  );
}

/// Mapea la rama 'R': el resumen por motivo.
class PagadoItemResumenModel {
  PagadoItemResumenModel(this._j);
  final Map<String, dynamic> _j;

  factory PagadoItemResumenModel.fromJson(Map<String, dynamic> json) =>
      PagadoItemResumenModel(json);

  PagadoItemResumenEntity toEntity() => PagadoItemResumenEntity(
    // ISNULL(motivoExclusion, 'DESCONTO') lo resuelve el SP, asi que aca no
    // deberia llegar null. Si llega, es lo que descontó: es el unico caso en
    // que el motivo esta vacio.
    motivo: _j['motivo'] ?? MotivoItemPagado.desconto,
    items: _entero(_j['items']) ?? 0,
    montoBs: _importe(_j, 'monto') ?? 0,
    // Este no lleva sufijo BS: en la rama 'R' el alias es `descuento` a secas.
    descuentoBs: _num(_j['descuento']) ?? _importe(_j, 'descuento') ?? 0,
  );
}

/// Mapea p_list_tcom_PagadoItemCorte.
class PagadoItemCorteModel {
  PagadoItemCorteModel(this._j);
  final Map<String, dynamic> _j;

  factory PagadoItemCorteModel.fromJson(Map<String, dynamic> json) =>
      PagadoItemCorteModel(json);

  PagadoItemCorteEntity toEntity() => PagadoItemCorteEntity(
    idCorte: _entero(_j['idCorte']) ?? 0,
    mesPago: _entero(_j['mesPago']) ?? 0,
    anioPago: _entero(_j['anioPago']) ?? 0,
    esInterno: _entero(_j['esInterno']) ?? 1,
    items: _entero(_j['items']) ?? 0,
    itemsExcluidos: _entero(_j['itemsExcluidos']) ?? 0,
    notasPagadas: _entero(_j['notasPagadas']) ?? 0,
    notasConItems: _entero(_j['notasConItems']) ?? 0,
    notasSinItems: _entero(_j['notasSinItems']) ?? 0,
    politicaDesde: _fecha(_j['politicaDesde']),
    politicasActivas: _entero(_j['politicasActivas']) ?? 0,
    audFecha: _fecha(_j['audFecha']),
    lectura: _j['lectura'],
  );
}

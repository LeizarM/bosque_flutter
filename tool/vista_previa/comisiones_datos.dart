// Datos de mentira de la vista previa de Comisiones.
// Los textos son los más largos de la base real: con nombres cortos todo entra
// y el problema de layout pasa desapercibido.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';

/// Doble del repositorio: la barra de reportes lo lee en su `build` y sin él la
/// pestaña no dibuja. Sus métodos no se llaman (nadie aprieta botones aquí).
class RepoComisionesFalso implements ComisionesRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('La vista previa no llama a ${i.memberName}');
}

final _vendedores = <VendedorComisionEntity>[
  VendedorComisionEntity(
    idVendedor: BigInt.from(39),
    nomVenSap: 'Humberto de la Torre Villavicencio',
    comision: 0,
    esInterno: 1,
    activo: 1,
    audUsuario: BigInt.one,
    codVenImpexpap: 105,
    codVenEsppapel: 71,
    codVenProdpap: 33,
  ),
  VendedorComisionEntity(
    idVendedor: BigInt.from(55),
    nomVenSap: 'Marcela Caceres',
    comision: 0,
    esInterno: 1,
    activo: 1,
    audUsuario: BigInt.one,
    codVenImpexpap: 12,
  ),
  VendedorComisionEntity(
    idVendedor: BigInt.from(104),
    nomVenSap: 'Julio Buitrago',
    comision: 0,
    esInterno: 1,
    activo: 1,
    audUsuario: BigInt.one,
    codVenImpexpap: 44,
    codVenProdpap: 9,
  ),
  VendedorComisionEntity(
    idVendedor: BigInt.from(13),
    nomVenSap: 'Alexandro Zaballa',
    comision: 0,
    esInterno: 0,
    activo: 0,
    audUsuario: BigInt.one,
  ),
];

final _grupos = <GrupoComisionEntity>[
  GrupoComisionEntity(
    idGrupo: BigInt.from(17),
    grupo: 'Administracion Comercial',
    porcentaje: 0.025,
    esParaVenta: 0,
    esInterno: 1,
    bd: 1,
    siglaEmpresa: 'IMPEXPAP',
    activo: 1,
    audUsuario: BigInt.one,
  ),
  GrupoComisionEntity(
    idGrupo: BigInt.from(18),
    grupo: 'Supervisor Distribuicion',
    porcentaje: 0.02,
    esParaVenta: 0,
    esInterno: 1,
    bd: 1,
    siglaEmpresa: 'PRODUCTIVA PAPEL',
    activo: 1,
    audUsuario: BigInt.one,
  ),
  GrupoComisionEntity(
    idGrupo: BigInt.from(4),
    grupo: 'Cochabamba',
    porcentaje: 0.7,
    esParaVenta: 1,
    esInterno: 1,
    bd: 1,
    siglaEmpresa: 'IMPEXPAP',
    activo: 1,
    audUsuario: BigInt.one,
  ),
  GrupoComisionEntity(
    idGrupo: BigInt.from(13),
    grupo: 'Vendedor Externo',
    porcentaje: 0,
    esParaVenta: 1,
    esInterno: 0,
    bd: 1,
    siglaEmpresa: 'ESPPAPEL',
    activo: 0,
    audUsuario: BigInt.one,
  ),
];

final _asignaciones = <GrupoXVendedorEntity>[
  GrupoXVendedorEntity(
    idGrpVen: BigInt.one,
    idVendedor: BigInt.from(39),
    idGrupo: BigInt.from(17),
    estado: 1,
    ignoraComision: 0,
    fechaInicio: DateTime(2020, 1, 1),
    audUsuario: BigInt.one,
    nomVenSap: 'Humberto de la Torre Villavicencio',
    grupo: 'Administracion Comercial',
    porcentaje: 0.025,
    porcenComision: 2.5,
    esParaVenta: 0,
    esInterno: 1,
    vigente: 1,
  ),
  GrupoXVendedorEntity(
    idGrpVen: BigInt.two,
    idVendedor: BigInt.from(55),
    idGrupo: BigInt.from(4),
    estado: 1,
    ignoraComision: 1,
    fechaInicio: DateTime(2024, 6, 1),
    fechaFinalizacion: DateTime(2026, 12, 31),
    audUsuario: BigInt.one,
    nomVenSap: 'Marcela Caceres',
    grupo: 'Cochabamba',
    porcentaje: 0.7,
    porcenComision: 70,
    esParaVenta: 1,
    esInterno: 1,
    vigente: 1,
  ),
];

final _rangos = <ComisionPorRangoEntity>[
  ComisionPorRangoEntity(
    idCfr: BigInt.one,
    comision: 0.008,
    comisionVisual: 0.8,
    min: -999999999,
    max: -1,
    tipo: 'Contado',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
  ComisionPorRangoEntity(
    idCfr: BigInt.two,
    comision: 0.008,
    comisionVisual: 0.8,
    min: 0,
    max: 4,
    tipo: 'Contado',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
  ComisionPorRangoEntity(
    idCfr: BigInt.from(3),
    comision: 0.005,
    comisionVisual: 0.5,
    min: 5,
    max: 30,
    tipo: 'Credito',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
  ComisionPorRangoEntity(
    idCfr: BigInt.from(4),
    comision: 0.004,
    comisionVisual: 0.4,
    min: 31,
    max: 60,
    tipo: 'Credito',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
  ComisionPorRangoEntity(
    idCfr: BigInt.from(5),
    comision: 0.003,
    comisionVisual: 0.3,
    min: 61,
    max: 90,
    tipo: 'Credito',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
  ComisionPorRangoEntity(
    idCfr: BigInt.from(6),
    comision: 0.002,
    comisionVisual: 0.2,
    min: 91,
    max: 1000000,
    tipo: 'Credito',
    esInterno: 1,
    audUsuario: BigInt.one,
  ),
];

final _pendientes = <NotaPendienteEntity>[
  NotaPendienteEntity(
    fila: 1,
    idNoPagado: 111546,
    codVendedor: 105,
    nombreVen: 'Humberto de la Torre Villavicencio',
    fechaDoc: DateTime(2026, 8, 22),
    mes: 8,
    anio: 2026,
    docNum: 262211857,
    valido: 'V',
    indicador: 'PENDIENTE',
    estado: 'C',
    montoTotalBs: 1234567.89,
    montoCerradoBs: 1234567.89,
    origen: 'PRODUCTIVA PAPEL',
    saldoPendiente: 0,
  ),
  NotaPendienteEntity(
    fila: 2,
    idNoPagado: 111548,
    codVendedor: 71,
    nombreVen: 'Marcela Caceres',
    fechaDoc: DateTime(2026, 8, 21),
    mes: 8,
    anio: 2026,
    docNum: 262380980,
    valido: 'V',
    indicador: 'ABIERTA',
    estado: 'O',
    montoTotalBs: 48219.4,
    montoCerradoBs: 0,
    origen: 'ESPPAPEL',
    saldoPendiente: 48219.4,
  ),
];

final _preliminar = <PreliminarComisionEntity>[
  const PreliminarComisionEntity(
    ord: 1,
    idVendedor: 39,
    mes: 8,
    anio: 2026,
    etiqueta: 'Vendedor 2',
    nombreVen: 'Humberto de la Torre Villavicencio',
    comision: 0.0068432640459531778,
    ignoraComision: 0,
    montoBase: 627590.93,
    bsAPagar: 3394.18,
    usdAPagar: 295.15,
  ),
  const PreliminarComisionEntity(
    ord: 1,
    idVendedor: 55,
    mes: 8,
    anio: 2026,
    etiqueta: 'Cochabamba',
    nombreVen: 'Marcela Caceres',
    comision: 0.0078809113436591471,
    ignoraComision: 0,
    montoBase: 188214.4,
    bsAPagar: 1483.3,
    usdAPagar: 128.98,
  ),
  const PreliminarComisionEntity(
    ord: 1,
    idVendedor: 104,
    mes: 7,
    anio: 2026,
    etiqueta: 'Vendedor Sin comision',
    nombreVen: 'Julio Buitrago',
    comision: 0,
    ignoraComision: 1,
    montoBase: 370294,
    bsAPagar: 0,
    usdAPagar: 0,
  ),
  const PreliminarComisionEntity(
    ord: 2,
    etiqueta: 'TOTAL IPX',
    nombreVen: 'TOTAL IPX',
    comision: 0,
    ignoraComision: 0,
    montoBase: 1186099.33,
    bsAPagar: 4877.48,
    usdAPagar: 424.13,
  ),
];

final _descuentos = <DescuentoDetalleEntity>[
  DescuentoDetalleEntity(
    docNum: 262211852,
    empresa: 'IMPEXPAP',
    fechaDoc: DateTime(2026, 8, 21),
    nombreVen: 'Humberto de la Torre Villavicencio',
    cardCode: 'VA00669',
    grupoFamilia: 'Papel Bond Blanco',
    codGrupoSap: 147,
    itemCode: 'PBB075067089ACA',
    itemName: 'PAPEL BOND BLANCO 075G 067X089CM 500HJS  CELULOSA ARGENTINA',
    cantidad: 1,
    montoItemBs: 380,
    porcentajePago: 50,
    porcentajeDescuento: 50,
    descuentoBs: -190,
    montoBaseNotaBs: 0,
    montoNotaAjustadoBs: -190,
    notas: 1,
    items: 1,
  ),
  DescuentoDetalleEntity(
    docNum: 262211853,
    empresa: 'ESPPAPEL',
    fechaDoc: DateTime(2026, 8, 21),
    nombreVen: 'Marcela Caceres',
    cardCode: 'VA00712',
    grupoFamilia: 'Papel Bond Blanco',
    codGrupoSap: 147,
    itemCode: 'PBB056067087PRI',
    itemName: 'PAPEL BOND BLANCO 056G 067X087CM 500HJS PRISME',
    cantidad: 32.75,
    montoItemBs: 12435,
    porcentajePago: 50,
    porcentajeDescuento: 50,
    descuentoBs: -6217.5,
    montoBaseNotaBs: 0,
    montoNotaAjustadoBs: -6217.5,
    notas: 1,
    items: 1,
  ),
];

// Lo congelado al ejecutar el pago. Dos de tres líneas van excluidas: es la
// proporción real (15 de 19 en la tabla medida) y con menos, la previa mentiría
// sobre cómo se ve la pantalla llena.
final _itemsPagados = <PagadoItemEntity>[
  PagadoItemEntity(
    idPagadoItem: 1,
    idPagado: 111540,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    docNum: 262220421,
    origen: 'PRODUCTIVA PAPEL',
    fechaDoc: DateTime(2026, 8, 21),
    idVendedor: 39,
    itemCode: 'PBB075067089ACA',
    itemName: 'PAPEL BOND BLANCO 075G 067X089CM 500HJS  CELULOSA ARGENTINA',
    grpFam: 'Papel Bond Blanco',
    cantidad: 1,
    montoLineaBs: 1234567.89,
    porcentajePago: 50,
    descuentoBs: 617283.95,
  ),
  PagadoItemEntity(
    idPagadoItem: 2,
    idPagado: 111540,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    docNum: 262220421,
    origen: 'PRODUCTIVA PAPEL',
    fechaDoc: DateTime(2026, 8, 21),
    itemCode: 'CDX250070100',
    itemName: 'CARTULINA DUPLEX 250G 070X100CM DOBLE FAZ ESTUCADA',
    grpFam: 'Cartulina Duplex',
    cantidad: 12,
    montoLineaBs: 380,
    aplicaDescuento: false,
    motivoExclusion: MotivoItemPagado.fueraDeVigencia,
  ),
  PagadoItemEntity(
    idPagadoItem: 3,
    idPagado: 111541,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    docNum: 262211852,
    origen: 'IMPEXPAP',
    fechaDoc: DateTime(2026, 8, 20),
    itemCode: 'QUI010000000',
    itemName: 'HIPOCLORITO DE SODIO GRADO INDUSTRIAL 200LT',
    cantidad: 3,
    montoLineaBs: 9800,
    aplicaDescuento: false,
    motivoExclusion: MotivoItemPagado.sinFamilia,
  ),
];

final _resumenItems = <PagadoItemResumenEntity>[
  const PagadoItemResumenEntity(
    motivo: MotivoItemPagado.desconto,
    items: 1,
    montoBs: 1234567.89,
    descuentoBs: 617283.95,
  ),
  const PagadoItemResumenEntity(
    motivo: MotivoItemPagado.sinFamilia,
    items: 1,
    montoBs: 9800,
  ),
  const PagadoItemResumenEntity(
    motivo: MotivoItemPagado.fueraDeVigencia,
    items: 1,
    montoBs: 380,
  ),
];

final _corteItems = PagadoItemCorteEntity(
  idCorte: 1,
  mesPago: 8,
  anioPago: 2026,
  esInterno: 1,
  items: 3,
  itemsExcluidos: 2,
  notasPagadas: 2,
  notasConItems: 2,
  politicaDesde: DateTime(2026, 1, 1),
  politicasActivas: 2,
  audFecha: DateTime(2026, 8, 23),
  lectura: 'Con detalle',
);

/// Providers de la pantalla, alimentados con los datos de arriba.
List<Override> overridesComisiones() => [
  comisionesRepositoryProvider.overrideWithValue(RepoComisionesFalso()),
  vendedoresComisionProvider.overrideWith((ref) async => _vendedores),
  gruposComisionProvider.overrideWith((ref) async => _grupos),
  asignacionesVigentesProvider.overrideWith((ref) async => _asignaciones),
  notasPendientesProvider.overrideWith((ref) async => _pendientes),
  rangosComisionProvider.overrideWith((ref) async => _rangos),
  preliminarProvider.overrideWith((ref, f) async => _preliminar),
  descuentoDetalleProvider.overrideWith((ref, f) async => _descuentos),
  // El SP filtra por nota (@docNum + @origen); «solo lo excluido» lo resuelve
  // el diálogo en memoria, así que aquí basta con respetar el filtro de nota.
  itemsPagadosProvider.overrideWith(
    (ref, f) async =>
        f.docNum == null
            ? _itemsPagados
            : _itemsPagados
                .where(
                  (i) =>
                      i.docNum == f.docNum &&
                      (f.origen == null || i.origen == f.origen),
                )
                .toList(),
  ),
  resumenItemsPagadosProvider.overrideWith((ref, f) async => _resumenItems),
  corteItemsPagadosProvider.overrideWith((ref, c) async => _corteItems),
  politicaFamiliasProvider.overrideWith((ref) async => const []),
  vendedoresExentosProvider.overrideWith((ref) async => const []),
  clientesExcluidosProvider.overrideWith((ref) async => const []),
  familiasSapDisponiblesProvider.overrideWith((ref) async => const []),
  tipoCambioSugeridoProvider.overrideWith(
    (ref) async => TipoCambioComisionEntity(
      fecha: DateTime(2026, 8, 23),
      tipoCambio: 11.5,
      origen: 'SAP',
      diasDeAntiguedad: 0,
    ),
  ),
    ];

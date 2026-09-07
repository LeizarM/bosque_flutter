// Entrada aparte, solo para revisar el diseño del módulo:
//   flutter build web -t lib/vista_previa_comisiones.dart --output build/preview
//
// No entra en la app: main.dart no la importa. Existe porque el módulo vive
// detrás de un login, de permisos y de un backend que habla con SAP, así que
// mirar un cambio de tipografía o de densidad obligaba a levantar todo y entrar
// con tres usuarios distintos.
//
// Monta las pestañas REALES con datos de mentira, no una galería de widgets
// sueltos. La versión anterior mostraba piezas aisladas y por eso no servía
// para juzgar la apariencia: una tabla se ve bien o mal por cómo convive con
// el filtro de arriba y el pie de abajo, no en el vacío.
//
// Los textos son los más largos que hay en la base real. Con nombres cortos
// todo entra y todo se ve bien, que es justo el error que hay que evitar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
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
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_pestanas.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_asignaciones.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_grupos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_pendientes.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_politica.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_preliminar.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_rangos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_vendedores.dart';

void main() => runApp(const _App());

/// La barra de reportes hace `ref.read(comisionesRepositoryProvider)` en su
/// build: sin un doble, la pestaña ni se dibuja. Solo se lee, los métodos se
/// llaman al apretar un botón y acá no se aprieta ninguno.
class _RepoFalso implements ComisionesRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('La vista previa no llama a ${i.memberName}');
}

// ── Datos ──────────────────────────────────────────────────────────────────

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

// Lo congelado al ejecutar el pago. Dos de las tres lineas estan excluidas, y
// esa proporcion es la real -15 de cada 19 en la tabla medida-: con una sola
// linea excluida la previa mentiria sobre como se ve la pantalla llena.
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

// ── Armado ─────────────────────────────────────────────────────────────────

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      comisionesRepositoryProvider.overrideWithValue(_RepoFalso()),
      vendedoresComisionProvider.overrideWith((ref) async => _vendedores),
      gruposComisionProvider.overrideWith((ref) async => _grupos),
      asignacionesVigentesProvider.overrideWith((ref) async => _asignaciones),
      notasPendientesProvider.overrideWith((ref) async => _pendientes),
      rangosComisionProvider.overrideWith((ref) async => _rangos),
      preliminarProvider.overrideWith((ref, f) async => _preliminar),
      descuentoDetalleProvider.overrideWith((ref, f) async => _descuentos),
      // El SP filtra por nota (@docNum + @origen); «solo lo excluido» lo
      // resuelve el dialogo sobre lo que ya tiene en memoria, asi que aca
      // solo hay que respetar el filtro de nota.
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
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      ),
      // Los mismos breakpoints que monta main.dart. Sin esto, todo lo que
      // pregunte si esta en movil revienta, que es justo lo que hay que mirar.
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
      home: const _Modulo(),
    ),
  );
}

class _Pestana {
  const _Pestana(this.titulo, this.icono, this.contenido);
  final String titulo;
  final IconData icono;
  final Widget contenido;
}

class _Modulo extends StatelessWidget {
  const _Modulo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // El mismo orden y las mismas pestanias de comisiones_screen.dart. Falta
    // Ejecutar: depende de un StateNotifier que habla con el backend y no se
    // puede falsear sin reescribirlo.
    final pestanas = <_Pestana>[
      const _Pestana('Vendedores', Icons.badge_outlined, TabVendedores()),
      const _Pestana('Grupos', Icons.folder_outlined, TabGrupos()),
      const _Pestana('Asignaciones', Icons.link_outlined, TabAsignaciones()),
      const _Pestana('Escala por dias', Icons.timeline_outlined, TabRangos()),
      const _Pestana('Politica', Icons.rule_outlined, TabPolitica()),
      _Pestana(
        'Preliminar',
        Icons.calculate_outlined,
        TabPreliminar(modalidades: ModalidadPreliminar.values),
      ),
      const _Pestana(
        'Pendientes',
        Icons.pending_actions_outlined,
        TabPendientes(),
      ),
      // No es una pestania de la aplicacion: es el dialogo del detalle
      // congelado, montado como pestania para poder mirarlo. En la aplicacion
      // se abre desde Ejecutar y desde el Preliminar de un periodo ya pagado,
      // y esos dos caminos exigen un backend que confirme que el periodo se
      // ejecuto, o sea que la previa no lo alcanzaria nunca.
      const _Pestana(
        'Detalle congelado',
        Icons.rule_folder_outlined,
        DialogoItemsPagados(
          filtro: FiltroItemsPagados(mes: 8, anio: 2026, esInterno: 1),
        ),
      ),
    ];

    return Theme(
      data: ComisionesTema.temaModulo(context),
      // Builder, igual que comisiones_screen.dart: sin el, el Scaffold pinta
      // con el cs de AFUERA del Theme y la pagina sale con el verde de la app
      // mientras el resto del modulo usa la escala neutra. La previa mentiria.
      child: Builder(
        builder: (context) {
          final csMod = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: csMod.surface,
            body: SafeArea(
              child: DefaultTabController(
                length: pestanas.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 16, padding, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Comisiones', style: tt.headlineSmall),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure vendedores y escalas, revise el preliminar '
                              'y ejecute el mes.',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BarraPestanas(
                      items: [
                        for (final p in pestanas)
                          ItemPestana(p.titulo, p.icono),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ComisionesTema.anchoMaximo,
                          ),
                          child: TabBarView(
                            children: [for (final p in pestanas) p.contenido],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Repositorio falso del modulo de garantias con datos de ejemplo coherentes:
// varios clientes, garantias vigentes, por vencer, caducadas y cerradas, con
// sus documentos y su historial. Las fechas son relativas a hoy, asi el estado
// calculado (VIGENTE / CADUCADO / CERRADO) y los dias para vencer cuadran.
//
// Lo usan las capturas (test/capturas/capturas_garantias.dart). No escribe:
// las escrituras devuelven un id de mentira.
import 'dart:typed_data';

import 'package:bosque_flutter/data/models/accion_cbr_model.dart';
import 'package:bosque_flutter/data/models/cbr_detalle_model.dart';
import 'package:bosque_flutter/data/models/garantia_resumen_cliente_model.dart';
import 'package:bosque_flutter/data/models/garantia_vista_model.dart';
import 'package:bosque_flutter/data/models/tipo_cbr_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/domain/repositories/garantias_repository.dart';

String _f(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')} 00:00:00';

class _Cli {
  const _Cli(this.cod, this.nombre, this.lineaSap, this.saldo);
  final String cod;
  final String nombre;
  final double lineaSap;
  final double saldo;
}

class _Gar {
  const _Gar({
    required this.cod,
    required this.cli,
    required this.valor,
    required this.linea,
    required this.inicio,
    required this.fin,
    this.plazo = 30,
    this.traspasada = true,
    this.cerrada = false,
    this.tipos = const ['PAG'],
    this.registro = -1,
  });

  final int cod;
  final int cli;
  final double valor;
  final double linea;

  /// Dias respecto de hoy (negativo = en el pasado).
  final int inicio;
  final int fin;
  final int plazo;
  final bool traspasada;
  final bool cerrada;
  final List<String> tipos;

  /// Dias respecto de hoy de la fecha de registro; por defecto, el inicio.
  final int registro;
}

const _clientes = [
  _Cli('ADI0229', 'ADDY SALAZAR ORTIZ - EDITORA MENDEZ - CBBA', 21000, 3500.75),
  _Cli(
    'TU00527',
    'MARIA VERONICA MIRANDA SORAIRE - TUPAC KATARI',
    180000,
    96420.10,
  ),
  _Cli('LA00749', 'LAURA AGUIRRE RENE', 20000, 0),
  _Cli('VI00374', 'CHAMBI VARGAS EDGAR', 139400, 45210.00),
  _Cli('ES00491', 'ESPRIT SRL', 38066.03, 12800.50),
  _Cli('LD00390', 'ALVARO MIRANDA - LDX S.R.L.', 69600, 20100.00),
  _Cli('AM00435', 'AMARU', 69700, 0),
  _Cli(
    'PS00128',
    'ANTONIO JOAQUIN PONCE SALAZAR - T-PRISA SERVICIOS GRAFICOS',
    50000,
    8750.30,
  ),
  _Cli('AC00091', 'JORGE DAVILA - ACERTIJO PRODUCCIONES', 0, 0),
  _Cli('CE00647', 'CESPEDES SALAZAR BEATRIZ', 15000, 4300.00),
];

const _garantias = [
  _Gar(
    cod: 162,
    cli: 0,
    valor: 25000,
    linea: 14000,
    inicio: -210,
    fin: 14,
    tipos: ['RDD', 'PAG'],
  ),
  _Gar(
    cod: 171,
    cli: 0,
    valor: 8000,
    linea: 7000,
    inicio: -500,
    fin: -135,
    tipos: ['LDC'],
  ),
  _Gar(
    cod: 124,
    cli: 1,
    valor: 5227500,
    linea: 180000,
    inicio: -380,
    fin: 350,
    plazo: 60,
    tipos: ['INM'],
  ),
  _Gar(
    cod: 128,
    cli: 1,
    valor: 250000,
    linea: 0,
    inicio: -900,
    fin: -480,
    cerrada: true,
    tipos: ['VEH'],
  ),
  _Gar(
    cod: 125,
    cli: 2,
    valor: 7650,
    linea: 20000,
    inicio: -120,
    fin: 245,
    tipos: ['PAG'],
  ),
  _Gar(
    cod: 127,
    cli: 3,
    valor: 188279,
    linea: 139400,
    inicio: -60,
    fin: 305,
    plazo: 45,
    tipos: ['MAQ', 'PAG'],
  ),
  _Gar(
    cod: 132,
    cli: 4,
    valor: 233246,
    linea: 38066.03,
    inicio: -400,
    fin: 25,
    tipos: ['INM'],
  ),
  _Gar(
    cod: 188,
    cli: 5,
    valor: 69600,
    linea: 69600,
    inicio: -30,
    fin: 335,
    traspasada: false,
    tipos: ['RDD'],
    registro: -3,
  ),
  _Gar(
    cod: 189,
    cli: 5,
    valor: 34800,
    linea: 0,
    inicio: -300,
    fin: -20,
    tipos: ['FMI'],
  ),
  _Gar(
    cod: 145,
    cli: 6,
    valor: 362440,
    linea: 69700,
    inicio: -1400,
    fin: -1035,
    cerrada: true,
    tipos: ['CDS'],
  ),
  _Gar(
    cod: 190,
    cli: 7,
    valor: 13920,
    linea: 50000,
    inicio: -10,
    fin: 355,
    traspasada: false,
    tipos: ['PAG'],
    registro: -1,
  ),
  _Gar(
    cod: 99,
    cli: 8,
    valor: 45000,
    linea: 45000,
    inicio: -2000,
    fin: -1600,
    tipos: ['LDC'],
  ),
  _Gar(
    cod: 176,
    cli: 9,
    valor: 15000,
    linea: 15000,
    inicio: -90,
    fin: 6,
    tipos: ['PAG', 'QRG'],
  ),
];

const _nombreTipo = {
  'CDS': 'CONTRATO DE SUMINISTRO',
  'FMI': 'FORMULARIO INTERNO',
  'INM': 'INMUEBLE',
  'LDC': 'LETRA DE CAMBIO',
  'MAQ': 'MAQUINARIA',
  'PAG': 'PAGARE',
  'QRG': 'QUIROGRAFARIO',
  'RDD': 'RECONOCIMIENTO DE DEUDA',
  'VEH': 'VEHICULO',
};

class RepositorioGarantiasFalso implements GarantiasRepository {
  RepositorioGarantiasFalso({DateTime? hoy}) : hoy = hoy ?? DateTime.now();

  final DateTime hoy;

  DateTime _dia(int d) =>
      DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: d));

  String _estado(_Gar g) {
    if (g.cerrada) return 'CERRADO';
    return (g.inicio <= 0 && g.fin >= 0) ? 'VIGENTE' : 'CADUCADO';
  }

  GarantiaVistaEntity _vista(_Gar g) {
    final c = _clientes[g.cli];
    final reg = g.registro == -1 ? g.inicio : g.registro;
    return GarantiaVistaModel.fromJson({
      'codGarantia': g.cod,
      'codClienteSAP': c.cod,
      'montoGarantia': g.valor,
      'montoCredito': g.linea,
      'tiempoPago': g.plazo,
      'fechaInicio': _f(_dia(g.inicio)),
      'fechaExpiracion': _f(_dia(g.fin)),
      'montoGarantiaCalc': g.valor,
      'recFirmas': g.cod.isEven ? 'RF-${g.cod}' : null,
      'nroProtesta': null,
      'audUsuario': 47,
      'audFecha': _f(_dia(reg)),
      'datoCliente': c.nombre,
      'datoEstado': _estado(g),
      'diasParaVencer': g.fin,
      'creditLine': c.lineaSap,
      'balance': c.saldo,
      'traspasada': g.traspasada ? 1 : 0,
      'cantDetalles': g.tipos.length,
      'tiposGarantia': g.tipos.map((t) => _nombreTipo[t]).join(', '),
      'fechaRegistro': _f(_dia(reg)),
      'observacionRegistro':
          'Se recibe ${_nombreTipo[g.tipos.first]!.toLowerCase()} firmado por el '
          'cliente, con copia de su carnet.',
      'realizoEmp': 'ZEBALLOS ZUE HELEN SCARLET',
    }).toEntity();
  }

  @override
  Future<List<GarantiaResumenClienteEntity>> obtenerResumenClientes({
    String? buscar,
  }) async {
    final filas = <GarantiaResumenClienteEntity>[];
    for (var i = 0; i < _clientes.length; i++) {
      final c = _clientes[i];
      final suyas = _garantias.where((g) => g.cli == i).toList();
      if (suyas.isEmpty) continue;
      final vig = suyas.where((g) => _estado(g) == 'VIGENTE').toList();
      final prox =
          vig.isEmpty
              ? null
              : vig.map((g) => g.fin).reduce((a, b) => a < b ? a : b);
      filas.add(
        GarantiaResumenClienteModel.fromJson({
          'codClienteSAP': c.cod,
          'datoCliente': c.nombre,
          'cantGarantias': suyas.length,
          'cantVigentes': vig.length,
          'montoGarantia': vig.fold<double>(0, (s, g) => s + g.valor),
          'montoCredito': vig.fold<double>(0, (s, g) => s + g.linea),
          'proximoVencimiento': prox == null ? null : _f(_dia(prox)),
          'diasParaVencer': prox,
          'creditLine': c.lineaSap,
          'balance': c.saldo,
        }).toEntity(),
      );
    }
    filas.sort((a, b) => a.datoCliente.compareTo(b.datoCliente));
    return filas;
  }

  @override
  Future<List<GarantiaVistaEntity>> listarGarantias({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) async {
    bool entre(DateTime d, DateTime? a, DateTime? b) =>
        (a == null || !d.isBefore(a)) && (b == null || !d.isAfter(b));
    final lista =
        _garantias
            .map(_vista)
            .where(
              (g) =>
                  (codClienteSAP == null ||
                      g.garantia.codClienteSAP == codClienteSAP) &&
                  (estado == null || g.datoEstado == estado) &&
                  (tipoGarantia == null ||
                      (g.tiposGarantia ?? '').contains(
                        _nombreTipo[tipoGarantia] ?? '#',
                      )) &&
                  entre(g.garantia.fechaExpiracion!, vencDesde, vencHasta) &&
                  entre(g.fechaRegistro!, regDesde, regHasta),
            )
            .toList();
    lista.sort((a, b) {
      final c = a.datoCliente.compareTo(b.datoCliente);
      return c != 0
          ? c
          : b.garantia.fechaExpiracion!.compareTo(a.garantia.fechaExpiracion!);
    });
    return lista;
  }

  @override
  Future<GarantiaVistaEntity?> obtenerGarantia(BigInt codGarantia) async {
    for (final g in _garantias) {
      if (BigInt.from(g.cod) == codGarantia) return _vista(g);
    }
    return null;
  }

  @override
  Future<List<ClienteSapEntity>> buscarClientesSap(String buscar) async => [
    for (final c in _clientes)
      if (c.nombre.toLowerCase().contains(buscar.toLowerCase()) ||
          c.cod.toLowerCase().contains(buscar.toLowerCase()))
        ClienteSapEntity(codClienteSAP: c.cod, datoCliente: c.nombre),
  ];

  @override
  Future<List<CbrDetalleEntity>> obtenerDetalles(BigInt codGarantia) async {
    final g = _garantias.firstWhere((x) => BigInt.from(x.cod) == codGarantia);
    final parte = g.valor / g.tipos.length;
    return [
      for (var i = 0; i < g.tipos.length; i++)
        CbrDetalleModel.fromJson({
          'codDetalle': g.cod * 10 + i,
          'codGarantia': g.cod,
          'fecha': _f(_dia(g.inicio)),
          'tipoGarantia': g.tipos[i],
          'detalle':
              '${_nombreTipo[g.tipos[i]]!.toLowerCase()} N° ${1000 + g.cod + i}',
          'montoGarantiaParc': parte,
          'audUsuario': 47,
          'audFecha': _f(_dia(g.inicio)),
        }).toEntity(),
    ];
  }

  @override
  Future<List<AccionCbrEntity>> obtenerAcciones(BigInt codGarantia) async {
    final g = _garantias.firstWhere((x) => BigInt.from(x.cod) == codGarantia);
    final reg = g.registro == -1 ? g.inicio : g.registro;
    final filas = <Map<String, dynamic>>[
      {'estado': 'REG', 'dia': reg, 'obs': 'Recepción de la garantía.'},
      if (g.traspasada) {'estado': 'TRASP', 'dia': reg + 3, 'obs': ' '},
      if (g.traspasada && !g.cerrada)
        {
          'estado': 'NOT',
          'dia': reg + 40,
          'obs': 'Se comunica al cliente la próxima revisión de su línea.',
        },
      if (g.cerrada)
        {
          'estado': 'CER',
          'dia': g.fin + 10,
          'obs': 'Deuda cancelada; se devuelve el documento al cliente.',
        },
    ];
    return [
      for (var i = filas.length - 1; i >= 0; i--)
        AccionCbrModel.fromJson({
          'codAccion': g.cod * 10 + i,
          'codGarantia': g.cod,
          'fecha': _f(_dia(filas[i]['dia'] as int)),
          'estado': filas[i]['estado'],
          'observacion': filas[i]['obs'],
          'audUsuario': 47,
          'audFecha': _f(_dia(filas[i]['dia'] as int)),
        }).toEntity(),
    ];
  }

  @override
  Future<int> contarTraspasosPendientes() async =>
      _garantias.where((g) => !g.traspasada).length;

  @override
  Future<List<TipoCbrEntity>> obtenerTiposGarantia() async => [
    for (final e in _nombreTipo.entries)
      TipoCbrModel.fromJson({
        'codTipos': e.key,
        'nombre': e.value,
        'codGrupo': 28,
      }).toEntity(),
  ];

  @override
  Future<List<TipoCbrEntity>> obtenerEstadosAccion() async => [
    for (final (c, n) in const [
      ('REG', 'REGISTRADO BOSQUE'),
      ('TRASP', 'TRASPASO'),
      ('EXT', 'EXTENSION'),
      ('NOT', 'NOTA'),
      ('CER', 'CERRADO'),
    ])
      TipoCbrModel.fromJson({
        'codTipos': c,
        'nombre': n,
        'codGrupo': 29,
      }).toEntity(),
  ];

  // ── Escrituras y PDF: no se usan en las capturas ────────────────────────────
  @override
  Future<BigInt> registrarGarantia(GarantiaRegistroEntity registro) async =>
      BigInt.one;
  @override
  Future<BigInt> actualizarGarantia(GarantiaCbrEntity garantia) async =>
      BigInt.one;
  @override
  Future<BigInt> registrarExtension({
    required BigInt codGarantia,
    required DateTime fecha,
    required String? observacion,
    required DateTime fechaExpiracion,
  }) async => BigInt.one;
  @override
  Future<BigInt> registrarDetalle(CbrDetalleEntity detalle) async => BigInt.one;
  @override
  Future<BigInt> eliminarDetalle(BigInt codDetalle) async => BigInt.one;
  @override
  Future<BigInt> registrarAccion(AccionCbrEntity accion) async => BigInt.one;
  @override
  Future<BigInt> eliminarAccion(BigInt codAccion) async => BigInt.one;
  @override
  Future<int> generarTraspaso() async => 2;
  @override
  Future<Uint8List> reporteRecibo(BigInt codGarantia) async => Uint8List(0);
  @override
  Future<Uint8List> reporteTraspaso() async => Uint8List(0);
  @override
  Future<Uint8List> reporteBusqueda({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) async => Uint8List(0);
}

/// El resumen por empleado de una planilla ejecutada (R), agrupado por
/// sucursal como la planilla impresa (D39): horas y Bs por código, comidas,
/// otros y total.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// El ancho de lista que pide la grilla con todos sus códigos para que nada
/// se parta. Por debajo, tabla compacta o tarjetas: nunca va de lado.
const double _anchoGrilla = 1680;

// Cada `flex` de la tabla compacta es la mitad de los px de su columna; el
// ancho mínimo sale de su suma.
const int _flexEmpleadoCompacto = 88;
const int _flexCostoCompacto = 46;
const int _flexHorasCompacto = 136;
const int _flexComidasCompacto = 76;
const int _flexMontoCompacto = 50; // Comidas (Bs) y Otros (Bs)
const int _flexTotalCompacto = 62;

/// El ancho de lista que pide la tabla compacta (con el relleno de la fila):
/// 1040 px. Entre este y [_anchoGrilla] el resumen va en tabla compacta.
const double anchoTablaResumenCompactoHex =
    2.0 *
        (_flexEmpleadoCompacto +
            _flexCostoCompacto +
            _flexHorasCompacto +
            _flexComidasCompacto +
            2 * _flexMontoCompacto +
            _flexTotalCompacto) +
    2 * Esp.m;

/// Alto promedio estimado de una fila compacta; con muchos códigos la fila
/// crece y la tabla se desplaza por dentro, como las demás del módulo.
const double _altoFilaCompacta = 80;

/// Un código de horas del resumen: sus horas y su monto.
typedef _HorasCodigo =
    ({
      String codigo,
      double Function(HexPlanillaEmpleadoEntity) horas,
      double Function(HexPlanillaEmpleadoEntity) monto,
    });

/// Un código de comida del resumen: cuántas se pagaron.
typedef _ComidaCodigo =
    ({String codigo, int Function(HexPlanillaEmpleadoEntity) cantidad});

final List<_HorasCodigo> _horasResumen = [
  (codigo: 'HS', horas: (e) => e.hHS, monto: (e) => e.mHS),
  (codigo: 'H50', horas: (e) => e.hH50, monto: (e) => e.mH50),
  (codigo: 'H100', horas: (e) => e.hH100, monto: (e) => e.mH100),
  (codigo: 'HD', horas: (e) => e.hHD, monto: (e) => e.mHD),
  (codigo: 'HF', horas: (e) => e.hHF, monto: (e) => e.mHF),
];

final List<_ComidaCodigo> _comidasResumen = [
  (codigo: 'D', cantidad: (e) => e.cD),
  (codigo: 'DD', cantidad: (e) => e.cDD),
  (codigo: 'A', cantidad: (e) => e.cA),
  (codigo: 'DA', cantidad: (e) => e.cDA),
  (codigo: 'C', cantidad: (e) => e.cC),
  (codigo: 'DC', cantidad: (e) => e.cDC),
];

/// Una ficha: el código y su valor (horas y Bs, o cuántas comidas).
Widget _ficha(String codigo, String valor, TextStyle? cifras) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    CodigoHex(codigo),
    const SizedBox(width: Esp.xs),
    Flexible(child: Text(valor, style: cifras)),
  ],
);

/// Las fichas de horas de [e]: solo los códigos con algo. Las comparten la
/// tarjeta y la tabla compacta.
List<Widget> _fichasHoras(HexPlanillaEmpleadoEntity e, TextStyle? cifras) => [
  for (final h in _horasResumen)
    if (h.horas(e) != 0 || h.monto(e) != 0)
      _ficha(
        h.codigo,
        '${horasHex(h.horas(e))} · ${bsHex(h.monto(e))}',
        cifras,
      ),
];

/// Las fichas de comidas de [e]: solo las que se pagaron («C ×1»).
List<Widget> _fichasComidas(HexPlanillaEmpleadoEntity e, TextStyle? cifras) => [
  for (final c in _comidasResumen)
    if (c.cantidad(e) != 0) _ficha(c.codigo, '×${c.cantidad(e)}', cifras),
];

/// El resumen por empleado (R): grilla completa, tabla compacta o tarjetas
/// según el ancho. Bs por código + Comidas (Bs) + Otros = Total, como el PDF.
class ResumenPlanillaHex extends StatelessWidget {
  const ResumenPlanillaHex(this.filas, {super.key, required this.altoMaximo});

  final List<HexPlanillaEmpleadoEntity> filas;

  /// El alto que puede tomar la tabla en el ancho (el de la ventana).
  final double altoMaximo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final grilla = usaTablaHex(c.maxWidth, _anchoGrilla);
      final compacta =
          !grilla && usaTablaHex(c.maxWidth, anchoTablaResumenCompactoHex);
      // Cada sucursal lleva su cabecera; una fila más para la barra lateral.
      return cajaTablaHex(
        tabla: grilla || compacta,
        filas: filas.length + gruposHex(filas, (e) => e.codSucursal) + 1,
        maximo: altoMaximo,
        porFila: compacta ? _altoFilaCompacta : null,
        lista: _listado(context, grilla: grilla, compacta: compacta),
      );
    },
  );

  Widget _listado(
    BuildContext context, {
    required bool grilla,
    required bool compacta,
  }) {
    final celdas = _CeldasResumen(context);
    final tabla = grilla || compacta;
    return ListadoHex<HexPlanillaEmpleadoEntity>(
      filas: filas,
      anchoMinimoTabla: grilla ? _anchoGrilla : anchoTablaResumenCompactoHex,
      desplazamientoExterno: !tabla,
      vacio: const MensajeVacio(
        icono: Icons.inbox_outlined,
        titulo: 'La planilla no tiene empleados',
        detalle: 'No se congeló ningún monto en esta planilla.',
      ),
      cabeceraAntesDe: cabeceraPorGrupoHex(
        filas,
        // D39: por sucursal, como el PDF; el SP las ordena por `ordenSucursal`.
        (e) => e.codSucursal,
        (e) => FranjaGrupoHex(
          titulo: sucursalHex(e.nombreSucursal, e.codSucursal),
          enTabla: tabla,
        ),
      ),
      columnas: grilla ? celdas.grilla() : celdas.compacta(),
      tarjeta: (e) => _TarjetaResumenHex(e),
    );
  }
}

/// Las columnas del resumen con sus estilos: la grilla completa y la tabla
/// compacta comparten el empleado, los montos y las fichas.
class _CeldasResumen {
  _CeldasResumen(BuildContext context)
    : t = Theme.of(context).textTheme,
      cifras = estiloCifrasHex(Theme.of(context).textTheme.bodySmall),
      apagadas = estiloCifrasHex(context.apagado()),
      cargoApagado = context.apagado();

  final TextTheme t;
  final TextStyle? cifras;
  final TextStyle? apagadas;
  final TextStyle? cargoApagado;

  Widget nada() => Text('—', style: apagadas);

  Widget bs(double v) => v == 0 ? nada() : Text(bsHex(v), style: cifras);

  /// Fichas en línea que saltan de renglón; un guion si no hay ninguna.
  Widget fichas(List<Widget> lista) =>
      lista.isEmpty
          ? nada()
          : Wrap(spacing: Esp.s, runSpacing: Esp.xs, children: lista);

  BosqueColumn<HexPlanillaEmpleadoEntity> dinero(
    String rotulo,
    double Function(HexPlanillaEmpleadoEntity) valor, {
    int flex = 2,
  }) => BosqueColumn(
    label: rotulo,
    flex: flex,
    alignment: Alignment.centerRight,
    cellBuilder: (e) => bs(valor(e)),
  );

  BosqueColumn<HexPlanillaEmpleadoEntity> costoHora(int flex) => BosqueColumn(
    label: 'Costo hora (Bs)',
    flex: flex,
    alignment: Alignment.centerRight,
    cellBuilder: (e) => Text(bsHex(e.costoHora), style: cifras),
  );

  BosqueColumn<HexPlanillaEmpleadoEntity> total(int flex) => BosqueColumn(
    label: 'Total (Bs)',
    flex: flex,
    alignment: Alignment.centerRight,
    cellBuilder:
        (e) => Text(
          bsHex(e.total),
          style: estiloCifrasHex(t.bodyMedium, fuerte: true),
        ),
  );

  /// El nombre y, debajo, el cargo si [conCargo].
  Widget empleado(HexPlanillaEmpleadoEntity e, {required bool conCargo}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            oGuionHex(e.nombreEmpleado),
            style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
          if (conCargo && oGuionHex(e.cargo) != '—')
            Text(e.cargo!.trim(), style: cargoApagado),
        ],
      );

  /// La grilla completa (desde [_anchoGrilla]): una columna por código.
  List<BosqueColumn<HexPlanillaEmpleadoEntity>> grilla() => [
    BosqueColumn(
      label: 'Empleado',
      flex: 5,
      cellBuilder: (e) => empleado(e, conCargo: false),
    ),
    BosqueColumn(
      label: 'Cargo',
      flex: 3,
      cellBuilder: (e) => Text(oGuionHex(e.cargo), style: t.bodySmall),
    ),
    costoHora(2),
    for (final h in _horasResumen)
      BosqueColumn(
        label: h.codigo,
        flex: 2,
        alignment: Alignment.centerRight,
        cellBuilder:
            (e) =>
                h.horas(e) == 0 && h.monto(e) == 0
                    ? nada()
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(horasHex(h.horas(e)), style: cifras),
                        Text(bsHex(h.monto(e)), style: apagadas),
                      ],
                    ),
      ),
    for (final c in _comidasResumen)
      BosqueColumn(
        label: c.codigo,
        flex: 1,
        alignment: Alignment.center,
        cellBuilder:
            (e) =>
                c.cantidad(e) == 0
                    ? nada()
                    : Text('${c.cantidad(e)}', style: cifras),
      ),
    dinero('Comidas (Bs)', (e) => e.totalComidas),
    dinero('Otros (Bs)', (e) => e.mOtros),
    total(2),
  ];

  /// La tabla compacta: los códigos de horas y de comidas, en fichas.
  List<BosqueColumn<HexPlanillaEmpleadoEntity>> compacta() => [
    BosqueColumn(
      label: 'Empleado',
      flex: _flexEmpleadoCompacto,
      cellBuilder: (e) => empleado(e, conCargo: true),
    ),
    costoHora(_flexCostoCompacto),
    BosqueColumn(
      label: 'Horas por código',
      flex: _flexHorasCompacto,
      cellBuilder: (e) => fichas(_fichasHoras(e, cifras)),
    ),
    BosqueColumn(
      label: 'Comidas',
      flex: _flexComidasCompacto,
      cellBuilder: (e) => fichas(_fichasComidas(e, cifras)),
    ),
    dinero('Comidas (Bs)', (e) => e.totalComidas, flex: _flexMontoCompacto),
    dinero('Otros (Bs)', (e) => e.mOtros, flex: _flexMontoCompacto),
    total(_flexTotalCompacto),
  ];
}

/// Un empleado del resumen en el teléfono: solo los códigos que tienen algo
/// y las mismas sumas de la grilla.
class _TarjetaResumenHex extends StatelessWidget {
  const _TarjetaResumenHex(this.e);

  final HexPlanillaEmpleadoEntity e;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cifras = estiloCifrasHex(t.bodySmall);
    Widget suma(String rotulo, double valor, {bool fuerte = false}) => Row(
      children: [
        Expanded(child: Text(rotulo, style: context.apagado())),
        Text(
          bsHex(valor),
          style: estiloCifrasHex(
            fuerte ? t.bodyMedium : t.bodySmall,
            fuerte: fuerte,
          ),
        ),
      ],
    );
    final codigos = [..._fichasHoras(e, cifras), ..._fichasComidas(e, cifras)];
    // Sin menú de acciones la tarjeta casi no tiene margen derecho: se suma
    // aquí para que las cifras no toquen el borde.
    return TarjetaHex(
      titulo: oGuionHex(e.nombreEmpleado),
      subtitulo: [
        if (oGuionHex(e.cargo) != '—') e.cargo!.trim(),
        'costo hora ${bsHex(e.costoHora)}',
      ].join(' · '),
      contenido: Padding(
        padding: const EdgeInsets.only(right: Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (codigos.isNotEmpty) ...[
              Wrap(spacing: Esp.m, runSpacing: Esp.s, children: codigos),
              const SizedBox(height: Esp.s),
            ],
            suma('Comidas (Bs)', e.totalComidas),
            if (e.mOtros != 0) suma('Otros (Bs)', e.mOtros),
            suma('Total (Bs)', e.total, fuerte: true),
          ],
        ),
      ),
    );
  }
}

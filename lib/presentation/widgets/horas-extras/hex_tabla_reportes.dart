/// Tablas de reportes: las columnas que comparten Mis horas y las bandejas
/// de quien revisa y de quien aprueba, el ancho que piden para no partirse y
/// las acciones de cada fila.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_piezas.dart';

// Cada `flex` es la mitad de los px que pide su columna; el ancho mínimo de
// cada tabla sale de su suma. El estado es la más ancha: junta hasta tres
// fichas con ícono.
const int _flexEmpleado = 70;
const int flexJornadaHex = 52; // la misma en Mis horas
const int _flexHora = 55; // la hora, el día si cruza y el origen con ícono
const int _flexHoras = 34;
const int _flexComidas = 44;
const int _flexMonto = 64;
const int _flexEstado = 78; // fichas con ícono: «Rechazado» y «Editado»

/// Suma de los `flex` de [columnasDatosReporteHex].
const int flexDatosReporteHex =
    2 * _flexHora + _flexHoras + _flexComidas + _flexMonto + _flexEstado;

/// D41: la misma suma sin Comidas ni Monto, la de Mis horas del operario.
const int flexDatosReporteOperarioHex =
    2 * _flexHora + _flexHoras + _flexEstado;

/// La acción principal y el menú, de 48 px cada uno; o, en línea, la principal
/// con su texto («Dar visto bueno», unos 170 px) y hasta tres íconos de 48 px.
const int _flexAccionesCompactas = 56;
const int _flexAccionesEnLinea = 160;

int _flexAcciones(bool enLinea) =>
    enLinea ? _flexAccionesEnLinea : _flexAccionesCompactas;

/// El ancho de lista que pide la tabla de las bandejas (con el relleno de la
/// fila): 1040 px con las acciones compactas y 1248 con todas en línea. Por
/// debajo de 1040, tarjetas ([usaTablaHex]).
double anchoTablaReportesHex({bool accionesEnLinea = false}) =>
    2.0 *
        (_flexEmpleado +
            flexJornadaHex +
            flexDatosReporteHex +
            _flexAcciones(accionesEnLinea)) +
    2 * Esp.m;

/// Si alguna fila trae dinero a la vista (D38, `verMontos` del SP): sin
/// ninguna, la columna Monto no se dibuja.
bool conMontosHex(Iterable<HexReporteEntity> filas) =>
    filas.any((r) => r.verMontos);

/// Inicio, Fin, Horas, Comidas, Monto y Estado, iguales en Mis horas y en las
/// bandejas; cada pantalla pone las suyas antes y después. Sin [conMonto]
/// (nadie ve dinero) no va Monto; sin [conComidas] (el operario, D41), tampoco
/// Comidas, cuyos códigos explica la leyenda que él no ve.
List<BosqueColumn<HexReporteEntity>> columnasDatosReporteHex(
  BuildContext context, {
  bool conMonto = true,
  bool conComidas = true,
}) {
  final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
  return [
    BosqueColumn(
      label: 'Inicio',
      flex: _flexHora,
      cellBuilder:
          (r) => HoraOrigenHex(
            r.inicio,
            r.origenInicio,
            jornada: r.fechaJornada,
            idReporte: r.idReporte,
          ),
    ),
    BosqueColumn(
      label: 'Fin',
      flex: _flexHora,
      cellBuilder:
          (r) => HoraOrigenHex(
            r.fin,
            r.origenFin,
            jornada: r.fechaJornada,
            idReporte: r.idReporte,
          ),
    ),
    BosqueColumn(
      label: 'Horas',
      flex: _flexHoras,
      alignment: Alignment.centerRight,
      cellBuilder: (r) => HorasReporteHex(r, estilo: cifras),
    ),
    if (conComidas)
      BosqueColumn(
        label: 'Comidas',
        flex: _flexComidas,
        cellBuilder: (r) => ComidasHex(r.comidas, explicar: true),
      ),
    if (conMonto)
      BosqueColumn(
        label: 'Monto',
        flex: _flexMonto,
        alignment: Alignment.centerRight,
        cellBuilder:
            (r) =>
                r.verMontos
                    ? MontoHex(r.montoTotal, provisional: r.esProvisional)
                    : const SizedBox.shrink(),
      ),
    BosqueColumn(
      label: 'Estado',
      flex: _flexEstado,
      cellBuilder:
          (r) => Wrap(
            spacing: Esp.xs,
            runSpacing: Esp.xs,
            children: [
              EtiquetaEstadoHex(
                r.estado,
                r.estadoTexto,
                ayuda: r.textoPendiente,
              ),
              if (r.esEditado) const EtiquetaEditadoHex(),
              if (r.avisoBiometrico) const EtiquetaAvisoBiometricoHex(),
              if (r.sinSalidaMarcada) EtiquetaSinSalidaHex(r.avisoSalida),
            ],
          ),
    ),
  ];
}

/// Columnas de un reporte en las bandejas: la sucursal va bajo el empleado
/// y el tipo bajo la jornada, así entra en una laptop con el menú lateral.
/// [acciones] son las que permite el SP; el botón las filtra al dibujarlas.
List<BosqueColumn<HexReporteEntity>> columnasReportesHex(
  BuildContext context, {
  required List<AccionHex> Function(HexReporteEntity r) acciones,
  required bool accionesEnLinea,
  required Set<String> principales,
  bool conMonto = true,
}) {
  final cuerpo = Theme.of(context).textTheme.bodyMedium;
  Widget dosLineas(String arriba, String abajo, TextStyle? estilo) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(arriba, style: estilo),
      if (abajo.isNotEmpty) Text(abajo, style: context.apagado()),
    ],
  );
  return [
    BosqueColumn(
      label: 'Empleado',
      flex: _flexEmpleado,
      cellBuilder:
          (r) => dosLineas(
            oGuionHex(r.nombreEmpleado),
            r.nombreSucursal ?? '',
            cuerpo?.copyWith(fontWeight: Peso.titulo),
          ),
    ),
    BosqueColumn(
      label: 'Jornada',
      flex: flexJornadaHex,
      cellBuilder:
          (r) => dosLineas(
            fechaHex(r.fechaJornada),
            // El mismo orden que la tarjeta: tipo y luego tipo de día.
            [
              r.tipoTexto,
              r.tipoDiaTexto,
            ].where((p) => p.isNotEmpty).join(' · '),
            estiloCifrasHex(cuerpo, fuerte: true),
          ),
    ),
    ...columnasDatosReporteHex(context, conMonto: conMonto),
    BosqueColumn(
      label: 'Acciones',
      flex: _flexAcciones(accionesEnLinea),
      alignment: accionesEnLinea ? Alignment.centerLeft : Alignment.centerRight,
      cellBuilder:
          (r) => AccionesFilaHex(
            acciones(r),
            enLinea: accionesEnLinea,
            principales: principales,
          ),
    ),
  ];
}

/// Las acciones de una fila. En línea: todas, con la principal (por su botón
/// en [principales]) con ícono y texto. Compactas: la principal solo con su
/// ícono y el resto en el menú, que cae en el borde derecho.
class AccionesFilaHex extends StatelessWidget {
  const AccionesFilaHex(
    this.acciones, {
    super.key,
    required this.enLinea,
    this.principales = const {},
  });

  final List<AccionHex> acciones;
  final bool enLinea;
  final Set<String> principales;

  @override
  Widget build(BuildContext context) {
    bool principal(AccionHex a) => principales.contains(a.boton);
    if (enLinea) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final a in acciones)
            if (principal(a))
              BotonPrincipalHex(a)
            else
              AccionesHex(acciones: [a]),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final a in acciones.where(principal))
          BotonPrincipalHex(a, conTexto: false),
        AccionesHex(
          acciones: acciones.where((a) => !principal(a)).toList(),
          enMenu: true,
        ),
      ],
    );
  }
}

/// Las horas pagables y, debajo y en chico, el resumen de tiempo del SP (D36).
/// La columna es angosta: el resumen se corta y entero va en la ayuda.
class HorasReporteHex extends StatelessWidget {
  const HorasReporteHex(this.r, {super.key, this.estilo});

  final HexReporteEntity r;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final resumen = r.resumenTiempo?.trim() ?? '';
    final horas = Text(horasHex(r.horasPagables), style: estilo);
    if (resumen.isEmpty) return horas;
    return Tooltip(
      message: resumen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          horas,
          Text(
            resumen,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

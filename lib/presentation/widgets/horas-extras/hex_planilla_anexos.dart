/// El anexo de una planilla ejecutada, tal como quedó congelado: el detalle
/// con una fila por reporte (A). Decide tabla o tarjetas por su propio ancho.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

/// Ancho mínimo de la tabla del anexo (A).
const double _anchoTablaAnexo = 1120;

/// Filas del anexo por página (se pagina en la pantalla: llega completo).
const int _filasAnexo = 50;

/// El anexo de detalle (A): llega completo y se pagina aquí.
class AnexoPlanillaHex extends StatefulWidget {
  const AnexoPlanillaHex(this.filas, {super.key, required this.altoMaximo});

  final List<HexPlanillaDetalleEntity> filas;
  final double altoMaximo;

  @override
  State<AnexoPlanillaHex> createState() => _AnexoPlanillaHexState();
}

class _AnexoPlanillaHexState extends State<AnexoPlanillaHex> {
  int _pagina = 1;

  @override
  Widget build(BuildContext context) {
    final filas = widget.filas;
    final paginas = ((filas.length - 1) ~/ _filasAnexo) + 1;
    final pagina = _pagina.clamp(1, paginas);
    final desde = (pagina - 1) * _filasAnexo;
    final visibles = filas.sublist(
      desde.clamp(0, filas.length),
      (desde + _filasAnexo).clamp(0, filas.length),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = usaTablaHex(c.maxWidth, _anchoTablaAnexo);
        return cajaTablaHex(
          tabla: ancho,
          filas: visibles.length,
          maximo: widget.altoMaximo,
          conPaginador: paginas > 1,
          lista: _AnexoHex(
            filas: visibles,
            ancho: ancho,
            pagina: pagina,
            total: filas.length,
            // Con una sola página no hay paginador.
            alCambiarPagina:
                paginas > 1 ? (n) => setState(() => _pagina = n) : null,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANEXO DE DETALLE (A)
// ═══════════════════════════════════════════════════════════════════════════

/// Las horas de un reporte por código (solo las que tiene), como fichas.
class _HorasDelReporteHex extends StatelessWidget {
  const _HorasDelReporteHex(this.r);

  final HexPlanillaDetalleEntity r;

  @override
  Widget build(BuildContext context) {
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodySmall);
    final horas = [
      ('HS', r.hHS),
      ('H50', r.hH50),
      ('H100', r.hH100),
      ('HD', r.hHD),
      ('HF', r.hHF),
      ('Otros', r.hOtros),
    ].where((h) => h.$2 != 0);
    if (horas.isEmpty) return const Text('—');
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      children: [
        for (final (codigo, h) in horas)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CodigoHex(codigo),
              const SizedBox(width: Esp.xs),
              Text(horasHex(h), style: cifras),
            ],
          ),
      ],
    );
  }
}

/// El anexo: una fila por reporte con el origen de cada hora en palabras del
/// SP, las horas por código, comidas y total.
class _AnexoHex extends StatelessWidget {
  const _AnexoHex({
    required this.filas,
    required this.ancho,
    required this.pagina,
    required this.total,
    required this.alCambiarPagina,
  });

  final List<HexPlanillaDetalleEntity> filas;
  final bool ancho;
  final int pagina;
  final int total;
  final ValueChanged<int>? alCambiarPagina;

  static void _verReporte(BuildContext context, HexPlanillaDetalleEntity r) {
    final id = r.idReporte;
    if (id != null) mostrarDetalleReporteHex(context, id);
  }

  static List<AccionHex> _acciones(
    BuildContext context,
    HexPlanillaDetalleEntity r,
  ) => [
    AccionHex(
      'Ver reporte',
      Icons.visibility_outlined,
      () => _verReporte(context, r),
    ),
  ];

  static List<Widget> _marcas(HexPlanillaDetalleEntity r) => [
    if (r.esPeriodoAnterior)
      const Etiqueta(texto: 'De período anterior', tono: TonoEtiqueta.neutro),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget hora(
      DateTime? h,
      String origen,
      String texto,
      DateTime? j,
      BigInt? id,
    ) =>
        HoraOrigenHex(h, origen, jornada: j, textoOrigen: texto, idReporte: id);
    return ListadoHex<HexPlanillaDetalleEntity>(
      filas: filas,
      pagina: pagina,
      total: total,
      tamano: _filasAnexo,
      alCambiarPagina: alCambiarPagina,
      anchoMinimoTabla: _anchoTablaAnexo,
      desplazamientoExterno: !ancho,
      alTocarFila: (r) => _verReporte(context, r),
      vacio: const MensajeVacio(
        icono: Icons.filter_alt_off_outlined,
        titulo: 'No hay reportes en esta planilla',
        detalle: 'El anexo se arma con los reportes que entraron en el pago.',
      ),
      columnas: [
        BosqueColumn(
          label: 'Empleado',
          flex: 3,
          cellBuilder:
              (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    oGuionHex(r.nombreEmpleado),
                    style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  // D39: la sucursal; el área solo si no viene.
                  Text(
                    oGuionHex(r.nombreSucursal ?? r.nombreArea),
                    style: context.apagado(),
                  ),
                ],
              ),
        ),
        BosqueColumn(
          label: 'Jornada',
          flex: 3,
          cellBuilder:
              (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fechaHex(r.fechaJornada)),
                  Text(oGuionHex(r.tipoTexto), style: context.apagado()),
                  ..._marcas(r),
                ],
              ),
        ),
        BosqueColumn(
          label: 'Inicio',
          flex: 2,
          cellBuilder:
              (r) => hora(
                r.inicio,
                r.origenInicio,
                r.origenInicioTexto,
                r.fechaJornada,
                r.idReporte,
              ),
        ),
        BosqueColumn(
          label: 'Fin',
          flex: 2,
          cellBuilder:
              (r) => hora(
                r.fin,
                r.origenFin,
                r.origenFinTexto,
                r.fechaJornada,
                r.idReporte,
              ),
        ),
        BosqueColumn(
          label: 'Horas',
          flex: 4,
          cellBuilder: (r) => _HorasDelReporteHex(r),
        ),
        BosqueColumn(
          label: 'Comidas',
          flex: 2,
          cellBuilder: (r) => ComidasHex(r.comidas),
        ),
        BosqueColumn(
          label: 'Total (Bs)',
          flex: 3,
          alignment: Alignment.centerRight,
          cellBuilder: (r) => MontoHex(r.total),
        ),
        BosqueColumn(
          label: '',
          flex: 1,
          alignment: Alignment.centerRight,
          cellBuilder: (r) => AccionesHex(acciones: _acciones(context, r)),
        ),
      ],
      tarjeta:
          (r) => TarjetaHex(
            titulo: oGuionHex(r.nombreEmpleado),
            subtitulo: [
              fechaHex(r.fechaJornada),
              if (r.tipoTexto.isNotEmpty) r.tipoTexto,
            ].join(' · '),
            alTocar: () => _verReporte(context, r),
            acciones: _acciones(context, r),
            contenido: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: hora(
                        r.inicio,
                        r.origenInicio,
                        r.origenInicioTexto,
                        r.fechaJornada,
                        r.idReporte,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Esp.s),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    Expanded(
                      child: hora(
                        r.fin,
                        r.origenFin,
                        r.origenFinTexto,
                        r.fechaJornada,
                        r.idReporte,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.s),
                _HorasDelReporteHex(r),
                const SizedBox(height: Esp.xs),
                ComidasHex(r.comidas),
                const SizedBox(height: Esp.s),
                MontoHex(r.total),
                if (oGuionHex(r.motivo) != '—')
                  Text(r.motivo!.trim(), style: context.apagado()),
              ],
            ),
            etiquetas: _marcas(r),
          ),
    );
  }
}

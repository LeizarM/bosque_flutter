import 'dart:ui' show FontFeature;

import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Constantes y formateadores compartidos
// ---------------------------------------------------------------------------

enum _VistaDetalle { moderna, clasica }

const Color _verde = Color(0xFF2E7D32);

/// Ancho mínimo de la vista clásica. Si el diálogo es más angosto, la tabla
/// completa (cabecera, filas y totales) se desplaza junta horizontalmente.
const double _anchoMinTabla = 1404;

const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

final NumberFormat _fmtBs = NumberFormat.currency(
  symbol: 'Bs ',
  decimalDigits: 2,
);
// Cuotas USD ya no se usa (descomentar junto con sus columnas si vuelve).
// final NumberFormat _fmtUsd = NumberFormat.currency(
//   symbol: r'$ ',
//   decimalDigits: 2,
// );
final NumberFormat _fmtNum = NumberFormat('#,##0.00');
final DateFormat _fmtFecha = DateFormat('dd/MM/yyyy');

// ---------------------------------------------------------------------------
// Diálogo principal
// ---------------------------------------------------------------------------

class PlanillasDetalleDialog extends ConsumerStatefulWidget {
  final PlanillaEntity planilla;

  const PlanillasDetalleDialog({super.key, required this.planilla});

  @override
  ConsumerState<PlanillasDetalleDialog> createState() =>
      _PlanillasDetalleDialogState();
}

class _PlanillasDetalleDialogState
    extends ConsumerState<PlanillasDetalleDialog> {
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  _VistaDetalle _vista = _VistaDetalle.clasica;

  String _columnaOrden = '#';
  bool _ordenAsc = true;

  /// null = decide según el dispositivo (abierto en escritorio, cerrado en móvil)
  bool? _totalesExpandidos;

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planilla = widget.planilla;
    final st = ref.watch(planillaDetalleProvider(planilla.codPlanilla));
    final ntf = ref.read(
      planillaDetalleProvider(planilla.codPlanilla).notifier,
    );
    final cs = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    // En móvil solo tiene sentido la vista moderna (tarjetas).
    final vista = isMobile ? _VistaDetalle.moderna : _vista;
    final size = MediaQuery.of(context).size;
    final pad = isMobile ? 12.0 : 20.0;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600, maxHeight: 920),
        child: SizedBox(
          width: size.width * 0.96,
          height: size.height * 0.92,
          child: Column(
            children: [
              _buildHeader(cs, planilla, isMobile),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildToolbar(cs, ntf, isMobile, vista),
                      const SizedBox(height: 12),
                      Expanded(child: _buildBody(cs, st, vista)),
                      if (vista == _VistaDetalle.moderna && st.items.isNotEmpty)
                        _buildTotalesModerno(cs, st.items.first, isMobile),
                      const SizedBox(height: 8),
                      _buildPaginacion(cs, st, ntf),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cabecera
  // -------------------------------------------------------------------------

  Widget _buildHeader(ColorScheme cs, PlanillaEntity p, bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 24,
        isMobile ? 12 : 16,
        isMobile ? 6 : 12,
        isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: cs.onPrimary,
              size: isMobile ? 22 : 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETALLE DE PLANILLA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.empresa}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 21,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chipInfo(
                      cs,
                      Icons.point_of_sale_rounded,
                      'Caja: ${p.caja}',
                    ),
                    _chipInfo(cs, Icons.flag_outlined, 'Estado: ${p.estado}'),
                    if (isMobile)
                      _chipInfo(
                        cs,
                        Icons.payments_outlined,
                        'Total Líquido: ${_fmtBs.format(p.totalLiquido)}',
                        strong: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _verde.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL LÍQUIDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtBs.format(p.totalLiquido),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _verde,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _chipInfo(
    ColorScheme cs,
    IconData icon,
    String text, {
    bool strong = false,
  }) {
    final color = strong ? _verde : cs.onSurface.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              strong
                  ? _verde.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Barra de herramientas: búsqueda + selector de vista
  // -------------------------------------------------------------------------

  Widget _buildToolbar(
    ColorScheme cs,
    dynamic ntf,
    bool isMobile,
    _VistaDetalle vista,
  ) {
    final search = TextField(
      decoration: InputDecoration(
        hintText: 'Buscar empleado...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (val) {
        ntf.buscar(val);
      },
    );

    if (isMobile) return search;

    return Row(
      children: [
        SizedBox(width: 360, child: search),
        const Spacer(),
        SegmentedButton<_VistaDetalle>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(
              value: _VistaDetalle.moderna,
              icon: Icon(Icons.view_agenda_outlined, size: 18),
              label: Text('Moderna'),
              tooltip: 'Vista tipo boleta',
            ),
            ButtonSegment(
              value: _VistaDetalle.clasica,
              icon: Icon(Icons.table_rows_outlined, size: 18),
              label: Text('Clásica'),
              tooltip: 'Vista de tabla',
            ),
          ],
          selected: {vista},
          onSelectionChanged: (s) => setState(() => _vista = s.first),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Cuerpo
  // -------------------------------------------------------------------------

  Widget _buildBody(ColorScheme cs, dynamic st, _VistaDetalle vista) {
    if (st.cargando && st.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (st.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron registros de detalle.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    final contenido =
        vista == _VistaDetalle.moderna
            ? _buildListaModerna(st)
            : _buildTablaClasica(cs, st);

    return Column(
      children: [
        if (st.cargando)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(child: contenido),
      ],
    );
  }

  // ----------------------------- Vista moderna -----------------------------

  Widget _buildListaModerna(dynamic st) {
    final items = _ordenarItems(st.items);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final PlanillaDetalleEntity emp = items[index];
        return _EmpleadoCard(
          key: ValueKey('${emp.fila}_${emp.ciNumero}'),
          emp: emp,
        );
      },
    );
  }

  Widget _buildTotalesModerno(
    ColorScheme cs,
    PlanillaDetalleEntity t,
    bool isMobile,
  ) {
    final abierto = _totalesExpandidos ?? !isMobile;

    final ingresos = <Widget>[
      _totBadge('Haber Básico', _fmtBs.format(t.totalHaberBasico), cs),
      _totBadge('B. Antigüedad', _fmtBs.format(t.totalBonoAntiguedad), cs),
      _totBadge(
        'Tot. Ganado',
        _fmtBs.format(t.sumTotalGanado),
        cs,
        isPrimary: true,
      ),
    ];
    final descuentos = <Widget>[
      _totBadge('AFP', _fmtBs.format(t.totalAFP), cs),
      _totBadge('Cuotas Bs', _fmtBs.format(t.totalCuotasBolivianos), cs),
      // _totBadge('Cuotas USD', _fmtUsd.format(t.totalCuotasDolares), cs),
      _totBadge('Anticipos', _fmtBs.format(t.totalAnticipo), cs),
      _totBadge('Multas', _fmtBs.format(t.totalMultas), cs),
      _totBadge('Otros', _fmtBs.format(t.totalOtros), cs),
      _totBadge(
        'Tot. Desc.',
        _fmtBs.format(t.totalTotalDescuentos),
        cs,
        isError: true,
      ),
    ];
    final liquido = <Widget>[
      _totBadge(
        'Líquido Pagable',
        _fmtBs.format(t.totalLiquido),
        cs,
        isSuccess: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _totalesExpandidos = !abierto),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'TOTALES DE LA PLANILLA',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: cs.primary,
                    ),
                  ),
                  const Spacer(),
                  if (!abierto)
                    Flexible(
                      child: Text(
                        'Líquido Pagable: ${_fmtBs.format(t.totalLiquido)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _verde,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    abierto
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 22,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          if (abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final g1 = _grupoTotales('INGRESOS', ingresos, cs);
                  final g2 = _grupoTotales('DESCUENTOS', descuentos, cs);
                  final g3 = _grupoTotales('LÍQUIDO', liquido, cs);
                  if (c.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: g1),
                        _separadorVertical(cs),
                        Expanded(flex: 7, child: g2),
                        _separadorVertical(cs),
                        g3,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      g1,
                      const SizedBox(height: 12),
                      g2,
                      const SizedBox(height: 12),
                      g3,
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _grupoTotales(String titulo, List<Widget> badges, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: badges),
      ],
    );
  }

  Widget _separadorVertical(ColorScheme cs) => Container(
    width: 1,
    height: 52,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: cs.outlineVariant,
  );

  // ----------------------------- Vista clásica -----------------------------

  void _toggleSort(String label) {
    setState(() {
      if (_columnaOrden == label) {
        _ordenAsc = !_ordenAsc;
      } else {
        _columnaOrden = label;
        // En columnas numéricas/montos suele ser más práctico iniciar de mayor a menor (descendente)
        const descInicial = [
          'H. Básico',
          'B. Antig.',
          'Tot. Ganado',
          'AFP',
          'Cuotas Bs',
          'Anticipos',
          'Multas',
          'Otros',
          'Tot. Desc.',
          'Líquido',
        ];
        _ordenAsc = !descInicial.contains(label);
      }
    });
  }

  List<PlanillaDetalleEntity> _ordenarItems(List<PlanillaDetalleEntity> items) {
    final list = List<PlanillaDetalleEntity>.from(items);
    list.sort((a, b) {
      int cmp = 0;
      switch (_columnaOrden) {
        case '#':
          cmp = a.fila.compareTo(b.fila);
          break;
        case 'Empleado':
          cmp = a.nombreCompleto.toLowerCase().compareTo(
            b.nombreCompleto.toLowerCase(),
          );
          break;
        case 'CI':
          cmp = a.ciNumero.compareTo(b.ciNumero);
          break;
        case 'Cargo':
          cmp = a.cargo.toLowerCase().compareTo(b.cargo.toLowerCase());
          break;
        case 'F. Ingreso':
          if (a.fechaIngreso == null && b.fechaIngreso == null) {
            cmp = 0;
          } else if (a.fechaIngreso == null) {
            cmp = -1;
          } else if (b.fechaIngreso == null) {
            cmp = 1;
          } else {
            cmp = a.fechaIngreso!.compareTo(b.fechaIngreso!);
          }
          break;
        case 'F. Salida':
          if (a.fechaSalida == null && b.fechaSalida == null) {
            cmp = 0;
          } else if (a.fechaSalida == null) {
            cmp = -1;
          } else if (b.fechaSalida == null) {
            cmp = 1;
          } else {
            cmp = a.fechaSalida!.compareTo(b.fechaSalida!);
          }
          break;
        case 'Días':
          cmp = a.diasPagadosMes.compareTo(b.diasPagadosMes);
          break;
        case 'H. Básico':
          cmp = a.haberBasico.compareTo(b.haberBasico);
          break;
        case 'B. Antig.':
          cmp = a.bonoAntiguedad.compareTo(b.bonoAntiguedad);
          break;
        case 'Tot. Ganado':
          cmp = a.total.compareTo(b.total);
          break;
        case 'AFP':
          cmp = a.afp.compareTo(b.afp);
          break;
        case 'Cuotas Bs':
          cmp = a.cuotasBolivianos.compareTo(b.cuotasBolivianos);
          break;
        case 'Anticipos':
          cmp = a.anticipo.compareTo(b.anticipo);
          break;
        case 'Multas':
          cmp = a.multas.compareTo(b.multas);
          break;
        case 'Otros':
          cmp = a.otros.compareTo(b.otros);
          break;
        case 'Tot. Desc.':
          cmp = a.totalDescuentos.compareTo(b.totalDescuentos);
          break;
        case 'Líquido':
          cmp = a.liquido.compareTo(b.liquido);
          break;
        default:
          cmp = a.fila.compareTo(b.fila);
      }
      return _ordenAsc ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildTablaClasica(ColorScheme cs, dynamic st) {
    final PlanillaDetalleEntity totales = st.items.first;
    final itemsOrdenados = _ordenarItems(st.items);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final tabla = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tablaHeader(cs),
              Expanded(
                child: Scrollbar(
                  controller: _vScroll,
                  child: ListView.builder(
                    controller: _vScroll,
                    itemCount: itemsOrdenados.length,
                    itemBuilder: (context, index) {
                      final PlanillaDetalleEntity emp = itemsOrdenados[index];
                      return _tablaFila(cs, emp, index);
                    },
                  ),
                ),
              ),
              _tablaTotales(cs, totales),
            ],
          );

          if (c.maxWidth >= _anchoMinTabla) return tabla;

          // Pantalla angosta: toda la tabla (incluidos los totales) se
          // desplaza junta, así las columnas siempre quedan alineadas.
          return Scrollbar(
            controller: _hScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _hScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _anchoMinTabla,
                height: c.maxHeight,
                child: tabla,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tablaHeader(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Row(
        children: [
          for (final c in _cols)
            c.wrap(
              InkWell(
                onTap: () => _toggleSort(c.label),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          c.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color:
                                _columnaOrden == c.label
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      if (_columnaOrden == c.label) ...[
                        const SizedBox(width: 2),
                        Icon(
                          _ordenAsc
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tablaFila(ColorScheme cs, PlanillaDetalleEntity e, int index) {
    final err = e.tieneError;
    final bg =
        err
            ? cs.errorContainer.withValues(alpha: 0.28)
            : (index.isEven
                ? Colors.transparent
                : cs.surfaceContainerHighest.withValues(alpha: 0.25));
    final muted = cs.onSurface.withValues(alpha: 0.6);

    final cells = <Widget>[
      Text('${e.fila}', style: TextStyle(fontSize: 12, color: muted)),
      _celdaEmpleado(cs, e),
      Text('${e.ciNumero}', style: const TextStyle(fontSize: 12.5)),
      Text(
        '${e.cargo}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      _celdaFecha(e.fechaIngreso, null),
      _celdaFecha(e.fechaSalida, cs.error),
      Text(
        '${e.diasPagadosMes}',
        style: const TextStyle(fontSize: 12.5, fontFeatures: _tabular),
      ),
      _num(_fmtNum.format(e.haberBasico)),
      _num(_fmtNum.format(e.bonoAntiguedad)),
      _num(_fmtNum.format(e.total), w: FontWeight.w700, color: _verde),
      _num(_fmtNum.format(e.afp)),
      _num(_fmtNum.format(e.cuotasBolivianos)),
      // _num(_fmtNum.format(e.cuotasDolares)),
      _num(_fmtNum.format(e.anticipo)),
      _num(_fmtNum.format(e.multas)),
      _num(_fmtNum.format(e.otros)),
      _num(
        _fmtNum.format(e.totalDescuentos),
        w: FontWeight.w700,
        color: cs.error,
      ),
      _num(
        _fmtNum.format(e.liquido),
        w: FontWeight.w800,
        color: err ? cs.error : null,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _cols.length; i++) _cols[i].wrap(cells[i]),
        ],
      ),
    );
  }

  Widget _celdaEmpleado(ColorScheme cs, PlanillaDetalleEntity e) {
    final err = e.tieneError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${e.nombreCompleto}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: err ? cs.error : null,
                ),
              ),
            ),
            if (err) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: e.mensajeError ?? 'Error en el detalle',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: cs.error,
                ),
              ),
            ],
          ],
        ),
        if (e.mensajeError != null)
          Text(
            '${e.mensajeError}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.error,
            ),
          ),
      ],
    );
  }

  Widget _celdaFecha(DateTime? d, Color? color) {
    return Text(
      d == null ? '—' : _fmtFecha.format(d),
      style: TextStyle(fontSize: 12, color: d == null ? null : color),
    );
  }

  Widget _num(String s, {FontWeight? w, Color? color}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        s,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: w,
          color: color,
          fontFeatures: _tabular,
        ),
      ),
    );
  }

  Widget _tablaTotales(ColorScheme cs, PlanillaDetalleEntity t) {
    const blank = SizedBox.shrink();
    final cells = <Widget>[
      blank,
      Text(
        'TOTALES (Bs)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: cs.primary,
        ),
      ),
      blank,
      blank,
      blank,
      blank,
      blank,
      _num(_fmtNum.format(t.totalHaberBasico), w: FontWeight.w800),
      _num(_fmtNum.format(t.totalBonoAntiguedad), w: FontWeight.w800),
      _num(_fmtNum.format(t.sumTotalGanado), w: FontWeight.w800, color: _verde),
      _num(_fmtNum.format(t.totalAFP), w: FontWeight.w800),
      _num(_fmtNum.format(t.totalCuotasBolivianos), w: FontWeight.w800),
      // _num(_fmtNum.format(t.totalCuotasDolares), w: FontWeight.w800),
      _num(_fmtNum.format(t.totalAnticipo), w: FontWeight.w800),
      _num(_fmtNum.format(t.totalMultas), w: FontWeight.w800),
      _num(_fmtNum.format(t.totalOtros), w: FontWeight.w800),
      _num(
        _fmtNum.format(t.totalTotalDescuentos),
        w: FontWeight.w800,
        color: cs.error,
      ),
      _num(_fmtNum.format(t.totalLiquido), w: FontWeight.w800, color: _verde),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _cols.length; i++) _cols[i].wrap(cells[i]),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Paginación
  // -------------------------------------------------------------------------

  Widget _buildPaginacion(ColorScheme cs, dynamic st, dynamic ntf) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total registros: ${st.totalRegistros}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 16),
              const Text('Mostrar: '),
              DropdownButton<int>(
                value: st.tamanoPagina,
                isDense: true,
                underline: const SizedBox(),
                items:
                    [15, 30, 50, 100, 200]
                        .map(
                          (e) => DropdownMenuItem(value: e, child: Text('$e')),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) ntf.cambiarTamanoPagina(v);
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Página ${st.pagina} de ${st.totalPaginas}'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    st.pagina > 1
                        ? () => ntf.cambiarPagina(st.pagina - 1)
                        : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    st.pagina < st.totalPaginas
                        ? () => ntf.cambiarPagina(st.pagina + 1)
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Definición de columnas de la vista clásica
// ---------------------------------------------------------------------------

class _Col {
  final String label;
  final double? width;
  final int? flex;
  final Alignment align;

  const _Col(
    this.label, {
    this.width,
    this.flex,
    this.align = Alignment.centerLeft,
  });

  Widget wrap(Widget child) {
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Align(alignment: align, child: child),
    );
    return flex != null
        ? Expanded(flex: flex!, child: padded)
        : SizedBox(width: width, child: padded);
  }
}

const List<_Col> _cols = [
  _Col('#', width: 36, align: Alignment.center),
  _Col('Empleado', flex: 3),
  _Col('CI', width: 76),
  _Col('Cargo', flex: 2),
  _Col('F. Ingreso', width: 82, align: Alignment.center),
  _Col('F. Salida', width: 82, align: Alignment.center),
  _Col('Días', width: 40, align: Alignment.center),
  _Col('H. Básico', width: 84, align: Alignment.centerRight),
  _Col('B. Antig.', width: 84, align: Alignment.centerRight),
  _Col('Tot. Ganado', width: 88, align: Alignment.centerRight),
  _Col('AFP', width: 68, align: Alignment.centerRight),
  _Col('Cuotas Bs', width: 76, align: Alignment.centerRight),
  // _Col('Cuotas USD', width: 76, align: Alignment.centerRight),
  _Col('Anticipos', width: 72, align: Alignment.centerRight),
  _Col('Multas', width: 64, align: Alignment.centerRight),
  _Col('Otros', width: 64, align: Alignment.centerRight),
  _Col('Tot. Desc.', width: 84, align: Alignment.centerRight),
  _Col('Líquido', width: 92, align: Alignment.centerRight),
];

// ---------------------------------------------------------------------------
// Tarjeta de empleado (vista moderna / boleta)
// ---------------------------------------------------------------------------

class _EmpleadoCard extends StatefulWidget {
  final PlanillaDetalleEntity emp;

  const _EmpleadoCard({super.key, required this.emp});

  @override
  State<_EmpleadoCard> createState() => _EmpleadoCardState();
}

class _EmpleadoCardState extends State<_EmpleadoCard> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final err = widget.emp.tieneError;

    return Material(
      color: err ? cs.errorContainer.withValues(alpha: 0.2) : cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              err
                  ? cs.error.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: LayoutBuilder(
                builder:
                    (context, c) =>
                        c.maxWidth >= 720
                            ? _headerAncho(cs)
                            : _headerCompacto(cs),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                _abierto
                    ? _detalle(cs)
                    : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  // ------------------------------- Cabecera --------------------------------

  Widget _headerAncho(ColorScheme cs) {
    return Row(
      children: [
        _filaBadge(cs),
        const SizedBox(width: 12),
        Expanded(flex: 5, child: _nombreColumn(cs)),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Wrap(spacing: 8, runSpacing: 4, children: _fechas(cs)),
        ),
        const SizedBox(width: 12),
        _liquidoPill(cs),
        const SizedBox(width: 8),
        _chevron(cs),
      ],
    );
  }

  Widget _headerCompacto(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filaBadge(cs),
            const SizedBox(width: 10),
            Expanded(child: _nombreColumn(cs)),
            _chevron(cs),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [..._fechas(cs), _liquidoPill(cs)],
        ),
      ],
    );
  }

  /// Número de fila: insignia pequeña, sin ocupar espacio de más.
  Widget _filaBadge(ColorScheme cs) {
    final err = widget.emp.tieneError;
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: err ? cs.error : cs.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${widget.emp.fila}',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: err ? cs.onError : cs.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _nombreColumn(ColorScheme cs) {
    final e = widget.emp;
    final err = e.tieneError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${e.nombreCompleto}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: err ? cs.error : cs.onSurface,
                ),
              ),
            ),
            if (err) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: e.mensajeError ?? 'Error en el detalle',
                child: Icon(Icons.warning_rounded, size: 18, color: cs.error),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Cargo: ${e.cargo}  •  CI: ${e.ciNumero}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            color: err ? cs.error : cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        if (e.mensajeError != null) ...[
          const SizedBox(height: 2),
          Text(
            'Error: ${e.mensajeError}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.error,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _fechas(ColorScheme cs) {
    final e = widget.emp;
    return [
      if (e.fechaIngreso != null)
        _buildDateChip('Fecha Ingreso', e.fechaIngreso!, _verde, Icons.login),
      if (e.fechaSalida != null)
        _buildDateChip('Fecha Salida', e.fechaSalida!, cs.error, Icons.logout),
    ];
  }

  Widget _liquidoPill(ColorScheme cs) {
    final err = widget.emp.tieneError;
    final color = err ? cs.error : _verde;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LÍQUIDO',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            _fmtBs.format(widget.emp.liquido),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron(ColorScheme cs) {
    return AnimatedRotation(
      turns: _abierto ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.expand_more_rounded,
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  // ------------------------------- Detalle ---------------------------------

  Widget _detalle(ColorScheme cs) {
    final e = widget.emp;

    final ingresos = _PanelDetalle(
      titulo: 'INGRESOS',
      icono: Icons.trending_up_rounded,
      color: _verde,
      lineas: [
        _Linea('Días Pagados', '${e.diasPagadosMes}'),
        _Linea('Haber Básico', _fmtBs.format(e.haberBasico)),
        _Linea('Bono Antigüedad', _fmtBs.format(e.bonoAntiguedad)),
        _Linea('Total Ganado', _fmtBs.format(e.total), strong: true),
      ],
    );

    final descuentos = _PanelDetalle(
      titulo: 'DESCUENTOS',
      icono: Icons.trending_down_rounded,
      color: cs.error,
      lineas: [
        _Linea('AFP', _fmtBs.format(e.afp)),
        _Linea('Cuotas BS', _fmtBs.format(e.cuotasBolivianos)),
        // _Linea('Cuotas USD', _fmtUsd.format(e.cuotasDolares)),
        _Linea('Anticipos', _fmtBs.format(e.anticipo)),
        _Linea('Multas', _fmtBs.format(e.multas)),
        _Linea('Otros Desc.', _fmtBs.format(e.otros)),
        _Linea(
          'Total Descuentos',
          _fmtBs.format(e.totalDescuentos),
          strong: true,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 720) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ingresos),
                  const SizedBox(width: 12),
                  Expanded(child: descuentos),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ingresos, const SizedBox(height: 10), descuentos],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel de detalle (Ingresos / Descuentos)
// ---------------------------------------------------------------------------

class _Linea {
  final String label;
  final String value;
  final bool strong;

  const _Linea(this.label, this.value, {this.strong = false});
}

class _PanelDetalle extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<_Linea> lineas;

  const _PanelDetalle({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.lineas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ],
          ),
          Divider(height: 18, color: color.withValues(alpha: 0.2)),
          for (final l in lineas) ...[
            if (l.strong)
              Divider(height: 14, color: color.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.label,
                      style: TextStyle(
                        fontSize: l.strong ? 13.5 : 13,
                        fontWeight:
                            l.strong ? FontWeight.w700 : FontWeight.w400,
                        color: cs.onSurface.withValues(
                          alpha: l.strong ? 0.9 : 0.75,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.value,
                    style: TextStyle(
                      fontSize: l.strong ? 14 : 13,
                      fontWeight: l.strong ? FontWeight.w800 : FontWeight.w600,
                      color: l.strong ? color : null,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares compartidos
// ---------------------------------------------------------------------------

Widget _totBadge(
  String label,
  String value,
  ColorScheme cs, {
  bool isPrimary = false,
  bool isError = false,
  bool isSuccess = false,
}) {
  Color bg = cs.surface;
  Color fg = cs.onSurface;
  if (isPrimary) {
    bg = cs.primary;
    fg = cs.onPrimary;
  } else if (isError) {
    bg = cs.errorContainer;
    fg = cs.onErrorContainer;
  } else if (isSuccess) {
    bg = _verde;
    fg = Colors.white;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border:
          isPrimary || isError || isSuccess
              ? null
              : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: fg.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: fg,
            fontWeight: FontWeight.bold,
            fontFeatures: _tabular,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDateChip(String label, DateTime date, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ${_fmtFecha.format(date)}',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

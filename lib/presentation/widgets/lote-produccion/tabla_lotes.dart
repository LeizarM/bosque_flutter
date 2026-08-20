/// La planilla de "Ver lote de produccion".
///
/// El sistema anterior mostraba diecisiete columnas de cada lote; la primera
/// version de esta pantalla las redujo a seis y dejo el resto en el detalle.
/// Vuelven todas: revisar la produccion del dia es comparar lotes entre si, y
/// para eso hay que verlos juntos y no abrirlos de a uno.
///
/// Lo que se agrega sobre la planilla original:
///
/// - **La cabecera no se va con el scroll**, y las columnas estan agrupadas por
///   lo que responden: tiempos, ingreso, salida y cuadre.
/// - **Los totales del periodo** quedan fijos abajo, cada uno debajo de su
///   columna.
/// - **Las acciones estan al principio.** Antes habia que recorrer diecinueve
///   columnas de costado para llegar al boton.
/// - **La vista resumida sigue disponible**, que es la que sirve para el dia a
///   dia cuando solo se quiere saber que lote no cuadra.
library;

import 'dart:math' as math;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';

/// Cuanta informacion se muestra de cada lote.
enum VistaLotes {
  resumen('Resumen', Icons.view_agenda_outlined),
  completa('Completa', Icons.table_rows_outlined);

  const VistaLotes(this.rotulo, this.icono);

  final String rotulo;
  final IconData icono;
}

const double _altoBanda = 24;
const double _altoCabecera = 40;
const double _altoFila = 48;
const double _altoTotales = 44;

/// Cuanto duro el corte.
///
/// Si la hora de fin es menor que la de inicio el lote cruzo la medianoche: el
/// turno de noche es habitual y sin esto la duracion salia negativa.
String duracionCorte(String inicio, String fin) {
  final a = _enMinutos(inicio);
  final b = _enMinutos(fin);
  if (a == null || b == null) return '--';
  final total = b >= a ? b - a : b + 24 * 60 - a;
  return '${total ~/ 60}h ${(total % 60).toString().padLeft(2, '0')}m';
}

int? _enMinutos(String hhmm) {
  final partes = hhmm.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0].trim());
  final m = int.tryParse(partes[1].trim());
  if (h == null || m == null) return null;
  return h * 60 + m;
}

// ═══════════════════════════════════════════════════════════════════════════
// LA TABLA
// ═══════════════════════════════════════════════════════════════════════════

class TablaLotes extends StatefulWidget {
  const TablaLotes({
    super.key,
    required this.lotes,
    required this.vista,
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
    required this.padding,
  });

  final List<LoteProduccionEntity> lotes;
  final VistaLotes vista;
  final bool puedeReabrir;
  final void Function(LoteProduccionEntity) onAbrir;
  final void Function(LoteProduccionEntity) onReporte;
  final EdgeInsets padding;

  @override
  State<TablaLotes> createState() => _TablaLotesState();
}

class _TablaLotesState extends State<TablaLotes> {
  final _scrollH = ScrollController();

  @override
  void didUpdateWidget(TablaLotes anterior) {
    super.didUpdateWidget(anterior);
    // Al pasar a la vista corta la tabla se angosta: sin esto quedaba mirando
    // un hueco a la derecha hasta que alguien la arrastrara de vuelta.
    if (anterior.vista != widget.vista) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollH.hasClients) _scrollH.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollH.dispose();
    super.dispose();
  }

  // ── Columnas ──────────────────────────────────────────────────────────────

  List<_Col> _columnas() {
    final todas = <_Col>[
      _Col(
        'LOTE',
        140,
        (c, l) => _CeldaLote(lote: l),
        alinear: Alignment.centerLeft,
        enResumen: true,
        pie: (c, lotes) => _cifra(
          c,
          lotes.length == 1 ? '1 lote' : '${lotes.length} lotes',
          fuerte: true,
        ),
      ),
      _Col('', 92, _acciones, alinear: Alignment.centerLeft, enResumen: true),
      _Col(
        'FECHA',
        104,
        (c, l) => _cifra(c, fechaCorta(l.fecha)),
        alinear: Alignment.centerLeft,
        enResumen: true,
      ),

      // ── Tiempos ──
      _Col(
        'INICIO CORTE',
        108,
        (c, l) => _hora(c, l.hraInicioCorte),
        banda: 'TIEMPOS',
        ayuda: 'Hora a la que la maquina empezo a cortar.',
      ),
      _Col(
        'INICIO',
        84,
        (c, l) => _hora(c, l.hraInicio),
        banda: 'TIEMPOS',
        ayuda: 'Hora de inicio del lote.',
      ),
      _Col(
        'FIN',
        84,
        (c, l) => _hora(c, l.hraFin),
        banda: 'TIEMPOS',
        ayuda: 'Hora de cierre del lote.',
      ),
      _Col(
        'DURACION',
        96,
        (c, l) => _cifra(
          c,
          duracionCorte(l.hraInicio, l.hraFin),
          vacio: l.hraInicio.isEmpty || l.hraFin.isEmpty,
        ),
        banda: 'TIEMPOS',
        ayuda:
            'De inicio a fin. No estaba en la planilla anterior: se calcula '
            'aqui para no tener que restar las horas a mano.',
      ),

      // ── Ingreso ──
      _Col(
        'BOBINAS',
        92,
        (c, l) => _cifra(c, fmtEntero.format(l.cantBobinasIngresoTotal)),
        banda: 'INGRESO',
        enResumen: true,
        pie: _sumaEntera((l) => l.cantBobinasIngresoTotal),
      ),
      _Col(
        'KG INGRESO',
        112,
        (c, l) =>
            _cifra(c, fmtNumero.format(l.pesoKilosTotalIngreso), fuerte: true),
        banda: 'INGRESO',
        enResumen: true,
        ayuda: 'Kilos de las bobinas que entraron al lote.',
        pie: _suma((l) => l.pesoKilosTotalIngreso),
      ),

      // ── Salida ──
      _Col(
        'KG SALIDA',
        108,
        (c, l) => _cifra(c, fmtNumero.format(l.pesoTotalSalida)),
        banda: 'SALIDA',
        ayuda: 'Peso de las resmas que salieron, sin la paleta.',
        pie: _suma((l) => l.pesoTotalSalida),
      ),
      _Col(
        'KG PALETA',
        104,
        (c, l) => _cifra(c, fmtNumero.format(l.pesoPaletaSalida)),
        banda: 'SALIDA',
        ayuda: 'Peso de las paletas sobre las que salio el material.',
        pie: _suma((l) => l.pesoPaletaSalida),
      ),
      _Col(
        'KG MATERIAL',
        116,
        (c, l) =>
            _cifra(c, fmtNumero.format(l.pesoMaterialSalida), fuerte: true),
        banda: 'SALIDA',
        ayuda:
            'Material de salida: es el que se compara contra el ingreso para '
            'saber si el lote cuadra.',
        pie: _suma((l) => l.pesoMaterialSalida),
      ),
      _Col(
        'RESMAS',
        96,
        (c, l) => _cifra(c, fmtEntero.format(l.cantResmaSalida), fuerte: true),
        banda: 'SALIDA',
        enResumen: true,
        ayuda: 'Resmas contadas al cerrar el lote.',
        pie: _sumaEntera((l) => l.cantResmaSalida),
      ),
      _Col(
        'HOJAS',
        100,
        (c, l) => _cifra(c, fmtEntero.format(l.cantHojasSalida)),
        banda: 'SALIDA',
        ayuda: 'Hojas sueltas de salida, fuera de resma.',
        pie: _suma((l) => l.cantHojasSalida, entera: true),
      ),

      // ── Cuadre ──
      _Col(
        'MERMA KG',
        104,
        (c, l) => _cifra(c, fmtNumero.format(l.mermaTotal)),
        banda: 'CUADRE',
        enResumen: true,
        ayuda: 'Kilos que se descartaron en el corte.',
        pie: _suma((l) => l.mermaTotal),
      ),
      _Col(
        'DIF. KG',
        104,
        (c, l) => _cifra(
          c,
          fmtNumero.format(l.diferenciaProduccion),
          color: _colorDiferencia(c, l),
          fuerte: true,
        ),
        banda: 'CUADRE',
        ayuda:
            'Kilos de ingreso que no se explican con el material de salida ni '
            'con la merma.',
        pie: _suma((l) => l.diferenciaProduccion),
      ),
      _Col(
        'DIF. RESMAS',
        108,
        (c, l) => _cifra(c, fmtNumero.format(l.diferenciaProdResma)),
        banda: 'CUADRE',
        ayuda: 'Resmas contadas menos resmas estimadas por balanza.',
        pie: _suma((l) => l.diferenciaProdResma),
      ),
      _Col(
        'RESMAS EST.',
        112,
        (c, l) => _cifra(
          c,
          l.cantEstimadaResma <= 0
              ? '--'
              : fmtNumero.format(l.cantEstimadaResma),
          vacio: l.cantEstimadaResma <= 0,
        ),
        banda: 'CUADRE',
        ayuda:
            'Resmas que deberian haber salido segun el peso de balanza. Sin '
            'UTM cargada en el articulo no hay estimacion posible.',
        pie: _suma((l) => l.cantEstimadaResma),
      ),
      _Col(
        'KG BALANZA',
        112,
        (c, l) => _cifra(c, fmtNumero.format(l.pesoBalanzaTotal)),
        banda: 'CUADRE',
        ayuda: 'Peso pesado en balanza, del que sale la estimacion de resmas.',
        pie: _suma((l) => l.pesoBalanzaTotal),
      ),
      _Col(
        'CUADRE',
        116,
        (c, l) => EtiquetaCuadre(
          diferenciaKilos: l.diferenciaProduccion,
          kilosIngreso: l.pesoKilosTotalIngreso,
        ),
        banda: 'CUADRE',
        alinear: Alignment.centerLeft,
        enResumen: true,
        ayuda: 'La diferencia de kilos leida contra el tamano del lote.',
      ),

      // ── Referencia ──
      _Col(
        'ORDEN',
        116,
        (c, l) => _cifra(
          c,
          l.docNumOrdFab == 0 ? '--' : l.docNumOrdFab.toString(),
          vacio: l.docNumOrdFab == 0,
        ),
        banda: 'REFERENCIA',
        enResumen: true,
        ayuda: 'Orden de fabricacion de SAP.',
      ),
      _Col(
        'OBSERVACION',
        280,
        _observacion,
        banda: 'REFERENCIA',
        alinear: Alignment.centerLeft,
      ),
    ];

    return widget.vista == VistaLotes.completa
        ? todas
        : todas.where((c) => c.enResumen).toList();
  }

  Widget _acciones(BuildContext context, LoteProduccionEntity lote) {
    // Un lote cerrado se mira igual: ver lo que se corto no necesita permiso,
    // corregirlo si.
    final editable = lote.estado == 1 || widget.puedeReabrir;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BotonFila(
          icono: Icons.picture_as_pdf_outlined,
          ayuda: 'Generar PDF del lote',
          onPressed: () => widget.onReporte(lote),
        ),
        _BotonFila(
          icono: editable ? Icons.edit_outlined : Icons.visibility_outlined,
          ayuda: editable
              ? 'Abrir el lote'
              : 'Ver el lote. No tiene permiso para reabrirlo.',
          onPressed: () => widget.onAbrir(lote),
        ),
      ],
    );
  }

  // ── Dibujo ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = _columnas();
    final completa = widget.vista == VistaLotes.completa;

    return Padding(
      padding: widget.padding.copyWith(bottom: Esp.xl),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final pedido = cols.fold(0.0, (s, c) => s + c.ancho);
            // Cuando sobra lugar la tabla se estira: una planilla angosta con
            // medio panel vacio al lado se lee como si le faltara algo.
            final ancho = math.max(pedido, restricciones.maxWidth);
            final estirar = ancho - pedido;
            final desborda = pedido > restricciones.maxWidth;

            return ScrollConfiguration(
              behavior: const ArrastreLateral(),
              child: Scrollbar(
                controller: _scrollH,
                thumbVisibility: desborda,
                child: SingleChildScrollView(
                  controller: _scrollH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: ancho,
                    child: Column(
                      children: [
                        if (completa) _banda(cols, estirar),
                        _cabecera(cols, estirar),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemExtent: _altoFila,
                            itemCount: widget.lotes.length,
                            itemBuilder: (context, i) => _fila(i, cols, estirar),
                          ),
                        ),
                        _totales(cols, estirar),
                        // Deja pasar la barra de scroll horizontal sin que se
                        // apoye encima de los totales.
                        SizedBox(height: desborda ? 10 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// La banda que agrupa las columnas por lo que responden.
  Widget _banda(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final grupos = _agrupar(cols);

    return SizedBox(
      height: _altoBanda,
      child: Row(
        children: [
          for (final (i, g) in grupos.indexed)
            Container(
              width: g.ancho + (i == grupos.length - 1 ? estirar : 0),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: Esp.s),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(
                    color: g.nombre.isEmpty
                        ? Colors.transparent
                        : colorDeCatalogo(cs, i).fondo,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                g.nombre,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: Peso.titulo,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecera(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, col) in cols.indexed)
            _celda(
              col,
              estirar: i == cols.length - 1 ? estirar : 0,
              hijo: col.ayuda == null
                  ? _rotulo(col.titulo)
                  : Tooltip(
                      message: col.ayuda!,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: _rotulo(col.titulo)),
                          SizedBox(width: Esp.xs),
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _rotulo(String texto) => Text(
    texto,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
  );

  /// Una fila por lote. El rayado alterno es lo que deja seguir un lote a lo
  /// ancho de veintidos columnas sin perder el renglon.
  Widget _fila(int i, List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final lote = widget.lotes[i];

    return Material(
      color: i.isOdd ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
      child: InkWell(
        onTap: () => widget.onAbrir(lote),
        child: Row(
          children: [
            for (final (j, col) in cols.indexed)
              _celda(
                col,
                estirar: j == cols.length - 1 ? estirar : 0,
                hijo: col.celda(context, lote),
              ),
          ],
        ),
      ),
    );
  }

  /// Los totales del periodo, cada uno debajo de su columna.
  Widget _totales(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _altoTotales,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, col) in cols.indexed)
            _celda(
              col,
              estirar: i == cols.length - 1 ? estirar : 0,
              hijo: col.pie?.call(context, widget.lotes) ?? const SizedBox(),
            ),
        ],
      ),
    );
  }

  Widget _celda(_Col col, {required Widget hijo, double estirar = 0}) =>
      Container(
        width: col.ancho + estirar,
        alignment: col.alinear,
        padding: EdgeInsets.symmetric(horizontal: Esp.s),
        child: hijo,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una columna de la planilla.
class _Col {
  const _Col(
    this.titulo,
    this.ancho,
    this.celda, {
    this.banda = '',
    this.ayuda,
    this.pie,
    this.enResumen = false,
    this.alinear = Alignment.centerRight,
  });

  final String titulo;
  final double ancho;
  final Widget Function(BuildContext, LoteProduccionEntity) celda;

  /// El grupo al que pertenece, para la banda de arriba.
  final String banda;

  /// Que significa la columna, cuando el rotulo no alcanza.
  final String? ayuda;

  /// El total del periodo, si la columna suma.
  final Widget Function(BuildContext, List<LoteProduccionEntity>)? pie;

  /// Si sobrevive a la vista corta.
  final bool enResumen;

  final Alignment alinear;
}

typedef _Grupo = ({String nombre, double ancho});

/// Junta las columnas contiguas que comparten banda.
List<_Grupo> _agrupar(List<_Col> cols) {
  final grupos = <_Grupo>[];
  for (final col in cols) {
    if (grupos.isNotEmpty && grupos.last.nombre == col.banda) {
      grupos[grupos.length - 1] = (
        nombre: col.banda,
        ancho: grupos.last.ancho + col.ancho,
      );
    } else {
      grupos.add((nombre: col.banda, ancho: col.ancho));
    }
  }
  return grupos;
}

/// Numero de lote y estado juntos, que es como se busca.
class _CeldaLote extends StatelessWidget {
  const _CeldaLote({required this.lote});

  final LoteProduccionEntity lote;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${lote.numLote}/${lote.anio}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
        ),
      ),
      Text(lote.estado == 1 ? 'Abierto' : 'Cerrado', style: context.apagado()),
    ],
  );
}

/// Un boton de fila, del tamano que deja pasar veintidos columnas.
class _BotonFila extends StatelessWidget {
  const _BotonFila({
    required this.icono,
    required this.ayuda,
    required this.onPressed,
  });

  final IconData icono;
  final String ayuda;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icono, size: 18),
    tooltip: ayuda,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    padding: EdgeInsets.zero,
  );
}

/// Una cifra de la planilla. El cero se atenua: en veintidos columnas hay
/// muchos, y en negro compiten con los numeros que si dicen algo.
Widget _cifra(
  BuildContext context,
  String texto, {
  bool fuerte = false,
  bool vacio = false,
  Color? color,
}) => Text(
  texto,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: context.numero(
    fuerte: fuerte,
    color: color ?? (vacio ? Theme.of(context).hintColor : null),
  ),
);

Widget _hora(BuildContext context, String hhmm) =>
    _cifra(context, hhmm.isEmpty ? '--' : hhmm, vacio: hhmm.isEmpty);

Widget _observacion(BuildContext context, LoteProduccionEntity lote) {
  final texto = lote.obs.trim();
  if (texto.isEmpty) return _cifra(context, '--', vacio: true);

  return Tooltip(
    message: texto,
    child: Text(
      texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

/// El color de la diferencia sin explicar: el mismo criterio que la etiqueta de
/// cuadre, para que la columna y la etiqueta nunca digan cosas distintas.
Color? _colorDiferencia(BuildContext context, LoteProduccionEntity lote) {
  final cs = Theme.of(context).colorScheme;
  return switch (cuadreDe(
    diferenciaKilos: lote.diferenciaProduccion,
    kilosIngreso: lote.pesoKilosTotalIngreso,
  )) {
    EstadoCuadre.cuadrado => null,
    EstadoCuadre.desvio => cs.tertiary,
    EstadoCuadre.desviado => cs.error,
  };
}

Widget Function(BuildContext, List<LoteProduccionEntity>) _suma(
  double Function(LoteProduccionEntity) valor, {
  bool entera = false,
}) => (context, lotes) {
  final total = lotes.fold(0.0, (s, l) => s + valor(l));
  return _cifra(
    context,
    entera ? fmtEntero.format(total) : fmtNumero.format(total),
    fuerte: true,
  );
};

Widget Function(BuildContext, List<LoteProduccionEntity>) _sumaEntera(
  int Function(LoteProduccionEntity) valor,
) => (context, lotes) => _cifra(
  context,
  fmtEntero.format(lotes.fold(0, (s, l) => s + valor(l))),
  fuerte: true,
);

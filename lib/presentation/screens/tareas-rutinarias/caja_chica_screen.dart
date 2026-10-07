// Destino final: lib/presentation/screens/tareas-rutinarias/caja_chica_screen.dart
import 'dart:async';

import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/caja_chica_flujo_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/data/repositories/caja_chica_flujo_impl.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/ofrecer_pdf.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';

/// Reemplaza dlgCajaChica del legacy. A diferencia de ese diálogo (que
/// borraba la fila en silencio si el saldo corrido quedaba negativo), aquí
/// el backend rechaza el egreso ANTES de guardar nada y explica por qué —
/// ver p_cajaChica_registrarEgreso.
class CajaChicaScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  const CajaChicaScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  Future<void> _abrirFormularioEgreso(
    BuildContext context,
    WidgetRef ref,
    CajaChicaParams params,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioEgreso(params: params),
    );
  }

  /// "Ver Cajas Chicas" del legacy — histórico de lotes de esta sucursal.
  void _abrirHistorialLotes(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _HistorialLotesDialog(idBitTarea: idBitTarea),
    );
  }

  /// Reemplaza la mitad "esto reiniciara su caja chica" del "Generar PDF"
  /// del legacy (el reporte en sí lo migra un esfuerzo aparte): cierra el
  /// lote vigente y abre uno nuevo con su saldo inicial. Pide confirmación
  /// primero porque, a diferencia de un egreso, no hay forma de deshacerlo
  /// desde aquí.
  Future<void> _confirmarCerrarLote(
    BuildContext context,
    WidgetRef ref,
    CajaChicaParams params,
    double saldoActual,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Cerrar este lote?'),
            content: Text(
              'Se va a cerrar el lote actual (saldo: ${FormatoMoneda.monto.format(saldoActual)}) '
              'y se va a abrir uno nuevo para esta sucursal, con su propio saldo inicial de '
              'caja chica. Los movimientos de este lote quedan guardados y siguen disponibles '
              'en "Ver cajas chicas anteriores", pero ya no se le pueden agregar más egresos.',
            ),
            actions: [
              TextButton(
                onPressed: () => cerrarRuta(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => cerrarRuta(ctx, true),
                child: const Text('Cerrar lote'),
              ),
            ],
          ),
    );
    if (confirmar != true || !context.mounted) return;

    // El lote y la sucursal se leen ANTES de cerrar: después, el provider ya
    // recargó con el lote NUEVO (vacío) y el que se acaba de archivar no está
    // más en pantalla — pedir el PDF con esos datos daría el lote equivocado.
    final filas = ref.read(cajaChicaFlujoProvider(params)).items;
    final loteCerrado = filas.isEmpty ? null : filas.first.lote;
    final codSucursal = filas.isEmpty ? null : filas.first.codSucursal;

    final ok =
        await ref.read(cajaChicaFlujoProvider(params).notifier).cerrarLote();
    // Si falló, el listener de errores de la pantalla ya muestra el aviso
    // (mensajeError) — no hace falta duplicarlo aquí.
    if (!ok || !context.mounted) return;

    HapticFeedback.mediumImpact();

    // El PDF del lote recién cerrado, en el mismo momento del cierre: en el
    // legacy ese reporte era el paso con el que la caja chica entraba a
    // archivo, no un extra a buscar después en el histórico.
    if (loteCerrado != null && codSucursal != null) {
      await ofrecerPdf(
        context,
        tituloDialogo: 'Lote cerrado',
        mensaje:
            'Se cerró el lote $loteCerrado y se abrió uno nuevo para esta '
            'sucursal. ¿Quieres el PDF del lote cerrado, para archivo?',
        titulo: 'Caja chica — Lote $loteCerrado',
        nombreArchivo: 'caja_chica_lote_$loteCerrado.pdf',
        generar:
            () => CajaChicaFlujoImpl().generarReportePdf(
              lote: loteCerrado,
              codSucursal: codSucursal,
            ),
      );
    } else {
      mostrarAviso(
        context,
        'Lote cerrado. Se abrió un lote nuevo para esta sucursal.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (idBitTarea: idBitTarea);
    final state = ref.watch(cajaChicaFlujoProvider(params));
    final notifier = ref.read(cajaChicaFlujoProvider(params).notifier);

    ref.listen(cajaChicaFlujoProvider(params), (previo, actual) {
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreTarea,
          subtitulo:
              state.items.isEmpty
                  ? null
                  : 'Lote ${state.items.first.lote ?? '—'} · '
                      '${state.cantidadEgresos == 1 ? '1 egreso' : '${state.cantidadEgresos} egresos'}',
          insignia: InsigniaTarea.deTipo(context, 7),
          acciones: [
            IconButton(
              icon:
                  state.cerrandoLote
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ),
                      )
                      : const Icon(Icons.restart_alt),
              tooltip: 'Cerrar lote y empezar uno nuevo',
              onPressed:
                  state.cerrandoLote
                      ? null
                      : () => _confirmarCerrarLote(
                        context,
                        ref,
                        params,
                        state.saldoActual,
                      ),
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Ver cajas chicas anteriores',
              onPressed: () => _abrirHistorialLotes(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: notifier.cargar,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child:
                !state.cargado
                    ? (state.cargando
                        ? const Center(
                          key: ValueKey('cargando'),
                          child: CircularProgressIndicator(),
                        )
                        // Un error de lectura no es "todavía no hay movimientos".
                        : EstadoTareas.error(
                          key: const ValueKey('error'),
                          titulo: 'No se pudo leer el lote de caja chica',
                          error: state.errorCarga,
                          onReintentar: notifier.cargar,
                        ))
                    : state.items.isEmpty
                    ? const EstadoTareas(
                      key: ValueKey('vacio'),
                      icono: Icons.savings_outlined,
                      titulo: 'Todavía no hay movimientos en este lote',
                      detalle: 'Registra el primero con "Registrar egreso".',
                    )
                    // El ancho del cajón y no el de la ventana: el sidebar del
                    // dashboard se come 260 px.
                    : LayoutBuilder(
                      key: const ValueKey('lista'),
                      builder:
                          (context, cajon) => _LibroContable(
                            items: state.items,
                            esAncho:
                                cajon.maxWidth >= TareasBreakpoints.compactMax,
                          ),
                    ),
          ),
        ),
        // Un solo FAB: registrar un egreso es lo único que se hace aquí, y
        // cada uno se guarda en el momento. "Finalizar y cerrar tarea" se fue
        // el 2026-10-05: solo marcaba la ocurrencia del día como hecha, y eso
        // ahora lo hace el propio egreso (archivo SQL 78).
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'agregarEgreso',
          onPressed: () => _abrirFormularioEgreso(context, ref, params),
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Registrar egreso'),
        ),
        bottomNavigationBar: _BarraSaldo(state: state),
      ),
    );
  }
}

/// Barra fija con la plata del lote.
///
/// El saldo vivía en una tira de 28px bajo el título del AppBar, en 11px: es
/// el número con el que se decide si se puede pagar el próximo egreso, o sea
/// lo único que la pantalla realmente tiene que contestar, y estaba escrito
/// más chico que las descripciones de los movimientos. Aquí está siempre a la
/// vista mientras se scrollea la lista — mismo patrón que la barra de "Total
/// contado / Dif." de Arqueo de Caja, para que las dos pantallas de plata del
/// módulo se lean igual.
///
/// Los tres números juntos y no solo el saldo: "quedan 340" no dice nada sin
/// "de 1.000, con 12 egresos".
class _BarraSaldo extends StatelessWidget {
  final CajaChicaFlujoState state;

  const _BarraSaldo({required this.state});

  @override
  Widget build(BuildContext context) {
    // Sin plata no se puede registrar el próximo egreso: el saldo pasa al tono
    // de alerta del módulo en vez de quedar igual que cuando sobra.
    final sinSaldo = state.saldoActual <= 0;
    final tono =
        sinSaldo
            ? TareasColors.vencidoTexto(context)
            // El tono de caja chica y no el de "dato de SAP", que no es.
            : TareasColors.tipoTareaTexto(context, 7);

    return BarraAccionTareas(
      resumen: Wrap(
        spacing: Esp.l,
        runSpacing: Esp.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Cifra(
            etiqueta: 'Saldo inicial',
            valor: FormatoMoneda.monto.format(state.saldoInicial),
          ),
          _Cifra(
            etiqueta: 'Egresos (${state.cantidadEgresos})',
            valor: FormatoMoneda.monto.format(state.totalEgresos),
          ),
          _Cifra(
            etiqueta: 'Disponible',
            valor: FormatoMoneda.monto.format(state.saldoActual),
            color: tono,
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;
  final bool destacado;

  const _Cifra({
    required this.etiqueta,
    required this.valor,
    this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          valor,
          style: (destacado
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: destacado ? Peso.dato : Peso.titulo,
                fontFeatures: cifrasTabulares,
                color: color ?? scheme.onSurface,
              ),
        ),
      ],
    );
  }
}

/// Entrada suave para una fila que recién aparece en el listado (nuevo
/// egreso registrado) — cero costo si ya estaba en pantalla.
class _FilaAnimada extends StatelessWidget {
  final Widget child;

  const _FilaAnimada({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
      child: child,
    );
  }
}

/// La lista de movimientos, como un libro de caja.
///
/// Antes era una pila de tarjetas donde cada movimiento repetia la frase
/// "Saldo tras el movimiento: 2.959,00" en letra chica: para saber cuanto
/// entro, cuanto salio y con que quedaste habia que leer renglon por renglon y
/// sumar de memoria. Un libro de caja resuelve eso desde hace siglos con tres
/// columnas -entradas, salidas y saldo corriente- y los numeros alineados a la
/// derecha, que es lo que deja comparar magnitudes de un vistazo.
///
/// **Encabezado y totales fijos, asientos virtualizados.** Un lote llega a
/// tener 125 movimientos (medido en la base). Con el encabezado dentro del
/// scroll habia que subir hasta arriba para recordar que columna era cual, y
/// con todas las filas construidas de una el scroll y cada registro daban un
/// tiron. Aca el encabezado y la linea de totales viven FUERA del scroll y
/// solo se construyen los asientos visibles.
///
/// En el telefono no hay ancho para cinco columnas, asi que ahi el mismo dato
/// va apilado, con la misma alineacion.
class _LibroContable extends StatelessWidget {
  final List<CajaChicaEntity> items;
  final bool esAncho;

  const _LibroContable({
    required this.items,
    required this.esAncho,
  });

  /// Los anchos son los MISMOS para encabezado, asientos y totales: ahi esta
  /// toda la alineacion de la tabla.
  static const _anchos = <AnchoCol>[
    AnchoCol.fijo(96), // fecha
    AnchoCol.flexible(), // detalle
    AnchoCol.fijo(120), // entradas
    AnchoCol.fijo(120), // salidas
    AnchoCol.fijo(128), // saldo
  ];

  @override
  Widget build(BuildContext context) {
    if (!esAncho) {
      return ListView.builder(
        key: const ValueKey('libroCompacto'),
        // Abajo, el alto del FAB "Registrar egreso".
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, aireBajoFab),
        itemCount: items.length,
        itemBuilder:
            (context, i) => _FilaAnimada(
              key: ValueKey(items[i].idCC),
              child: _AsientoCompacto(item: items[i]),
            ),
      );
    }

    final totalIng = items.fold<double>(0, (a, i) => a + (i.montoIng ?? 0));
    final totalEg = items.fold<double>(0, (a, i) => a + (i.montoEg ?? 0));
    // El saldo final es el del ULTIMO asiento, no `totalIng - totalEg`: el
    // saldo lo lleva la base (tac_cajaChica.saldo) y recalcularlo aca seria
    // inventar una segunda fuente de verdad que puede discrepar.
    final saldoFinal = items.isEmpty ? 0.0 : (items.last.saldo ?? 0);

    return Padding(
      key: const ValueKey('libroAncho'),
      // Sin tope centrado: el libro usa todo el ancho. Abajo, el alto del
      // FAB, que tapaba la columna Saldo.
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, aireBajoFab),
      child: MarcoTabla(
        child: Column(
          children: [
            const EncabezadoTabla(
              anchos: _anchos,
              titulos: ['Fecha', 'Detalle', 'Entradas', 'Salidas', 'Saldo'],
              aLaDerecha: {2, 3, 4},
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder:
                    (context, i) => _AsientoDelLibro(
                      item: items[i],
                      anchos: _anchos,
                      rayado: i.isOdd,
                    ),
              ),
            ),
            _TotalesDelLibro(
              anchos: _anchos,
              totalIng: totalIng,
              totalEg: totalEg,
              saldoFinal: saldoFinal,
            ),
          ],
        ),
      ),
    );
  }
}

/// Un renglon del libro.
class _AsientoDelLibro extends StatelessWidget {
  final CajaChicaEntity item;
  final List<AnchoCol> anchos;
  final bool rayado;

  const _AsientoDelLibro({
    required this.item,
    required this.anchos,
    required this.rayado,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ing = item.montoIng ?? 0;
    final eg = item.montoEg ?? 0;
    final esIngreso = ing > 0;

    final meta = <String>[
      if (item.numFactura != null && item.numFactura! > 0)
        'Factura N.${item.numFactura}',
      if (item.numVale != null && item.numVale! > 0) 'Vale N.${item.numVale}',
    ].join(' - ');

    return FilaTabla(
      anchos: anchos,
      // Rayado de libro: las filas impares apenas tintadas. Ayuda a seguir el
      // renglon hasta la columna del saldo sin perder la linea.
      fondo:
          rayado
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : null,
      celdas: [
        Text(
          item.fecha == null
              ? '-'
              : FormatearFecha.formatearFecha(item.fecha!),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.descripcion ?? (esIngreso ? 'Saldo inicial' : 'Egreso'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (meta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  meta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        _Importe(
          valor: ing,
          color: TareasColors.realizadoTexto(context),
          enNegrita: esIngreso,
        ),
        _Importe(
          valor: eg,
          color: TareasColors.vencidoTexto(context),
          enNegrita: !esIngreso && eg > 0,
        ),
        _Importe(
          valor: item.saldo ?? 0,
          color: scheme.onSurface,
          enNegrita: false,
          siempreVisible: true,
        ),
      ],
    );
  }
}

/// La linea de cierre del libro. Vive FUERA del scroll: es el numero con el
/// que se decide si alcanza para el proximo egreso, y tener que buscarlo
/// scrolleando 125 renglones lo vuelve inutil.
class _TotalesDelLibro extends StatelessWidget {
  final List<AnchoCol> anchos;
  final double totalIng;
  final double totalEg;
  final double saldoFinal;

  const _TotalesDelLibro({
    required this.anchos,
    required this.totalIng,
    required this.totalEg,
    required this.saldoFinal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilaTabla(
      anchos: anchos,
      fondo: scheme.surfaceContainerHighest,
      borde: Border(top: BorderSide(color: scheme.outlineVariant)),
      celdas: [
        const SizedBox.shrink(),
        Text(
          'Totales',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        _Importe(
          valor: totalIng,
          color: TareasColors.realizadoTexto(context),
          enNegrita: true,
          siempreVisible: true,
        ),
        _Importe(
          valor: totalEg,
          color: TareasColors.vencidoTexto(context),
          enNegrita: true,
          siempreVisible: true,
        ),
        _Importe(
          valor: saldoFinal,
          color: scheme.onSurface,
          enNegrita: true,
          siempreVisible: true,
        ),
      ],
    );
  }
}


class _Importe extends StatelessWidget {
  final double valor;
  final Color color;
  final bool enNegrita;

  /// Un cero en la columna de entradas de un egreso no es información: es
  /// ruido. Se pinta una raya, como en un libro de papel.
  final bool siempreVisible;

  const _Importe({
    required this.valor,
    required this.color,
    required this.enNegrita,
    this.siempreVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (valor == 0 && !siempreVisible) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return Text(
      FormatoMoneda.monto.format(valor),
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: enNegrita ? FontWeight.w700 : FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// El mismo asiento, para pantallas donde cinco columnas no entran.
class _AsientoCompacto extends StatelessWidget {
  final CajaChicaEntity item;

  const _AsientoCompacto({required this.item});

  /// Fecha real + Nº factura/vale del movimiento — el backend ya los
  /// devuelve (p_list_tac_CajaChica ACCION='D', columnas fecha/numFactura/
  /// numVale de tac_cajaChica) y el formulario de egreso ya los captura
  /// (_FormularioEgreso más abajo); solo faltaba pintarlos aquí. Mismo hueco
  /// que las columnas de Vales en Arqueo: dato soportado de punta a punta,
  /// nunca mostrado en el listado.
  String? _metaLinea() {
    final partes = <String>[];
    if (item.fecha != null) {
      partes.add(FormatearFecha.formatearFecha(item.fecha!));
    }
    if (item.numFactura != null && item.numFactura! > 0) {
      partes.add('Factura Nº${item.numFactura}');
    }
    if (item.numVale != null && item.numVale! > 0) {
      partes.add('Vale Nº${item.numVale}');
    }
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = (item.montoIng ?? 0) > 0;
    final scheme = Theme.of(context).colorScheme;
    final meta = _metaLinea();
    final colorImporte =
        esIngreso
            ? TareasColors.realizadoTexto(context)
            : TareasColors.vencidoTexto(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La franja de color reemplaza al fondo tintado entero: marca si es
          // entrada o salida sin teñir el texto, que en la lista larga hacía
          // que todo pareciera un aviso.
          Container(
            width: 3,
            height: 34,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: colorImporte,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.descripcion ?? (esIngreso ? 'Saldo inicial' : 'Egreso'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (meta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      meta,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Importe y saldo alineados a la derecha y con cifras tabulares: es
          // la misma lectura vertical que da el libro en escritorio.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (esIngreso ? '+' : '−') +
                    FormatoMoneda.monto.format(
                      esIngreso ? item.montoIng! : (item.montoEg ?? 0),
                    ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorImporte,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Saldo ${FormatoMoneda.monto.format(item.saldo ?? 0)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormularioEgreso extends ConsumerStatefulWidget {
  final CajaChicaParams params;

  const _FormularioEgreso({required this.params});

  @override
  ConsumerState<_FormularioEgreso> createState() => _FormularioEgresoState();
}

/// Sin validaciones propias: monto mayor a cero, descripción, a quién se
/// entregó y que alcance el saldo los decide p_abm_tac_CajaChica 'R' (errores
/// 10 a 14), y su mensaje sale en el aviso. Marcelo, 2026-10-06: las reglas
/// de registro van en SQL, para cambiarlas sin recompilar la app.
class _FormularioEgresoState extends ConsumerState<_FormularioEgreso> {
  double? _monto;
  final _descripcionCtrl = TextEditingController();
  int? _codEmpDestino;
  int? _numFactura;
  int? _numVale;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaChicaFlujoProvider(widget.params));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Affordance de arrastre — la hoja ya soporta drag-to-dismiss por
        // default (showModalBottomSheet, sin un scroll que capture el
        // gesto antes), esto solo lo hace visible.
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Registrar egreso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo disponible: ${FormatoMoneda.monto.format(state.saldoActual)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged:
                        (v) => setState(() => _monto = double.tryParse(v)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _EmpleadoDestinoField(
                    onSeleccionado:
                        (codEmpleado) =>
                            setState(() => _codEmpDestino = codEmpleado),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'N° factura (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (v) => _numFactura = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'N° vale (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onChanged: (v) => _numVale = int.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          state.guardando
                              ? null
                              : () async {
                                final ok = await ref
                                    .read(
                                      cajaChicaFlujoProvider(
                                        widget.params,
                                      ).notifier,
                                    )
                                    .registrarEgreso(
                                      montoEg: _monto ?? 0,
                                      descripcion: _descripcionCtrl.text.trim(),
                                      codEmpDestino: _codEmpDestino,
                                      numFactura: _numFactura,
                                      numVale: _numVale,
                                    );
                                if (ok && context.mounted) {
                                  cerrarRuta(context);
                                } else {
                                  HapticFeedback.lightImpact();
                                }
                              },
                      child:
                          state.guardando
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                              : const Text('Registrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Picker "Empleado Destino" — el legacy usa un `<p:selectOneMenu
/// filter="true">` con nombre+cargo, no un id numérico tipeado a mano.
/// Búsqueda remota con debounce (no dispara en cada tecla), resultados en
/// una lista corta debajo del campo, y una vez elegido muestra el nombre
/// en vez del número — la persona nunca ve ni escribe un código crudo.
class _EmpleadoDestinoField extends StatefulWidget {
  final ValueChanged<int?> onSeleccionado;

  const _EmpleadoDestinoField({required this.onSeleccionado});

  @override
  State<_EmpleadoDestinoField> createState() => _EmpleadoDestinoFieldState();
}

class _EmpleadoDestinoFieldState extends State<_EmpleadoDestinoField> {
  final _ctrl = TextEditingController();
  final _repo = CajaChicaFlujoImpl();
  Timer? _debounce;
  bool _buscando = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _labelSeleccionado;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Nombre y cargo de un empleado del picker.
  ///
  /// **Las rutas importan y no son las obvias.** `p_list_Empleado @ACCION='Y'`
  /// devuelve columnas planas y `EmpleadoDao` las reparte a mano por el grafo:
  ///
  /// ```java
  /// temp.getPersona().setDatoPersona(rs.getString(4));
  /// temp.getEmpleadoCargo().getCargoSucursal().getCargo()
  ///     .setDescripcion(rs.getString(6));
  /// ```
  ///
  /// O sea que el nombre viene armado en `persona.datoPersona` —no en
  /// `nombres`/`apPaterno`, que ese SP no trae— y el cargo cuelga cuatro
  /// niveles abajo. Leyendo `persona.nombres` la rama existe (los objetos
  /// nacen con `= new X()`) pero está VACÍA, así que el picker caía siempre al
  /// respaldo y listaba "Empleado 172", "Empleado 104"… un menú de números
  /// donde había que elegir una persona.
  String _label(Map<String, dynamic> emp) {
    final persona = emp['persona'] as Map<String, dynamic>?;
    final nombre = (persona?['datoPersona'] as String?)?.trim() ?? '';

    final cargoDesc =
        ((emp['empleadoCargo'] as Map<String, dynamic>?)?['cargoSucursal']
                    as Map<String, dynamic>?)?['cargo']
                as Map<String, dynamic>?;
    final desc = (cargoDesc?['descripcion'] as String?)?.trim() ?? '';

    if (nombre.isEmpty) return 'Empleado ${emp['codEmpleado']}';
    return desc.isEmpty ? nombre : '$nombre - $desc';
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _buscando = true);
      try {
        final resultados = await _repo.buscarEmpleados(texto.trim());
        if (mounted) {
          setState(() {
            _resultados = resultados;
            _buscando = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _resultados = [];
            _buscando = false;
          });
        }
      }
    });
  }

  void _elegir(Map<String, dynamic> emp) {
    final codEmpleado = (emp['codEmpleado'] as num?)?.toInt();
    setState(() {
      _labelSeleccionado = _label(emp);
      _resultados = [];
      _ctrl.clear();
    });
    HapticFeedback.selectionClick();
    widget.onSeleccionado(codEmpleado);
  }

  @override
  Widget build(BuildContext context) {
    if (_labelSeleccionado != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Entregado a',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cambiar',
            onPressed: () {
              setState(() => _labelSeleccionado = null);
              widget.onSeleccionado(null);
            },
          ),
        ),
        child: Text(_labelSeleccionado!, overflow: TextOverflow.ellipsis),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: 'Entregado a — buscar por nombre',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _buscando
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : null,
          ),
          onChanged: _buscar,
        ),
        if (_resultados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _resultados.length,
              itemBuilder: (context, i) {
                final emp = _resultados[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    _label(emp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _elegir(emp),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// "Ver Cajas Chicas" del legacy — histórico de lotes de esta sucursal.
class _HistorialLotesDialog extends StatefulWidget {
  final int idBitTarea;

  const _HistorialLotesDialog({required this.idBitTarea});

  @override
  State<_HistorialLotesDialog> createState() => _HistorialLotesDialogState();
}

class _HistorialLotesDialogState extends State<_HistorialLotesDialog> {
  final _repo = CajaChicaFlujoImpl();
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _lotes = [];
  // Lote cuyo PDF se está generando en este momento (null = ninguno) — solo
  // ese botón muestra spinner y se deshabilitan los demás mientras dura.
  int? _generandoLote;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lotes = await _repo.obtenerHistorialLotes(widget.idBitTarea);
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  // Sigue siendo necesario como wrapper: el valor crudo llega como
  // `dynamic` (String ISO o null) desde el JSON del backend, algo que
  // FormatearFecha.formatearFecha (que espera un DateTime ya parseado) no
  // resuelve por sí solo.
  String _fmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : null;
    if (d == null) return '—';
    return FormatearFecha.formatearFecha(d);
  }

  /// "Generar PDF" del legacy (RptCajaChica), por fila del histórico.
  /// codSucursal viene de esta misma fila — ya resuelta server-side por
  /// /caja-chica/historial-lotes a partir del cargo vigente del empleado
  /// dueño de la ocurrencia, nunca de un valor tipeado a mano aquí.
  Future<void> _generarPdf(Map<String, dynamic> lote) async {
    final numLote = (lote['lote'] as num?)?.toInt();
    final codSucursal = (lote['codSucursal'] as num?)?.toInt();
    if (numLote == null) return;
    if (codSucursal == null) {
      HapticFeedback.lightImpact();
      mostrarAviso(
        context,
        'No se pudo determinar la sucursal de este lote.',
        tono: TonoAviso.error,
      );
      return;
    }

    setState(() => _generandoLote = numLote);
    try {
      final bytes = await _repo.generarReportePdf(
        lote: numLote,
        codSucursal: codSucursal,
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      await mostrarPdf(
        context,
        bytes: bytes,
        titulo: 'Caja chica — Lote $numLote',
        nombreArchivo: 'caja_chica_lote_$numLote.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      mostrarAviso(
        context,
        'No se pudo generar el reporte: $e',
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) setState(() => _generandoLote = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final altoDisponible = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      title: const Text('Cajas chicas anteriores'),
      content: SizedBox(
        width: (anchoDisponible - 80).clamp(240, 420),
        height: (altoDisponible * 0.5).clamp(220, 420),
        child:
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('No se pudo cargar: $_error'))
                : _lotes.isEmpty
                ? const Center(
                  child: Text('No hay lotes anteriores para esta sucursal.'),
                )
                : ListView.builder(
                  itemCount: _lotes.length,
                  itemBuilder: (context, i) {
                    final lote = _lotes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text('Lote ${lote['lote']}'),
                        subtitle: Text(
                          '${_fmt(lote['desde'])} – ${_fmt(lote['hasta'])} · ${lote['nombreSucursal'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bs ${FormatoMoneda.monto.format((lote['totalEgresos'] as num?)?.toDouble() ?? 0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: TareasColors.vencidoTexto(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _generandoLote == (lote['lote'] as num?)?.toInt()
                                ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : IconButton(
                                  icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Generar PDF',
                                  onPressed:
                                      _generandoLote != null
                                          ? null
                                          : () => _generarPdf(lote),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => cerrarRuta(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

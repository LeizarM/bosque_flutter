import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_comparativa.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Notas cerradas que todavía no se pagaron, y descarga de los reportes.
///
/// En Bosque v2 esta lista existía pero nunca se llenaba: el método que la
/// cargaba estaba comentado, así que el diálogo salía siempre vacío y lo único
/// que funcionaba era el PDF.
/// Lo que se escribió en el buscador de esta pestaña.
///
/// Propio y no `filtroBusquedaComisionProvider`: ese lo comparten Vendedores,
/// Grupos y Asignaciones, y el texto se arrastraría al cambiar de pestaña. Son
/// búsquedas distintas sobre datos distintos.
final filtroPendientesProvider = StateProvider.autoDispose<String>((_) => '');

/// Filtra por vendedor o por número de documento.
///
/// Con búsqueda activa se van también las filas de TOTAL: el SP las calcula
/// sobre TODAS las notas, así que junto a un detalle filtrado mostrarían un
/// número que no corresponde a lo que se está viendo. El conteo real de lo
/// visible va en la barra.
List<NotaPendienteEntity> _filtrar(
  List<NotaPendienteEntity> lista,
  String busqueda,
) {
  final q = busqueda.trim().toLowerCase();
  if (q.isEmpty) return lista;
  return lista
      .where(
        (n) =>
            !n.esTotal &&
            (n.nombreVen.toLowerCase().contains(q) ||
                (n.docNum?.toString().contains(q) ?? false) ||
                n.origen.toLowerCase().contains(q)),
      )
      .toList();
}

class _BuscadorPendientes extends StatelessWidget {
  const _BuscadorPendientes({
    required this.padding,
    required this.texto,
    required this.alBuscar,
    this.conteo,
  });

  final double padding;
  final String texto;
  final ValueChanged<String> alBuscar;

  /// Qué quedó a la vista. Null sin búsqueda: sin filtro no hay nada que
  /// aclarar, y el resumen de arriba ya da los totales.
  final String? conteo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 10),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                // Mismo tope que BarraModulo: sin él, en un monitor ancho el
                // campo se estira hasta ocupar toda la fila.
                constraints: const BoxConstraints(maxWidth: 360),
                child: TextFormField(
                  initialValue: texto,
                  onChanged: alBuscar,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar vendedor, documento o sistema',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
          if (conteo != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                conteo!,
                overflow: TextOverflow.ellipsis,
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TabPendientes extends ConsumerWidget {
  const TabPendientes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notas = ref.watch(notasPendientesProvider);
    final busqueda = ref.watch(filtroPendientesProvider);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La barra de reportes de comisiones pagadas vive solo en Preliminar.
        // Estaba tambien aca y era una repeticion sin publico: no hay ningun
        // usuario que abra Pendientes y no abra Preliminar -btnComPendientes
        // esta en cero para los 128 `lim`, y los 6 `adm` ven las ocho
        // pestanas-. El ERP viejo la repetia en sus cinco pestanas porque cada
        // una era independiente; aca es un widget compartido y con una vez
        // alcanza.
        _BuscadorPendientes(
          padding: padding,
          texto: busqueda,
          alBuscar:
              (v) => ref.read(filtroPendientesProvider.notifier).state = v,
          conteo: notas.whenOrNull(
            data: (l) {
              final visibles = _filtrar(l, busqueda);
              final detalle = visibles.where((n) => !n.esTotal).toList();
              if (busqueda.trim().isEmpty) return null;
              final suma = detalle.fold<double>(
                0,
                (a, n) => a + n.saldoPendiente,
              );
              return '${detalle.length} '
                  '${detalle.length == 1 ? 'nota' : 'notas'} · '
                  'Bs ${FormatoComision.monto.format(suma)}';
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: notas.when(
            loading:
                () => EstadoVista.cargandoTabla(
                  context,
                  // Ocho: las mismas que declara la DataTable de abajo. Un
                  // esqueleto con menos columnas hace saltar la tabla al
                  // llegar los datos.
                  columnas: 8,
                  filas: 7,
                ),
            error:
                (e, _) => EstadoVista.error(
                  context,
                  error: e,
                  alReintentar: () => ref.invalidate(notasPendientesProvider),
                ),
            data: (listaCruda) {
              final lista = _filtrar(listaCruda, busqueda);
              if (lista.isEmpty) {
                // Dos vacíos distintos y no se pueden decir igual: que no
                // quede nada por cobrar es una buena noticia; que la búsqueda
                // no encuentre nada es que hay que cambiar el texto. Con el
                // mensaje único, escribir un apellido mal tecleado anunciaba
                // que estaba todo pagado.
                final buscando = busqueda.trim().isNotEmpty;
                return EstadoVista.vacio(
                  context,
                  titulo:
                      buscando
                          ? 'Sin coincidencias'
                          : 'No hay notas pendientes',
                  indicacion:
                      buscando
                          ? 'Ninguna nota pendiente coincide con '
                              '«${busqueda.trim()}». Se busca por nombre de '
                              'vendedor, número de documento o sistema.'
                          : 'Todas las notas cerradas ya fueron pagadas.',
                  icono:
                      buscando
                          ? Icons.search_off_outlined
                          : Icons.check_circle_outline,
                  textoAccion: buscando ? 'Limpiar búsqueda' : null,
                  alPulsarAccion:
                      buscando
                          ? () =>
                              ref
                                  .read(filtroPendientesProvider.notifier)
                                  .state = ''
                          : null,
                );
              }
              return Column(
                children: [
                  _Resumen(notas: lista, padding: padding),
                  Expanded(
                    child:
                        esMovil
                            ? _Tarjetas(notas: lista, padding: padding)
                            : _Tabla(notas: lista, padding: padding),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Cifras de cabecera.
///
/// La tabla sola no dice cuanto se debe en total ni a cuanta gente: hay que
/// bajar hasta la ultima fila para enterarse. Estas tarjetas lo ponen arriba.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.notas, required this.padding});

  final List<NotaPendienteEntity> notas;
  final double padding;

  @override
  Widget build(BuildContext context) {
    // Solo el detalle: el SP ya emite filas de total y sumarlas contaria doble.
    final detalle = notas.where((n) => !n.esTotal).toList();
    final saldo = detalle.fold<double>(0, (a, n) => a + n.saldoPendiente);
    final vendedores = detalle.map((n) => n.nombreVen).toSet().length;

    final masAntigua = detalle
        .where((n) => n.fechaDoc != null)
        .fold<NotaPendienteEntity?>(
          null,
          (a, n) => a == null || n.fechaDoc!.isBefore(a.fechaDoc!) ? n : a,
        );

    final dias =
        masAntigua == null
            ? null
            : DateTime.now().difference(masAntigua.fechaDoc!).inDays;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 12),
      child: FranjaCifras(
        cifras: [
          TarjetaCifra(
            rotulo: 'Saldo pendiente',
            valor: 'Bs ${FormatoComision.monto.format(saldo)}',
            detalle: '${detalle.length} notas sin cobrar',
            icono: Icons.account_balance_wallet_outlined,
            destacada: true,
          ),
          TarjetaCifra(
            rotulo: 'Vendedores',
            valor: '$vendedores',
            detalle: 'con notas abiertas',
            icono: Icons.groups_outlined,
          ),
          if (dias != null)
            TarjetaCifra(
              rotulo: 'Nota mas antigua',
              valor: '$dias dias',
              detalle: FormatoComision.fecha.format(masAntigua!.fechaDoc!),
              icono: Icons.history,
            ),
        ],
      ),
    );
  }
}

// ── Reportes ──────────────────────────────────────────────────────────

// ── Tabla de escritorio ───────────────────────────────────────────────

class _Tabla extends StatelessWidget {
  const _Tabla({required this.notas, required this.padding});

  final List<NotaPendienteEntity> notas;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // La tarjeta llena el hueco en vez de flotar, y deja de estirarse en un
    // monitor ancho.
    //
    // Antes: SingleChildScrollView > Card > DataTable. El scroll recibe el alto
    // del Expanded pero pinta a la Card con su alto intrinseco y la ancla
    // arriba: con cuatro filas eran 224 px de tarjeta y ~700 de fondo pelado
    // debajo. La pagina se veia sin terminar.
    //
    // Los dos constraints van en el MISMO ConstrainedBox y no en dos anidados:
    // Align llama a constraints.loosen(), asi que un minHeight puesto por
    // encima del Align se pierde y la tarjeta se vuelve a encoger.
    //
    // El math.max no es adorno: en un hueco mas bajo que el padding, la resta
    // da negativo y el layout muere con "BoxConstraints has a negative minimum
    // height".
    return LayoutBuilder(
      builder: (context, hueco) {
        final alto = math.max(0.0, hueco.maxHeight - 36);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ComisionesTema.anchoTabla,
                minHeight: alto,
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: ComisionesTema.brContenedor,
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: ComisionesTema.brContenedor,
                  child: LayoutBuilder(
                    builder:
                        (context, limites) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            // La tabla ocupa todo el ancho disponible. Con un minimo fijo
                            // quedaba una franja vacia a la derecha en pantallas anchas.
                            // El ancho se mide FUERA del scroll horizontal: adentro
                            // limites.maxWidth es infinito, math.max lo propaga y el
                            // layout muere con "BoxConstraints forces an infinite width".
                            constraints: BoxConstraints(
                              minWidth: math.max(900, limites.maxWidth),
                            ),
                            child: DataTable(
                              columnSpacing: ComisionesTema.separacionColumnas,
                              dataRowMinHeight: ComisionesTema.altoFila,
                              dataRowMaxHeight: ComisionesTema.altoFila,
                              headingRowHeight: ComisionesTema.altoEncabezado,
                              headingRowColor: ComisionesTema.encabezadoTabla(
                                context,
                              ),
                              columns: const [
                                DataColumn(label: Text('Vendedor')),
                                DataColumn(label: Text('Documento')),
                                // El mismo rotulo que usa dialogo_notas_fila:
                                // es el mismo dato y tiene que llamarse igual.
                                DataColumn(label: Text('Sistema')),
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(
                                  label: Text('Total Bs'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text('Cerrado Bs'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text('Saldo Bs'),
                                  numeric: true,
                                ),
                              ],
                              rows: [
                                for (final n in notas)
                                  DataRow(
                                    onLongPress: () {},
                                    color:
                                        n.esTotal
                                            ? WidgetStatePropertyAll(
                                              n.esTotalGeneral
                                                  ? cs.primaryContainer
                                                      .withValues(alpha: 0.4)
                                                  : cs.surfaceContainerHighest
                                                      .withValues(alpha: 0.3),
                                            )
                                            : null,
                                    cells: [
                                      DataCell(
                                        Text(
                                          n.nombreVen,
                                          style: TextStyle(
                                            fontWeight:
                                                n.esTotal
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        NumeroCopiable(
                                          valor: n.docNum?.toString(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(n.origen.isEmpty ? '—' : n.origen),
                                      ),
                                      DataCell(
                                        Text(
                                          n.fechaDoc == null
                                              ? '—'
                                              : FormatoComision.fecha.format(
                                                n.fechaDoc!,
                                              ),
                                        ),
                                      ),
                                      DataCell(
                                        n.estado.isEmpty
                                            ? const Text('—')
                                            : _Etiqueta(texto: n.estado),
                                      ),
                                      DataCell(
                                        _Num(
                                          valor: n.montoTotalBs,
                                          negrita: n.esTotal,
                                        ),
                                      ),
                                      DataCell(
                                        _Num(
                                          valor: n.montoCerradoBs,
                                          negrita: n.esTotal,
                                        ),
                                      ),
                                      DataCell(
                                        _Num(
                                          valor: n.saldoPendiente,
                                          negrita: n.esTotal,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final abierta = texto.toLowerCase().startsWith('abier');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: abierta ? cs.tertiaryContainer : cs.surfaceContainerHighest,
        borderRadius: ComisionesTema.brChip,
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: abierta ? cs.onTertiaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num({required this.valor, this.negrita = false});

  final double valor;
  final bool negrita;

  @override
  Widget build(BuildContext context) {
    return Text(
      FormatoComision.monto.format(valor),
      style: ComisionesTema.numeroCelda(context, fuerte: negrita),
    );
  }
}

// ── Tarjetas para móvil ───────────────────────────────────────────────

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({required this.notas, required this.padding});

  final List<NotaPendienteEntity> notas;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
      itemCount: notas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = notas[i];
        return Card(
          elevation: 0,
          color: n.esTotal ? cs.surfaceContainerHigh : null,
          shape: RoundedRectangleBorder(
            borderRadius: ComisionesTema.brContenedor,
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.nombreVen,
                        style: tt.titleSmall?.copyWith(
                          fontWeight:
                              n.esTotal ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!n.esTotal && n.estado.isNotEmpty)
                      _Etiqueta(texto: n.estado),
                  ],
                ),
                if (!n.esTotal) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Doc ${n.docNum ?? '—'}'
                    '${n.origen.isEmpty ? '' : ' · ${n.origen}'}'
                    '${n.fechaDoc == null ? '' : '  ·  ${FormatoComision.fecha.format(n.fechaDoc!)}'}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Par(
                      etiqueta: 'Total',
                      valor: FormatoComision.monto.format(n.montoTotalBs),
                    ),
                    _Par(
                      etiqueta: 'Cerrado',
                      valor: FormatoComision.monto.format(n.montoCerradoBs),
                    ),
                    _Par(
                      etiqueta: 'Saldo',
                      valor: FormatoComision.monto.format(n.saldoPendiente),
                      destacado: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Par extends StatelessWidget {
  const _Par({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          valor,
          style: ComisionesTema.numeroCelda(context, fuerte: destacado),
        ),
      ],
    );
  }
}

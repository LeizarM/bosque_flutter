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

/// Texto del buscador de esta pestaña. Propio y no `filtroBusquedaComisionProvider`
/// (compartido por Vendedores, Grupos y Asignaciones): el texto se arrastraría al
/// cambiar de pestaña.
final filtroPendientesProvider = StateProvider.autoDispose<String>((_) => '');

/// Filtra por vendedor o número de documento. Con búsqueda activa se van también
/// las filas de TOTAL: el SP las calcula sobre TODAS las notas y, junto a un
/// detalle filtrado, mostrarían un número que no corresponde. El conteo real de
/// lo visible va en la barra.
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

/// Notas cerradas que todavía no se pagaron.
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
        // La barra de reportes de pagadas vive solo en Preliminar: nadie abre
        // Pendientes sin abrir Preliminar (btnComPendientes está en cero para los
        // 128 `lim`; los 6 `adm` ven las ocho pestañas). El ERP viejo la repetía en
        // cada pestaña.
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
                  // Ocho: las mismas columnas que declara la DataTable; con menos,
                  // la tabla salta al llegar los datos.
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
                // Dos vacíos distintos: que no quede nada por cobrar es buena
                // noticia; que la búsqueda no encuentre nada es que hay que cambiar
                // el texto (con mensaje único, un apellido mal tecleado anunciaba
                // que todo estaba pagado).
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

/// Cifras de cabecera: la tabla sola no dice cuánto se debe en total ni a
/// cuánta gente sin bajar hasta la última fila.
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

class _Tabla extends StatelessWidget {
  const _Tabla({required this.notas, required this.padding});

  final List<NotaPendienteEntity> notas;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // minHeight y maxWidth van en el MISMO ConstrainedBox (Align hace loosen() y
    // un minHeight por encima se pierde); el math.max evita un alto negativo.
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
                            // El ancho se mide FUERA del scroll horizontal: adentro
                            // maxWidth es infinito y math.max lo propaga
                            // ("BoxConstraints forces an infinite width").
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

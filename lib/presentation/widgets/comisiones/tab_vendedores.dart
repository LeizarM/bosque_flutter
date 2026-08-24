import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_vendedor.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Listado y mantenimiento de vendedores, con sus codigos por empresa SAP.
class TabVendedores extends ConsumerWidget {
  const TabVendedores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendedores = ref.watch(vendedoresComisionProvider);
    final busqueda = ref.watch(filtroBusquedaComisionProvider);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    // Cuantas filas se estan viendo. Se calcula sobre la lista ya
    // filtrada, que es lo que el usuario tiene delante; mientras carga
    // o si falla queda en null y no se dibuja, en vez de mostrar un
    // cero que no es cierto.
    final conteo = vendedores.whenOrNull(
      data: (l) {
        final n = _filtrar(l, busqueda).length;
        return n == 1 ? '1 vendedor' : '$n vendedores';
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraModulo(
          textoBusqueda: 'Buscar vendedor',
          conteo: conteo,
          textoAccion: 'Nuevo vendedor',
          alBuscar:
              (v) =>
                  ref.read(filtroBusquedaComisionProvider.notifier).state = v,
          alPulsarAccion:
              () => showDialog<void>(
                context: context,
                builder: (_) => const DialogoVendedor(),
              ),
        ),
        Expanded(
          child: vendedores.when(
            loading:
                () => EstadoVista.cargandoTabla(context, columnas: 5, filas: 7),
            error:
                (e, _) => EstadoVista.error(
                  context,
                  error: e,
                  alReintentar:
                      () => ref.invalidate(vendedoresComisionProvider),
                ),
            data: (lista) {
              final filtrada = _filtrar(lista, busqueda);

              if (filtrada.isEmpty) {
                return EstadoVista.vacio(
                  context,
                  titulo:
                      busqueda.isEmpty
                          ? 'Todavia no hay vendedores'
                          : 'Sin coincidencias',
                  indicacion:
                      busqueda.isEmpty
                          ? 'Registre un vendedor y sus codigos en cada empresa SAP.'
                          : 'Pruebe con otro nombre.',
                  icono: Icons.badge_outlined,
                  textoAccion: busqueda.isEmpty ? 'Nuevo vendedor' : null,
                  alPulsarAccion:
                      busqueda.isEmpty
                          ? () => showDialog<void>(
                            context: context,
                            builder: (_) => const DialogoVendedor(),
                          )
                          : null,
                );
              }

              return esMovil
                  ? _Tarjetas(vendedores: filtrada, padding: padding)
                  : _Tabla(vendedores: filtrada, padding: padding);
            },
          ),
        ),
      ],
    );
  }

  static List<VendedorComisionEntity> _filtrar(
    List<VendedorComisionEntity> lista,
    String busqueda,
  ) {
    if (busqueda.trim().isEmpty) return lista;
    final q = busqueda.toLowerCase();
    return lista.where((v) => v.nomVenSap.toLowerCase().contains(q)).toList();
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({required this.vendedores, required this.padding});

  final List<VendedorComisionEntity> vendedores;
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
        final alto = math.max(0.0, hueco.maxHeight - 24);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
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
                              minWidth: math.max(760, limites.maxWidth),
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
                                DataColumn(label: Text('Comision base')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Codigos SAP')),
                                DataColumn(label: Text('')),
                              ],
                              rows: [
                                for (final v in vendedores)
                                  DataRow(
                                    onLongPress: () {},
                                    cells: [
                                      DataCell(
                                        Text(
                                          v.nomVenSap,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        v.comisionVisual <= 0
                                            ? Text(
                                              '—',
                                              style: TextStyle(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            )
                                            : ChipPorcentaje(
                                              valor: v.comisionVisual,
                                            ),
                                      ),
                                      DataCell(
                                        Text(
                                          v.esInterno == 1
                                              ? 'Interno'
                                              : 'Externo',
                                        ),
                                      ),
                                      DataCell(_Codigos(vendedor: v)),
                                      DataCell(_Acciones(vendedor: v)),
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

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({required this.vendedores, required this.padding});

  final List<VendedorComisionEntity> vendedores;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 24),
      itemCount: vendedores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final v = vendedores[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: ComisionesTema.brContenedor,
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.nomVenSap,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _Acciones(vendedor: v),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (v.comisionVisual > 0)
                      ChipPorcentaje(valor: v.comisionVisual),
                    Text(
                      v.esInterno == 1 ? 'Interno' : 'Externo',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Codigos(vendedor: v),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Codigos del vendedor en cada empresa SAP.
class _Codigos extends StatelessWidget {
  const _Codigos({required this.vendedor});

  final VendedorComisionEntity vendedor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final codigos = vendedor.codigosPorEmpresa;

    if (codigos.isEmpty) {
      return const ChipEstado(
        texto: 'Sin codigos',
        tono: TonoChip.neutro,
        icono: Icons.link_off,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in codigos.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: ComisionesTema.brChip,
            ),
            child: Text(
              '${e.key} ${e.value}',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _Acciones extends ConsumerWidget {
  const _Acciones({required this.vendedor});

  final VendedorComisionEntity vendedor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed:
              () => showDialog<void>(
                context: context,
                builder: (_) => DialogoVendedor(vendedor: vendedor),
              ),
        ),
        IconButton(
          tooltip: 'Dar de baja',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _confirmarBaja(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmarBaja(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Dar de baja el vendedor'),
            content: Text(
              '"${vendedor.nomVenSap}" dejara de aparecer en nuevas asignaciones. '
              'Las comisiones ya calculadas no cambian.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Dar de baja'),
              ),
            ],
          ),
    );

    if (confirmado != true || !context.mounted) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .eliminarVendedor(vendedor.copyWith(audUsuario: BigInt.from(uid)));

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    avisar(
      context,
      ok
          ? 'Vendedor dado de baja.'
          : (estado.error ?? 'No se pudo dar de baja.'),
      esError: !ok,
    );
  }
}

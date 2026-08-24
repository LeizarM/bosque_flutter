import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_grupo.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Listado y mantenimiento de grupos de comision.
class TabGrupos extends ConsumerWidget {
  const TabGrupos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = ref.watch(gruposComisionProvider);
    final busqueda = ref.watch(filtroBusquedaComisionProvider);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    // Cuantas filas se estan viendo. Se calcula sobre la lista ya
    // filtrada, que es lo que el usuario tiene delante; mientras carga
    // o si falla queda en null y no se dibuja, en vez de mostrar un
    // cero que no es cierto.
    final conteo = grupos.whenOrNull(
      data: (l) {
        final n = _filtrar(l, busqueda).length;
        return n == 1 ? '1 grupo' : '$n grupos';
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraModulo(
          textoBusqueda: 'Buscar grupo',
          conteo: conteo,
          textoAccion: 'Nuevo grupo',
          alBuscar:
              (v) =>
                  ref.read(filtroBusquedaComisionProvider.notifier).state = v,
          alPulsarAccion: () => _abrirFormulario(context, ref),
        ),
        Expanded(
          child: grupos.when(
            loading:
                () => EstadoVista.cargandoTabla(context, columnas: 4, filas: 6),
            error:
                (e, _) => EstadoVista.error(
                  context,
                  error: e,
                  alReintentar: () => ref.invalidate(gruposComisionProvider),
                ),
            data: (lista) {
              final filtrada = _filtrar(lista, busqueda);

              if (filtrada.isEmpty) {
                return EstadoVista.vacio(
                  context,
                  titulo:
                      busqueda.isEmpty
                          ? 'Todavia no hay grupos'
                          : 'Sin coincidencias',
                  indicacion:
                      busqueda.isEmpty
                          ? 'Cree el primer grupo para poder asignarlo a los vendedores.'
                          : 'Pruebe con otro nombre.',
                  icono: Icons.folder_outlined,
                  textoAccion: busqueda.isEmpty ? 'Nuevo grupo' : null,
                  alPulsarAccion:
                      busqueda.isEmpty
                          ? () => _abrirFormulario(context, ref)
                          : null,
                );
              }

              return esMovil
                  ? _ListaTarjetas(grupos: filtrada, padding: padding)
                  : _Tabla(grupos: filtrada, padding: padding);
            },
          ),
        ),
      ],
    );
  }

  static List<GrupoComisionEntity> _filtrar(
    List<GrupoComisionEntity> lista,
    String busqueda,
  ) {
    if (busqueda.trim().isEmpty) return lista;
    final q = busqueda.toLowerCase();
    return lista.where((g) => g.grupo.toLowerCase().contains(q)).toList();
  }

  static Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    GrupoComisionEntity? grupo,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DialogoGrupo(grupo: grupo),
    );
  }
}

// ── Vista de escritorio ───────────────────────────────────────────────

class _Tabla extends ConsumerWidget {
  const _Tabla({required this.grupos, required this.padding});

  final List<GrupoComisionEntity> grupos;
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                              minWidth: math.max(720, limites.maxWidth),
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
                                DataColumn(label: Text('Grupo')),
                                DataColumn(label: Text('Porcentaje')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Destino')),
                                DataColumn(label: Text('Empresa')),
                                DataColumn(label: Text('')),
                              ],
                              rows: [
                                for (final g in grupos)
                                  DataRow(
                                    onLongPress: () {},
                                    cells: [
                                      DataCell(
                                        Text(
                                          g.grupo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ChipPorcentaje(
                                          valor: g.porcentajeVisual,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          g.esInterno == 1
                                              ? 'Interno'
                                              : 'Externo',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          g.esParaVenta == 1
                                              ? 'Venta'
                                              : 'Cobranza',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          g.siglaEmpresa.isEmpty
                                              ? 'Todas'
                                              : g.siglaEmpresa,
                                        ),
                                      ),
                                      DataCell(_Acciones(grupo: g)),
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

// ── Vista movil ───────────────────────────────────────────────────────

class _ListaTarjetas extends ConsumerWidget {
  const _ListaTarjetas({required this.grupos, required this.padding});

  final List<GrupoComisionEntity> grupos;
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 24),
      itemCount: grupos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final g = grupos[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: ComisionesTema.brContenedor,
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.grupo,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChipPorcentaje(valor: g.porcentajeVisual),
                          Text(
                            g.esInterno == 1 ? 'Interno' : 'Externo',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '·',
                            style: tt.bodySmall?.copyWith(color: cs.outline),
                          ),
                          Text(
                            g.esParaVenta == 1 ? 'Venta' : 'Cobranza',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Acciones(grupo: g),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Acciones por fila ─────────────────────────────────────────────────

class _Acciones extends ConsumerWidget {
  const _Acciones({required this.grupo});

  final GrupoComisionEntity grupo;

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
                builder: (_) => DialogoGrupo(grupo: grupo),
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
            title: const Text('Dar de baja el grupo'),
            content: Text(
              'El grupo "${grupo.grupo}" dejara de estar disponible para nuevas '
              'asignaciones. Las comisiones ya calculadas no cambian.',
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
    final acciones = ref.read(comisionesAccionesProvider.notifier);
    final ok = await acciones.eliminarGrupo(
      grupo.copyWith(audUsuario: BigInt.from(uid)),
    );

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    avisar(
      context,
      ok ? 'Grupo dado de baja.' : (estado.error ?? 'No se pudo dar de baja.'),
      esError: !ok,
    );
  }
}

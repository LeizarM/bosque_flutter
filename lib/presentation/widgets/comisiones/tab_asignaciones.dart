import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';

import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/barra_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_asignacion.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Asignaciones vigentes de grupo por vendedor.
///
/// Se agrupan por vendedor: un vendedor puede pertenecer a varios grupos y lo
/// que interesa revisar es su conjunto, no filas sueltas como en Bosque v2.
class TabAsignaciones extends ConsumerWidget {
  const TabAsignaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asignaciones = ref.watch(asignacionesVigentesProvider);
    final busqueda = ref.watch(filtroBusquedaComisionProvider);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    // Cuantas filas se estan viendo. Se calcula sobre la lista ya
    // filtrada, que es lo que el usuario tiene delante; mientras carga
    // o si falla queda en null y no se dibuja, en vez de mostrar un
    // cero que no es cierto.
    final conteo = asignaciones.whenOrNull(
      data: (l) {
        final n = _filtrar(l, busqueda).length;
        return n == 1 ? '1 asignacion' : '$n asignaciones';
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraModulo(
          textoBusqueda: 'Buscar vendedor o grupo',
          conteo: conteo,
          textoAccion: 'Asignar grupo',
          alBuscar:
              (v) =>
                  ref.read(filtroBusquedaComisionProvider.notifier).state = v,
          alPulsarAccion:
              () => showDialog<void>(
                context: context,
                builder: (_) => const DialogoAsignacion(),
              ),
        ),
        Expanded(
          child: asignaciones.when(
            loading:
                () => EstadoVista.cargandoTabla(context, columnas: 5, filas: 6),
            error:
                (e, _) => EstadoVista.error(
                  context,
                  error: e,
                  alReintentar:
                      () => ref.invalidate(asignacionesVigentesProvider),
                ),
            data: (lista) {
              final filtrada = _filtrar(lista, busqueda);

              if (filtrada.isEmpty) {
                return EstadoVista.vacio(
                  context,
                  titulo:
                      busqueda.isEmpty
                          ? 'Todavia no hay asignaciones'
                          : 'Sin coincidencias',
                  indicacion:
                      busqueda.isEmpty
                          ? 'Asigne un grupo a cada vendedor para que su comision se calcule.'
                          : 'Pruebe con otro nombre.',
                  icono: Icons.link_outlined,
                  textoAccion: busqueda.isEmpty ? 'Asignar grupo' : null,
                  alPulsarAccion:
                      busqueda.isEmpty
                          ? () => showDialog<void>(
                            context: context,
                            builder: (_) => const DialogoAsignacion(),
                          )
                          : null,
                );
              }

              final porVendedor = _agrupar(filtrada);

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(padding, 4, padding, 24),
                itemCount: porVendedor.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final entrada = porVendedor.entries.elementAt(i);
                  return _TarjetaVendedor(
                    vendedor: entrada.key,
                    asignaciones: entrada.value,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static List<GrupoXVendedorEntity> _filtrar(
    List<GrupoXVendedorEntity> lista,
    String busqueda,
  ) {
    if (busqueda.trim().isEmpty) return lista;
    final q = busqueda.toLowerCase();
    return lista
        .where(
          (a) =>
              a.nomVenSap.toLowerCase().contains(q) ||
              a.grupo.toLowerCase().contains(q),
        )
        .toList();
  }

  static Map<String, List<GrupoXVendedorEntity>> _agrupar(
    List<GrupoXVendedorEntity> lista,
  ) {
    final mapa = <String, List<GrupoXVendedorEntity>>{};
    for (final a in lista) {
      mapa.putIfAbsent(a.nomVenSap, () => []).add(a);
    }
    return mapa;
  }
}

class _TarjetaVendedor extends StatelessWidget {
  const _TarjetaVendedor({required this.vendedor, required this.asignaciones});

  final String vendedor;
  final List<GrupoXVendedorEntity> asignaciones;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ComisionesTema.brContenedor,
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vendedor,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  asignaciones.length == 1
                      ? '1 grupo'
                      : '${asignaciones.length} grupos',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final a in asignaciones) _FilaAsignacion(asignacion: a),
        ],
      ),
    );
  }
}

class _FilaAsignacion extends ConsumerWidget {
  const _FilaAsignacion({required this.asignacion});

  final GrupoXVendedorEntity asignacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = FormatoComision.fecha;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(asignacion.grupo, style: tt.bodyMedium),
                    ChipPorcentaje(valor: asignacion.porcentajeVisual),
                    ChipVigencia(vigente: asignacion.estaVigente),
                    if (asignacion.ignora)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer,
                          borderRadius: ComisionesTema.brChip,
                        ),
                        child: Text(
                          'No comisiona',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  asignacion.fechaFinalizacion == null
                      ? 'Desde ${fmt.format(asignacion.fechaInicio)}'
                      : 'Del ${fmt.format(asignacion.fechaInicio)} al ${fmt.format(asignacion.fechaFinalizacion!)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed:
                () => showDialog<void>(
                  context: context,
                  builder: (_) => DialogoAsignacion(asignacion: asignacion),
                ),
          ),
          IconButton(
            tooltip: 'Cerrar vigencia',
            icon: const Icon(Icons.event_busy_outlined, size: 20),
            onPressed: () => _cerrar(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cerrar la asignacion'),
            content: Text(
              '${asignacion.nomVenSap} dejara de comisionar por el grupo '
              '"${asignacion.grupo}" a partir de hoy.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );

    if (confirmado != true || !context.mounted) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .eliminarAsignacion(asignacion.copyWith(audUsuario: BigInt.from(uid)));

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    avisar(
      context,
      ok ? 'Asignacion cerrada.' : (estado.error ?? 'No se pudo cerrar.'),
      esError: !ok,
    );
  }
}

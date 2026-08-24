import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_rango.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/escala_rangos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Escala de comisión según los días que tardó el cliente en pagar.
///
/// La lectura es libre; el mantenimiento queda restringido a ROLE_ADM porque
/// tocar estos tramos cambia lo que se paga en todos los períodos que se
/// calculen de acá en adelante. El backend lo exige además del ocultamiento.
class TabRangos extends ConsumerWidget {
  const TabRangos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangos = ref.watch(rangosComisionProvider);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final esAdmin = ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM';

    return rangos.when(
      loading: () => EstadoVista.cargando(context, mensaje: 'Cargando escala'),
      error:
          (e, _) => EstadoVista.error(
            context,
            error: e,
            alReintentar: () => ref.invalidate(rangosComisionProvider),
          ),
      data: (lista) {
        if (lista.isEmpty) {
          return EstadoVista.vacio(
            context,
            titulo: 'No hay tramos cargados',
            indicacion:
                esAdmin
                    ? 'Defina el primer tramo para que la modalidad dinámica pueda calcular.'
                    : 'Pida a un administrador que cargue la escala.',
            icono: Icons.timeline_outlined,
            textoAccion: esAdmin ? 'Nuevo tramo' : null,
            alPulsarAccion:
                esAdmin
                    ? () => showDialog<void>(
                      context: context,
                      builder: (_) => const DialogoRango(),
                    )
                    : null,
          );
        }

        final porTipo = <String, List<ComisionPorRangoEntity>>{};
        for (final r in lista) {
          porTipo.putIfAbsent(r.tipo, () => []).add(r);
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
          children: [
            _Explicacion(esAdmin: esAdmin),
            const SizedBox(height: 18),
            for (final entrada in porTipo.entries) ...[
              _BloqueTipo(
                tipo: entrada.key,
                rangos: entrada.value,
                esAdmin: esAdmin,
              ),
              const SizedBox(height: 22),
            ],
            if (esAdmin)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed:
                      () => showDialog<void>(
                        context: context,
                        builder: (_) => const DialogoRango(),
                      ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo tramo'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Explicacion extends StatelessWidget {
  const _Explicacion({required this.esAdmin});

  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: ComisionesTema.brControl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esAdmin ? Icons.info_outline : Icons.lock_outline,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esAdmin
                      ? 'Estos tramos definen cuánto se paga según los días que tardó el cobro. '
                          'Modificarlos cambia el cálculo de los períodos que se ejecuten de acá '
                          'en adelante, no el de los ya pagados.'
                      : 'Estos tramos definen cuánto se paga según los días que tardó el cobro. '
                          'Solo un administrador puede modificarlos.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Días transcurridos hasta el cobro. A más demora, '
                        'menor comisión.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueTipo extends ConsumerWidget {
  const _BloqueTipo({
    required this.tipo,
    required this.rangos,
    required this.esAdmin,
  });

  final String tipo;
  final List<ComisionPorRangoEntity> rangos;
  final bool esAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ComisionesTema.brContenedor,
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tipo,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                Text(
                  rangos.length == 1 ? '1 tramo' : '${rangos.length} tramos',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 14),
            EscalaRangos(
              rangos: rangos,
              alto: ComisionesTema.esMovil(context) ? 72 : 110,
              alTocar:
                  esAdmin
                      ? (r) => showDialog<void>(
                        context: context,
                        builder: (_) => DialogoRango(rango: r),
                      )
                      : null,
            ),
            if (esAdmin) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              for (final r in rangos) _FilaRango(rango: r),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaRango extends ConsumerWidget {
  const _FilaRango({required this.rango});

  final ComisionPorRangoEntity rango;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(rango.rangoLegible, style: tt.bodyMedium)),
          Text(
            '${rango.comisionVisual.toStringAsFixed(2)} %',
            style: ComisionesTema.numeroCelda(context, fuerte: true),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed:
                () => showDialog<void>(
                  context: context,
                  builder: (_) => DialogoRango(rango: rango),
                ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _confirmar(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar el tramo'),
            content: Text(
              'Se elimina el tramo ${rango.rangoLegible} de ${rango.tipo}. '
              'Las notas que caían en ese rango dejarán de encontrar escala.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (ok != true || !context.mounted) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final hecho = await ref
        .read(comisionesAccionesProvider.notifier)
        .eliminarRango(rango.copyWith(audUsuario: BigInt.from(uid)));

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    avisar(
      context,
      hecho ? 'Tramo eliminado.' : (estado.error ?? 'No se pudo eliminar.'),
      esError: !hecho,
    );
  }
}

import 'package:bosque_flutter/core/state/planilla_incapacidad_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/filtros_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/resumen_revision.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/tabla_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/tarjeta_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desde este ancho del cajón va la tabla; por debajo, tarjetas. 1060 entra
/// en una laptop de 1366 con el sidebar abierto.
const double anchoTablaIncapacidad = 1060;

/// Marca o desmarca, y avisa solo si el servidor lo rechazó: el cambio de la
/// pastilla ya es la confirmación.
Future<void> marcarRevision(
  BuildContext context,
  WidgetRef ref,
  PlanillaIncapacidadEntity fila,
  bool revisado,
) async {
  final error = await ref
      .read(planillaIncapacidadProvider.notifier)
      .marcar(fila.idPIT, revisado);
  if (error != null && context.mounted) {
    mostrarAviso(context, textoParaUsuario(error), tono: TonoAviso.error);
  }
}

/// Escritorio: filtros y resumen fijos arriba, la tabla ocupa el resto.
class VistaAmpliaIncapacidad extends ConsumerWidget {
  const VistaAmpliaIncapacidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(planillaIncapacidadProvider);
    final estado = _estado(ref, s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FiltrosIncapacidad(),
        const SizedBox(height: Esp.l),
        if (s.filas.isNotEmpty) ...[
          _resumen(s),
          const SizedBox(height: Esp.l),
        ],
        _Recargando(visible: s.cargando && s.cargado),
        Expanded(
          child:
              estado ??
              TablaIncapacidad(
                filas: s.visibles,
                guardando: s.guardando,
                onMarcar: (f, v) => marcarRevision(context, ref, f, v),
              ),
        ),
      ],
    );
  }
}

/// Teléfono y tablet: todo en un solo scroll, para que la lista no quede en
/// un hueco debajo de los filtros.
class VistaCompactaIncapacidad extends ConsumerWidget {
  const VistaCompactaIncapacidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(planillaIncapacidadProvider);
    final estado = _estado(ref, s);
    final filas = s.visibles;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: FiltrosIncapacidad()),
        const SliverToBoxAdapter(child: SizedBox(height: Esp.l)),
        if (s.filas.isNotEmpty) ...[
          SliverToBoxAdapter(child: _resumen(s)),
          const SliverToBoxAdapter(child: SizedBox(height: Esp.l)),
        ],
        SliverToBoxAdapter(child: _Recargando(visible: s.cargando && s.cargado)),
        if (estado != null)
          SliverToBoxAdapter(child: SizedBox(height: 380, child: estado))
        else
          SliverList.separated(
            itemCount: filas.length,
            separatorBuilder: (_, __) => const SizedBox(height: Esp.m),
            itemBuilder:
                (context, i) => TarjetaIncapacidad(
                  fila: filas[i],
                  guardando: s.guardando.contains(filas[i].idPIT),
                  onMarcar: (v) => marcarRevision(context, ref, filas[i], v),
                ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Esp.l)),
      ],
    );
  }
}

Widget _resumen(PlanillaIncapacidadState s) => ResumenRevision(
  revisadas: s.revisadas,
  total: s.total,
  diasSeguro: s.diasSeguro,
  descuento: s.totalDescuento,
);

/// Lo que va en lugar de la lista cuando no hay lista; null si la hay.
Widget? _estado(WidgetRef ref, PlanillaIncapacidadState s) {
  final notifier = ref.read(planillaIncapacidadProvider.notifier);
  if (!s.cargado) {
    if (s.error == null) return const EsqueletoLista(filas: 6, altoFila: 64);
    return EstadoTareas.error(
      titulo: 'No se pudo leer la planilla de incapacidad',
      error: s.error,
      onReintentar: notifier.cargar,
    );
  }
  if (s.filas.isEmpty) {
    return const EstadoTareas(
      icono: Icons.event_busy_outlined,
      titulo: 'No hay bajas que empiecen en este rango',
      detalle:
          'Una baja aparece aquí cuando ya está ejecutada la planilla del mes '
          'en que empieza. Prueba con otro rango.',
    );
  }
  if (s.visibles.isEmpty) {
    final todoRevisado =
        s.filtro == FiltroRevision.pendientes && s.busqueda.isEmpty;
    return EstadoTareas(
      icono: todoRevisado ? Icons.task_alt : Icons.filter_alt_off_outlined,
      tono: todoRevisado ? TonoEstadoTareas.listo : TonoEstadoTareas.neutro,
      titulo:
          todoRevisado
              ? 'No queda nada pendiente en este rango'
              : 'Ninguna baja coincide con el filtro',
      detalle:
          todoRevisado
              ? 'Todas las bajas del rango están revisadas.'
              : 'Cambia la búsqueda o muestra todas las bajas del rango.',
      accion: TextButton.icon(
        onPressed: notifier.limpiarFiltros,
        icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
        label: const Text('Ver todas'),
      ),
    );
  }
  return null;
}

/// Hilo de progreso al actualizar sin borrar lo que ya se ve.
class _Recargando extends StatelessWidget {
  final bool visible;

  const _Recargando({required this.visible});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: visible ? const LinearProgressIndicator(minHeight: 3) : null,
  );
}

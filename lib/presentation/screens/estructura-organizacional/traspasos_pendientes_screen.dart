// Destino final: lib/presentation/screens/estructura-organizacional/traspasos_pendientes_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/traspasos_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Cambios de cargo sin resolver" — lo que se pierde cuando a alguien lo
/// mueven de puesto.
///
/// El generador de tareas mira SOLO el cargo más reciente del empleado. El día
/// que RR.HH. carga el cargo nuevo, las tareas del anterior dejan de generarse:
/// nadie las borra, simplemente no vuelven a salir, y nadie se entera. Medido
/// contra la base real: 26 empleados con un traspaso posible y 192 decisiones
/// esperando.
///
/// Esta pantalla no automatiza la decisión, la hace visible. Y avisa lo que
/// cuesta: las tareas se asignan A CARGOS, así que copiar una al cargo nuevo se
/// la da a TODA la gente de ese cargo, no solo a quien se movió. Ese número va
/// arriba de todo, antes de los botones, porque es la parte que se olvida.
///
/// Requiere el archivo SQL 39 (ACCION 'T' en p_list_tac_TarRuXCargo y en
/// p_abm_tac_TarRuXCargo).
class TraspasosPendientesScreen extends ConsumerWidget {
  const TraspasosPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(traspasosProvider);
    final notifier = ref.read(traspasosProvider.notifier);
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = TareasBreakpoints.columnasLista(ancho);
    final margen =
        ancho > TareasBreakpoints.contentMaxWidthSplit
            ? (ancho - TareasBreakpoints.contentMaxWidthSplit) / 2
            : 0.0;

    ref.listen(traspasosProvider, (previo, actual) {
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return TareasScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambios de cargo sin resolver'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: notifier.cargar,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: notifier.cargar,
          child:
              state.cargando && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? const _SinTraspasos()
                  : ListView(
                    padding: EdgeInsets.fromLTRB(
                      margen + 8,
                      12,
                      margen + 8,
                      24,
                    ),
                    children: [
                      _Explicacion(cantidad: state.items.length),
                      const SizedBox(height: 4),
                      for (var i = 0; i < state.items.length; i += columnas)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var c = 0; c < columnas; c++)
                              Expanded(
                                child:
                                    (i + c) < state.items.length
                                        ? _TarjetaTraspaso(
                                          traspaso: state.items[i + c],
                                          copiando: state.copiando,
                                          onCopiar: (
                                            idTarRuti,
                                            codCargo,
                                          ) async {
                                            final ok = await notifier.traspasar(
                                              idTarRuti: idTarRuti,
                                              codCargoDestino: codCargo,
                                            );
                                            if (ok && context.mounted) {
                                              HapticFeedback.selectionClick();
                                              mostrarAviso(
                                                context,
                                                'Tarea copiada al cargo nuevo.',
                                              );
                                            }
                                          },
                                        )
                                        : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _Explicacion extends StatelessWidget {
  final int cantidad;

  const _Explicacion({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        '$cantidad ${cantidad == 1 ? 'persona cambió' : 'personas cambiaron'} de cargo en el último año. '
        'Las tareas de su cargo anterior dejaron de generarse. Elige cuáles pasan al cargo nuevo.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _SinTraspasos extends StatelessWidget {
  const _SinTraspasos();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.task_alt, size: 56, color: scheme.outline),
        const SizedBox(height: 16),
        Text(
          'No hay cambios de cargo sin resolver.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TarjetaTraspaso extends StatelessWidget {
  final Traspaso traspaso;
  final int? copiando;
  final Future<void> Function(int idTarRuti, int codCargoDestino) onCopiar;

  const _TarjetaTraspaso({
    required this.traspaso,
    required this.copiando,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resuelto = traspaso.porDecidir == 0;

    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: FranjaAcento(
        color:
            resuelto
                ? TareasColors.realizadoTexto(context)
                : TareasColors.pendienteTexto(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      traspaso.nombreEmpleado,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (traspaso.fechaCambio != null)
                    Text(
                      FormatearFecha.formatearFecha(traspaso.fechaCambio!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // El movimiento en una línea: de dónde viene y a dónde fue.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    traspaso.cargoAnterior,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  Text(
                    traspaso.cargoNuevo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // La advertencia va ANTES de los botones, no como nota al pie:
              // copiar aquí no afecta solo a quien se movió.
              if (!resuelto)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TareasColors.pendiente(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 15,
                        color: TareasColors.pendienteTexto(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          traspaso.personasEnCargoNuevo == 1
                              ? 'Copiar aquí se lo asigna a la única persona de ${traspaso.cargoNuevo}.'
                              : 'Copiar aquí se lo asigna a las ${traspaso.personasEnCargoNuevo} personas de ${traspaso.cargoNuevo}, no solo a esta.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: TareasColors.pendienteTexto(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              for (final t in traspaso.tareas)
                _FilaTarea(
                  tarea: t,
                  copiando: copiando == t.idTarRuti,
                  habilitado: copiando == null,
                  onCopiar: () => onCopiar(t.idTarRuti, traspaso.codCargoNuevo),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaTarea extends StatelessWidget {
  final TareaDeTraspaso tarea;
  final bool copiando;
  final bool habilitado;
  final VoidCallback onCopiar;

  const _FilaTarea({
    required this.tarea,
    required this.copiando,
    required this.habilitado,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ya = tarea.yaEstaEnCargoNuevo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ya ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: ya ? TareasColors.realizadoTexto(context) : scheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (tarea.frecuencia != null)
                  Text(
                    tarea.frecuencia!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (ya)
            Text(
              'ya la tiene',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TareasColors.realizadoTexto(context),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            OutlinedButton(
              onPressed: habilitado ? onCopiar : null,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              child:
                  copiando
                      ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Copiar'),
            ),
        ],
      ),
    );
  }
}

// Destino final: lib/presentation/screens/tareas-rutinarias/coches_screen.dart
import 'package:bosque_flutter/core/state/coches_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgCoches del legacy. A diferencia de WizardTareas.java (que
/// cerraba la tarea al marcar CUALQUIER coche), acá el backend
/// (p_coches_marcarLlegada) recién cierra cuando el último coche pendiente
/// queda con respuesta — ver hallazgo de code-review, 2026-09-03.
class CochesScreen extends ConsumerWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const CochesScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (idTarRuti: idTarRuti, idBitTarea: idBitTarea);
    final state = ref.watch(cochesProvider(params));
    final notifier = ref.read(cochesProvider(params).notifier);
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 700;

    ref.listen(cochesProvider(params), (previo, actual) {
      if (actual.tareaCerrada && previo?.tareaCerrada != true) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Todos los coches quedaron revisados — tarea completada.');
        Navigator.of(context).pop(true);
      }
      if (actual.mensajeError != null && actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    final revisados = state.items.where((c) => c.yaMarcado).length;
    final total = state.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreTarea, overflow: TextOverflow.ellipsis),
        bottom: total == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$revisados de $total revisados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.85) ??
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: total == 0 ? 0 : revisados / total),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(TareasColors.realizadoTexto(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: state.cargando && state.items.isEmpty
              ? const Center(key: ValueKey('cargando'), child: CircularProgressIndicator())
              : state.items.isEmpty
                  ? Center(
                      key: const ValueKey('vacio'),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_car_outlined,
                                size: 56, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No hay coches activos configurados para tu sucursal.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Align(
                      key: const ValueKey('lista'),
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: esAncho ? 640 : double.infinity),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.items.length,
                          itemBuilder: (context, i) => _CocheCard(
                            coche: state.items[i],
                            guardando: state.guardandoIdCo == state.items[i].idCo,
                            onMarcar: (llego, obs) {
                              HapticFeedback.selectionClick();
                              notifier.marcarLlegada(state.items[i].idCo, llego, obs: obs);
                            },
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _CocheCard extends StatefulWidget {
  final CocheDelDiaEntity coche;
  final bool guardando;
  final void Function(int llego, String? obs) onMarcar;

  const _CocheCard({required this.coche, required this.guardando, required this.onMarcar});

  @override
  State<_CocheCard> createState() => _CocheCardState();
}

class _CocheCardState extends State<_CocheCard> {
  late final TextEditingController _obsCtrl = TextEditingController(text: widget.coche.obs);

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  /// El legacy deja editar la observación en cualquier momento, aunque ya se
  /// haya contestado ¿LLEGÓ? (ajax propio, sin relación con esa respuesta) —
  /// reenvía el `llego` YA guardado (nunca lo pisa) junto con el texto
  /// nuevo, reusando el mismo `onMarcar` que usa el botón SI/NO.
  void _guardarObs() {
    final llego = widget.coche.llego;
    if (llego == null) return;
    widget.onMarcar(llego, _obsCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coche;
    final scheme = Theme.of(context).colorScheme;
    final marcado = c.yaMarcado;

    final Color borderColor = marcado
        ? (c.llego == 1 ? TareasColors.realizado(context) : TareasColors.vencido(context))
        : scheme.outlineVariant;
    final Color fillColor = marcado
        ? (c.llego == 1 ? TareasColors.realizado(context) : TareasColors.vencido(context)).withValues(alpha: 0.35)
        : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: marcado ? 1.4 : 1),
        color: fillColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car_filled_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.marca ?? ''} ${c.clase ?? ''}'.trim().isEmpty
                            ? 'Coche'
                            : '${c.marca ?? ''} ${c.clase ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Placa ${c.placa ?? '—'} · ${c.color ?? ''} ${c.anio ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Editable SIEMPRE, marcado o no — en el legacy la observación
            // no depende de la respuesta ¿LLEGÓ? (ajax propio). Antes acá se
            // bloqueaba apenas se marcaba, una regresión real frente al
            // legacy.
            TextField(
              controller: _obsCtrl,
              maxLines: 1,
              onChanged: (_) => setState(() {}),
              onSubmitted: marcado ? (_) => _guardarObs() : null,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Observación (opcional)',
                border: const OutlineInputBorder(),
                suffixIcon: marcado && _obsCtrl.text.trim() != (widget.coche.obs ?? '').trim()
                    ? IconButton(
                        tooltip: 'Guardar observación',
                        icon: const Icon(Icons.save_outlined, size: 20),
                        onPressed: _guardarObs,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(sizeFactor: animation, axisAlignment: -1, child: child),
              ),
              child: widget.guardando
                  ? const Padding(
                      key: ValueKey('guardando'),
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                      ),
                    )
                  : marcado
                      ? Row(
                          key: const ValueKey('marcado'),
                          children: [
                            Icon(
                              c.llego == 1 ? Icons.check_circle : Icons.cancel,
                              color: c.llego == 1
                                  ? TareasColors.realizadoTexto(context)
                                  : TareasColors.vencidoTexto(context),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.llego == 1 ? 'Llegó' : 'No llegó',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: c.llego == 1
                                    ? TareasColors.realizadoTexto(context)
                                    : TareasColors.vencidoTexto(context),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('sinMarcar'),
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onMarcar(0, _obsCtrl.text.trim()),
                                icon: const Icon(Icons.close),
                                label: const Text('No llegó'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => widget.onMarcar(1, _obsCtrl.text.trim()),
                                icon: const Icon(Icons.check),
                                label: const Text('Llegó'),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

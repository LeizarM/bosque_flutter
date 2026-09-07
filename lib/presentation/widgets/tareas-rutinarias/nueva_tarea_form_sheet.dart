// Destino final: lib/presentation/widgets/tareas-rutinarias/nueva_tarea_form_sheet.dart
import 'package:bosque_flutter/core/state/dependientes_jefe_provider.dart';
import 'package:bosque_flutter/core/state/frecuencia_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja inferior con los datos de la nueva tarea, una vez ya elegidos los
/// dependientes. Separada de la lista de selección a propósito: dos
/// decisiones distintas (a quién / qué) no deberían competir por atención
/// en la misma pantalla.
class NuevaTareaFormSheet extends ConsumerStatefulWidget {
  final int cantidadSeleccionados;

  const NuevaTareaFormSheet({super.key, required this.cantidadSeleccionados});

  @override
  ConsumerState<NuevaTareaFormSheet> createState() =>
      _NuevaTareaFormSheetState();
}

class _NuevaTareaFormSheetState extends ConsumerState<NuevaTareaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  int? _idFrec;
  DateTime _fechaPartida = DateTime.now();
  DateTime _fechaInicioAsignacion = DateTime.now();
  DateTime? _fechaFinAsignacion;
  bool _permanente = true;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String _dateFmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _elegirFecha({required bool esFin}) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          esFin ? (_fechaFinAsignacion ?? DateTime.now()) : _fechaPartida,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    setState(() {
      if (esFin) {
        _fechaFinAsignacion = elegida;
      } else {
        _fechaPartida = elegida;
      }
    });
  }

  /// Fecha de INICIO de la asignación (tac_tarRuXCargo.fechaInicio) — antes
  /// quedaba implícita en "hoy" (el backend la defaultea si no llega), sin
  /// que el jefe pudiera elegir "empieza a regir desde tal fecha" como sí
  /// puede el admin desde el organigrama. Misma paridad ahora en las dos UI.
  Future<void> _elegirFechaInicioAsignacion() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaInicioAsignacion,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    setState(() => _fechaInicioAsignacion = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final frecuenciaState = ref.watch(frecuenciaProvider);
    final dependientesState = ref.watch(dependientesJefeProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nueva tarea rutinaria',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Se asignará a ${widget.cantidadSeleccionados} dependiente(s) elegido(s).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionCtrl,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Qué hay que hacer',
                  hintText: 'Ej: Revisar cierre de caja del día',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Describe la tarea.'
                            : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Con qué frecuencia',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (frecuenciaState.cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (frecuenciaState.mensajeError != null)
                // Antes esto se quedaba en blanco sin avisar nada — un error
                // de red acá se veía idéntico a "no hay frecuencias".
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No se pudieron cargar las frecuencias. Desliza para reintentar.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        onPressed:
                            () =>
                                ref.read(frecuenciaProvider.notifier).cargar(),
                      ),
                    ],
                  ),
                )
              else if (frecuenciaState.items.isEmpty)
                Text(
                  'No hay frecuencias activas configuradas.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      frecuenciaState.items.map((f) {
                        final elegido = _idFrec == f.idFrec;
                        return ChoiceChip(
                          selected: elegido,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _idFrec = f.idFrec);
                          },
                          label: Text(f.descripcion ?? 'Sin nombre'),
                          backgroundColor: TareasColors.frecuencia(
                            context,
                            f.idFrec,
                          ),
                          selectedColor: TareasColors.frecuencia(
                            context,
                            f.idFrec,
                          ),
                          labelStyle: TextStyle(
                            color: TareasColors.frecuenciaTexto(
                              context,
                              f.idFrec,
                            ),
                            fontWeight:
                                elegido ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color:
                                elegido
                                    ? TareasColors.frecuenciaTexto(
                                      context,
                                      f.idFrec,
                                    )
                                    : Colors.transparent,
                            width: 1.4,
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 16),
              Text(
                'Empieza a repetirse desde',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _elegirFecha(esFin: false),
                icon: const Icon(Icons.event_outlined),
                label: Text(_dateFmt(_fechaPartida)),
              ),
              const SizedBox(height: 16),
              Text(
                'Vigencia de la asignación',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Empieza a regir desde',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _elegirFechaInicioAsignacion,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_dateFmt(_fechaInicioAsignacion)),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _permanente,
                onChanged:
                    (v) => setState(() {
                      _permanente = v;
                      if (v) _fechaFinAsignacion = null;
                    }),
                title: const Text('Permanente'),
                subtitle: Text(
                  _permanente
                      ? 'Se sigue generando hasta que la desactives.'
                      : 'Deja de generarse después de una fecha.',
                ),
              ),
              if (!_permanente)
                OutlinedButton.icon(
                  onPressed: () => _elegirFecha(esFin: true),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(
                    _fechaFinAsignacion == null
                        ? 'Elegir fecha de fin'
                        : _dateFmt(_fechaFinAsignacion!),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      dependientesState.guardando
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_idFrec == null) {
                              HapticFeedback.lightImpact();
                              mostrarAviso(
                                context,
                                'Elige una frecuencia.',
                                tono: TonoAviso.aviso,
                              );
                              return;
                            }
                            final ok = await ref
                                .read(dependientesJefeProvider.notifier)
                                .registrarTarea(
                                  descripcion: _descripcionCtrl.text.trim(),
                                  idFrec: _idFrec!,
                                  fechaPartida: _fechaPartida,
                                  fechaInicioAsignacion: _fechaInicioAsignacion,
                                  fechaFinAsignacion: _fechaFinAsignacion,
                                );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                  icon:
                      dependientesState.guardando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.check),
                  label: Text(
                    dependientesState.guardando ? 'Guardando…' : 'Crear tarea',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

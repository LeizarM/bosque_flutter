// Destino final: lib/presentation/screens/estructura-organizacional/tareas_rutinarias_por_cargo_screen.dart
import 'package:bosque_flutter/core/state/accion_tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/frecuencia_provider.dart';
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/tareas_por_cargo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgTarFunXCargo de WizardEstOrg.java (legacy) — solo el lado
/// "TAREAS RUTINARIA" del diálogo original. La pestaña "FUNCIONES" del
/// legacy (tb_funcion/tb_cargoXFuncion) es un subsistema aparte, sin
/// relación con tac_*, y queda fuera de este alcance a pedido de Marcelo.
///
/// Admin/RRHH-only (mismo gate que registrar-tar-ru-x-cargo): a diferencia
/// de "Programar tarea a mi equipo" (jefe, subárbol propio), acá se puede
/// asignar/editar/copiar para CUALQUIER cargo de la empresa.
class TareasRutinariasPorCargoScreen extends ConsumerWidget {
  final CargoEntity cargo;

  const TareasRutinariasPorCargoScreen({super.key, required this.cargo});

  String _dateFmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tareasRutinariasPorCargoProvider(cargo.codCargo));
    final notifier = ref.read(
      tareasRutinariasPorCargoProvider(cargo.codCargo).notifier,
    );

    ref.listen(tareasRutinariasPorCargoProvider(cargo.codCargo), (prev, next) {
      if (next.mensajeError != null &&
          next.mensajeError != prev?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, next.mensajeError!, tono: TonoAviso.error);
      } else if (next.mensajeExito != null &&
          next.mensajeExito != prev?.mensajeExito) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, next.mensajeExito!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tareas rutinarias — ${cargo.descripcion}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule_folder_outlined),
            tooltip: 'Acciones de tarea rutinaria (catálogo)',
            onPressed: () => _abrirAccionesCatalogo(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          _abrirCrearTarea(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea rutinaria'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildBody(context, ref, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TareasPorCargoState state,
    TareasPorCargoNotifier notifier,
  ) {
    if (state.cargando && state.items.isEmpty) {
      return const Center(
        key: ValueKey('cargando'),
        child: CircularProgressIndicator(),
      );
    }

    if (state.mensajeError != null && state.items.isEmpty) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('No se pudieron cargar las tareas de este cargo.'),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: notifier.cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        key: const ValueKey('vacio'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Este cargo todavía no tiene tareas rutinarias asignadas.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _abrirCrearTarea(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Agregar la primera'),
              ),
            ],
          ),
        ),
      );
    }

    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 900;

    return RefreshIndicator(
      key: const ValueKey('contenido'),
      onRefresh: notifier.cargar,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: esAncho ? (anchoDisponible - 900) / 2 + 12 : 12,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          final fila = state.items[i];
          final idFrec = (fila['idFrec'] as num?)?.toInt();
          final estadoActivo = ((fila['estado'] as num?)?.toInt() ?? 1) == 1;
          return TweenAnimationBuilder<double>(
            key: ValueKey(fila['idTarXCargo']),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + (i.clamp(0, 8) * 25)),
            curve: Curves.easeOut,
            builder:
                (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 8),
                    child: child,
                  ),
                ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color:
                        estadoActivo
                            ? TareasColors.realizado(context)
                            : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    (fila['descripcion'] as String?) ?? 'Sin descripción',
                    style: TextStyle(
                      decoration:
                          estadoActivo ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (idFrec != null)
                          Chip(
                            label: Text(
                              (fila['descripcionFrecuencia'] as String?) ??
                                  'Frecuencia $idFrec',
                            ),
                            backgroundColor: TareasColors.frecuencia(
                              context,
                              idFrec,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: TareasColors.frecuenciaTexto(
                                context,
                                idFrec,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        Text(
                          'Desde: ${_dateFmt(DateTime.tryParse((fila['fechaPartida'] ?? '').toString()))}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  leading: Switch(
                    value: estadoActivo,
                    onChanged:
                        state.guardando
                            ? null
                            : (_) {
                              HapticFeedback.selectionClick();
                              notifier.toggleEstado(fila);
                            },
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Más acciones',
                    onSelected: (opcion) {
                      if (opcion == 'editar') {
                        _abrirEditarTarea(context, ref, fila);
                      } else if (opcion == 'copiar') {
                        _abrirCopiarACargos(context, ref, fila);
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(
                            value: 'editar',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'copiar',
                            child: ListTile(
                              leading: Icon(Icons.copy_all_outlined),
                              title: Text('Copiar a otros cargos'),
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _abrirCrearTarea(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CrearTareaPorCargoSheet(codCargo: cargo.codCargo),
    );
  }

  void _abrirEditarTarea(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fila,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => _EditarTareaDialog(
            fila: fila,
            onGuardado:
                () =>
                    ref
                        .read(
                          tareasRutinariasPorCargoProvider(
                            cargo.codCargo,
                          ).notifier,
                        )
                        .cargar(),
          ),
    );
  }

  void _abrirCopiarACargos(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fila,
  ) {
    final idTarRuti = (fila['idTarRuti'] as num).toInt();
    showDialog(
      context: context,
      builder:
          (context) => CopiarACargosDialog(
            idTarRuti: idTarRuti,
            nombreTarea: (fila['descripcion'] as String?) ?? 'esta tarea',
            codEmpresa: cargo.codEmpresa,
            onCopiado:
                (destinos) => ref
                    .read(
                      tareasRutinariasPorCargoProvider(cargo.codCargo).notifier,
                    )
                    .copiarACargos(idTarRuti, destinos),
          ),
    );
  }

  void _abrirAccionesCatalogo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AccionesTareaRutinariaDialog(),
    );
  }
}

// ============================================================================
// Hoja "Agregar Tarea Rutinaria" — crea la tarea y la asigna a ESTE cargo.
// ============================================================================
class _CrearTareaPorCargoSheet extends ConsumerStatefulWidget {
  final int codCargo;

  const _CrearTareaPorCargoSheet({required this.codCargo});

  @override
  ConsumerState<_CrearTareaPorCargoSheet> createState() =>
      _CrearTareaPorCargoSheetState();
}

class _CrearTareaPorCargoSheetState
    extends ConsumerState<_CrearTareaPorCargoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  int? _idFrec;
  DateTime _fechaPartida = DateTime.now();

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String _dateFmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final frecuenciaState = ref.watch(frecuenciaProvider);
    final estado = ref.watch(tareasRutinariasPorCargoProvider(widget.codCargo));

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
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionCtrl,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Qué hay que hacer',
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
                const LinearProgressIndicator()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      frecuenciaState.items.map((f) {
                        final elegido = _idFrec == f.idFrec;
                        return ChoiceChip(
                          selected: elegido,
                          onSelected: (_) => setState(() => _idFrec = f.idFrec),
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
                onPressed: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaPartida,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (elegida != null) setState(() => _fechaPartida = elegida);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(_dateFmt(_fechaPartida)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      estado.guardando
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
                                .read(
                                  tareasRutinariasPorCargoProvider(
                                    widget.codCargo,
                                  ).notifier,
                                )
                                .crearTarea(
                                  descripcion: _descripcionCtrl.text.trim(),
                                  idFrec: _idFrec!,
                                  fechaPartida: _fechaPartida,
                                );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  icon:
                      estado.guardando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check),
                  label: Text(estado.guardando ? 'Guardando…' : 'Crear tarea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Diálogo "Editar" — descripción/frecuencia/fecha de partida de una tarea ya
// existente. Reusa tareaRutinariaProvider (CRUD estándar), no un endpoint
// nuevo.
// ============================================================================
class _EditarTareaDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> fila;
  final VoidCallback onGuardado;

  const _EditarTareaDialog({required this.fila, required this.onGuardado});

  @override
  ConsumerState<_EditarTareaDialog> createState() => _EditarTareaDialogState();
}

class _EditarTareaDialogState extends ConsumerState<_EditarTareaDialog> {
  late final TextEditingController _descripcionCtrl;
  int? _idFrec;
  late DateTime _fechaPartida;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl = TextEditingController(
      text: (widget.fila['descripcion'] as String?) ?? '',
    );
    _idFrec = (widget.fila['idFrec'] as num?)?.toInt();
    _fechaPartida =
        DateTime.tryParse((widget.fila['fechaPartida'] ?? '').toString()) ??
        DateTime.now();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frecuenciaState = ref.watch(frecuenciaProvider);
    return AlertDialog(
      title: const Text('Editar tarea rutinaria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descripcionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  frecuenciaState.items.map((f) {
                    return ChoiceChip(
                      selected: _idFrec == f.idFrec,
                      onSelected: (_) => setState(() => _idFrec = f.idFrec),
                      label: Text(f.descripcion ?? '—'),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _guardando
                  ? null
                  : () async {
                    setState(() => _guardando = true);
                    final ok = await ref
                        .read(tareaRutinariaProvider.notifier)
                        .guardar(
                          TareaRutinariaEntity(
                            idTarRuti:
                                (widget.fila['idTarRuti'] as num).toInt(),
                            idFrec: _idFrec,
                            idArea: (widget.fila['idArea'] as num?)?.toInt(),
                            fechaPartida: _fechaPartida,
                            idATR: (widget.fila['idATR'] as num?)?.toInt(),
                            descripcion: _descripcionCtrl.text.trim(),
                            audUsuario: 0,
                          ),
                        );
                    if (ok) HapticFeedback.mediumImpact();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (ok) {
                        widget.onGuardado();
                        mostrarAviso(context, 'Tarea actualizada.');
                      } else {
                        mostrarAviso(
                          context,
                          'No se pudo actualizar la tarea.',
                          tono: TonoAviso.error,
                        );
                      }
                    }
                  },
          child:
              _guardando
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ============================================================================
// Diálogo "Agregar Acciones Tarea Rutinaria" — catálogo de
// tac_accionTareaRutinaria. CRUD ya construido en accionTareaRutinariaProvider,
// esto es solo la UI que faltaba.
// ============================================================================
class _AccionesTareaRutinariaDialog extends ConsumerStatefulWidget {
  const _AccionesTareaRutinariaDialog();

  @override
  ConsumerState<_AccionesTareaRutinariaDialog> createState() =>
      _AccionesTareaRutinariaDialogState();
}

class _AccionesTareaRutinariaDialogState
    extends ConsumerState<_AccionesTareaRutinariaDialog> {
  final _nuevaCtrl = TextEditingController();

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accionTareaRutinariaProvider);
    final codUsuario = ref.watch(userProvider)?.codUsuario ?? 0;
    final anchoDisponible = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: const Text('Acciones de tarea rutinaria (catálogo)'),
      content: SizedBox(
        width: (anchoDisponible - 80).clamp(240, 400),
        height: 420,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nueva acción...',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () async {
                    final texto = _nuevaCtrl.text.trim();
                    if (texto.isEmpty) return;
                    final ok = await ref
                        .read(accionTareaRutinariaProvider.notifier)
                        .guardar(
                          AccionTareaRutinariaEntity(
                            idATR: 0,
                            descripcionAccion: texto,
                            estado: 1,
                            audUsuario: codUsuario,
                          ),
                        );
                    if (ok) _nuevaCtrl.clear();
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child:
                  state.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, i) {
                          final a = state.items[i];
                          final activo = (a.estado ?? 1) == 1;
                          return ListTile(
                            dense: true,
                            title: Text(
                              a.descripcionAccion,
                              style: TextStyle(
                                decoration:
                                    activo ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            trailing: Switch(
                              value: activo,
                              onChanged:
                                  (_) => ref
                                      .read(
                                        accionTareaRutinariaProvider.notifier,
                                      )
                                      .guardar(
                                        a.copyWith(
                                          estado: activo ? 0 : 1,
                                          audUsuario: codUsuario,
                                        ),
                                      ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

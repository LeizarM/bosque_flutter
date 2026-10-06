// Destino final: lib/presentation/screens/estructura-organizacional/tareas_rutinarias_por_cargo_screen.dart
import 'package:bosque_flutter/core/state/accion_tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/frecuencia_provider.dart';
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/tareas_por_cargo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/elegir_tarea_del_catalogo_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/crear_tarea_por_cargo_sheet.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgTarFunXCargo de WizardEstOrg.java (legacy) — solo el lado
/// "TAREAS RUTINARIA" del diálogo original. La pestaña "FUNCIONES" del
/// legacy (tb_funcion/tb_cargoXFuncion) es un subsistema aparte, sin
/// relación con tac_*, y queda fuera de este alcance a pedido de Marcelo.
///
/// Admin/RRHH-only (mismo gate que registrar-tar-ru-x-cargo): a diferencia
/// de "Programar tarea a mi equipo" (jefe, subárbol propio), aquí se puede
/// asignar/editar/copiar para CUALQUIER cargo de la empresa.
/// Filtro por frecuencia. `null` = todas.
///
/// Vive en un provider y no en un StatefulWidget para no convertir toda la
/// pantalla: es estado de interfaz, se descarta al salir, y va por cargo
/// porque abrir otro cargo no deberia heredar el filtro del anterior.
final filtroFrecuenciaPorCargo =
    StateProvider.autoDispose.family<int?, int>((ref, codCargo) => null);

/// Filtro por estado. `null` = todas, `true` solo activas, `false` solo
/// inactivas.
final filtroActivoPorCargo =
    StateProvider.autoDispose.family<bool?, int>((ref, codCargo) => null);

class TareasRutinariasPorCargoScreen extends ConsumerWidget {
  final CargoEntity cargo;

  const TareasRutinariasPorCargoScreen({super.key, required this.cargo});

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

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: cargo.descripcion,
          subtitulo:
              state.items.isEmpty
                  ? 'Tareas rutinarias del cargo'
                  : 'Tareas rutinarias del cargo · '
                      '${state.items.where((f) => ((f['estado'] as num?)?.toInt() ?? 1) == 1).length} activas',
          insignia: InsigniaTarea.modulo(context, Icons.badge_outlined),
          acciones: [
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Acciones de tarea rutinaria (catálogo)',
              onPressed: () => _abrirAccionesCatalogo(context),
            ),
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: notifier.cargar,
            ),
          ],
          bottom:
              state.items.isEmpty
                  ? null
                  : PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: _BarraFiltros(codCargo: cargo.codCargo, items: state.items),
                  ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.selectionClick();
            _elegirComoAgregar(context, ref);
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar tarea rutinaria'),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // El ancho del cajón y no el de la ventana: el sidebar del
          // dashboard se come 260 px.
          child: LayoutBuilder(
            builder:
                (context, cajon) =>
                    _buildBody(context, ref, state, notifier, cajon.maxWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TareasPorCargoState state,
    TareasPorCargoNotifier notifier,
    double anchoDisponible,
  ) {
    if (state.cargando && state.items.isEmpty) {
      return const Center(
        key: ValueKey('cargando'),
        child: CircularProgressIndicator(),
      );
    }

    if (state.mensajeError != null && state.items.isEmpty) {
      return EstadoTareas.error(
        key: const ValueKey('error'),
        titulo: 'No se pudieron cargar las tareas de este cargo',
        error: state.mensajeError,
        onReintentar: notifier.cargar,
      );
    }

    if (state.items.isEmpty) {
      return EstadoTareas(
        key: const ValueKey('vacio'),
        icono: Icons.assignment_outlined,
        titulo: 'Este cargo todavía no tiene tareas rutinarias asignadas',
        accion: FilledButton.icon(
          onPressed: () => _abrirCrearTarea(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Agregar la primera'),
        ),
      );
    }

    // La tabla pide mas aire que las tarjetas: por debajo de esto las seis
    // columnas se pisan y se lee peor que una lista.
    final enTabla = anchoDisponible >= TareasBreakpoints.wideMax;

    final filas = _aplicarFiltros(ref, state.items);

    if (filas.isEmpty) {
      // Se distingue de "este cargo no tiene tareas": aqui SI tiene, y lo que
      // falta es sacar un filtro. Decir lo mismo en los dos casos manda a
      // buscar un problema que no existe.
      return EstadoTareas(
        key: const ValueKey('sinCoincidencias'),
        icono: Icons.filter_alt_off_outlined,
        titulo:
            'Ninguna de las ${state.items.length} tareas de este cargo '
            'coincide con los filtros',
        accion: TextButton.icon(
          onPressed: () {
            ref.read(filtroFrecuenciaPorCargo(cargo.codCargo).notifier).state =
                null;
            ref.read(filtroActivoPorCargo(cargo.codCargo).notifier).state =
                null;
          },
          icon: const Icon(Icons.clear_all),
          label: const Text('Quitar filtros'),
        ),
      );
    }

    if (enTabla) {
      return RefreshIndicator(
        key: const ValueKey('tabla'),
        onRefresh: notifier.cargar,
        child: Padding(
          // Abajo, el alto del FAB "Agregar tarea rutinaria": tapaba el
          // menú de la última fila.
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, aireBajoFab),
          child: MarcoTabla(
            child: Column(
              children: [
                const EncabezadoTabla(
                  anchos: _anchosCargo,
                  titulos: [
                    'Activa',
                    'Tarea',
                    'Frecuencia',
                    'Asignada desde',
                    'Hasta',
                    '',
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filas.length,
                    itemBuilder:
                        (context, i) => _FilaTablaTarea(
                          fila: filas[i],
                          guardando: state.guardando,
                          onToggle: () {
                            HapticFeedback.selectionClick();
                            notifier.toggleEstado(filas[i]);
                          },
                          onEditar:
                              () => _abrirEditarTarea(context, ref, filas[i]),
                          onCopiar:
                              () => _abrirCopiarACargos(context, ref, filas[i]),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('contenido'),
      onRefresh: notifier.cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, aireBajoFab),
        itemCount: filas.length,
        itemBuilder: (context, i) {
          final fila = filas[i];
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
            // La franja con FranjaAcento y no con un Border de un solo lado:
            // un Border que no es uniforme junto con borderRadius lanza al
            // pintarse (ver arqueo_caja_screen.dart), y en un teléfono la
            // tarjeta quedaba sin dibujar.
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: FranjaAcento(
                color:
                    estadoActivo
                        ? TareasColors.realizadoTexto(context)
                        : Theme.of(context).colorScheme.outlineVariant,
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
                          PildoraTareas.frecuencia(
                            context,
                            idFrec,
                            (fila['descripcionFrecuencia'] as String?) ??
                                'Frecuencia $idFrec',
                          ),
                        Text(
                          textoVigenciaAsignacion(fila),
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

  /// Aplica los dos filtros de la barra.
  List<Map<String, dynamic>> _aplicarFiltros(
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    final frec = ref.watch(filtroFrecuenciaPorCargo(cargo.codCargo));
    final activo = ref.watch(filtroActivoPorCargo(cargo.codCargo));
    return items.where((f) {
      if (frec != null && (f['idFrec'] as num?)?.toInt() != frec) return false;
      if (activo != null) {
        final esActiva = ((f['estado'] as num?)?.toInt() ?? 1) == 1;
        if (esActiva != activo) return false;
      }
      return true;
    }).toList();
  }

  /// Pregunta si la tarea sale del catálogo o es nueva.
  ///
  /// Antes este botón creaba siempre una tarea NUEVA, y no había forma de
  /// enganchar una existente desde el lado del cargo. El resultado se ve en
  /// los datos: 7 descripciones repetidas en el catálogo, y una tarea
  /// asignada dos veces al mismo cargo por dos `idTarRuti` distintos — que el
  /// índice único no puede impedir, porque para la base son dos tareas.
  ///
  /// "Elegir del catálogo" va primero a propósito: reusar es lo correcto casi
  /// siempre, y crear una nueva debería costar un toque más que reusar, no al
  /// revés.
  Future<void> _elegirComoAgregar(BuildContext context, WidgetRef ref) async {
    final delCatalogo = await showModalBottomSheet<bool>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add_check),
                  title: const Text('Elegir del catálogo'),
                  subtitle: const Text(
                    'Reusa una tarea que ya existe. No se ofrecen las que '
                    'este cargo ya tiene.',
                  ),
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('Crear una tarea nueva'),
                  subtitle: const Text(
                    'Solo si de verdad no existe todavía.',
                  ),
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
              ],
            ),
          ),
    );
    if (delCatalogo == null || !context.mounted) return;
    if (delCatalogo) {
      await _abrirCatalogo(context, ref);
    } else {
      await _abrirCrearTarea(context, ref);
    }
  }

  /// El selector de tareas ya existentes.
  Future<void> _abrirCatalogo(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(
      tareasRutinariasPorCargoProvider(cargo.codCargo).notifier,
    );
    // Se manda el ESTADO de cada asignación, no solo los ids: una tarea
    // inactiva tampoco se puede volver a insertar (quedarían dos filas para
    // el mismo par tarea/cargo, porque el índice único solo mira las
    // activas), pero el motivo es distinto y el diálogo lo dice.
    final yaAsignadas = <int, bool>{
      for (final f in ref.read(tareasRutinariasPorCargoProvider(cargo.codCargo)).items)
        if ((f['idTarRuti'] as num?) != null)
          (f['idTarRuti'] as num).toInt():
              ((f['estado'] as num?)?.toInt() ?? 1) == 1,
    };

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => ElegirTareaDelCatalogoDialog(
            yaAsignadas: yaAsignadas,
            nombreCargo: cargo.descripcion,
            onElegidas: (ids, desde) =>
                notifier.asignarExistentes(ids, desde: desde),
            // La misma operación que el interruptor de la lista: toggleEstado
            // invierte el estado de la fila, y aquí solo se le pasan filas
            // inactivas.
            onReactivar: (idTarRuti) async {
              final filas =
                  ref.read(tareasRutinariasPorCargoProvider(cargo.codCargo)).items;
              for (final f in filas) {
                if ((f['idTarRuti'] as num?)?.toInt() == idTarRuti &&
                    ((f['estado'] as num?)?.toInt() ?? 1) != 1) {
                  return notifier.toggleEstado(f);
                }
              }
              return false;
            },
          ),
    );
  }

  /// Abre la hoja compartida ([CrearTareaPorCargoSheet]) con la lista de un
  /// único elemento -- el cargo de esta pantalla -- para no cambiar en nada
  /// el flujo de "Agregar tarea rutinaria" que ya existía aquí. Lo único que
  /// se mueve es de dónde sale el aviso de éxito: la hoja, al ser
  /// reutilizable desde el catálogo (que no tiene un `codCargo` propio para
  /// escuchar), ya no toca el estado de [tareasRutinariasPorCargoProvider]
  /// -- ver el porqué en su propio doc comment --, así que este método
  /// dispara el mismo aviso/haptic/refresco que antes disparaba el
  /// `ref.listen` de arriba al ver `mensajeExito`.
  Future<void> _abrirCrearTarea(BuildContext context, WidgetRef ref) async {
    final creada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => CrearTareaPorCargoSheet(codCargos: [cargo.codCargo]),
    );
    if (creada == true && context.mounted) {
      HapticFeedback.mediumImpact();
      mostrarAviso(context, 'Tarea creada y asignada a este cargo.');
      ref
          .read(tareasRutinariasPorCargoProvider(cargo.codCargo).notifier)
          .cargar();
    }
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
            const SizedBox(height: 16),
            Text(
              'Fecha de partida',
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
              label: Text(FormatearFecha.formatearFecha(_fechaPartida)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => cerrarRuta(context),
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
                      cerrarRuta(context);
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
          onPressed: () => cerrarRuta(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────

/// Cuando empieza y termina la ASIGNACION de esta tarea a este cargo.
///
/// Lee `fechaInicio`/`fechaFin` de tac_tarRuXCargo, no `fechaPartida` de la
/// tarea. La pantalla mostraba lo segundo bajo el rotulo "Desde:", y son cosas
/// distintas: `fechaPartida` es desde cuando existe la TAREA, `fechaInicio` es
/// desde cuando la tiene ESTE cargo. Medido el 2026-09-10: difieren en 534 de
/// las 541 asignaciones, asi que el rotulo estaba equivocado casi siempre —
/// para el cargo de la captura decia 2020 cuando la asignacion es de 2026.
String textoVigenciaAsignacion(Map<String, dynamic> fila) {
  String fmt(Object? v) {
    final d = DateTime.tryParse((v ?? '').toString());
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  final desde = fmt(fila['fechaInicio']);
  final hasta = fila['fechaFin'] == null ? null : fmt(fila['fechaFin']);
  return hasta == null ? 'Desde: $desde' : 'Del $desde al $hasta';
}

/// Los filtros. Solo ofrecen frecuencias que este cargo REALMENTE tiene: un
/// chip "Bimestral (0)" es una promesa vacia.
class _BarraFiltros extends ConsumerWidget {
  final int codCargo;
  final List<Map<String, dynamic>> items;

  const _BarraFiltros({required this.codCargo, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frecSel = ref.watch(filtroFrecuenciaPorCargo(codCargo));
    final activoSel = ref.watch(filtroActivoPorCargo(codCargo));

    final porFrecuencia = <int, ({String nombre, int cuantas})>{};
    var activas = 0;
    for (final f in items) {
      final id = (f['idFrec'] as num?)?.toInt();
      if (id != null) {
        final actual = porFrecuencia[id];
        porFrecuencia[id] = (
          nombre:
              (f['descripcionFrecuencia'] as String?) ?? 'Frecuencia $id',
          cuantas: (actual?.cuantas ?? 0) + 1,
        );
      }
      if (((f['estado'] as num?)?.toInt() ?? 1) == 1) activas++;
    }
    final inactivas = items.length - activas;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Center(
            child: FilterChip(
              label: Text('Activas ($activas)'),
              selected: activoSel == true,
              showCheckmark: false,
              avatar: const Icon(Icons.toggle_on_outlined, size: 18),
              onSelected: (v) =>
                  ref.read(filtroActivoPorCargo(codCargo).notifier).state =
                      v ? true : null,
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: FilterChip(
              label: Text('Inactivas ($inactivas)'),
              selected: activoSel == false,
              showCheckmark: false,
              avatar: const Icon(Icons.toggle_off_outlined, size: 18),
              onSelected: (v) =>
                  ref.read(filtroActivoPorCargo(codCargo).notifier).state =
                      v ? false : null,
            ),
          ),
          if (porFrecuencia.length > 1) ...[
            const SizedBox(width: 12),
            const Center(child: SizedBox(height: 24, child: VerticalDivider())),
            const SizedBox(width: 12),
            for (final e in porFrecuencia.entries) ...[
              Center(
                child: FilterChip(
                  label: Text('${e.value.nombre} (${e.value.cuantas})'),
                  selected: frecSel == e.key,
                  showCheckmark: false,
                  backgroundColor: TareasColors.frecuencia(context, e.key),
                  onSelected: (v) => ref
                      .read(filtroFrecuenciaPorCargo(codCargo).notifier)
                      .state = v ? e.key : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ],
      ),
    );
  }
}

const _anchosCargo = <AnchoCol>[
  AnchoCol.fijo(70), // activa
  AnchoCol.flexible(3), // tarea
  AnchoCol.fijo(120), // frecuencia
  AnchoCol.fijo(130), // asignada desde
  AnchoCol.fijo(110), // hasta
  AnchoCol.fijo(48), // acciones
];

class _FilaTablaTarea extends StatelessWidget {
  final Map<String, dynamic> fila;
  final bool guardando;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onCopiar;

  const _FilaTablaTarea({
    required this.fila,
    required this.guardando,
    required this.onToggle,
    required this.onEditar,
    required this.onCopiar,
  });

  String _fmt(Object? v) {
    final d = DateTime.tryParse((v ?? '').toString());
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final idFrec = (fila['idFrec'] as num?)?.toInt();
    final activa = ((fila['estado'] as num?)?.toInt() ?? 1) == 1;

    return FilaTabla(
      anchos: _anchosCargo,
      celdas: [
        Switch(
          value: activa,
          onChanged: guardando ? null : (_) => onToggle(),
        ),
        Text(
          (fila['descripcion'] as String?) ?? 'Sin descripción',
          // Tachada cuando esta inactiva: en una tabla, el interruptor de la
          // primera columna se pierde de vista al leer la fila entera.
          style: TextStyle(
            decoration: activa ? null : TextDecoration.lineThrough,
            color:
                activa ? null : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        if (idFrec == null)
          const Text('—')
        else
          Align(
            alignment: Alignment.centerLeft,
            child: PildoraTareas.frecuencia(
              context,
              idFrec,
              (fila['descripcionFrecuencia'] as String?) ?? 'Frec. $idFrec',
            ),
          ),
        Text(_fmt(fila['fechaInicio'])),
        Text(
          fila['fechaFin'] == null ? 'Permanente' : _fmt(fila['fechaFin']),
          style: fila['fechaFin'] == null
              ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
        PopupMenuButton<String>(
          tooltip: 'Más acciones',
          onSelected: (o) => o == 'editar' ? onEditar() : onCopiar(),
          itemBuilder: (context) => const [
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
      ],
    );
  }
}

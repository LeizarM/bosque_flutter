// Destino final: lib/presentation/screens/estructura-organizacional/tareas_rutinarias_catalogo_screen.dart
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/tar_ru_x_cargo_provider.dart';
import 'package:bosque_flutter/core/state/frecuencia_provider.dart';
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/data/repositories/tar_ru_x_cargo_impl.dart';
import 'package:bosque_flutter/domain/entities/frecuencia_entity.dart';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/crear_tarea_por_cargo_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/traspasos_pendientes_screen.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catálogo global de tareas rutinarias — busca CUALQUIER tarea ya creada
/// (no solo las de un cargo puntual) para copiarla a uno o varios cargos.
/// Antes la única forma de copiar era entrar al cargo QUE YA TIENE la tarea,
/// abrirla ahí y copiarla desde esa lista — si no te acordabas en qué cargo
/// vivía, no había forma de encontrarla. Aquí se busca por nombre primero, se
/// elige el destino después.
///
/// 2026-09-07: la lista ya no aparece completa por defecto (Marcelo: "que no
/// cargue todas las tareas por default") — el catálogo real ronda ~15-20
/// tareas, así que sigue trayéndose entero de una sola vez (mismo patrón que
/// el resto del módulo, sin endpoint nuevo), pero la pantalla no la MUESTRA
/// hasta que el usuario elige un tipo de frecuencia o escribe una búsqueda.
/// Frecuencia y texto se combinan (ambos filtran sobre la misma lista ya
/// cargada, en el cliente).
class TareasRutinariasCatalogoScreen extends ConsumerStatefulWidget {
  final int codEmpresa;

  const TareasRutinariasCatalogoScreen({super.key, required this.codEmpresa});

  @override
  ConsumerState<TareasRutinariasCatalogoScreen> createState() =>
      _TareasRutinariasCatalogoScreenState();
}

class _TareasRutinariasCatalogoScreenState
    extends ConsumerState<TareasRutinariasCatalogoScreen> {
  final _buscarCtrl = TextEditingController();
  int? _idFrecSeleccionado;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  /// Copiar desde el catálogo no tiene "un cargo propio" cuyo estado
  /// refrescar (a diferencia de TareasPorCargoNotifier.copiarACargos) — es
  /// el mismo INSERT (p_abm_tac_TarRuXCargo ACCION='I', uno por cargo
  /// elegido), pero aquí alcanza con reponer tarRuXCargoProvider al final
  /// para que el propio diálogo (que lo mira para calcular "disponibles")
  /// vea el cambio si se reabre.
  Future<bool> _copiarACargos(int idTarRuti, List<int> destinos) async {
    try {
      final repo = TarRuXCargoImpl();
      for (final destino in destinos) {
        await repo.registrar(
          TarRuXCargoEntity(
            idTarXCargo: 0,
            idTarRuti: idTarRuti,
            codCargo: destino,
            estado: 1,
            audUsuario: 0,
          ),
        );
      }
      if (mounted) {
        ref.read(tarRuXCargoProvider.notifier).cargar();
        mostrarAviso(context, 'Tarea copiada a ${destinos.length} cargo(s).');
      }
      return true;
    } catch (e) {
      if (mounted) mostrarAviso(context, e.toString(), tono: TonoAviso.error);
      return false;
    }
  }

  /// FAB "Nueva tarea rutinaria": el flujo completo de alta rápida en dos
  /// pasos, cada uno un widget ya existente.
  ///
  /// 1. [CopiarACargosDialog] en su modo "elegir cargos para una tarea
  ///    nueva" (`idTarRuti: null`) — mismo buscador/multi-selección que ya
  ///    usa "Copiar", pero aquí el callback [onCopiado] no copia nada: solo
  ///    junta la selección en [codCargosElegidos] y devuelve `true` para
  ///    que el diálogo se cierre solo, como ya hace en modo copia.
  /// 2. Recién cuando ESE diálogo ya se cerró (el `await` de abajo) se abre
  ///    [CrearTareaPorCargoSheet] con los cargos elegidos. Encadenarlo así
  ///    -- y no adentro del propio `onCopiado` -- evita que la hoja nueva
  ///    quede empujando al diálogo todavía abierto (`Navigator.pop()` del
  ///    diálogo se llevaría puesta la hoja recién abierta, no a él mismo,
  ///    si las dos rutas quedaran apiladas a la vez).
  Future<void> _abrirNuevaTarea(BuildContext context) async {
    List<int>? codCargosElegidos;
    await showDialog<void>(
      context: context,
      builder:
          (context) => CopiarACargosDialog(
            codEmpresa: widget.codEmpresa,
            onCopiado: (codCargos) async {
              codCargosElegidos = codCargos;
              return true;
            },
          ),
    );
    if (!mounted) return;
    final elegidos = codCargosElegidos;
    if (elegidos == null || elegidos.isEmpty) return;

    final creada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CrearTareaPorCargoSheet(codCargos: elegidos),
    );
    if (creada == true && mounted) {
      HapticFeedback.mediumImpact();
      ref.read(tareaRutinariaProvider.notifier).cargar();
      mostrarAviso(
        context,
        'Tarea creada y asignada a ${elegidos.length} cargo(s).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tareaRutinariaProvider);
    final frecuenciaState = ref.watch(frecuenciaProvider);
    final busqueda = _buscarCtrl.text.trim().toLowerCase();

    // Sin frecuencia elegida NI texto de búsqueda -> no se muestra nada
    // todavía (a propósito, ver doc de la clase). Cualquiera de las dos
    // cosas alcanza para empezar a mostrar resultados, y se combinan si
    // están las dos.
    final hayFiltro = _idFrecSeleccionado != null || busqueda.isNotEmpty;
    final filtradas =
        !hayFiltro
            ? const <TareaRutinariaEntity>[]
            : state.items.where((t) {
              final coincideFrecuencia =
                  _idFrecSeleccionado == null ||
                  t.idFrec == _idFrecSeleccionado;
              final coincideTexto =
                  busqueda.isEmpty ||
                  t.descripcion.toLowerCase().contains(busqueda);
              return coincideFrecuencia && coincideTexto;
            }).toList();

    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= TareasBreakpoints.mediumMax;
    // Sin columna centrada: el catálogo usa todo el ancho (antes quedaba en
    // ~610 px con el resto de la pantalla vacío).
    const paddingHorizontal = Esp.l;

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: 'Catálogo de tareas rutinarias',
          subtitulo:
              state.items.isEmpty
                  ? null
                  : '${state.items.length} tareas en el catálogo',
          insignia: InsigniaTarea.modulo(context, Icons.library_books_outlined),
          acciones: [
            // Entra desde aquí y no desde un ítem de menú propio: quien
            // administra las tareas por cargo es exactamente quien tiene que
            // resolver los traspasos, y comparten el permiso
            // (btnTareasRutXCargo, vista 12).
            IconButton(
              tooltip: 'Cambios de cargo sin resolver',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TraspasosPendientesScreen(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed:
                  () => ref.read(tareaRutinariaProvider.notifier).cargar(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.selectionClick();
            _abrirNuevaTarea(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva tarea rutinaria'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                paddingHorizontal,
                12,
                paddingHorizontal,
                0,
              ),
              child: TextField(
                controller: _buscarCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar tarea rutinaria por nombre...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      _buscarCtrl.text.isEmpty
                          ? null
                          : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed:
                                () => setState(() => _buscarCtrl.clear()),
                          ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                paddingHorizontal,
                12,
                paddingHorizontal,
                4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'O elige un tipo de frecuencia',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                paddingHorizontal,
                0,
                paddingHorizontal,
                8,
              ),
              child:
                  frecuenciaState.cargando && frecuenciaState.items.isEmpty
                      ? const LinearProgressIndicator()
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            frecuenciaState.items.map((f) {
                              final elegido = _idFrecSeleccionado == f.idFrec;
                              return ChoiceChip(
                                selected: elegido,
                                onSelected:
                                    (sel) => setState(
                                      () =>
                                          _idFrecSeleccionado =
                                              sel ? f.idFrec : null,
                                    ),
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
                                      elegido
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                              );
                            }).toList(),
                      ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildLista(
                  context,
                  state,
                  frecuenciaState.items,
                  filtradas,
                  hayFiltro,
                  esAncho,
                  anchoDisponible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    TareaRutinariaState state,
    List<FrecuenciaEntity> frecuencias,
    List<TareaRutinariaEntity> filtradas,
    bool hayFiltro,
    bool esAncho,
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
        titulo: 'No se pudieron cargar las tareas rutinarias',
        error: state.mensajeError,
        onReintentar: () => ref.read(tareaRutinariaProvider.notifier).cargar(),
      );
    }
    if (!hayFiltro) {
      return const EstadoTareas(
        key: ValueKey('sinFiltro'),
        icono: Icons.filter_alt_outlined,
        titulo: 'Elige una frecuencia o escribe un nombre',
        detalle: 'Así se ven solo las tareas que buscas, y no el catálogo entero.',
      );
    }
    if (filtradas.isEmpty) {
      return const EstadoTareas(
        key: ValueKey('vacio'),
        icono: Icons.search_off,
        titulo: 'Ninguna tarea coincide con lo elegido',
      );
    }

    return ListView.builder(
      key: const ValueKey('lista'),
      // Abajo, el alto del FAB "Nueva tarea rutinaria": tapaba el botón
      // Copiar de la última tarjeta.
      padding: const EdgeInsets.fromLTRB(Esp.s, Esp.s, Esp.s, aireBajoFab),
      itemCount: filtradas.length,
      itemBuilder: (context, i) {
        final t = filtradas[i];
        // El nombre real de la frecuencia (no el id crudo) -- se busca en la
        // misma lista ya cargada para el selector de arriba, sin pedir nada
        // nuevo. Si la tarea trae un idFrec que ya no está en el catálogo
        // activo (borrado/desactivado), se cae al id como antes en vez de
        // romper.
        String? nombreFrecuencia;
        if (t.idFrec != null) {
          for (final f in frecuencias) {
            if (f.idFrec == t.idFrec) {
              nombreFrecuencia = f.descripcion;
              break;
            }
          }
          nombreFrecuencia ??= 'Frecuencia ${t.idFrec}';
        }
        // Franja izquierda con el mismo color de frecuencia que ya usa el
        // chip de abajo y el ChoiceChip de arriba — antes la tarjeta era
        // neutra y el color de frecuencia solo vivía en el chip pequeño,
        // ahora la fila entera se identifica de un vistazo (mismo patrón que
        // TareaPendienteTile.franja de estado). Sin idFrec, se deja el borde
        // neutro de siempre.
        final colorFrecuencia =
            t.idFrec != null
                ? TareasColors.frecuenciaTexto(context, t.idFrec!)
                : null;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          // FranjaAcento y no IntrinsicHeight — ver el doc de ese widget.
          child: FranjaAcento(
            color: colorFrecuencia,
            child: ListTile(
              title: Text(
                t.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle:
                  nombreFrecuencia != null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PildoraTareas.frecuencia(
                            context,
                            t.idFrec!,
                            nombreFrecuencia,
                          ),
                        ),
                      )
                      : null,
              trailing: FilledButton.tonalIcon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showDialog(
                    context: context,
                    builder:
                        (context) => CopiarACargosDialog(
                          idTarRuti: t.idTarRuti,
                          nombreTarea: t.descripcion,
                          codEmpresa: widget.codEmpresa,
                          onCopiado:
                              (destinos) =>
                                  _copiarACargos(t.idTarRuti, destinos),
                        ),
                  );
                },
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copiar'),
              ),
            ),
          ),
        );
      },
    );
  }
}

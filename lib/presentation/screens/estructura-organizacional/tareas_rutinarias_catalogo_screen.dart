// Destino final: lib/presentation/screens/estructura-organizacional/tareas_rutinarias_catalogo_screen.dart
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/state/tar_ru_x_cargo_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/data/repositories/tar_ru_x_cargo_impl.dart';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catálogo global de tareas rutinarias — busca CUALQUIER tarea ya creada
/// (no solo las de un cargo puntual) para copiarla a uno o varios cargos.
/// Antes la única forma de copiar era entrar al cargo QUE YA TIENE la tarea,
/// abrirla ahí y copiarla desde esa lista — si no te acordabas en qué cargo
/// vivía, no había forma de encontrarla. Acá se busca por nombre primero, se
/// elige el destino después.
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

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  /// Copiar desde el catálogo no tiene "un cargo propio" cuyo estado
  /// refrescar (a diferencia de TareasPorCargoNotifier.copiarACargos) — es
  /// el mismo INSERT (p_abm_tac_TarRuXCargo ACCION='I', uno por cargo
  /// elegido), pero acá alcanza con reponer tarRuXCargoProvider al final
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tareaRutinariaProvider);
    final busqueda = _buscarCtrl.text.trim().toLowerCase();
    final filtradas =
        busqueda.isEmpty
            ? state.items
            : state.items
                .where((t) => t.descripcion.toLowerCase().contains(busqueda))
                .toList();

    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de tareas rutinarias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tareaRutinariaProvider.notifier).cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: esAncho ? (anchoDisponible - 900) / 2 + 16 : 16,
              vertical: 12,
            ),
            child: TextField(
              controller: _buscarCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar tarea rutinaria...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon:
                    _buscarCtrl.text.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _buscarCtrl.clear()),
                        ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildLista(
                context,
                state,
                filtradas,
                esAncho,
                anchoDisponible,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    TareaRutinariaState state,
    List<TareaRutinariaEntity> filtradas,
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
              const Text('No se pudieron cargar las tareas rutinarias.'),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed:
                    () => ref.read(tareaRutinariaProvider.notifier).cargar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (filtradas.isEmpty) {
      return Center(
        key: const ValueKey('vacio'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                state.items.isEmpty
                    ? 'Todavía no hay tareas rutinarias creadas.'
                    : 'Ninguna tarea coincide con la búsqueda.',
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('lista'),
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: esAncho ? (anchoDisponible - 900) / 2 : 0,
      ),
      itemCount: filtradas.length,
      itemBuilder: (context, i) {
        final t = filtradas[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListTile(
            title: Text(
              t.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                t.idFrec != null
                    ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text('Frecuencia ${t.idFrec}'),
                        backgroundColor: TareasColors.frecuencia(
                          context,
                          t.idFrec!,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: TareasColors.frecuenciaTexto(
                            context,
                            t.idFrec!,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            (destinos) => _copiarACargos(t.idTarRuti, destinos),
                      ),
                );
              },
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Copiar'),
            ),
          ),
        );
      },
    );
  }
}

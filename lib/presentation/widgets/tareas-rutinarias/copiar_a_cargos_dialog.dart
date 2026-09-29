// Destino final: lib/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/tar_ru_x_cargo_provider.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';

/// Diálogo "Copiar a otros cargos" — reusa una tarea rutinaria ya existente
/// para más cargos. "Disponibles" = cargos de la empresa que TODAVÍA no
/// tienen esta tarea asignada (mismo criterio que
/// TarRuXCargoManagedBean.lstCargoAsg del legacy). Diff enteramente
/// client-side: cargosXEmpresaProvider (organigrama ya existente) menos los
/// codCargo ya asignados a este idTarRuti (fetch sin filtro de
/// TarRuXCargoImpl().obtener(), no hace falta un endpoint nuevo).
///
/// Compartido entre la pantalla "Tareas rutinarias por cargo" (un cargo
/// puntual, ya con su propio estado a refrescar) y el catálogo global (sin
/// cargo de origen, solo elige la tarea) — por eso [onCopiado] es un
/// callback: cada pantalla decide qué hacer con el resultado, el diálogo
/// solo junta la selección.
///
/// **Dos modos, un mismo buscador.** [idTarRuti] `null` es el tercer uso:
/// "elegir cargos para una tarea que todavía no existe" (FAB "Nueva tarea
/// rutinaria" del catálogo, que abre esto y después
/// `CrearTareaPorCargoSheet` con lo elegido). Ahí no hay asignaciones
/// previas que excluir -- se listan TODOS los cargos visibles de la
/// empresa -- ni un nombre de tarea que mostrar en el título. El resto
/// (buscador, multi-selección, botón "Asignar (N)") es idéntico en los dos
/// modos: por eso esto no se duplicó en un widget aparte, solo se
/// volvieron opcionales las dos props que únicamente tienen sentido cuando
/// la tarea YA existe.
class CopiarACargosDialog extends ConsumerStatefulWidget {
  final int? idTarRuti;
  final String? nombreTarea;
  final int codEmpresa;
  final Future<bool> Function(List<int> destinos) onCopiado;

  const CopiarACargosDialog({
    super.key,
    this.idTarRuti,
    this.nombreTarea,
    required this.codEmpresa,
    required this.onCopiado,
  });

  @override
  ConsumerState<CopiarACargosDialog> createState() =>
      _CopiarACargosDialogState();
}

class _CopiarACargosDialogState extends ConsumerState<CopiarACargosDialog> {
  bool _guardando = false;
  final Set<int> _seleccionados = {};
  final TextEditingController _buscarCtrl = TextEditingController();

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  List<CargoEntity> _aplanar(List<CargoEntity> jerarquia) {
    final plano = <CargoEntity>[];
    void recorrer(List<CargoEntity> nivel) {
      for (final c in nivel) {
        if (c.esVisible != 0) plano.add(c);
        if (c.items.isNotEmpty) recorrer(c.items);
      }
    }

    recorrer(jerarquia);
    return plano;
  }

  @override
  Widget build(BuildContext context) {
    // Reactivos: cargosXEmpresaProvider ya está viva (la pantalla de
    // organigrama la mantiene cargada) y tarRuXCargoProvider trae TODAS las
    // asignaciones sin filtro (se filtra aquí por idTarRuti) — ninguno de los
    // dos necesita un fetch manual nuevo. En modo "tarea nueva" (idTarRuti
    // null) no hace falta ver asignaciones de nadie, así que ni se watchea.
    final cargosAsync = ref.watch(cargosXEmpresaProvider(widget.codEmpresa));
    final asignacionesState =
        widget.idTarRuti != null
            ? ref.watch(tarRuXCargoProvider)
            : const TarRuXCargoState();

    final busqueda = _buscarCtrl.text.trim().toLowerCase();
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final altoDisponible = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      title: Text(
        widget.idTarRuti != null
            ? 'Copiar "${widget.nombreTarea}" a otros cargos'
            : 'Elegir cargos para la nueva tarea',
      ),
      content: SizedBox(
        width: (anchoDisponible - 80).clamp(240, 420),
        // Antes 420 fijo — en un viewport bajo (browser achicado) se salía
        // del diálogo. Acotado a lo que realmente hay, con un piso legible.
        height: (altoDisponible * 0.5).clamp(260, 420),
        child: cargosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (jerarquia) {
            if (widget.idTarRuti != null &&
                asignacionesState.cargando &&
                asignacionesState.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final yaAsignados =
                widget.idTarRuti == null
                    ? const <int>{}
                    : asignacionesState.items
                        .where((a) => a.idTarRuti == widget.idTarRuti)
                        .map((a) => a.codCargo)
                        .whereType<int>()
                        .toSet();
            final disponibles =
                _aplanar(
                    jerarquia,
                  ).where((c) => !yaAsignados.contains(c.codCargo)).toList()
                  ..sort((a, b) => a.descripcion.compareTo(b.descripcion));
            final filtrados =
                busqueda.isEmpty
                    ? disponibles
                    : disponibles
                        .where(
                          (c) => c.descripcion.toLowerCase().contains(busqueda),
                        )
                        .toList();

            return Column(
              children: [
                TextField(
                  controller: _buscarCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar cargo destino...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      filtrados.isEmpty
                          ? Center(
                            child: Text(
                              widget.idTarRuti != null
                                  ? 'Todos los cargos ya tienen esta tarea asignada.'
                                  : 'Ningún cargo coincide con la búsqueda.',
                            ),
                          )
                          : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, i) {
                              final c = filtrados[i];
                              return CheckboxListTile(
                                dense: true,
                                value: _seleccionados.contains(c.codCargo),
                                title: Text(c.descripcion),
                                onChanged:
                                    (marcado) => setState(() {
                                      HapticFeedback.selectionClick();
                                      if (marcado == true) {
                                        _seleccionados.add(c.codCargo);
                                      } else {
                                        _seleccionados.remove(c.codCargo);
                                      }
                                    }),
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => cerrarRuta(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _seleccionados.isEmpty || _guardando
                  ? null
                  : () async {
                    setState(() => _guardando = true);
                    final ok = await widget.onCopiado(_seleccionados.toList());
                    if (ok) HapticFeedback.mediumImpact();
                    if (context.mounted) cerrarRuta(context);
                    if (!ok) return;
                  },
          child: Text(
            _guardando ? 'Copiando…' : 'Asignar (${_seleccionados.length})',
          ),
        ),
      ],
    );
  }
}

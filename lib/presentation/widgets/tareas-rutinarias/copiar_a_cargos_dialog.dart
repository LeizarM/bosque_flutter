// Destino final: lib/presentation/widgets/tareas-rutinarias/copiar_a_cargos_dialog.dart
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/tar_ru_x_cargo_provider.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class CopiarACargosDialog extends ConsumerStatefulWidget {
  final int idTarRuti;
  final String nombreTarea;
  final int codEmpresa;
  final Future<bool> Function(List<int> destinos) onCopiado;

  const CopiarACargosDialog({
    super.key,
    required this.idTarRuti,
    required this.nombreTarea,
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
    // asignaciones sin filtro (se filtra acá por idTarRuti) — ninguno de los
    // dos necesita un fetch manual nuevo.
    final cargosAsync = ref.watch(cargosXEmpresaProvider(widget.codEmpresa));
    final asignacionesState = ref.watch(tarRuXCargoProvider);

    final busqueda = _buscarCtrl.text.trim().toLowerCase();
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final altoDisponible = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      title: Text('Copiar "${widget.nombreTarea}" a otros cargos'),
      content: SizedBox(
        width: (anchoDisponible - 80).clamp(240, 420),
        // Antes 420 fijo — en un viewport bajo (browser achicado) se salía
        // del diálogo. Acotado a lo que realmente hay, con un piso legible.
        height: (altoDisponible * 0.5).clamp(260, 420),
        child: cargosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (jerarquia) {
            if (asignacionesState.cargando && asignacionesState.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final yaAsignados =
                asignacionesState.items
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
                          ? const Center(
                            child: Text(
                              'Todos los cargos ya tienen esta tarea asignada.',
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
          onPressed: () => Navigator.of(context).pop(),
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
                    if (context.mounted) Navigator.of(context).pop();
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

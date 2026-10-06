import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/planilla_incapacidad_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/vistas_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';

/// Planilla de Incapacidad (tb_vista 166 'tacTareas/PlanillaIncapacidad').
///
/// Bajas médicas con su descuento por incapacidad. Aquí solo se marca cada una como
/// revisada; días e importes los calcula `p_abm_planillaIncapacidad`.
class PlanillaIncapacidadScreen extends ConsumerWidget {
  const PlanillaIncapacidadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con datos a la vista, un fallo al actualizar se avisa; sin datos lo
    // muestra el cuerpo.
    ref.listen<Object?>(planillaIncapacidadProvider.select((s) => s.error), (
      previo,
      actual,
    ) {
      if (actual != null &&
          actual != previo &&
          ref.read(planillaIncapacidadProvider).cargado) {
        mostrarAviso(context, textoParaUsuario(actual), tono: TonoAviso.error);
      }
    });
    final cargando = ref.watch(
      planillaIncapacidadProvider.select((s) => s.cargando),
    );

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: 'Planilla de incapacidad',
          subtitulo: 'Bajas médicas y descuento: marca cada una al revisarla',
          insignia: InsigniaTarea.modulo(context, Icons.healing_outlined),
          acciones: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed:
                  cargando
                      ? null
                      : ref.read(planillaIncapacidadProvider.notifier).cargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: MargenPaginaTareas(
            child: LayoutBuilder(
              builder:
                  (context, cajon) =>
                      cajon.maxWidth >= anchoTablaIncapacidad
                          ? const VistaAmpliaIncapacidad()
                          : const VistaCompactaIncapacidad(),
            ),
          ),
        ),
      ),
    );
  }
}

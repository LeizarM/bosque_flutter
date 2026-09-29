// Destino final: lib/presentation/widgets/tareas-rutinarias/pildora_cumplimiento.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';

/// El tono de un estado de cumplimiento.
///
/// Vive aquí y no en cada pantalla porque lo usan dos: la bitácora y el panel
/// de tareas del día de la revisión de Cierre de Operaciones. La misma
/// "No realizada" tiene que verse igual en las dos.
({Color fondo, Color texto}) tonoDeCumplimiento(
  BuildContext context,
  Cumplimiento? cumplimiento,
) {
  switch (cumplimiento) {
    case Cumplimiento.realizada:
      return (
        fondo: TareasColors.realizado(context),
        texto: TareasColors.realizadoTexto(context),
      );
    case Cumplimiento.noRealizada:
      return (
        fondo: TareasColors.vencido(context),
        texto: TareasColors.vencidoTexto(context),
      );
    case Cumplimiento.enPlazo:
      return (
        fondo: TareasColors.pendiente(context),
        texto: TareasColors.pendienteTexto(context),
      );
    // Sin cumplimiento no hay nada que reclamar: el mismo tono neutro que
    // "no aplica".
    case Cumplimiento.noAplica:
    case null:
      return (
        fondo: TareasColors.noAplica(context),
        texto: TareasColors.noAplicaTexto(context),
      );
  }
}

/// "Realizada", "No realizada", "En plazo", "No aplica".
class PildoraCumplimiento extends StatelessWidget {
  final Cumplimiento? cumplimiento;

  const PildoraCumplimiento({super.key, required this.cumplimiento});

  @override
  Widget build(BuildContext context) {
    final tono = tonoDeCumplimiento(context, cumplimiento);
    return PildoraTareas(
      texto: cumplimiento?.etiqueta ?? '—',
      fondo: tono.fondo,
      color: tono.texto,
    );
  }
}

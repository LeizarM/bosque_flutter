import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/formato_incapacidad.dart';
import 'package:flutter/material.dart';

/// Lo único editable de la planilla: si la baja fue revisada.
///
/// Una pastilla y no un `Checkbox` suelto: dice el estado en palabras y, ya
/// revisada, cuándo. Los tonos son los de "Realizado"/"Pendiente" del módulo
/// Tareas, así una pendiente se lee igual en toda la app.
class InterruptorRevision extends StatelessWidget {
  final bool revisado;
  final DateTime? fecha;
  final bool guardando;
  final ValueChanged<bool> onCambiar;

  const InterruptorRevision({
    super.key,
    required this.revisado,
    required this.onCambiar,
    this.fecha,
    this.guardando = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fondo =
        revisado ? TareasColors.realizado(context) : TareasColors.pendiente(context);
    final tinta =
        revisado
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context);
    final forma = StadiumBorder(
      side: BorderSide(color: tinta.withValues(alpha: 0.35)),
    );

    return Semantics(
      button: true,
      toggled: revisado,
      label: 'Baja revisada',
      child: Tooltip(
        message: revisado ? 'Quitar la revisión' : 'Marcar como revisada',
        child: Material(
          color: fondo,
          shape: forma,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: forma,
            onTap: guardando ? null : () => onCambiar(!revisado),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Esp.s, Esp.xs + 2, Esp.m, Esp.xs + 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child:
                          guardando
                              ? Padding(
                                key: const ValueKey('guardando'),
                                padding: const EdgeInsets.all(2),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tinta,
                                ),
                              )
                              : Icon(
                                revisado
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                key: ValueKey(revisado),
                                size: 20,
                                color: tinta,
                              ),
                    ),
                  ),
                  const SizedBox(width: Esp.s),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          revisado ? 'Revisada' : 'Pendiente',
                          style: tema.textTheme.labelLarge?.copyWith(
                            color: tinta,
                            fontWeight: Peso.titulo,
                            height: 1.1,
                          ),
                        ),
                        if (revisado && fecha != null)
                          Text(
                            fechaHoraIncapacidad(fecha!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: tinta.withValues(alpha: 0.85),
                              fontFeatures: cifrasTabulares,
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

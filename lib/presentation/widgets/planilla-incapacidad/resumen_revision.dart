import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/formato_incapacidad.dart';
import 'package:flutter/material.dart';

/// Cuánto falta revisar del rango y cuánto suma el descuento.
///
/// Cuenta todo el rango, no lo filtrado: la pregunta es "¿terminé este
/// periodo?", y esconder las revisadas no la cambia.
class ResumenRevision extends StatelessWidget {
  final int revisadas;
  final int total;
  final int diasSeguro;
  final double descuento;

  const ResumenRevision({
    super.key,
    required this.revisadas,
    required this.total,
    required this.diasSeguro,
    required this.descuento,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(Esp.l),
      child: LayoutBuilder(
        builder: (context, cajon) {
          final progreso = _Progreso(revisadas: revisadas, total: total);
          final dias = _Dato(
            rotulo: 'Días a cargo del seguro',
            valor: enteroIncapacidad(diasSeguro),
          );
          final monto = _Dato(
            rotulo: 'Descuento total',
            valor: montoIncapacidad(descuento),
            unidad: 'Bs',
            fuerte: true,
          );

          if (cajon.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                progreso,
                const SizedBox(height: Esp.l),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dias),
                    const SizedBox(width: Esp.l),
                    Expanded(child: monto),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: progreso),
              const _Separador(),
              Expanded(flex: 3, child: dias),
              const _Separador(),
              Expanded(flex: 3, child: monto),
            ],
          );
        },
      ),
    );
  }
}

class _Progreso extends StatelessWidget {
  final int revisadas;
  final int total;

  const _Progreso({required this.revisadas, required this.total});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pendientes = total - revisadas;
    final avance = total == 0 ? 0.0 : revisadas / total;
    final completo = total > 0 && pendientes == 0;
    final nota = switch (total) {
      0 => 'Sin bajas en el rango',
      _ when completo => 'Todo el rango está revisado',
      _ => pendientes == 1 ? 'Falta 1 baja' : 'Faltan $pendientes bajas',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Rotulo('Revisión'),
        const SizedBox(height: Esp.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: enteroIncapacidad(revisadas),
                style: tema.textTheme.headlineSmall?.copyWith(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              TextSpan(
                text: ' de ${enteroIncapacidad(total)} revisadas',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Esp.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.pastilla),
          child: LinearProgressIndicator(
            value: avance,
            minHeight: 8,
            color: TareasColors.realizadoTexto(context),
            backgroundColor: TareasColors.pendiente(context),
            semanticsLabel: 'Avance de la revisión',
            semanticsValue: '${(avance * 100).round()} %',
          ),
        ),
        const SizedBox(height: Esp.xs + 2),
        Text(
          nota,
          style: tema.textTheme.bodySmall?.copyWith(
            color:
                completo
                    ? TareasColors.realizadoTexto(context)
                    : tema.colorScheme.onSurfaceVariant,
            fontWeight: completo ? Peso.titulo : null,
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String rotulo;
  final String valor;
  final String? unidad;
  final bool fuerte;

  const _Dato({
    required this.rotulo,
    required this.valor,
    this.unidad,
    this.fuerte = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: Esp.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                if (unidad != null)
                  TextSpan(
                    text: '$unidad ',
                    style: tema.textTheme.titleSmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                TextSpan(
                  text: valor,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: fuerte ? Peso.dato : Peso.titulo,
                    fontFeatures: cifrasTabulares,
                    color: fuerte ? tema.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      texto.toUpperCase(),
      maxLines: 2,
      style: tema.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        fontWeight: Peso.titulo,
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 72,
    margin: const EdgeInsets.symmetric(horizontal: Esp.l),
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

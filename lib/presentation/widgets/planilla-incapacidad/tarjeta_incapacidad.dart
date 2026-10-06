import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/formato_incapacidad.dart';
import 'package:bosque_flutter/presentation/widgets/planilla-incapacidad/interruptor_revision.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:flutter/material.dart';

/// Una baja en pantallas angostas: quién y cuándo arriba, los importes abajo
/// y el descuento al final, que es el número que se revisa.
class TarjetaIncapacidad extends StatelessWidget {
  final PlanillaIncapacidadEntity fila;
  final bool guardando;
  final ValueChanged<bool> onMarcar;

  const TarjetaIncapacidad({
    super.key,
    required this.fila,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: FranjaAcento(
        color: fila.fueRevisado ? null : TareasColors.pendienteTexto(context),
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fila.datoEmpleado,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: Peso.titulo,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fila.motivo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Esp.m),
                  InterruptorRevision(
                    revisado: fila.fueRevisado,
                    fecha: fila.fechaRevisado,
                    guardando: guardando,
                    onCambiar: onMarcar,
                  ),
                ],
              ),
              const SizedBox(height: Esp.m),
              _Linea(
                icono: Icons.event_outlined,
                texto:
                    '${periodoBaja(fila.desde, fila.hasta)} · '
                    '${_dias(fila.diasBaja)}, ${enteroIncapacidad(fila.diasAsumidosCordes)} a cargo del seguro',
              ),
              const SizedBox(height: Esp.xs),
              _Linea(
                icono: Icons.health_and_safety_outlined,
                texto: seguroBaja(fila.seguro, fila.numSeguro),
              ),
              const SizedBox(height: Esp.m),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: Esp.m),
              Wrap(
                spacing: Esp.xl,
                runSpacing: Esp.m,
                children: [
                  _Importe('Salario mensual', fila.salarioMensual),
                  _Importe('Diario', fila.salarioDiario),
                  _Importe('75 % diario', fila.porcentajeAl75),
                  _Importe('Descuento', fila.totalDescuento, fuerte: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dias(int n) => n == 1 ? '1 día' : '${enteroIncapacidad(n)} días';
}

class _Linea extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Linea({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: tema.colorScheme.onSurfaceVariant),
        const SizedBox(width: Esp.xs + 2),
        Expanded(
          child: Text(
            texto,
            style: tema.textTheme.bodySmall?.copyWith(
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
      ],
    );
  }
}

class _Importe extends StatelessWidget {
  final String rotulo;
  final double valor;
  final bool fuerte;

  const _Importe(this.rotulo, this.valor, {this.fuerte = false});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: context.apagado()),
        Text(
          montoIncapacidad(valor),
          style: (fuerte ? tema.textTheme.titleMedium : tema.textTheme.bodyLarge)
              ?.copyWith(
                fontWeight: fuerte ? Peso.dato : Peso.normal,
                fontFeatures: cifrasTabulares,
                color: fuerte ? tema.colorScheme.primary : null,
              ),
        ),
      ],
    );
  }
}

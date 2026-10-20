/// Los exámenes de quien rinde (empleado o postulante): qué tiene pendiente,
/// en curso y ya calificado, con la acción que corresponde a cada uno.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

class ListaMisExamenes extends StatelessWidget {
  const ListaMisExamenes({super.key, required this.examenes, required this.onAbrir});

  final List<TcpeEstadoRendicionEntity> examenes;
  final void Function(TcpeEstadoRendicionEntity examen) onAbrir;

  /// Lo pendiente primero: en curso, sin iniciar y después lo cerrado.
  static int _peso(TcpeEstadoRendicionEntity e) => switch (EstadoExamenTcpe.desde(e.estado)) {
    EstadoExamenTcpe.enCurso => 0,
    EstadoExamenTcpe.sinIniciar => 1,
    EstadoExamenTcpe.porRevisar => 2,
    _ => 3,
  };

  static String accion(TcpeEstadoRendicionEntity e) {
    if (!e.esOnline) return 'Ver';
    return switch (EstadoExamenTcpe.desde(e.estado)) {
      EstadoExamenTcpe.sinIniciar => 'Empezar',
      EstadoExamenTcpe.enCurso => 'Continuar',
      _ => 'Ver resultado',
    };
  }

  @override
  Widget build(BuildContext context) {
    final filas = [...examenes]..sort((a, b) => _peso(a).compareTo(_peso(b)));
    return TablaExamenes<TcpeEstadoRendicionEntity>(
      filas: filas,
      claveFila: (e) => e.codExamen,
      tonoFila: (e) => aspectoDeEstado(EstadoExamenTcpe.desde(e.estado)).$1,
      alTocarFila: onAbrir,
      vacio: const VacioExamenes(
        icono: Icons.assignment_outlined,
        titulo: 'No tienes exámenes asignados',
        detalle: 'Cuando el evaluador te asigne uno, aparecerá aquí.',
      ),
      columnas: [
        ColumnaExamen(
          'Examen',
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [CeldaTexto(e.titulo, fuerte: true), CeldaTexto(e.nombreClasificacion, apagado: true)],
          ),
          flex: 6,
        ),
        ColumnaExamen('Modalidad', (e) => PastillaModalidad(e.modalidad), flex: 2),
        ColumnaExamen('Tiempo', (e) => _tiempo(context, e), flex: 2),
        ColumnaExamen('Estado', (e) => EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)), flex: 2),
        ColumnaExamen('Resp.', (e) => CeldaNumero('${e.respondidas}/${e.totalPreguntas}'), flex: 2, alinear: Alignment.centerRight),
        ColumnaExamen(
          'Nota',
          (e) => CeldaNumero(
            nota(e.notaVisible),
            fuerte: true,
            color: switch (e.aprobacion) {
              true => Theme.of(context).colorScheme.primary,
              false => Theme.of(context).colorScheme.error,
              null => null,
            },
          ),
          flex: 1,
          alinear: Alignment.centerRight,
        ),
        ColumnaExamen('Resultado', (e) => EtiquetaAprobacion(e.aprobacion, enCelda: true), flex: 2),
        ColumnaExamen(
          '',
          (e) => _botonAbrir(e),
          flex: 2,
          alinear: Alignment.centerRight,
        ),
      ],
      tarjeta:
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.titulo ?? 'Examen', style: Theme.of(context).textTheme.titleSmall)),
                  EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)),
                ],
              ),
              const SizedBox(height: Esp.xs),
              Text(
                '${e.nombreClasificacion ?? ''} · ${e.totalPreguntas} preguntas · ${duracionTexto(e.duracionMinutos)}',
                style: context.apagado(),
              ),
              if ((e.mensajeEstado ?? '').trim().isNotEmpty) Text(e.mensajeEstado!.trim(), style: context.apagado()),
              if (e.notaVisible != null) ...[
                const SizedBox(height: Esp.xs),
                Wrap(
                  spacing: Esp.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Nota ${nota(e.notaVisible)}', style: context.numero(fuerte: true)),
                    if (e.aprobacion != null) EtiquetaAprobacion(e.aprobacion),
                  ],
                ),
              ],
              const SizedBox(height: Esp.s),
              Row(
                children: [
                  _tiempo(context, e),
                  const Spacer(),
                  _botonAbrir(e),
                ],
              ),
            ],
          ),
    );
  }

  /// Empezar o continuar es lo principal (relleno); ver un resultado, tonal.
  Widget _botonAbrir(TcpeEstadoRendicionEntity e) {
    final estado = EstadoExamenTcpe.desde(e.estado);
    final pendiente = e.esOnline && (estado == EstadoExamenTcpe.sinIniciar || estado == EstadoExamenTcpe.enCurso);
    if (!pendiente) return FilledButton.tonal(onPressed: () => onAbrir(e), child: Text(accion(e)));
    return FilledButton.icon(
      onPressed: () => onAbrir(e),
      icon: Icon(estado == EstadoExamenTcpe.enCurso ? Icons.play_arrow_rounded : Icons.edit_outlined, size: 18),
      label: Text(accion(e)),
    );
  }

  Widget _tiempo(BuildContext context, TcpeEstadoRendicionEntity e) {
    if (EstadoExamenTcpe.desde(e.estado) == EstadoExamenTcpe.enCurso) {
      return Text(
        'Quedan ${CronometroExamen.formato(e.segundosRestantes)}',
        style: context.numero(fuerte: true, color: Theme.of(context).colorScheme.tertiary),
      );
    }
    return CeldaTexto(duracionTexto(e.duracionMinutos), apagado: true);
  }
}

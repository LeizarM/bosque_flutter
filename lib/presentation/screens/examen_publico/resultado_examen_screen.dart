/// `/examen/resultado/:codExamen`: cómo quedó el examen del postulante, con
/// la nota, si aprobó y la devolución pregunta por pregunta.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/ingreso_examen_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/marco_publico.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/resultado_examen.dart';

class ResultadoExamenScreen extends ConsumerWidget {
  const ResultadoExamenScreen({super.key, required this.codExamen});

  final String codExamen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cod = BigInt.tryParse(codExamen);
    void volver() => context.go(AppConstants.rutaTcpeIngreso);
    if (cod == null) {
      return MarcoPublicoExamen(child: MensajeError(error: 'El enlace del examen no es válido.', onReintentar: volver));
    }
    final estado = ref.watch(estadoExamenPostulanteProvider(cod));
    return estado.when(
      loading: () => const MarcoPublicoExamen(child: SizedBox(height: 240, child: EsqueletoLista(filas: 3))),
      error:
          (e, _) => MarcoPublicoExamen(
            child: MensajeError(error: e, onReintentar: () => ref.invalidate(estadoExamenPostulanteProvider(cod))),
          ),
      data: (e) {
        if (e == null) {
          return MarcoPublicoExamen(
            child: MensajeError(error: 'No encontramos este examen entre los tuyos.', onReintentar: volver),
          );
        }
        if (e.esOnline && EstadoExamenTcpe.desde(e.estado).cerrado) {
          return MarcoPublicoExamen(
            centrado: false,
            child: ResultadoExamen(
              clave: ClaveRendicion(OrigenRendicion.postulante, cod),
              estado: e,
              onSalir: volver,
            ),
          );
        }
        return MarcoPublicoExamen(
          child: _Abierto(estado: e, onVolver: volver, onRendir: () => context.go(rutaRendir(cod))),
        );
      },
    );
  }
}

/// Un examen todavía abierto (o escrito): no hay resultado que mostrar.
class _Abierto extends StatelessWidget {
  const _Abierto({required this.estado, required this.onVolver, required this.onRendir});

  final TcpeEstadoRendicionEntity estado;
  final VoidCallback onVolver;
  final VoidCallback onRendir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final abierto = estado.esOnline && !EstadoExamenTcpe.desde(estado.estado).cerrado;
    return TarjetaPublica(
      children: [
        Icon(abierto ? Icons.play_circle_outline : Icons.edit_note_outlined, size: 40, color: cs.primary),
        const SizedBox(height: Esp.m),
        Text(estado.titulo ?? 'Examen', style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Text(
          abierto ? 'Tu examen sigue abierto' : 'Este examen es escrito',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.s),
        Text(
          abierto
              ? 'Todavía puedes rendirlo.'
              : 'Se rinde en papel, en el lugar y la hora que indicó el evaluador.',
        ),
        const SizedBox(height: Esp.l),
        Text('${estado.respondidas} de ${estado.totalPreguntas} preguntas respondidas', style: context.apagado()),
        const SizedBox(height: Esp.xl),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            TextButton(onPressed: onVolver, child: const Text('Volver a mis exámenes')),
            if (abierto) FilledButton(onPressed: onRendir, child: const Text('Ir al examen')),
          ],
        ),
      ],
    );
  }
}

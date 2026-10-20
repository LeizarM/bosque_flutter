/// Mis exámenes (`tcpeExamenes/MisExamenes`): la lista del empleado. Cada
/// examen se rinde a pantalla completa en su propia ruta, fuera del shell. El
/// backend busca su `tcpe_usuario` por el `codEmpleado` del token.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/rendir_mi_examen_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/lista_mis_examenes.dart';

class MisExamenesScreen extends ConsumerWidget {
  const MisExamenesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final datos = ref.watch(tcpeMisExamenesProvider);
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        return Scaffold(
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Evaluaciones',
                  titulo: 'Mis exámenes',
                  icono: Icons.assignment_outlined,
                  detalle: 'Los exámenes que te asignaron. Al empezar uno, el tiempo corre aunque salgas de la pantalla.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(tcpeMisExamenesProvider),
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                Expanded(
                  child: datos.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoLista(),
                    error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(tcpeMisExamenesProvider)),
                    data:
                        (lista) => ListaMisExamenes(
                          examenes: lista,
                          onAbrir: (e) {
                            if (EstadoExamenTcpe.desde(e.estado) == EstadoExamenTcpe.desconocido) return;
                            GoRouter.maybeOf(context)?.go(rutaRendirMiExamen(e.codExamen));
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

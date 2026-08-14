import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/abono_dias_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los días libres que se le acreditaron a alguien por fuera de la vacación. Es
/// la pestaña «Abonos».
///
/// **Acá el alta sí es un botón suelto**, al revés que en la vacación asignada:
/// un abono no cuelga de ningún aniversario, se carga el día que se decide.
///
/// El total lo manda el backend con la lista (`totalDias` del subreporte) y es
/// el mismo número que la ficha muestra como «Días abonados»: si los dos no
/// coinciden, el que está mal es el de acá —esta lista es de una relación
/// laboral y la ficha también—.
class AbonoDiasTab extends ConsumerWidget {
  const AbonoDiasTab({super.key, required this.codEmpleado});

  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clave = (codEmpleado: codEmpleado, codRelEmplEmpr: 0);
    final abonos = ref.watch(detalleAbonosProvider(clave));
    final ficha = ref.watch(fichaSaldoProvider(codEmpleado)).valueOrNull;

    return abonos.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar: () => ref.invalidate(detalleAbonosProvider(clave)),
          ),
      data: (filas) {
        // El alta necesita la relación laboral vigente y **no la inventa**: sin
        // ella el SP escribiría la fila en ninguna relación y ninguna lectura
        // volvería a encontrarla. Sale de la ficha, que es quien la resuelve.
        final relacion = ficha?.datoRelEmplEmprVigente ?? 0;
        final nombre = ficha?.datoEmpleado ?? '';

        return LayoutBuilder(
          builder: (context, cajon) {
            final aire = Aire.de(cajon.maxWidth);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(detalleAbonosProvider(clave));
                await ref.read(detalleAbonosProvider(clave).future);
              },
              child: ListView(
                padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Bloque(
                        icono: Icons.add_card_outlined,
                        titulo: 'Días abonados',
                        explicacion:
                            'Días libres que se cobran igual: compensaciones y '
                            'regularizaciones. Suman al saldo.',
                        hijo: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // La pestaña la abre `btnDetalles` (leer); cargar
                            // pide `btnEditarAbonoDia`, que es lo que exige el
                            // backend en `/abono-dias/registrar`.
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PermissionWidget(
                                buttonName: btnAbonoDias,
                                child: FilledButton.icon(
                                  // Apagado y no escondido: sin relación
                                  // laboral el alta no se puede hacer, y quien
                                  // mira tiene que saber por qué.
                                  onPressed:
                                      relacion <= 0
                                          ? null
                                          : () => mostrarAbonoDiasSheet(
                                            context: context,
                                            abono: AbonoDiasEntity(
                                              codAbonoDias: 0,
                                              codEmpleado: codEmpleado,
                                              codRelEmplEmpr: relacion,
                                              diasAbonados: 0,
                                              motivo: '',
                                              fecha: DateTime.now(),
                                            ),
                                            datoEmpleado: nombre,
                                          ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Abonar días'),
                                ),
                              ),
                            ),
                            if (relacion <= 0) ...[
                              const SizedBox(height: Esp.s),
                              const AvisoDelDato(
                                icono: Icons.warning_amber_rounded,
                                texto:
                                    'No se pudo resolver la relación laboral '
                                    'vigente de este empleado, así que no se '
                                    'puede abonar. Revise la pestaña «Saldo».',
                              ),
                            ],
                            const Divider(height: Esp.xl),
                            if (filas.isEmpty)
                              Text(
                                'Este empleado no tiene ningún día abonado en '
                                'su relación laboral vigente.',
                                style: context.apagado(),
                              )
                            else ...[
                              for (final a in filas)
                                _Fila(abono: a, datoEmpleado: nombre),
                              const SizedBox(height: Esp.s),
                              _Total(abonos: filas),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Fila extends ConsumerWidget {
  const _Fila({required this.abono, required this.datoEmpleado});

  final AbonoDiasEntity abono;
  final String datoEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = abono;
    final dias =
        a.diasAbonadosTxt.isEmpty
            ? '${numeroDeDias(a.diasAbonados)} días'
            : a.diasAbonadosTxt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                fechaCorta(a.fecha),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: Peso.titulo,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              Text(dias, style: context.numero(fuerte: true)),
            ],
          ),
          if (a.motivo.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(a.motivo, style: context.apagado()),
          ],
          const SizedBox(height: Esp.xs),
          // Sin id no hay edición posible: el botón mandaría un alta. Pasa si el
          // backend arma la lista con el subreporte `'B'`, que no trae el id.
          if (a.esAlta)
            Text(
              'Este abono llegó sin identificador, así que no se puede editar '
              'ni borrar desde acá. Avisá a Sistemas.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.cs.error),
            )
          else
            Wrap(
              spacing: Esp.s,
              children: [
                PermissionWidget(
                  buttonName: btnAbonoDias,
                  child: TextButton.icon(
                    onPressed:
                        () => mostrarAbonoDiasSheet(
                          context: context,
                          abono: a,
                          datoEmpleado: datoEmpleado,
                        ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
                PermissionWidget(
                  buttonName: btnAbonoDias,
                  child: TextButton.icon(
                    onPressed: () => _eliminar(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          const Divider(height: Esp.m),
        ],
      ),
    );
  }

  /// La baja, con `ACCION 'D'`.
  ///
  /// **No es lo que hace el legacy**: allá `eliminarAbonDia()` llama a
  /// `registrar()`, que con id distinto de cero manda una `'U'` con todo en
  /// NULL — código que parece que borra y no borra. Acá borra, y el trigger
  /// `dad_abonoDias` archiva la fila en `trh_abonoDiasEliminado`.
  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final quien = datoEmpleado.isEmpty ? 'este empleado' : datoEmpleado;
    final cuantos =
        abono.diasAbonadosTxt.isEmpty
            ? '${numeroDeDias(abono.diasAbonados)} días'
            : abono.diasAbonadosTxt;
    final ok = await confirmar(
      context,
      titulo: '¿Borrar el abono?',
      mensaje:
          'Vas a borrar los $cuantos abonados a $quien con fecha '
          '${fechaCorta(abono.fecha)}.\n\n'
          'Esa cantidad deja de sumar a su saldo. La fila queda archivada: '
          'Sistemas puede recuperarla.',
      accion: 'Borrar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    try {
      final msg = await ref
          .read(permisosRrhhAccionesProvider)
          .eliminarAbonoDias(abono);
      if (!context.mounted) return;
      avisar(context, msg.isEmpty ? 'Se borró el abono.' : msg);
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

/// El acumulado que manda el backend, repetido en cada fila: se lee de la
/// primera y no se vuelve a sumar acá — el número que RR.HH. compara es el del
/// servidor.
class _Total extends StatelessWidget {
  const _Total({required this.abonos});

  final List<AbonoDiasEntity> abonos;

  @override
  Widget build(BuildContext context) {
    final primera = abonos.first;
    final texto =
        primera.totalDiasTxt.isEmpty
            ? '${numeroDeDias(primera.totalDias)} días'
            : primera.totalDiasTxt;

    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total abonado (${abonos.length} ${abonos.length == 1 ? 'registro' : 'registros'})',
              style: context.tituloSeccion(),
            ),
          ),
          const SizedBox(width: Esp.s),
          Text(
            texto,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ],
      ),
    );
  }
}

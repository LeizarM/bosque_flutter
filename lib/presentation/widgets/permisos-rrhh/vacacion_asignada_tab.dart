import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/vacacion_asignada_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los días que la empresa le **debe** a alguien, un año laboral por fila. Es la
/// pestaña «Asignada».
///
/// **El SP devuelve una fila por aniversario, no una por registro.**
/// `p_list_vacacionAsignada 'B'` recorre la relación laboral desde su
/// `fechaIni` sumando un año, y por cada aniversario que todavía no tiene
/// registro **inventa una fila** con `codVacacionAsignada = 0`.
///
/// **Esas filas inventadas no se listan.** La grilla muestra sólo lo que existe
/// de verdad en `trh_vacacionAsignada`, para que no se confunda un año
/// pendiente con uno cargado en cero.
///
/// **Pero la fecha del alta sigue sin ser libre**, y eso no cambió: el backend
/// (`validarAniversarioLibre`) sólo acepta uno de los aniversarios que arma ese
/// mismo SP; cargar otra fecha sería una asignación que ningún tramo del
/// desglose va a encontrar. Así que el botón de arriba no abre un formulario en
/// blanco: **abre el aniversario pendiente más viejo**, que es la única fila que
/// se podía cargar cuando el alta vivía dentro de la grilla.
///
/// **Esta pantalla no es la única que escribe esta tabla.** 1.155 de sus 1.424
/// filas las puso un proceso automático (`audUsuarioI = -1`, día 1 de cada mes a
/// las 07:00) y ya hay filas fechadas en 2026: la lista se relee después de cada
/// escritura y no se cachea entre sesiones.
class VacacionAsignadaTab extends ConsumerWidget {
  const VacacionAsignadaTab({super.key, required this.codEmpleado});

  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Relación en 0 = «la vigente, la resuelve el servidor». El saldo se cuenta por
    // relación laboral, así que la pantalla no elige una: la elige el servidor,
    // que es el que sabe cuál está activa.
    final clave = (codEmpleado: codEmpleado, codRelEmplEmpr: 0);
    final historial = ref.watch(historialVacacionAsignadaProvider(clave));

    // Para nombrar a la persona en la confirmación. El SP lo manda en cada fila;
    // la ficha es el respaldo para cuando la lista viene vacía.
    final deLaFicha =
        ref.watch(fichaSaldoProvider(codEmpleado)).valueOrNull?.datoEmpleado ??
        '';

    return historial.when(
      loading: () => const Cargando(),
      error:
          (e, _) => ErrorDelDato(
            error: e,
            onReintentar:
                () => ref.invalidate(historialVacacionAsignadaProvider(clave)),
          ),
      data: (todas) {
        // Lo que existe en la base, y los aniversarios que todavía no.
        final filas = todas.where((v) => !v.esSintetica).toList();
        final pendientes = todas.where((v) => v.esSintetica).toList();

        if (todas.isEmpty) {
          return const MensajeVacio(
            icono: Icons.event_busy_outlined,
            titulo: 'Sin aniversarios que mostrar',
            detalle:
                'El sistema anterior no pudo armar el año laboral de este '
                'empleado. Verifique que tenga fecha de inicio de beneficio y '
                'relación laboral activa.',
          );
        }

        return LayoutBuilder(
          builder: (context, cajon) {
            final aire = Aire.de(cajon.maxWidth);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(historialVacacionAsignadaProvider(clave));
                await ref.read(historialVacacionAsignadaProvider(clave).future);
              },
              child: ListView(
                padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Bloque(
                        icono: Icons.event_available_outlined,
                        titulo: 'Vacación asignada',
                        explicacion:
                            'Un año cumplido por fila, y sólo los que ya están '
                            'registrados. Los que faltan se cargan con el '
                            'botón de arriba.',
                        hijo: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Alta(pendientes: pendientes, deLaFicha: deLaFicha),
                            if (filas.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Esp.m,
                                ),
                                child: Text(
                                  'Todavía no hay ninguna asignación '
                                  'registrada para esta relación laboral.',
                                  style: context.apagado(),
                                ),
                              )
                            else
                              for (final v in filas)
                                _Fila(
                                  vacacion: v,
                                  datoEmpleado:
                                      v.datoEmpleado.isEmpty
                                          ? deLaFicha
                                          : v.datoEmpleado,
                                ),
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

/// El alta, que dejó de ser una fila de la grilla.
///
/// **Dice a qué aniversario va, y no sólo «Nuevo».** El backend sólo acepta uno
/// de los aniversarios que arma el SP, así que este botón no abre un formulario
/// en blanco: abre el pendiente **más viejo**. Con la fecha puesta en el botón,
/// quien lo aprieta sabe qué año está por cargar antes de abrir nada — que era
/// lo que se veía solo cuando el alta era la fila.
///
/// Sin aniversarios pendientes no hay nada que cargar y el botón no existe:
/// ofrecerlo llevaría a un formulario que el backend va a rechazar.
class _Alta extends StatelessWidget {
  const _Alta({required this.pendientes, required this.deLaFicha});

  final List<VacacionAsignadaEntity> pendientes;
  final String deLaFicha;

  @override
  Widget build(BuildContext context) {
    if (pendientes.isEmpty) return const SizedBox.shrink();

    // El SP recorre los aniversarios desde `fechaIni` hacia adelante, así que
    // el primero es el más viejo. Es el que hay que cargar primero: dejar
    // huecos atrás desordena el desglose.
    final proxima = pendientes.first;

    return PermissionWidget(
      buttonName: btnVacacionAsignada,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.tonalIcon(
              onPressed:
                  () => mostrarVacacionAsignadaSheet(
                    context: context,
                    vacacion: proxima,
                    datoEmpleado:
                        proxima.datoEmpleado.isEmpty
                            ? deLaFicha
                            : proxima.datoEmpleado,
                  ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Asignar ${fechaCorta(proxima.fecha)}'),
            ),
            const SizedBox(height: Esp.xs),
            Text(
              pendientes.length == 1
                  ? 'Es el único año cumplido que todavía no tiene asignación.'
                  : 'Faltan ${pendientes.length} años por asignar; se cargan '
                      'del más viejo al más nuevo.',
              style: context.apagado(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un aniversario ya registrado.
class _Fila extends ConsumerWidget {
  const _Fila({required this.vacacion, required this.datoEmpleado});

  final VacacionAsignadaEntity vacacion;
  final String datoEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vacacion;
    // Los días ya vienen formateados del backend; los de una fila sintética no
    // existen todavía, así que ahí no se muestra ningún número.
    final dias =
        v.diasAsignadosTxt.isEmpty
            ? '${numeroDeDias(v.diasAsignados)} días'
            : v.diasAsignadosTxt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `Wrap` y no `Row`: la fecha, el número y la etiqueta no entran en
          // una línea de 360 px, y un `Row` que no entra pinta la franja
          // amarilla y negra en vez de acomodarse.
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                fechaCorta(v.fecha),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: Peso.titulo,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              Text(dias, style: context.numero(fuerte: true)),
            ],
          ),
          if (v.motivo.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(v.motivo, style: context.apagado()),
          ],
          const SizedBox(height: Esp.xs),
          // **La pestaña es de lectura (`btnDetalles`); esto es la escritura.**
          // Son dos permisos distintos y el backend los pide por separado, así
          // que quien puede mirar el historial no necesariamente puede cargar
          // ni borrar. La baja va con su propia constante aunque hoy apunte al
          // mismo botón: ver `btnVacacionAsignadaBaja`.
          Wrap(
            spacing: Esp.s,
            children: [
              PermissionWidget(
                buttonName: btnVacacionAsignada,
                child: TextButton.icon(
                  onPressed: () => _abrir(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              PermissionWidget(
                buttonName: btnVacacionAsignadaBaja,
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

  void _abrir(BuildContext context) => mostrarVacacionAsignadaSheet(
    context: context,
    vacacion: vacacion,
    datoEmpleado: datoEmpleado,
  );

  /// La baja.
  ///
  /// **Es una operación que hoy nadie puede ejecutar**: en el legacy el botón
  /// Eliminar está con `rendered="false"`. Traerla no es migrar, es habilitar,
  /// así que la confirmación dice las dos cosas que importan: que el registro
  /// deja de sumar al saldo, y que se puede recuperar —el trigger
  /// `dad_vacacionAsignada` copia la fila entera a
  /// `trh_vacacionAsignadaEliminado` antes de que desaparezca—.
  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final quien = datoEmpleado.isEmpty ? 'este empleado' : datoEmpleado;
    final ok = await confirmar(
      context,
      titulo: '¿Borrar la asignación?',
      mensaje:
          'Vas a borrar los ${vacacion.diasAsignadosTxt.isEmpty ? '${numeroDeDias(vacacion.diasAsignados)} días' : vacacion.diasAsignadosTxt} '
          'asignados a $quien con fecha ${fechaCorta(vacacion.fecha)}.\n\n'
          'Esa cantidad deja de sumar a su saldo de vacación. La fila queda '
          'archivada: Sistemas puede recuperarla.',
      accion: 'Borrar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    try {
      final msg = await ref
          .read(permisosRrhhAccionesProvider)
          .eliminarVacacionAsignada(vacacion);
      if (!context.mounted) return;
      // El mensaje del servidor tal cual: ya viene redactado para quien lo lee.
      avisar(context, msg.isEmpty ? 'Se borró la asignación.' : msg);
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }
}

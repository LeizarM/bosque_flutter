import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tramo_saldo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **De dónde sale un tramo del desglose**: los permisos que suman ese número.
///
/// El desglose dice «Vacación utilizada desde el (28/02/2025) hasta hoy — 11,5
/// días» y hasta ahora había que creerle. Esta hoja abre la cuenta: lista los
/// permisos que la componen y al pie vuelve a sumarlos, para que el número se
/// explique solo.
///
/// Sólo tres de los cinco tramos se abren. `ASIGNADA_ANIO` suma
/// `trh_vacacionAsignada` —que tiene su propia pestaña— y `ACUMULADA` es
/// `f_calcVacacionesAnioLaboral`, una fórmula: no hay lista que mostrar.
Future<void> mostrarDetalleTramo(
  BuildContext context, {
  required int codEmpleado,
  required TramoSaldoEntity tramo,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (_) => _DetalleTramoSheet(codEmpleado: codEmpleado, tramo: tramo),
);

class _DetalleTramoSheet extends ConsumerWidget {
  const _DetalleTramoSheet({required this.codEmpleado, required this.tramo});

  final int codEmpleado;
  final TramoSaldoEntity tramo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clave = (codEmpleado: codEmpleado, clave: tramo.clave);
    final detalle = ref.watch(detalleTramoProvider(clave));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // La etiqueta literal del SP, la misma que se tocó para llegar
              // acá: si dijera otra cosa, parecería otro dato.
              Text(tramo.etiqueta, style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              Text(
                'Los permisos que suman ${tramo.montoTxt}.',
                style: context.apagado(),
              ),
              const Divider(height: Esp.xl),
              Flexible(
                child: detalle.when(
                  loading: () => const Cargando(),
                  error:
                      (e, _) => ErrorDelDato(
                        error: e,
                        onReintentar:
                            () => ref.invalidate(detalleTramoProvider(clave)),
                      ),
                  data: (lista) => _cuerpo(context, lista),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, List<NominaPermisoEntity> lista) {
    if (lista.isEmpty) {
      return const MensajeVacio(
        icono: Icons.event_busy_outlined,
        titulo: 'Sin permisos en este tramo',
        detalle:
            'El tramo no se arma con permisos registrados. Si el monto no es '
            'cero, el número viene de otra parte del cálculo.',
      );
    }

    final suma = lista.fold<double>(0, (a, p) => a + p.dias);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: lista.length,
            separatorBuilder: (_, _) => const Divider(height: Esp.l),
            itemBuilder: (_, i) => _fila(context, lista[i]),
          ),
        ),
        const Divider(height: Esp.xl),
        // El cierre de la cuenta. Que la suma de las filas coincida con el
        // monto del tramo es justo lo que se vino a comprobar, así que se dice
        // en vez de dejarlo para que el ojo lo haga.
        Row(
          children: [
            Expanded(
              child: Text(
                '${lista.length} permiso(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '${numeroDeDias(suma)} d',
              style: context.numero(fuerte: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fila(BuildContext context, NominaPermisoEntity p) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${fechaCorta(p.desde)} → ${fechaCorta(p.hasta)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFeatures: cifrasTabulares,
              ),
            ),
            if (p.motivo.trim().isNotEmpty)
              Text(p.motivo, style: context.apagado()),
          ],
        ),
      ),
      const SizedBox(width: Esp.m),
      Text('${numeroDeDias(p.dias)} d', style: context.numero(fuerte: true)),
    ],
  );
}

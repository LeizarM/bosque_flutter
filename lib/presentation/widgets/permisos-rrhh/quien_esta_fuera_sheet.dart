import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Quién está fuera hoy, y quién sale pronto.**
///
/// Es la única vista del módulo que no es por empleado: todo lo demás responde
/// «¿cuántos días tiene Fulano?» y esto responde «¿quién falta hoy?», que es la
/// pregunta de pasillo.
///
/// Reemplaza al *Cronograma de Vacaciones* del sistema anterior, que está en el
/// menú de 194 usuarios pero **no funciona**: su bean `cronogramaBackBean` no
/// existe en el código fuente, y sus tres reportes Jasper tienen la consulta
/// vacía porque los alimentaba ese bean. Acá el dato sale del SP
/// (`p_list_Permiso 'Q'` sin `codEmpleado`), no de una colección en memoria.
Future<void> mostrarQuienEstaFuera(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _QuienEstaFueraSheet(),
    );

class _QuienEstaFueraSheet extends ConsumerWidget {
  const _QuienEstaFueraSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = ref.watch(quienEstaFueraHoyProvider);
    final pronto = ref.watch(quienSaleProntoProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Quién está fuera', style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              Text(
                'De toda la empresa, no del empleado seleccionado.',
                style: context.apagado(),
              ),
              const Divider(height: Esp.xl),

              _seccion(
                context,
                ref,
                titulo: 'Hoy',
                vacio:
                    'Nadie está de permiso hoy. Todos los que tienen permiso '
                    'cargado empiezan más adelante.',
                datos: hoy,
                provider: quienEstaFueraHoyProvider,
              ),
              const SizedBox(height: Esp.xl),
              _seccion(
                context,
                ref,
                titulo: 'Salen en los próximos 30 días',
                vacio: 'No hay permisos cargados para el mes que viene.',
                datos: pronto,
                provider: quienSaleProntoProvider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(
    BuildContext context,
    WidgetRef ref, {
    required String titulo,
    required String vacio,
    required AsyncValue<List<NominaPermisoEntity>> datos,
    required ProviderBase<Object?> provider,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
          ),
          const SizedBox(width: Esp.s),
          datos.maybeWhen(
            data:
                (l) =>
                    l.isEmpty
                        ? const SizedBox.shrink()
                        : Etiqueta(texto: '${l.length}'),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      const SizedBox(height: Esp.s),
      datos.when(
        loading: () => const Cargando(),
        error:
            (e, _) =>
                ErrorDelDato(error: e, onReintentar: () => ref.invalidate(provider)),
        data:
            (lista) =>
                lista.isEmpty
                    ? Text(vacio, style: context.apagado())
                    : Column(children: [for (final p in lista) _fila(context, p)]),
      ),
    ],
  );

  Widget _fila(BuildContext context, NominaPermisoEntity p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.datoEmpleado.trim().isEmpty
                    ? 'Empleado ${p.codEmpleado}'
                    : p.datoEmpleado,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${fechaCorta(p.desde)} → ${fechaCorta(p.hasta)}',
                style: context.apagado()?.copyWith(
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Esp.m),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${numeroDeDias(p.dias)} d',
              style: context.numero(fuerte: true),
            ),
            if (p.datoTipoPermiso.trim().isNotEmpty)
              Text(p.datoTipoPermiso, style: context.apagado()),
          ],
        ),
      ],
    ),
  );
}

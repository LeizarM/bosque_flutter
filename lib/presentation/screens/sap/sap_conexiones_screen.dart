import 'package:bosque_flutter/core/state/sap_conexion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/sap/sap_conexion_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las conexiones a SAP que comparten los módulos (Administración > Conexiones SAP): una tarjeta
/// por conexión, con su empresa, si apunta a la base real o a la de prueba, dónde corren los SP y
/// con qué usuario se entra al Service Layer.
///
/// Los módulos (por ahora, el asiento de planilla) eligen una de estas conexiones en su propia
/// configuración. Todo vive en la base (tsap_Conexion): un cambio rige en el próximo uso, sin
/// compilar ni reiniciar nada.
class SapConexionesScreen extends ConsumerWidget {
  const SapConexionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conexiones = ref.watch(sapConexionesProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final margen = aire.esChico ? Esp.m : Esp.xl;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(
                aire: aire,
                margen: margen,
                onAgregar: conexiones.hasValue ? () => editarSapConexion(context, ref) : null,
              ),
              // Dos píxeles siempre reservados: así la página no salta en cada recarga.
              if (conexiones.isLoading && conexiones.hasValue)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child: conexiones.when(
                  loading: () => const EsqueletoLista(filas: 3, altoFila: 150),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        onReintentar: () => ref.invalidate(sapConexionesProvider),
                      ),
                  data:
                      (lista) =>
                          lista.isEmpty
                              ? const MensajeVacio(
                                icono: Icons.hub_outlined,
                                titulo: 'Ninguna conexión',
                                detalle:
                                    'Agrega una con «Agregar conexión»: la empresa, su base de SAP '
                                    'y el usuario del Service Layer.',
                              )
                              : ListView.separated(
                                padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.xxl),
                                itemCount: lista.length,
                                separatorBuilder: (_, __) => const SizedBox(height: Esp.m),
                                itemBuilder:
                                    (_, i) => Align(
                                      alignment: Alignment.topCenter,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 1100),
                                        child: _Tarjeta(conexion: lista[i], aire: aire),
                                      ),
                                    ),
                              ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.aire, required this.margen, required this.onAgregar});

  final Aire aire;
  final double margen;
  final VoidCallback? onAgregar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexiones SAP',
                  style: tt.titleLarge?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4),
                ),
                if (!aire.esChico)
                  Text(
                    'La base de SAP y el usuario del Service Layer que usan los módulos. '
                    'Los cambios rigen en el próximo uso, sin reiniciar nada.',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          if (aire.esChico)
            IconButton(
              tooltip: 'Agregar conexión',
              onPressed: onAgregar,
              icon: const Icon(Icons.add_link),
            )
          else
            FilledButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Agregar conexión'),
            ),
          const SizedBox(width: Esp.xs),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(sapConexionesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends ConsumerWidget {
  const _Tarjeta({required this.conexion, required this.aire});

  final SapConexionEntity conexion;
  final Aire aire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final c = conexion;
    final enUso = c.enUso > 0;

    final acciones = [
      TextButton.icon(
        onPressed: () => editarSapConexion(context, ref, actual: c),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Editar'),
      ),
      TextButton.icon(
        onPressed: () => cargarClaveSapConexion(context, ref, c),
        icon: const Icon(Icons.key_outlined, size: 18),
        label: const Text('Contraseña'),
      ),
      TextButton.icon(
        onPressed: c.claveCargada ? () => probarSapConexion(context, c) : null,
        icon: const Icon(Icons.wifi_tethering, size: 18),
        label: const Text('Probar'),
      ),
      IconButton(
        tooltip: enUso ? 'La usa ${_usos(c.enUso)}: no se puede quitar' : 'Quitar ${c.nombre}',
        onPressed: enUso ? null : () => eliminarSapConexion(context, ref, c),
        icon: Icon(Icons.delete_outline, color: enUso ? null : cs.error),
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: cs.primary),
                const SizedBox(width: Esp.s),
                Expanded(child: Text(c.nombre, style: context.tituloSeccion())),
                if (!aire.esChico) ...acciones,
              ],
            ),
            const SizedBox(height: Esp.s),
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              children: [
                Etiqueta(
                  texto: c.esPrueba ? 'Prueba' : 'Producción',
                  tono: c.esPrueba ? TonoEtiqueta.neutro : TonoEtiqueta.aviso,
                ),
                Etiqueta(
                  texto: c.habilitada ? 'Habilitada' : 'Deshabilitada',
                  tono: c.habilitada ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
                ),
                Etiqueta(
                  texto: c.claveCargada ? 'Contraseña cargada' : 'Falta la contraseña',
                  tono: c.claveCargada ? TonoEtiqueta.exito : TonoEtiqueta.aviso,
                ),
                if (enUso) Etiqueta(texto: 'La usa ${_usos(c.enUso)}', tono: TonoEtiqueta.neutro),
              ],
            ),
            const SizedBox(height: Esp.m),
            _Dato(etiqueta: 'Empresa', valor: c.empresa.isEmpty ? '${c.codEmpresa}' : c.empresa),
            _Dato(
              etiqueta: 'Base de SAP',
              valor: c.linkedServer.isEmpty ? c.baseSap : '[${c.linkedServer}].[${c.baseSap}]',
            ),
            _Dato(etiqueta: 'Service Layer', valor: '${c.slUsuario} en ${c.slUrl}'),
            if (c.audFecha != null)
              Padding(
                padding: const EdgeInsets.only(top: Esp.xs),
                child: Text('Modificada el ${fechaCorta(c.audFecha)}', style: context.apagado()),
              ),
            if (aire.esChico) ...[
              const SizedBox(height: Esp.s),
              Wrap(spacing: Esp.xs, children: acciones),
            ],
          ],
        ),
      ),
    );
  }

  static String _usos(int n) => n == 1 ? '1 configuración' : '$n configuraciones';
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(etiqueta, style: context.apagado()?.copyWith(fontWeight: Peso.titulo)),
        ),
        Expanded(child: SelectableText(valor, style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
  );
}

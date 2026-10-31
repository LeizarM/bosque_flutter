import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/asiento_sap_config_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La configuración del asiento de planilla en SAP, una tarjeta por empresa: el SP que lo
/// arma, la base de SAP y el usuario del Service Layer.
///
/// Todo vive en la base (tsap_AsientoPlanilla) y el backend lo lee en cada envío: una empresa
/// nueva o un SP distinto rigen en el próximo asiento, sin compilar ni reiniciar nada.
class AsientoSapConfigScreen extends ConsumerWidget {
  const AsientoSapConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(asientoSapConfigProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final margen = aire.esChico ? Esp.m : Esp.xl;
          final lista = configs.valueOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(
                aire: aire,
                margen: margen,
                onAgregar:
                    lista == null
                        ? null
                        : () => editarAsientoSapConfig(
                          context,
                          ref,
                          yaConfiguradas: {for (final c in lista) c.codEmpresa},
                        ),
              ),
              // Dos píxeles siempre reservados: así la página no salta en cada recarga.
              if (configs.isLoading && configs.hasValue)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child: configs.when(
                  loading: () => const EsqueletoLista(filas: 3, altoFila: 160),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        onReintentar: () => ref.invalidate(asientoSapConfigProvider),
                      ),
                  data:
                      (lista) =>
                          lista.isEmpty
                              ? const MensajeVacio(
                                icono: Icons.receipt_long_outlined,
                                titulo: 'Ninguna empresa configurada',
                                detalle:
                                    'Agrega una con «Agregar empresa»: el SP que arma su asiento, '
                                    'su base de SAP y el usuario del Service Layer.',
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
                                        child: _Tarjeta(
                                          config: lista[i],
                                          aire: aire,
                                          yaConfiguradas: {for (final c in lista) c.codEmpresa},
                                        ),
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
                  'Asiento SAP: configuración',
                  style: tt.titleLarge?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4),
                ),
                if (!aire.esChico)
                  Text(
                    'El SP, la base de SAP y el usuario del Service Layer de cada empresa. '
                    'Los cambios rigen en el próximo asiento, sin reiniciar nada.',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          if (aire.esChico)
            IconButton(
              tooltip: 'Agregar empresa',
              onPressed: onAgregar,
              icon: const Icon(Icons.add_business_outlined),
            )
          else
            FilledButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Agregar empresa'),
            ),
          const SizedBox(width: Esp.xs),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(asientoSapConfigProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends ConsumerWidget {
  const _Tarjeta({required this.config, required this.aire, required this.yaConfiguradas});

  final AsientoSapConfigEntity config;
  final Aire aire;
  final Set<int> yaConfiguradas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final c = config;
    final destino = [
      if (c.linkedServer.isNotEmpty) '[${c.linkedServer}]',
      '[${c.baseSap}]',
      '[${c.esquema}]',
      '[${c.sp}]',
    ].join('.');

    final acciones = [
      TextButton.icon(
        onPressed:
            () => editarAsientoSapConfig(context, ref, actual: c, yaConfiguradas: yaConfiguradas),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Editar'),
      ),
      TextButton.icon(
        onPressed: () => cargarClaveAsientoSap(context, ref, c),
        icon: const Icon(Icons.key_outlined, size: 18),
        label: const Text('Contraseña'),
      ),
      TextButton.icon(
        onPressed: c.claveCargada ? () => probarAsientoSap(context, c) : null,
        icon: const Icon(Icons.wifi_tethering, size: 18),
        label: const Text('Probar'),
      ),
      IconButton(
        tooltip: 'Quitar ${c.empresa}',
        onPressed: () => eliminarAsientoSapConfig(context, ref, c),
        icon: Icon(Icons.delete_outline, color: cs.error),
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
                Icon(Icons.business_outlined, color: cs.primary),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    c.empresa.isEmpty ? 'Empresa ${c.codEmpresa}' : c.empresa,
                    style: context.tituloSeccion(),
                  ),
                ),
                if (!aire.esChico) ...acciones,
              ],
            ),
            const SizedBox(height: Esp.s),
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              children: [
                Etiqueta(
                  texto: c.habilitado ? 'Habilitada' : 'Deshabilitada',
                  tono: c.habilitado ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
                ),
                Etiqueta(
                  texto: c.claveCargada ? 'Contraseña cargada' : 'Falta la contraseña',
                  tono: c.claveCargada ? TonoEtiqueta.exito : TonoEtiqueta.aviso,
                ),
                if (c.evitarDuplicados)
                  const Etiqueta(texto: 'Evita duplicados', tono: TonoEtiqueta.neutro),
              ],
            ),
            const SizedBox(height: Esp.m),
            _Dato(
              etiqueta: 'SP',
              valor: '$destino @${c.paramAnio}, @${c.paramMes}',
            ),
            _Dato(
              etiqueta: 'Columnas',
              valor: [c.colCodigo, c.colNombre, c.colCuenta, c.colDebito, c.colCredito].join(' · '),
            ),
            _Dato(
              etiqueta: 'Asiento',
              valor:
                  '${c.memo}  ·  ref. ${c.referencia}'
                  '${c.campoReferencia.isEmpty ? '' : ' (${c.campoReferencia})'}'
                  '  ·  día ${c.diaDelMes == 0 ? 'último' : c.diaDelMes}'
                  '${c.prefijosSocio.isEmpty ? '' : '  ·  socios ${c.prefijosSocio}'}',
            ),
            _Dato(etiqueta: 'Service Layer', valor: '${c.slUsuario} en ${c.slUrl}'),
            if (c.audFecha != null)
              Padding(
                padding: const EdgeInsets.only(top: Esp.xs),
                child: Text('Modificado el ${fechaCorta(c.audFecha)}', style: context.apagado()),
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

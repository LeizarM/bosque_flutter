/// «Actualizar datos SAP» de la barra de Cheques: trae los clientes nuevos de
/// SAP a la base del Bosque.
///
/// Sin esos clientes un cheque desaparece de la grilla (la consulta cruza con la
/// tabla de clientes) y el cliente no sale en el combo del formulario; por eso
/// existe el boton. Lo gobierna `PermisosCheque.puedeActualizarDatosSap`
/// (`btnNuevoCH`); el servidor exige el mismo boton y su mensaje, si falla, se
/// muestra **tal cual** dentro del dialogo.
///
/// Es un dialogo y no una confirmacion suelta porque la accion tiene tres
/// momentos: explicar para que sirve, esperar a SAP con el boton bloqueado
/// («Actualizando…»: nadie debe poder lanzarla dos veces) y contar el resultado.
/// El resultado es un aviso de exito **sin numero**: el servidor no informa
/// cuantos clientes trajo. Al terminar bien, `ActualizarSociosSapNotifier` ya
/// volvio a pedir los clientes y la grilla.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/actualizar_socios_sap_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Abre el dialogo. El estado de la vez anterior no se arrastra: el provider se
/// destruye con el dialogo.
Future<void> abrirActualizarDatosSap(BuildContext context) =>
    abrirPanelCheque<void>(
      context,
      anchoMaximo: 520,
      contenido: (_) => const _DialogoActualizarDatosSap(),
    );

class _DialogoActualizarDatosSap extends ConsumerWidget {
  const _DialogoActualizarDatosSap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(actualizarSociosSapProvider);
    final resultado = estado.resultado;
    final ocupado = estado.ocupado;

    void actualizar() =>
        ref.read(actualizarSociosSapProvider.notifier).actualizar();
    void cerrar() => Navigator.of(context).pop();

    final Widget cuerpo;
    if (resultado != null) {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotaDelDato(
            key: const ValueKey('actualizar-sap-resultado'),
            tono: TonoNota.exito,
            texto: resultado.mensaje,
          ),
          const SizedBox(height: Esp.m),
          Text(
            'La lista de clientes y la de cheques se volvieron a cargar.',
            style: context.apagado(),
          ),
        ],
      );
    } else {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.error != null) ...[
            ErrorServidorCheque(estado.error!),
            const SizedBox(height: Esp.l),
          ],
          Text(
            'Trae los clientes nuevos de SAP; los cheques de un cliente que no '
            'esté cargado no aparecen en la lista.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Esp.m),
          Text(
            'También actualiza el nombre, el NIT y la ciudad de los clientes '
            'ya cargados, en todas las empresas. Tarda unos segundos.',
            style: context.apagado(),
          ),
          if (ocupado) ...[
            const SizedBox(height: Esp.l),
            const LinearProgressIndicator(minHeight: 2),
            const NotaDelDato(
              texto:
                  'Consultando SAP y actualizando los clientes. No cierres '
                  'esta ventana.',
            ),
          ],
        ],
      );
    }

    return PopScope(
      // Mientras SAP responde no se puede salir: el servidor seguiria
      // trabajando y el resultado se perderia.
      canPop: !ocupado,
      child: MarcoPanelCheque(
        titulo: 'Actualizar datos SAP',
        subtitulo: 'Clientes de SAP',
        onCerrar: ocupado ? () {} : cerrar,
        cuerpo: cuerpo,
        acciones:
            resultado != null
                ? [FilledButton(onPressed: cerrar, child: const Text('Listo'))]
                : [
                  TextButton(
                    onPressed: ocupado ? null : cerrar,
                    child: const Text('Cancelar'),
                  ),
                  BotonGuardarCheque(
                    etiqueta: estado.error == null ? 'Actualizar' : 'Reintentar',
                    etiquetaOcupado: 'Actualizando…',
                    icono: Icons.cloud_download_outlined,
                    ocupado: ocupado,
                    onPressed: actualizar,
                  ),
                ],
      ),
    );
  }
}

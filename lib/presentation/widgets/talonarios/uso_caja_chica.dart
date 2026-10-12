import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/talonario_caja_chica_entity.dart';

/// En qué egreso de caja chica se usó cada vale de un talonario (archivo SQL
/// 93). Un talonario de otro tipo no trae vales y no pinta nada.
class UsoEnCajaChica extends ConsumerWidget {
  const UsoEnCajaChica({super.key, required this.codTalonario});

  final BigInt codTalonario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uso = ref.watch(usoCajaChicaTalonarioProvider(codTalonario));
    return uso.when(
      // Es un dato de apoyo del historial: mientras carga no reserva lugar.
      loading: () => const SizedBox.shrink(),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.only(bottom: Esp.l),
            child: MensajeError(
              error: e,
              compacto: true,
              onReintentar:
                  () => ref.invalidate(
                    usoCajaChicaTalonarioProvider(codTalonario),
                  ),
            ),
          ),
      data: (u) => u.total == 0 ? const SizedBox.shrink() : _Uso(u),
    );
  }
}

class _Uso extends StatelessWidget {
  const _Uso(this.uso);

  final UsoTalonarioCajaChica uso;

  @override
  Widget build(BuildContext context) {
    final usados = uso.usados;
    final saltados = uso.saltados;
    final resumen =
        usados.isEmpty
            ? 'Todavía no se usó ningún recibo en caja chica.'
            : uso.quedan == 0
            ? 'Se usó el último recibo.'
            : 'Quedan ${uso.quedan} ${uso.quedan == 1 ? 'recibo' : 'recibos'} después del ${uso.ultimo}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Uso en caja chica', style: context.tituloSeccion()),
            ),
            Text(
              '${usados.length} de ${uso.total}',
              style: context.numero(fuerte: true),
            ),
          ],
        ),
        const SizedBox(height: Esp.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.pastilla),
          child: LinearProgressIndicator(
            value: usados.length / uso.total,
            minHeight: 6,
            semanticsLabel: 'Recibos usados',
            semanticsValue: '${usados.length} de ${uso.total}',
          ),
        ),
        const SizedBox(height: Esp.s),
        Text(resumen, style: context.apagado()),
        if (saltados.isNotEmpty) ...[
          const SizedBox(height: Esp.s),
          NotaDelDato(
            tono: TonoNota.aviso,
            texto:
                'Sin registrar antes del ${uso.ultimo}: '
                '${saltados.join(', ')}. Si se rompieron o se perdieron, anótalo al cerrar el talonario.',
          ),
        ],
        for (final v in usados) ...[
          const SizedBox(height: Esp.m),
          _FilaVale(v),
        ],
        const SizedBox(height: Esp.l),
        const Divider(height: 1),
        const SizedBox(height: Esp.m),
        Text('Movimientos del talonario', style: context.tituloSeccion()),
        const SizedBox(height: Esp.s),
      ],
    );
  }
}

class _FilaVale extends StatelessWidget {
  const _FilaVale(this.vale);

  final ValeCajaChica vale;

  @override
  Widget build(BuildContext context) {
    final donde = [
      fechaCorta(vale.fecha),
      if (vale.nombreSucursal.isNotEmpty) vale.nombreSucursal,
      if (vale.lote != null) 'lote ${vale.lote}',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text('${vale.numVale}', style: context.numero(fuerte: true)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vale.descripcion.isEmpty ? 'Sin descripción' : vale.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(donde, style: context.apagado()),
              if (vale.entregadoA.isNotEmpty)
                Text(
                  'Entregado a ${vale.entregadoA}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
            ],
          ),
        ),
        const SizedBox(width: Esp.s),
        Text(FormatoMoneda.bs(vale.monto ?? 0), style: context.numero()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

/// Los que de verdad cambian: los que ya están en [destino] se omiten.
///
/// Se filtra aquí y no en el backend para poder decirle a la persona, antes de
/// confirmar, cuántos se tocan y cuántos ya estaban bien.
List<TalonarioEntity> talonariosAMover(
  List<TalonarioEntity> todos,
  BigInt destino,
) => todos.where((t) => t.codEmpresa != destino).toList();

/// Cuántos talonarios hay por empresa, en el orden en que aparecen.
Map<String, int> conteoPorEmpresa(List<TalonarioEntity> talonarios) {
  final cuenta = <String, int>{};
  for (final t in talonarios) {
    final nombre = t.datoEmpresa.isEmpty ? 'Sin empresa' : t.datoEmpresa;
    cuenta[nombre] = (cuenta[nombre] ?? 0) + 1;
  }
  return cuenta;
}

/// Pide la empresa destino y la aplica a [talonarios], todo o nada.
///
/// Devuelve cuántos talonarios cambió, o null si se canceló. Quien llama
/// refresca el listado y avisa.
Future<int?> mostrarCambioEmpresa(
  BuildContext context, {
  required List<TalonarioEntity> talonarios,
}) => showDialog<int>(
  context: context,
  barrierDismissible: false,
  builder: (_) => DialogoCambioEmpresa(talonarios: talonarios),
);

class DialogoCambioEmpresa extends ConsumerStatefulWidget {
  const DialogoCambioEmpresa({super.key, required this.talonarios});

  final List<TalonarioEntity> talonarios;

  @override
  ConsumerState<DialogoCambioEmpresa> createState() =>
      _DialogoCambioEmpresaState();
}

class _DialogoCambioEmpresaState extends ConsumerState<DialogoCambioEmpresa> {
  int? _destino;
  bool _ocupado = false;
  Object? _error;

  Future<void> _aplicar(List<TalonarioEntity> aMover) async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final ids = await ref
          .read(talonariosRepositoryProvider)
          .cambiarEmpresaLote(
            codTalonarios: aMover.map((t) => t.codTalonario).toList(),
            codEmpresa: BigInt.from(_destino!),
            audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
          );
      if (!mounted) return;
      Navigator.pop(context, ids.length);
    } catch (e) {
      // Se queda abierto: el backend no dejó nada a medias y se puede reintentar.
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresas = ref.watch(empresasProvider);
    final total = widget.talonarios.length;

    final destino = _destino;
    final aMover =
        destino == null
            ? const <TalonarioEntity>[]
            : talonariosAMover(widget.talonarios, BigInt.from(destino));
    final yaEstan = total - aMover.length;
    final circulados = aMover.where((t) => t.entregas > 0).length;
    final nombreDestino = empresas.maybeWhen(
      data: (lista) {
        for (final e in lista) {
          if (e.codEmpresa == destino) return e.nombre;
        }
        return null;
      },
      orElse: () => null,
    );

    final hoy = conteoPorEmpresa(
      widget.talonarios,
    ).entries.map((e) => '${e.key} ${e.value}').join('  ·  ');

    return AlertDialog(
      title: const Text('Cambiar empresa'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                MensajeError(error: _error, compacto: true),
                const SizedBox(height: Esp.m),
              ],
              Text(
                total == 1
                    ? '1 talonario seleccionado'
                    : '$total talonarios seleccionados',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: Esp.xs),
              Text('Hoy: $hoy', style: context.apagado()),
              const SizedBox(height: Esp.l),
              empresas.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error:
                    (e, _) => MensajeError(
                      error: e,
                      compacto: true,
                      onReintentar:
                          () => ref.read(empresasProvider.notifier).refresh(),
                    ),
                data:
                    (lista) => ComboBuscable<int>(
                      etiqueta: 'Empresa destino',
                      valor: _destino,
                      opciones:
                          lista
                              .map(
                                (e) => DropdownMenuEntry(
                                  value: e.codEmpresa,
                                  label: e.nombre,
                                ),
                              )
                              .toList(),
                      onElegir:
                          _ocupado ? (_) {} : (v) => setState(() => _destino = v),
                    ),
              ),
              if (destino != null) ...[
                const SizedBox(height: Esp.m),
                Text(
                  aMover.isEmpty
                      ? 'Todos ya están en ${nombreDestino ?? 'esa empresa'}: '
                          'no hay nada que cambiar.'
                      : yaEstan == 0
                      ? 'Se cambian los ${aMover.length}.'
                      : 'Se cambian ${aMover.length}; $yaEstan ya están en '
                          '${nombreDestino ?? 'esa empresa'} y se omiten.',
                ),
              ],
              if (circulados > 0) ...[
                const SizedBox(height: Esp.m),
                _AvisoSap(
                  circulados: circulados,
                  empresa: nombreDestino ?? 'la empresa elegida',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta:
              aMover.isEmpty
                  ? 'Cambiar empresa'
                  : 'Cambiar ${aMover.length} '
                      '${aMover.length == 1 ? 'talonario' : 'talonarios'}',
          etiquetaOcupado: 'Cambiando…',
          ocupado: _ocupado,
          onPressed:
              (destino == null || aMover.isEmpty) ? null : () => _aplicar(aMover),
        ),
      ],
    );
  }
}

/// El motivo por el que esto no es un cambio de rutina.
///
/// La conciliación con SAP empareja cada recibo con su talonario por empresa,
/// así que mover un talonario que ya circuló mueve también sus recibos de un
/// reporte al otro. Es lo correcto si la empresa estaba mal cargada.
class _AvisoSap extends StatelessWidget {
  const _AvisoSap({required this.circulados, required this.empresa});

  final int circulados;
  final String empresa;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: cs.onTertiaryContainer,
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              '${circulados == 1 ? '1 ya circuló' : '$circulados ya circularon'}: '
              'sus recibos emitidos pasan al reporte de conciliación con SAP de '
              '$empresa. Hazlo solo si la empresa estaba mal cargada.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

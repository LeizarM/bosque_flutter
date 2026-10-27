import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_encargado.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';

/// `ttkBingo/Cartones` (encargado): quién tiene cada cartón, asignar, liberar,
/// cambiar la forma e imprimir. Pantalla aparte para dar este permiso sin la configuración.
class TtkBingoCartonesScreen extends ConsumerWidget {
  const TtkBingoCartonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingos = ref.watch(ttkBingosProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final compacto = Aire.de(c.maxWidth).esChico;
          final relleno = compacto ? Esp.m : Esp.xl;
          return Padding(
            padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoTtk(
                  ceja: 'Bingo',
                  titulo: 'Cartones del bingo',
                  detalle:
                      'Busca un cartón por número o por dueño. Asígnalo a quien no pueda '
                      'elegirlo solo, libéralo o imprímelo. Solo los encargados ven quién '
                      'tiene cada cartón.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () {
                        ref.invalidate(ttkBingosProvider);
                        ref.invalidate(ttkCartonesProvider);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: bingos.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoListaTtk(),
                    error:
                        (e, _) => MensajeError(
                          error: e,
                          onReintentar: () => ref.invalidate(ttkBingosProvider),
                        ),
                    data: (lista) {
                      final b = bingoElegidoTtk(ref, lista);
                      if (b == null) {
                        return const MensajeVacio(
                          icono: Icons.casino_outlined,
                          titulo: 'No hay bingos',
                          detalle:
                              'Cuando se cree un bingo en la pantalla de eventos, sus cartones aparecen aquí.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: Esp.m,
                            runSpacing: Esp.s,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SelectorBingoTtk(bingos: lista),
                              if (b.puedeImprimir)
                                PermissionWidget(
                                  buttonName: BotonTtkBingo.imprimir,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        () => imprimirCartonesTtk(
                                          context,
                                          ref,
                                          b,
                                        ),
                                    icon: const Icon(Icons.print_outlined),
                                    label: const Text('Imprimir varios'),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: Esp.s),
                          Expanded(
                            child: _Cartones(
                              key: ValueKey(b.codBingo),
                              bingo: b,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cartones extends ConsumerStatefulWidget {
  const _Cartones({super.key, required this.bingo});

  final TtkBingoEntity bingo;

  @override
  ConsumerState<_Cartones> createState() => _CartonesState();
}

class _CartonesState extends ConsumerState<_Cartones> {
  final _buscador = TextEditingController();
  Timer? _espera;
  String _buscar = '';
  bool? _disponibles;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  void _alEscribir(String t) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _buscar = t.trim());
    });
  }

  String _nro(TtkBingoCartonEntity k) => k.nroCarton.toString().padLeft(4, '0');

  /// Impreso o en pantalla, solo en los cartones con dueño.
  Widget? _forma(TtkBingoCartonEntity k) =>
      k.asignado && (k.formaTexto ?? '').isNotEmpty
          ? Etiqueta(
            texto: k.formaTexto!,
            tono: k.impreso ? TonoEtiqueta.aviso : TonoEtiqueta.neutro,
          )
          : null;

  @override
  Widget build(BuildContext context) {
    final b = widget.bingo;
    final filtro = (
      codBingo: b.codBingo!,
      soloDisponibles: _disponibles,
      buscar: _buscar,
    );
    final cartones = ref.watch(ttkCartonesProvider(filtro));
    final filtroDueno = DropdownButtonHideUnderline(
      child: DropdownButton<bool?>(
        value: _disponibles,
        borderRadius: BorderRadius.circular(Esquina.chica),
        items: const [
          DropdownMenuItem(value: null, child: Text('Todos los cartones')),
          DropdownMenuItem(value: true, child: Text('Disponibles')),
          DropdownMenuItem(value: false, child: Text('Con dueño')),
        ],
        onChanged: (v) => setState(() => _disponibles = v),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: cartones.when(
        skipLoadingOnReload: true,
        loading: () => const EsqueletoListaTtk(),
        error:
            (e, _) => MensajeError(
              error: e,
              onReintentar: () => ref.invalidate(ttkCartonesProvider(filtro)),
            ),
        data:
            (lista) =>
                lista.isEmpty && _buscar.isEmpty && _disponibles == null
                    ? const MensajeVacio(
                      icono: Icons.style_outlined,
                      titulo: 'Aún no hay cartones',
                      detalle:
                          'Se generan en «Bingo: configuración», pestaña Resumen, con «Generar cartones».',
                    )
                    : ListadoTtk<TtkBingoCartonEntity>(
                      filas: lista,
                      buscador: _buscador,
                      alBuscar: _alEscribir,
                      pistaBuscar: 'Número de cartón o nombre',
                      filtros: [filtroDueno],
                      columnas: [
                        BosqueColumn(
                          label: 'N°',
                          cellBuilder:
                              (k) => Text(
                                _nro(k),
                                style: context
                                    .numero(fuerte: true)
                                    ?.copyWith(fontFamily: ttkFuenteNumeros),
                              ),
                        ),
                        BosqueColumn(
                          label: 'Dueño',
                          flex: 4,
                          cellBuilder:
                              (k) => Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      k.asignado
                                          ? ttkOGuion(k.nombreEmpleado)
                                          : 'Disponible',
                                      style:
                                          k.asignado ? null : context.apagado(),
                                    ),
                                  ),
                                  if (k.esInvitado) ...[
                                    const SizedBox(width: Esp.s),
                                    const Etiqueta(
                                      texto: 'Invitado',
                                      tono: TonoEtiqueta.aviso,
                                    ),
                                  ],
                                ],
                              ),
                        ),
                        BosqueColumn(
                          label: 'Origen',
                          flex: 3,
                          cellBuilder:
                              (k) => Text(
                                ttkOGuion(k.origenTexto),
                                style: context.apagado(),
                              ),
                        ),
                        BosqueColumn(
                          label: 'Forma',
                          flex: 2,
                          cellBuilder:
                              (k) => _forma(k) ?? const SizedBox.shrink(),
                        ),
                        BosqueColumn(
                          label: 'Asignado',
                          flex: 2,
                          cellBuilder:
                              (k) => Text(
                                k.fechaAsignacion == null
                                    ? '—'
                                    : fechaCorta(k.fechaAsignacion),
                                style: context.numero(),
                              ),
                        ),
                        BosqueColumn(
                          label: 'Ganador',
                          alignment: Alignment.center,
                          cellBuilder:
                              (k) =>
                                  k.esGanador
                                      ? const Etiqueta(
                                        texto: 'Ganó',
                                        tono: TonoEtiqueta.exito,
                                      )
                                      : const SizedBox.shrink(),
                        ),
                        BosqueColumn(
                          label: 'Acciones',
                          flex: 3,
                          alignment: Alignment.center,
                          cellBuilder:
                              (k) => AccionesEnLineaTtk(
                                acciones: accionesCartonTtk(context, ref, b, k),
                              ),
                        ),
                      ],
                      tarjeta:
                          (k) => TarjetaTtk(
                            inicio: Text(
                              _nro(k),
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontFamily: ttkFuenteNumeros,
                                fontFeatures: cifrasTabulares,
                              ),
                            ),
                            titulo:
                                k.asignado
                                    ? ttkOGuion(k.nombreEmpleado)
                                    : 'Disponible',
                            subtitulo: k.asignado ? k.origenTexto : null,
                            etiquetas: [
                              if (k.esInvitado)
                                const Etiqueta(
                                  texto: 'Invitado',
                                  tono: TonoEtiqueta.aviso,
                                ),
                              if (_forma(k) case final forma?) forma,
                              if (k.esGanador)
                                const Etiqueta(
                                  texto: 'Ganó',
                                  tono: TonoEtiqueta.exito,
                                ),
                            ],
                            acciones: accionesCartonTtk(context, ref, b, k),
                          ),
                    ),
      ),
    );
  }
}

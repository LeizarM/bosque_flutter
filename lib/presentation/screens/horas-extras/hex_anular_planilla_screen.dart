import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_anular.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutada.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_lista.dart';

/// Ancho mínimo de la tabla: con la anulación dentro del estado, las columnas
/// necesitan más que las de la lista de la planilla. Por debajo, tarjetas.
const double _anchoTablaAnular = 1280;

/// Alto de una fila de la tabla cuando trae el motivo de una anulación.
const double _altoFilaAnulada = 112;

/// `thexPlanilla/Anular`: RRHH anula una planilla ejecutada, o todo su lote
/// (D39), con un motivo; sus reportes quedan anulados para siempre. Muestra
/// las ejecutadas; las anuladas, con quién, cuándo y por qué, a pedido.
class HexAnularPlanillaScreen extends ConsumerStatefulWidget {
  const HexAnularPlanillaScreen({super.key});

  @override
  ConsumerState<HexAnularPlanillaScreen> createState() =>
      _HexAnularPlanillaScreenState();
}

class _HexAnularPlanillaScreenState
    extends ConsumerState<HexAnularPlanillaScreen> {
  final ScrollController _desplazamiento = ScrollController();
  bool _verAnuladas = false;
  int _pagina = 1;

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  /// Anuló, o ya estaba anulada (409): cambian la lista y los pendientes.
  void _recargar() {
    ref
      ..invalidate(hexPlanillasProvider)
      ..invalidate(hexPendientesProvider);
  }

  void _cambiarVista(bool ver) => setState(() {
    _verAnuladas = ver;
    _pagina = 1;
  });

  void _irAPagina(int n) {
    setState(() => _pagina = n);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) _desplazamiento.jumpTo(0);
    });
  }

  /// Solo una ejecutada se anula; el SP vuelve a validarlo al anular. Con
  /// lote, también el lote entero (las del lote que trae la lista).
  List<AccionHex> _acciones(
    HexPlanillaEntity p,
    List<HexPlanillaEntity> todas,
  ) => [
    if (planillaEjecutadaHex(p))
      AccionHex(
        'Anular',
        Icons.block,
        () => anularPlanillaHex(context, ref, p, refrescar: _recargar),
        boton: BotonHex.anularPlanilla,
        destructiva: true,
      ),
    if (planillaEjecutadaHex(p) && p.idLote != null)
      AccionHex(
        'Anular lote',
        Icons.layers_clear_outlined,
        () => anularLoteHex(
          context,
          ref,
          p,
          delLote: [
            for (final o in todas)
              if (o.idLote == p.idLote && planillaEjecutadaHex(o)) o,
          ],
          refrescar: _recargar,
        ),
        boton: BotonHex.anularPlanilla,
        destructiva: true,
      ),
  ];

  /// Un solo desplazamiento para la pantalla; en el ancho la tabla va en una
  /// caja con el alto de sus filas, hasta el de la ventana.
  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _desplazamiento,
    child: Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
          final anchoLista = c.maxWidth - 2 * relleno;
          final alto = math.max(c.maxHeight - 2 * relleno, hexAltoMinimoLista);
          final abajo = MediaQuery.paddingOf(context).bottom;
          return PaginaDesplazableHex(
            controlador: _desplazamiento,
            relleno: relleno,
            abajo: abajo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoHex(
                  titulo: 'Anular planilla',
                  detalle:
                      anchoLista >= hexAnchoTabla
                          ? 'Anula una planilla ejecutada, o todo su lote, con '
                              'su motivo. Sus reportes quedan anulados y no se '
                              'vuelven a pagar.'
                          : null,
                ),
                const SizedBox(height: Esp.m),
                _InterruptorAnuladas(
                  valor: _verAnuladas,
                  alCambiar: _cambiarVista,
                ),
                const SizedBox(height: Esp.m),
                ref
                    .watch(hexPlanillasProvider)
                    .when(
                      skipLoadingOnReload: true,
                      loading: () => _enCaja(const EsqueletoLista()),
                      error:
                          (e, _) => _enCaja(
                            vistaErrorHex(
                              e,
                              reintentar:
                                  () => ref.invalidate(hexPlanillasProvider),
                            ),
                          ),
                      data: (todas) => _lista(todas, anchoLista, alto),
                    ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _enCaja(Widget hijo) => SizedBox(height: hexAltoEstado, child: hijo);

  Widget _lista(List<HexPlanillaEntity> todas, double anchoLista, double alto) {
    final visibles = [
      for (final p in todas)
        if (_verAnuladas || planillaEjecutadaHex(p)) p,
    ];
    final hayOcultas = !_verAnuladas && visibles.length < todas.length;
    return ListaPlanillasHex(
      planillas: visibles,
      pagina: _pagina,
      alCambiarPagina: _irAPagina,
      anchoLista: anchoLista,
      altoMaximo: alto,
      anchoMinimoTabla: _anchoTablaAnular,
      // Las filas con el motivo de una anulación son más altas.
      porFila: _verAnuladas ? _altoFilaAnulada : null,
      vacio: MensajeVacio(
        icono: Icons.receipt_long_outlined,
        titulo: 'No hay planillas ejecutadas',
        detalle:
            hayOcultas
                ? 'Las planillas anuladas están ocultas: activa «Ver anuladas» '
                    'para verlas.'
                : 'Las planillas que RRHH ejecute aparecen aquí para poder '
                    'anularlas.',
      ),
      columnas: columnasPlanillasHex(
        context,
        ref,
        acciones: (p) => _acciones(p, todas),
        conAnulacion: true,
      ),
      tarjeta:
          (p) => TarjetaPlanillaHex(
            p,
            acciones: _acciones(p, todas),
            conAnulacion: true,
          ),
    );
  }
}

/// «Ver anuladas»: con 48 px de alto aunque el tema use la densidad del
/// escritorio, y sin ocupar todo el ancho.
class _InterruptorAnuladas extends StatelessWidget {
  const _InterruptorAnuladas({required this.valor, required this.alCambiar});

  final bool valor;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 48),
      child: SwitchListTile(
        tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Esp.m),
        visualDensity: VisualDensity.standard,
        title: const Text('Ver anuladas'),
        value: valor,
        onChanged: (v) {
          HapticaHex.toque();
          alCambiar(v);
        },
      ),
    ),
  );
}

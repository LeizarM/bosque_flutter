/// El juego del participante en su pantalla: el último bolillo, lo cantado y
/// su cartón del juego en curso para marcar a mano. El sistema no marca ni
/// avisa si ganó: el participante debe estar atento y gritar «¡Bingo!».
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_carton_papel.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_panel.dart'
    show EstadoConexionTtk;

String _nro(int n) => n.toString().padLeft(4, '0');

/// Ancho de contenedor desde el que el cantado va al costado del cartón.
const double _anchoDosColumnas = 900;

class JugarBingoTtk extends ConsumerStatefulWidget {
  const JugarBingoTtk({
    super.key,
    required this.bingo,
    required this.cartones,
    required this.alVolver,
  });

  final TtkBingoParticipanteEntity bingo;
  final List<TtkBingoCartonEntity> cartones;
  final VoidCallback alVolver;

  @override
  ConsumerState<JugarBingoTtk> createState() => _JugarBingoTtkState();
}

class _JugarBingoTtkState extends ConsumerState<JugarBingoTtk> {
  int _indice = 0;

  TtkBingoCartonEntity get _carton =>
      widget.cartones[_indice.clamp(0, widget.cartones.length - 1)];

  /// Solo avisa al encargado; la respuesta es la misma gane o no.
  Future<void> _avisar() async {
    final k = _carton;
    final ok = await confirmar(
      context,
      titulo: '¿Completaste la figura?',
      detalle:
          'El encargado revisará el cartón N° ${_nro(k.nroCarton)} con los bolillos que salieron. '
          'El sistema no te dirá si ganaste: sigue atento.',
      textoConfirmar: 'Avisar «¡Bingo!»',
      textoCancelar: 'Seguir jugando',
    );
    if (!ok || !mounted) return;
    if (await ejecutarTtk(
      context,
      () => ref.read(ttkBingoRepositoryProvider).cantarBingo(k.codCarton!),
    )) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bingo;
    final vivo = ref.watch(ttkVivoPublicoProvider(b.codBingo!));
    final publico = vivo.dato?.publico;
    final tablero = vivo.dato?.tablero ?? const <TtkBingoSorteoEntity>[];
    final enCurso = publico?.estadoJuego == 'EN_CURSO';
    final nroJuego = publico?.nroJuego ?? 1;
    final k = _carton;
    final clave = (codCarton: k.codCarton!, nroJuego: nroJuego);

    return LayoutBuilder(
      builder: (context, c) {
        final compacto = Aire.de(c.maxWidth).esChico;
        final encabezado = EncabezadoTtk(
          ceja: b.nombreEvento,
          titulo:
              publico?.nroJuego == null
                  ? 'Mi cartón'
                  : 'Juego ${publico!.nroJuego} · ${ttkOGuion(publico.nombreJuego)}',
          compacto: compacto,
          alVolver: widget.alVolver,
          acciones: [EstadoConexionTtk(conectado: vivo.conectado)],
        );
        final cantado = _Cantado(
          publico: publico,
          tablero: tablero,
          compacto: compacto,
        );
        final carton = _CartonDelJuego(
          bingo: b,
          carton: k,
          nroJuego: nroJuego,
          clave: clave,
          tocable: enCurso,
          maxCelda: compacto ? 64 : 88,
        );
        final controles = _Controles(
          bingo: b,
          publico: publico,
          cartones: widget.cartones,
          indice: _indice.clamp(0, widget.cartones.length - 1),
          enCurso: enCurso,
          alElegir: (i) => setState(() => _indice = i),
          alAvisar: _avisar,
        );

        if (c.maxWidth >= _anchoDosColumnas) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              encabezado,
              const SizedBox(height: Esp.l),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cantado,
                            const SizedBox(height: Esp.l),
                            controles,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Esp.xl),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: Esp.xl),
                        child: carton,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Esp.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              encabezado,
              const SizedBox(height: Esp.m),
              cantado,
              const SizedBox(height: Esp.m),
              carton,
              const SizedBox(height: Esp.l),
              controles,
            ],
          ),
        );
      },
    );
  }
}

/// El último bolillo grande y los anteriores, como en la sala.
class _Cantado extends StatelessWidget {
  const _Cantado({
    required this.publico,
    required this.tablero,
    required this.compacto,
  });

  final TtkBingoPublicoEntity? publico;
  final List<TtkBingoSorteoEntity> tablero;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ultimo = publico?.ultimoBolillo;
    final anteriores = [
      for (final s in tablero)
        if (s.marcado && s.orden != null && s.nroBolillo != ultimo) s,
    ]..sort((a, b) => b.orden!.compareTo(a.orden!));
    final letra =
        tablero.where((s) => s.nroBolillo == ultimo).firstOrNull?.letra ?? '';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Row(
          children: [
            // Cada bolillo nuevo cae y rebota, como al salir de la máquina.
            TweenAnimationBuilder<double>(
              key: ValueKey(ultimo),
              tween: Tween(begin: 0, end: 1),
              duration:
                  (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                      ? Duration.zero
                      : const Duration(milliseconds: 750),
              curve: Curves.bounceOut,
              builder:
                  (context, v, hijo) => Transform.translate(
                    offset: Offset(0, -36 * (1 - v)),
                    child: hijo,
                  ),
              child: BolilloGrandeTtk(
                numero: ultimo,
                letra: letra,
                diametro: compacto ? 84 : 120,
              ),
            ),
            const SizedBox(width: Esp.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${publico?.totalMarcados ?? 0} bolillos cantados',
                    style: context.tituloSeccion(),
                  ),
                  const SizedBox(height: Esp.s),
                  Wrap(
                    spacing: Esp.xs,
                    runSpacing: Esp.xs,
                    children: [
                      for (final s in anteriores.take(compacto ? 5 : 8))
                        BolilloTtk(
                          numero: s.nroBolillo,
                          estado: EstadoBolilloTtk.marcado,
                          diametro: 34,
                          etiqueta: s.etiqueta,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El juego en curso del cartón, para marcar a mano. Las marcas quedan en el
/// equipo; la figura sombreada muestra qué casillas cuentan.
class _CartonDelJuego extends ConsumerWidget {
  const _CartonDelJuego({
    required this.bingo,
    required this.carton,
    required this.nroJuego,
    required this.clave,
    required this.tocable,
    required this.maxCelda,
  });

  final TtkBingoParticipanteEntity bingo;
  final TtkBingoCartonEntity carton;
  final int nroJuego;
  final ClaveMarcasTtk clave;
  final bool tocable;
  final double maxCelda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celdas = ref.watch(
      ttkCeldasCartonProvider((codCarton: carton.codCarton!, encargado: false)),
    );
    final marcas = ref.watch(ttkMarcasProvider(clave));
    return celdas.when(
      skipLoadingOnReload: true,
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => MensajeError(error: e, compacto: true),
      data: (lista) {
        final delJuego = [
          for (final x in lista)
            if (x.nroJuego == nroJuego) x,
        ];
        if (delJuego.isEmpty) {
          return const MensajeVacio(
            icono: Icons.grid_off_outlined,
            titulo: 'Sin casillas para este juego',
            detalle: 'Actualiza la pantalla en un momento.',
          );
        }
        return MesaTtk(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Esp.m, Esp.l, Esp.m, Esp.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cartón N° ${_nro(carton.nroCarton)} · ${delJuego.first.nombreJuego}',
                  textAlign: TextAlign.center,
                  style: context.tituloSeccion(),
                ),
                const SizedBox(height: Esp.m),
                // Capa propia: el rebote del bolillo no repinta la hoja.
                RepaintBoundary(
                  child: HojaJuegoTtk(
                    celdas: delJuego,
                    filas: bingo.filas,
                    columnas: bingo.columnas,
                    letras: bingo.letras,
                    nroCarton: carton.nroCarton,
                    maxCelda: maxCelda,
                    marcas: marcas,
                    alTocar:
                        tocable
                            ? ref
                                .read(ttkMarcasProvider(clave).notifier)
                                .alternar
                            : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La guía, el aviso «¡Bingo!» (si el encargado lo dejó prendido), el cambio
/// de cartón y el tablero completo.
class _Controles extends StatelessWidget {
  const _Controles({
    required this.bingo,
    required this.publico,
    required this.cartones,
    required this.indice,
    required this.enCurso,
    required this.alElegir,
    required this.alAvisar,
  });

  final TtkBingoParticipanteEntity bingo;
  final TtkBingoPublicoEntity? publico;
  final List<TtkBingoCartonEntity> cartones;
  final int indice;
  final bool enCurso;
  final ValueChanged<int> alElegir;
  final VoidCallback alAvisar;

  @override
  Widget build(BuildContext context) {
    final puedeAvisar = publico?.puedeAvisar ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (publico?.hayGanador ?? false) ...[
          AvisoGanadorTtk(mensaje: publico!.mensaje),
          const SizedBox(height: Esp.m),
        ] else if (!enCurso && (publico?.mensaje ?? '').isNotEmpty) ...[
          NotaDelDato(texto: publico!.mensaje, tono: TonoNota.info),
          const SizedBox(height: Esp.m),
        ],
        NotaDelDato(
          texto:
              puedeAvisar
                  ? 'Marca tú cada número que salga. El sistema no te avisa si ganaste: '
                      'si completas la figura, grita «¡Bingo!» o usa el botón.'
                  : 'Marca tú cada número que salga. El sistema no te avisa si ganaste: '
                      'si completas la figura, grita «¡Bingo!».',
          tono: TonoNota.info,
        ),
        if (cartones.length > 1) ...[
          const SizedBox(height: Esp.m),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              for (var i = 0; i < cartones.length; i++)
                ChoiceChip(
                  label: Text('N° ${_nro(cartones[i].nroCarton)}'),
                  selected: i == indice,
                  onSelected: (_) => alElegir(i),
                ),
            ],
          ),
        ],
        const SizedBox(height: Esp.l),
        if (puedeAvisar && enCurso) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 64),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
              textStyle: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
            ),
            onPressed: alAvisar,
            icon: const Icon(Icons.campaign_outlined, size: 28),
            label: const Text('¡Bingo!'),
          ),
          const SizedBox(height: Esp.s),
        ],
        OutlinedButton.icon(
          onPressed:
              () => context.go(
                '/dashboard/${AppConstants.rutaTtkEnVivo}',
                extra: bingo.codBingo,
              ),
          icon: const Icon(Icons.live_tv_outlined),
          label: const Text('Ver el tablero completo'),
        ),
      ],
    );
  }
}

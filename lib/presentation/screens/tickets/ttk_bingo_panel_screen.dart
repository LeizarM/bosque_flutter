import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_encargado.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_panel.dart';

/// Ancho de contenedor desde el que el panel va en dos columnas.
const double _anchoDosColumnas = 1100;

/// `ttkBingo/Panel` (encargado, en vivo): marcar bolillos a mano, ver el
/// ranking que manda el servidor y confirmar ganadores. Pensado para laptop.
class TtkBingoPanelScreen extends ConsumerWidget {
  const TtkBingoPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingos = ref.watch(ttkBingosProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final compacto = Aire.de(c.maxWidth).esChico;
          final relleno = compacto ? Esp.m : Esp.l;
          return Padding(
            padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoTtk(
                  ceja: 'Bingo',
                  titulo: 'Panel en vivo',
                  detalle:
                      'Cada vez que salga un bolillo de la máquina, tócalo en el tablero. '
                      'El ranking y los avisos de «¡Bingo!» se actualizan solos.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(ttkBingosProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.s),
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
                              'Crea el bingo en «Configuración del bingo» e inícialo para usar este panel.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectorBingoTtk(bingos: lista),
                          ),
                          const SizedBox(height: Esp.s),
                          Expanded(
                            child: _Panel(key: ValueKey(b.codBingo), bingo: b),
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

class _Panel extends ConsumerStatefulWidget {
  const _Panel({super.key, required this.bingo});

  final TtkBingoEntity bingo;

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel> {
  final Set<int> _pendientes = {};
  TtkEstadoEncargadoEntity? _alerta;

  /// Cartones ya alertados por juego: un aviso o un ganador nuevo no reabren
  /// la alerta que el encargado cerró (esNuevo dura hasta el próximo bolillo).
  final Set<String> _alertados = {};

  /// Avisos «¡Bingo!» ya vistos: solo suena el que llega nuevo.
  final Set<BigInt> _avisosVistos = {};

  BigInt get _cod => widget.bingo.codBingo!;

  void _alCambiarEstado(
    EstadoTiempoReal<TtkEstadoEncargadoEntity>? antes,
    EstadoTiempoReal<TtkEstadoEncargadoEntity> ahora,
  ) {
    final a = antes?.dato;
    final s = ahora.dato;
    if (s == null || (a != null && s.version <= a.version)) return;
    final ap = a?.publico;
    final sp = s.publico;
    final otroJuego =
        a != null &&
        (ap?.nroJuego != sp?.nroJuego || ap?.estadoJuego != sp?.estadoJuego);
    int confirmados(TtkEstadoEncargadoEntity e) =>
        e.ranking.where((r) => r.esGanadorConfirmado).length;
    // Juegos y ganadores solo cambian con bolillos, juegos o ganadores: un aviso
    // nuevo no dispara dos lecturas más por cada panel abierto.
    if (a != null &&
        (otroJuego ||
            ap?.totalMarcados != sp?.totalMarcados ||
            ap?.hayGanador != sp?.hayGanador ||
            ap?.estado != sp?.estado ||
            confirmados(a) != confirmados(s))) {
      ref.invalidate(ttkJuegosProvider(_cod));
      ref.invalidate(ttkGanadoresProvider(_cod));
      if (ap?.estado != sp?.estado) ref.invalidate(ttkBingosProvider);
    }
    if (otroJuego && _alerta != null) setState(() => _alerta = null);
    final bingos = [
      for (final r in s.bingosNuevos)
        if (_alertados.add('${sp?.nroJuego}-${r.codCarton}')) r,
    ];
    if (bingos.isNotEmpty) {
      setState(() => _alerta = s);
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
    final nuevos = [
      for (final x in s.avisos)
        if (x.codAviso != null && !_avisosVistos.contains(x.codAviso)) x,
    ];
    _avisosVistos.addAll([for (final x in nuevos) x.codAviso!]);
    if (a != null && nuevos.isNotEmpty) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _tocar(TtkBingoSorteoEntity b) async {
    final repo = ref.read(ttkBingoRepositoryProvider);
    if (b.marcado) {
      final ok = await confirmar(
        context,
        titulo: 'Quitar el bolillo ${b.etiqueta}',
        detalle:
            'Úsalo solo si se marcó por error: el ranking se recalcula sin ese número.',
        textoConfirmar: 'Quitar',
        destructiva: true,
      );
      if (!ok || !mounted) return;
      await _ejecutar(
        b.nroBolillo,
        () => repo.quitarBolillo(_cod, b.nroBolillo),
      );
    } else {
      await _ejecutar(
        b.nroBolillo,
        () => repo.marcarBolillo(_cod, b.nroBolillo),
      );
    }
  }

  Future<void> _ejecutar(
    int nro,
    Future<TtkRespuesta> Function() accion,
  ) async {
    setState(() => _pendientes.add(nro));
    await ejecutarTtk(context, accion);
    if (!mounted) return;
    await ref.read(ttkVivoEncargadoProvider(_cod).notifier).refrescar();
    if (mounted) setState(() => _pendientes.remove(nro));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ttkVivoEncargadoProvider(_cod), _alCambiarEstado);
    final vivo = ref.watch(ttkVivoEncargadoProvider(_cod));
    final dato = vivo.dato;
    if (dato == null) {
      if (vivo.cargando) return const EsqueletoListaTtk();
      if (vivo.error != null) {
        return MensajeError(
          error: vivo.error,
          onReintentar:
              () =>
                  ref.read(ttkVivoEncargadoProvider(_cod).notifier).refrescar(),
        );
      }
      return const MensajeVacio(
        icono: Icons.sensors_off,
        titulo: 'El panel aún no tiene datos',
        detalle:
            'Se llena cuando el bingo está iniciado. Si ya lo iniciaste, toca el botón Actualizar.',
      );
    }

    final puedeMarcar = tienePermisoDeBoton(ref, BotonTtkBingo.marcar);
    final alerta = _alerta;
    final aviso =
        alerta == null
            ? null
            : AlertaBingoTtk(
              codBingo: _cod,
              aviso: alerta.aviso,
              cartones: [
                for (final r in alerta.bingosNuevos)
                  dato.ranking
                          .where((x) => x.codCarton == r.codCarton)
                          .firstOrNull ??
                      r,
              ],
              alCerrar: () => setState(() => _alerta = null),
            );
    final avisos =
        dato.avisos.isEmpty
            ? null
            : AvisosBingoTtk(codBingo: _cod, avisos: dato.avisos);

    final barra = _BarraJuego(
      estado: dato,
      conectado: vivo.conectado,
      juegos: JuegosPanelTtk(bingo: widget.bingo),
    );
    final tablero = _TableroPanel(
      estado: dato,
      pendientes: _pendientes,
      alTocar: puedeMarcar ? _tocar : null,
    );
    final validar = SeccionTtk(
      titulo: 'Validar un cartón',
      child: ValidarCartonTtk(codBingo: _cod),
    );
    final ranking = RankingBingoTtk(codBingo: _cod, ranking: dato.ranking);
    final ganadores = SingleChildScrollView(
      child: GanadoresBingoTtk(codBingo: _cod),
    );
    // Franja compacta arriba y el tablero con todo el alto que queda.
    // Si el alto no alcanza (teléfono con letra grande y avisos arriba), el
    // tablero conserva un alto mínimo y la franja se desplaza en vez de aplastarse.
    final juego = LayoutBuilder(
      builder:
          (context, k) =>
              k.maxHeight >= 440
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      barra,
                      const SizedBox(height: Esp.m),
                      Expanded(child: tablero),
                    ],
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        barra,
                        const SizedBox(height: Esp.m),
                        SizedBox(height: 320, child: tablero),
                      ],
                    ),
                  ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        // La alerta y los avisos nunca se comen el tablero: van topados y con scroll.
        final arriba =
            aviso == null && avisos == null
                ? null
                : Padding(
                  padding: const EdgeInsets.only(bottom: Esp.s),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: c.maxHeight * 0.4),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (aviso != null) aviso,
                          if (aviso != null && avisos != null)
                            const SizedBox(height: Esp.s),
                          if (avisos != null) avisos,
                        ],
                      ),
                    ),
                  ),
                );
        if (c.maxWidth >= _anchoDosColumnas) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (arriba != null) arriba,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Esp.l),
                        child: juego,
                      ),
                    ),
                    const SizedBox(width: Esp.l),
                    SizedBox(
                      width: 400,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Esp.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            validar,
                            const SizedBox(height: Esp.m),
                            Expanded(
                              child: _PestanasLado(
                                ranking: ranking,
                                ganadores: ganadores,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (arriba != null) arriba,
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Tablero'),
                        Tab(text: 'Ranking'),
                        Tab(text: 'Ganadores'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Esp.m,
                            ),
                            child: juego,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Esp.m),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                validar,
                                const SizedBox(height: Esp.s),
                                Expanded(child: ranking),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Esp.m),
                            child: ganadores,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PestanasLado extends StatelessWidget {
  const _PestanasLado({required this.ranking, required this.ganadores});

  final Widget ranking;
  final Widget ganadores;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Ranking'), Tab(text: 'Ganadores')]),
            Expanded(
              child: TabBarView(
                children: [
                  ranking,
                  Padding(
                    padding: const EdgeInsets.all(Esp.m),
                    child: ganadores,
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

/// El tablero del encargado: toca para marcar; llena el alto disponible.
class _TableroPanel extends StatelessWidget {
  const _TableroPanel({
    required this.estado,
    required this.pendientes,
    required this.alTocar,
  });

  final TtkEstadoEncargadoEntity estado;
  final Set<int> pendientes;
  final ValueChanged<TtkBingoSorteoEntity>? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Tablero', style: context.tituloSeccion()),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Text(
                    alTocar == null
                        ? 'Solo lectura: no tienes permiso para marcar bolillos'
                        : 'Toca el bolillo que salió de la máquina',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.apagado(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            Expanded(
              child: TableroBolillosTtk(
                tablero: estado.tablero,
                ultimo: estado.publico?.ultimoBolillo,
                pendientes: pendientes,
                alTocar: alTocar,
                llenar: true,
                minCelda: 30,
                maxCelda: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Último bolillo, juego actual con su figura, cuántos salieron, la conexión
/// y los juegos, en una franja compacta.
class _BarraJuego extends StatelessWidget {
  const _BarraJuego({
    required this.estado,
    required this.conectado,
    required this.juegos,
  });

  final TtkEstadoEncargadoEntity estado;
  final bool conectado;
  final Widget juegos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = estado.publico;
    final ultimo = p?.ultimoBolillo;
    final letra =
        estado.tablero
            .where((b) => b.nroBolillo == ultimo)
            .firstOrNull
            ?.letra ??
        '';
    final info = Row(
      children: [
        BolilloGrandeTtk(numero: ultimo, letra: letra, diametro: 84),
        const SizedBox(width: Esp.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EstadoConexionTtk(conectado: conectado),
              const SizedBox(height: Esp.xs),
              Text(
                ttkOGuion(p?.mensaje),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              if ((p?.textoPremio ?? '').isNotEmpty)
                Text(
                  p!.textoPremio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.primary, fontWeight: Peso.dato),
                ),
              Text(
                '${p?.totalMarcados ?? 0} bolillos en este juego',
                style: context.apagado()?.copyWith(
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ],
          ),
        ),
        if (p != null && (p.figura ?? '').isNotEmpty) ...[
          const SizedBox(width: Esp.m),
          FiguraTtk(
            figura: p.figura!,
            filas: p.filas,
            columnas: p.columnas,
            conComodin: p.conComodin,
            celda: 13,
          ),
        ],
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: LayoutBuilder(
          builder:
              (context, c) =>
                  c.maxWidth >= 860
                      ? Row(
                        children: [
                          Expanded(flex: 3, child: info),
                          const SizedBox(width: Esp.l),
                          Expanded(flex: 2, child: juegos),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [info, const SizedBox(height: Esp.s), juegos],
                      ),
        ),
      ),
    );
  }
}

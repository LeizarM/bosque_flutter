/// Bloques del panel en vivo del encargado: juegos, ranking, validación de un
/// cartón gritado, ganadores confirmados, la alerta de bingo y la conexión.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_encargado.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_eventos_dialogos.dart'
    show conEsperaTtk;

String _nro(int n) => n.toString().padLeft(4, '0');

String _hora(DateTime f) =>
    '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}:${f.second.toString().padLeft(2, '0')}';

/// Confirma como ganador un cartón con bingo y refresca el panel. Toma el
/// contenedor antes de esperar: quien lo llamó (un aviso, una fila) puede
/// desmontarse cuando llega el estado nuevo. Devuelve si se confirmó.
Future<bool> confirmarGanadorTtk(
  BuildContext context,
  BigInt codBingo,
  TtkRankingCartonEntity r,
) async {
  final contenedor = ProviderScope.containerOf(context, listen: false);
  final repo = contenedor.read(ttkBingoRepositoryProvider);
  final ok = await confirmar(
    context,
    titulo: 'Confirmar ganador',
    detalle:
        'Cartón N° ${_nro(r.nroCarton)}${(r.nombreEmpleado ?? '').isEmpty ? '' : ' de ${r.nombreEmpleado}'}.',
    textoConfirmar: 'Confirmar ganador',
  );
  if (!ok || !context.mounted) return false;
  if (!await ejecutarTtk(
    context,
    () => repo.confirmarGanador(codBingo, r.nroCarton),
  )) {
    return false;
  }
  HapticFeedback.mediumImpact();
  refrescarBingoEnTtk(contenedor, codBingo);
  return true;
}

/// «En vivo» o «Reconectando…», para saber si el tablero está al día.
class EstadoConexionTtk extends StatelessWidget {
  const EstadoConexionTtk({super.key, required this.conectado});

  final bool conectado;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Etiqueta(
      texto: conectado ? 'En vivo' : 'Reconectando…',
      tono: conectado ? TonoEtiqueta.exito : TonoEtiqueta.aviso,
    ),
  );
}

/// Aviso persistente cuando uno o más cartones completan la figura. Se queda
/// hasta que el encargado lo cierra: no debe pasar desapercibido.
class AlertaBingoTtk extends ConsumerWidget {
  const AlertaBingoTtk({
    super.key,
    required this.codBingo,
    required this.aviso,
    required this.cartones,
    required this.alCerrar,
  });

  final BigInt codBingo;
  final String? aviso;
  final List<TtkRankingCartonEntity> cartones;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 32,
                    color: cs.onTertiaryContainer,
                  ),
                  const SizedBox(width: Esp.m),
                  Expanded(
                    child: Text(
                      (aviso ?? '').isNotEmpty
                          ? aviso!
                          : cartones.first.mensaje,
                      style: t.titleMedium?.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: Peso.dato,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Entendido',
                    onPressed: alCerrar,
                    icon: Icon(Icons.close, color: cs.onTertiaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: Esp.s),
              for (final r in cartones)
                Padding(
                  padding: const EdgeInsets.only(top: Esp.xs),
                  child: Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'N° ${_nro(r.nroCarton)}',
                        style: t.titleMedium?.copyWith(
                          fontFamily: ttkFuenteNumeros,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      Text(
                        ttkOGuion(r.nombreEmpleado),
                        style: t.bodyMedium?.copyWith(
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      if (!r.esGanadorConfirmado)
                        PermissionWidget(
                          buttonName: BotonTtkBingo.confirmarGanador,
                          child: FilledButton(
                            onPressed:
                                () => confirmarGanadorTtk(context, codBingo, r),
                            child: const Text('Confirmar'),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «¡Bingo!» que avisaron los participantes desde su pantalla, en orden de
/// llegada. Validar revisa el cartón con los bolillos reales; «Listo» lo cierra.
class AvisosBingoTtk extends ConsumerWidget {
  const AvisosBingoTtk({
    super.key,
    required this.codBingo,
    required this.avisos,
  });

  final BigInt codBingo;
  final List<TtkBingoAvisoEntity> avisos;

  /// Recibe el repositorio y el panel ya leídos: si otro encargado lo atiende
  /// antes, este bloque se desmonta y `ref` deja de servir.
  Future<void> _atender(
    BuildContext context,
    TtkBingoRepository repo,
    TiempoRealNotifier<TtkEstadoEncargadoEntity> vivo,
    TtkBingoAvisoEntity a,
  ) async {
    if (await ejecutarTtk(context, () => repo.atenderAviso(a.codAviso!)) &&
        vivo.mounted) {
      vivo.refrescar();
    }
  }

  Future<void> _validar(
    BuildContext context,
    WidgetRef ref,
    TtkBingoAvisoEntity a,
  ) async {
    final repo = ref.read(ttkBingoRepositoryProvider);
    final vivo = ref.read(ttkVivoEncargadoProvider(codBingo).notifier);
    final TtkRankingCartonEntity? r;
    try {
      r = await conEsperaTtk<TtkRankingCartonEntity?>(
        context,
        'Revisando el cartón…',
        () => repo.validarCarton(codBingo, a.nroCarton),
      );
    } catch (e) {
      if (context.mounted) {
        mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
      }
      return;
    }
    if (r == null || !context.mounted) return;
    final resultado = r;
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Cartón N° ${_nro(a.nroCarton)}'),
            content: NotaDelDato(
              texto: [
                resultado.mensaje,
                if ((a.nombreEmpleado ?? '').isNotEmpty) a.nombreEmpleado!,
              ].join('\n'),
              tono: resultado.esBingo ? TonoNota.exito : TonoNota.info,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _atender(context, repo, vivo, a);
                },
                child: const Text('Marcar atendido'),
              ),
              if (resultado.esBingo && !resultado.esGanadorConfirmado)
                PermissionWidget(
                  buttonName: BotonTtkBingo.confirmarGanador,
                  child: FilledButton(
                    // Desde este diálogo (sigue vivo aunque el aviso se vaya).
                    onPressed: () async {
                      if (await confirmarGanadorTtk(ctx, codBingo, resultado) &&
                          ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Confirmar ganador'),
                  ),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final letra = cs.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign_outlined, color: letra),
                  const SizedBox(width: Esp.s),
                  Expanded(
                    child: Text(
                      avisos.length == 1
                          ? 'Un participante avisó «¡Bingo!»'
                          : '${avisos.length} participantes avisaron «¡Bingo!»',
                      style: t.titleMedium?.copyWith(
                        color: letra,
                        fontWeight: Peso.dato,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Esp.s),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 168),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: avisos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Esp.xs),
                  itemBuilder: (context, i) {
                    final a = avisos[i];
                    return Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'N° ${_nro(a.nroCarton)}',
                          style: t.titleSmall?.copyWith(
                            fontFamily: ttkFuenteNumeros,
                            fontFeatures: cifrasTabulares,
                            color: letra,
                          ),
                        ),
                        Text(
                          ttkOGuion(a.nombreEmpleado),
                          style: t.bodyMedium?.copyWith(color: letra),
                        ),
                        if (a.impreso)
                          Tooltip(
                            message: 'Juega con cartón impreso',
                            child: Icon(
                              Icons.print_outlined,
                              size: 16,
                              color: letra,
                            ),
                          ),
                        if (a.fechaAviso != null)
                          Text(
                            _hora(a.fechaAviso!),
                            style: t.bodySmall?.copyWith(
                              fontFeatures: cifrasTabulares,
                              color: letra,
                            ),
                          ),
                        FilledButton.tonal(
                          onPressed: () => _validar(context, ref, a),
                          child: const Text('Validar'),
                        ),
                        TextButton(
                          onPressed:
                              () => _atender(
                                context,
                                ref.read(ttkBingoRepositoryProvider),
                                ref.read(
                                  ttkVivoEncargadoProvider(codBingo).notifier,
                                ),
                                a,
                              ),
                          child: const Text('Listo'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los cartones más cerca de completar la figura, y todos los que ya la tienen.
class RankingBingoTtk extends ConsumerWidget {
  const RankingBingoTtk({
    super.key,
    required this.codBingo,
    required this.ranking,
  });

  final BigInt codBingo;
  final List<TtkRankingCartonEntity> ranking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (ranking.isEmpty) {
      return const MensajeVacio(
        icono: Icons.leaderboard_outlined,
        titulo: 'Sin ranking todavía',
        detalle:
            'Comienza un juego con el botón «Comenzar juego» y aquí verás los '
            'cartones más cerca de ganar.',
      );
    }
    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        itemCount: ranking.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = ranking[i];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.s,
              vertical: Esp.s,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${r.puesto}',
                    style: context.numero(fuerte: true),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'N° ${_nro(r.nroCarton)}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              fontFamily: ttkFuenteNumeros,
                              fontFeatures: cifrasTabulares,
                            ),
                          ),
                          if (r.impreso) ...[
                            const SizedBox(width: Esp.xs),
                            Tooltip(
                              message: 'Juega con cartón impreso',
                              child: Icon(
                                Icons.print_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Text(
                              ttkOGuion(r.nombreEmpleado),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.apagado(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Esquina.pastilla),
                        child: LinearProgressIndicator(
                          value: r.avance,
                          minHeight: 6,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: r.esBingo ? cs.tertiary : cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Esp.s),
                if (r.esGanadorConfirmado)
                  const Etiqueta(texto: 'Ganador', tono: TonoEtiqueta.exito)
                else if (r.esBingo)
                  PermissionWidget(
                    buttonName: BotonTtkBingo.confirmarGanador,
                    placeholder: const Etiqueta(
                      texto: '¡BINGO!',
                      tono: TonoEtiqueta.aviso,
                    ),
                    child: FilledButton.tonal(
                      onPressed:
                          () => confirmarGanadorTtk(context, codBingo, r),
                      child: const Text('Confirmar'),
                    ),
                  )
                else
                  SizedBox(
                    width: 64,
                    child: Text(
                      'faltan ${r.faltantes}',
                      textAlign: TextAlign.end,
                      style: context.numero(),
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

/// Verifica el cartón de quien gritó «¡BINGO!» con el mensaje del SP.
class ValidarCartonTtk extends ConsumerStatefulWidget {
  const ValidarCartonTtk({super.key, required this.codBingo});

  final BigInt codBingo;

  @override
  ConsumerState<ValidarCartonTtk> createState() => _ValidarCartonTtkState();
}

class _ValidarCartonTtkState extends ConsumerState<ValidarCartonTtk> {
  final _numero = TextEditingController();
  TtkRankingCartonEntity? _resultado;
  Object? _error;
  bool _buscando = false;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    // Enter repetido: una consulta a la vez, sin respuestas cruzadas.
    if (_buscando) return;
    final n = int.tryParse(_numero.text.trim());
    if (n == null) return;
    setState(() {
      _buscando = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(ttkBingoRepositoryProvider)
          .validarCarton(widget.codBingo, n);
      if (!mounted) return;
      setState(() => _resultado = r);
      if (r?.esBingo ?? false) HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Si alguien grita «¡Bingo!», escribe el número de su cartón: el sistema '
          'revisa si completó la figura con los bolillos que salieron.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _numero,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _validar(),
                style: const TextStyle(
                  fontFamily: ttkFuenteNumeros,
                  fontFeatures: cifrasTabulares,
                ),
                decoration: const InputDecoration(
                  labelText: 'N° del cartón que gritó',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: Esp.s),
            BotonAccion(
              etiqueta: 'Validar',
              ocupado: _buscando,
              onPressed: _validar,
              tonal: true,
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Esp.s),
            child: MensajeError(error: _error, compacto: true),
          ),
        if (r != null)
          NotaDelDato(
            texto: [
              r.mensaje,
              if ((r.nombreEmpleado ?? '').isNotEmpty) r.nombreEmpleado!,
            ].join('\n'),
            tono: r.esBingo ? TonoNota.exito : TonoNota.info,
            accion:
                r.esBingo && !r.esGanadorConfirmado
                    ? PermissionWidget(
                      buttonName: BotonTtkBingo.confirmarGanador,
                      child: FilledButton(
                        onPressed: () async {
                          await confirmarGanadorTtk(
                            context,
                            widget.codBingo,
                            r,
                          );
                          if (mounted) setState(() => _resultado = null);
                        },
                        child: const Text('Confirmar'),
                      ),
                    )
                    : null,
          ),
      ],
    );
  }
}

/// Ganadores confirmados de todos los juegos del bingo.
class GanadoresBingoTtk extends ConsumerWidget {
  const GanadoresBingoTtk({super.key, required this.codBingo});

  final BigInt codBingo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ganadores = ref.watch(ttkGanadoresProvider(codBingo));
    return ganadores.when(
      skipLoadingOnReload: true,
      loading: () => const LinearProgressIndicator(),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(ttkGanadoresProvider(codBingo)),
          ),
      data:
          (lista) =>
              lista.isEmpty
                  ? Text(
                    'Aún no hay ganadores confirmados.',
                    style: context.apagado(),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final g in lista)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: CircleAvatar(
                            child: Text(
                              '${g.nroJuego}',
                              style: context.numero(fuerte: true),
                            ),
                          ),
                          title: Text(
                            'N° ${_nro(g.nroCarton)} · ${ttkOGuion(g.nombreEmpleado)}',
                          ),
                          isThreeLine: g.ganoDesempate,
                          subtitle: Text(
                            [
                              '${g.nombreJuego}${g.nroBolillo == null ? '' : ' · con el ${g.nroBolillo}'}',
                              if (g.ganoDesempate)
                                'Ganó el desempate: ${ttkOGuion(g.motivoDesempate)}',
                            ].join('\n'),
                          ),
                          trailing:
                              g.puedeAnular
                                  ? PermissionWidget(
                                    buttonName: BotonTtkBingo.confirmarGanador,
                                    child: IconButton(
                                      tooltip: 'Anular',
                                      icon: const Icon(Icons.undo),
                                      onPressed: () async {
                                        // Antes de esperar: la pestaña puede desmontarse.
                                        final contenedor =
                                            ProviderScope.containerOf(
                                              context,
                                              listen: false,
                                            );
                                        final ok = await confirmar(
                                          context,
                                          titulo: 'Anular ganador',
                                          detalle:
                                              'Se quita la confirmación del cartón N° ${_nro(g.nroCarton)}.',
                                          textoConfirmar: 'Anular',
                                          destructiva: true,
                                        );
                                        if (!ok || !context.mounted) return;
                                        if (await ejecutarTtk(
                                          context,
                                          () => contenedor
                                              .read(ttkBingoRepositoryProvider)
                                              .anularGanador(g.codGanador!),
                                        )) {
                                          refrescarBingoEnTtk(
                                            contenedor,
                                            codBingo,
                                          );
                                        }
                                      },
                                    ),
                                  )
                                  : null,
                        ),
                    ],
                  ),
    );
  }
}

/// Los juegos del bingo con comenzar / finalizar, y finalizar el bingo.
class JuegosPanelTtk extends ConsumerWidget {
  const JuegosPanelTtk({super.key, required this.bingo});

  final TtkBingoEntity bingo;

  /// El contenedor se toma antes de esperar: en el teléfono la pestaña de
  /// juegos puede desmontarse mientras responde el backend.
  Future<void> _correr(
    BuildContext context,
    WidgetRef ref,
    Future<TtkRespuesta> Function() accion,
  ) async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    if (await ejecutarTtk(context, accion)) {
      refrescarBingoEnTtk(contenedor, bingo.codBingo!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final repo = ref.read(ttkBingoRepositoryProvider);
    final juegos = ref.watch(ttkJuegosProvider(bingo.codBingo!));
    final lista = juegos.valueOrNull ?? const [];
    final siguiente = lista.where((j) => j.puedeComenzar).firstOrNull;
    final enCurso = lista.where((j) => j.enCurso).firstOrNull;
    // Confirmados del juego en curso: con dos o más hay que resolver el desempate.
    final empatados = [
      for (final g
          in ref.watch(ttkGanadoresProvider(bingo.codBingo!)).valueOrNull ??
              const <TtkBingoGanadorEntity>[])
        if (enCurso != null && g.codJuego == enCurso.codJuego) g,
    ];
    final puedeDesempatar =
        empatados.length > 1 && empatados.first.puedeResolverEmpate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (juegos.isLoading && lista.isEmpty) const LinearProgressIndicator(),
        Wrap(
          spacing: Esp.xs,
          runSpacing: Esp.xs,
          children: [
            for (final j in lista)
              Tooltip(
                message: '${j.nombre} · ${j.estadoTexto}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Esp.s,
                    vertical: Esp.xs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        j.enCurso
                            ? cs.primary
                            : (j.estado == 'FINALIZADO'
                                ? cs.surfaceContainerHighest
                                : cs.surface),
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                    border: Border.all(
                      color: j.enCurso ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Text(
                    '${j.nroJuego}',
                    style: context.numero(
                      fuerte: j.enCurso,
                      color: j.enCurso ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Esp.s),
        if (enCurso != null && enCurso.empatePendiente) ...[
          NotaDelDato(
            tono: TonoNota.aviso,
            icono: Icons.balance_outlined,
            texto:
                'Hay ${enCurso.ganadoresConfirmados} ganadores empatados en el juego ${enCurso.nroJuego}. '
                'Resuelve el desempate (quién ganó y por qué) para poder cerrarlo.',
          ),
          const SizedBox(height: Esp.s),
        ],
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            if (puedeDesempatar)
              PermissionWidget(
                buttonName: BotonTtkBingo.confirmarGanador,
                child: FilledButton.tonalIcon(
                  onPressed:
                      () => resolverEmpateTtk(
                        context,
                        codBingo: bingo.codBingo!,
                        empatados: empatados,
                        reglaEmpate: bingo.reglaEmpate,
                      ),
                  icon: const Icon(Icons.balance_outlined),
                  label: Text(
                    enCurso!.empatePendiente
                        ? 'Resolver empate del juego ${enCurso.nroJuego}'
                        : 'Cambiar desempate',
                  ),
                ),
              ),
            if (siguiente != null)
              PermissionWidget(
                buttonName: BotonTtkBingo.marcar,
                child: FilledButton.icon(
                  onPressed:
                      () => _correr(
                        context,
                        ref,
                        () => repo.comenzarJuego(siguiente.codJuego!),
                      ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Comenzar juego ${siguiente.nroJuego}'),
                ),
              ),
            if (enCurso != null && enCurso.puedeFinalizar)
              PermissionWidget(
                buttonName: BotonTtkBingo.confirmarGanador,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final ok = await confirmar(
                      context,
                      titulo: 'Finalizar el juego ${enCurso.nroJuego}',
                      detalle:
                          'Se cierra «${enCurso.nombre}» con sus ganadores confirmados.',
                      textoConfirmar: 'Finalizar juego',
                    );
                    if (ok && context.mounted) {
                      await _correr(
                        context,
                        ref,
                        () => repo.finalizarJuego(enCurso.codJuego!),
                      );
                    }
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: Text('Finalizar juego ${enCurso.nroJuego}'),
                ),
              ),
            if (bingo.puedeFinalizar)
              PermissionWidget(
                buttonName: BotonTtkBingo.confirmarGanador,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await confirmar(
                      context,
                      titulo: 'Finalizar el bingo',
                      detalle:
                          'Termina el bingo de «${bingo.nombreEvento}». El tablero público muestra el cierre.',
                      textoConfirmar: 'Finalizar bingo',
                      destructiva: true,
                    );
                    if (ok && context.mounted) {
                      await _correr(
                        context,
                        ref,
                        () => repo.finalizarBingo(bingo.codBingo!),
                      );
                    }
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Finalizar bingo'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Elige quién ganó el desempate entre los confirmados del juego y anota cómo
/// se resolvió. Siempre queda un solo ganador: sin esto el juego no se cierra.
Future<void> resolverEmpateTtk(
  BuildContext context, {
  required BigInt codBingo,
  required List<TtkBingoGanadorEntity> empatados,
  String? reglaEmpate,
}) => showDialog<void>(
  context: context,
  builder:
      (_) => _DialogoDesempate(
        codBingo: codBingo,
        empatados: empatados,
        reglaEmpate: reglaEmpate,
      ),
);

class _DialogoDesempate extends ConsumerStatefulWidget {
  const _DialogoDesempate({
    required this.codBingo,
    required this.empatados,
    this.reglaEmpate,
  });

  final BigInt codBingo;
  final List<TtkBingoGanadorEntity> empatados;
  final String? reglaEmpate;

  @override
  ConsumerState<_DialogoDesempate> createState() => _DialogoDesempateState();
}

class _DialogoDesempateState extends ConsumerState<_DialogoDesempate> {
  // Si ya estaba resuelto, se abre con esa elección para cambiarla.
  late final TtkBingoGanadorEntity? _actual =
      widget.empatados.where((g) => g.ganoDesempate).firstOrNull;
  late BigInt? _elegido = _actual?.codGanador;
  late final _motivo = TextEditingController(
    text: _actual?.motivoDesempate ?? '',
  );
  bool _guardando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    setState(() => _guardando = true);
    final ok = await ejecutarTtk(
      context,
      () => contenedor
          .read(ttkBingoRepositoryProvider)
          .resolverEmpate(_elegido!, _motivo.text.trim()),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarBingoEnTtk(contenedor, widget.codBingo);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _elegido != null && _motivo.text.trim().isNotEmpty;
    final regla = widget.reglaEmpate ?? '';
    return AlertDialog(
      title: Text(
        'Resolver el empate del juego ${widget.empatados.first.nroJuego}',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige quién ganó el desempate y anota cómo se resolvió. Queda registrado '
                'y la pantalla en vivo lo muestra con su foto.',
                style: context.apagado(),
              ),
              if (regla.isNotEmpty) ...[
                const SizedBox(height: Esp.m),
                NotaDelDato(
                  icono: Icons.balance_outlined,
                  texto: 'Regla anunciada: $regla',
                ),
              ],
              const SizedBox(height: Esp.m),
              for (final g in widget.empatados)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  selected: g.codGanador == _elegido,
                  leading: Icon(
                    g.codGanador == _elegido
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(ttkOGuion(g.nombreEmpleado)),
                  subtitle: Text('Cartón N° ${_nro(g.nroCarton)}'),
                  onTap: () => setState(() => _elegido = g.codGanador),
                ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _motivo,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Cómo se resolvió',
                  hintText:
                      'Por ejemplo: sacó 6 en el dado; los demás sacaron 4 y 2.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Confirmar ganador',
          etiquetaOcupado: 'Guardando…',
          ocupado: _guardando,
          onPressed: listo ? _guardar : null,
        ),
      ],
    );
  }
}

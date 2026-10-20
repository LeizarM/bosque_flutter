/// La pantalla de rendición, la misma para el empleado y el postulante (solo
/// cambia [ClaveRendicion.origen]). Su centro es la **hoja de respuestas**,
/// la grilla del papel: cada casilla se marca al responder y abre su pregunta.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/core/utils/detector_salida_pestana.dart';
import 'package:bosque_flutter/core/utils/guardia_salida_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/resultado_examen.dart';

const double _anchoDosPaneles = 900;

class RendicionExamen extends ConsumerStatefulWidget {
  const RendicionExamen({super.key, required this.clave, this.onSalir, this.onEntregado});

  final ClaveRendicion clave;

  /// Volver a la lista de exámenes.
  final VoidCallback? onSalir;

  /// Se llama una vez cuando el examen pasa de "en curso" a entregado.
  final void Function(TcpeEstadoRendicionEntity? estado)? onEntregado;

  @override
  ConsumerState<RendicionExamen> createState() => _RendicionExamenState();
}

class _RendicionExamenState extends ConsumerState<RendicionExamen> {
  final Map<BigInt, TextEditingController> _textos = {};
  late final DetectorSalidaPestana _detector;

  @override
  void initState() {
    super.initState();
    _detector = DetectorSalidaPestana(() {
      if (mounted) ref.read(rendicionExamenProvider(widget.clave).notifier).salioDePestana();
    })..iniciar();
  }

  TextEditingController _controlador(BigInt cod, String inicial) =>
      _textos.putIfAbsent(cod, () => TextEditingController(text: inicial));

  @override
  void dispose() {
    _detector.detener();
    GuardiaSalidaExamen.liberar();
    for (final c in _textos.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _avisoSalida =>
      (ref.read(configExamenesProvider(widget.clave.origen)).valueOrNull ?? TcpeConfiguracion.respaldo)
          .avisoSalidaExamen;

  @override
  Widget build(BuildContext context) {
    final proveedor = rendicionExamenProvider(widget.clave);
    final cfg = ref.watch(configExamenesProvider(widget.clave.origen)).valueOrNull;
    if (cfg != null) ref.read(proveedor.notifier).ajustarLatido(Duration(seconds: cfg.segundosLatido));
    ref.listen<RendicionExamenState>(proveedor, (antes, ahora) {
      // En curso no se sale; se libera antes de avisar la entrega (que navega).
      if (ahora.estadoExamen == EstadoExamenTcpe.enCurso) {
        GuardiaSalidaExamen.activar(_avisoSalida);
      } else {
        GuardiaSalidaExamen.liberar();
      }
      if (ahora.aviso != null && ahora.avisoId != antes?.avisoId) {
        final vencio = esTiempoVencido(ahora.aviso!);
        mostrarAviso(
          context,
          vencio ? ahora.aviso! : textoParaUsuario(ahora.aviso),
          tono: vencio ? TonoAviso.aviso : TonoAviso.error,
        );
      }
      final eraEnCurso = antes?.estadoExamen == EstadoExamenTcpe.enCurso;
      if (eraEnCurso && ahora.estadoExamen.cerrado) {
        widget.onEntregado?.call(ahora.estado);
      }
    });

    final s = ref.watch(proveedor);
    final n = ref.read(proveedor.notifier);
    // También en el primer build: al recargar, el examen ya llega en curso.
    if (s.estadoExamen == EstadoExamenTcpe.enCurso) {
      GuardiaSalidaExamen.activar(_avisoSalida);
    } else {
      GuardiaSalidaExamen.liberar();
    }

    if (s.estado == null && s.cargando) {
      return const EsqueletoLista(filas: 4, altoFila: 64);
    }
    if (s.estado == null) {
      return MensajeError(error: s.error, onReintentar: n.cargar);
    }
    final estado = s.estado!;
    if (!estado.esOnline) {
      final msg = (estado.mensajeEstado ?? '').trim();
      return _Cierre(
        estado: estado,
        icono: Icons.edit_note_outlined,
        titulo: 'Este examen es escrito',
        // mensajeEstado de SQL (msgEscrito o la nota); el texto fijo solo si no vino.
        detalle: msg.isNotEmpty ? msg : 'Se rinde en papel, en el lugar y la hora que indicó el evaluador.',
        onSalir: widget.onSalir,
      );
    }
    final enCurso = s.estadoExamen == EstadoExamenTcpe.enCurso;
    return PopScope(
      canPop: !enCurso,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && enCurso) GuardiaSalidaExamen.mostrarAviso(context, _avisoSalida);
      },
      child: switch (s.estadoExamen) {
        EstadoExamenTcpe.sinIniciar => _Portada(
          estado: estado,
          iniciando: s.iniciando,
          onComenzar: n.iniciar,
          onSalir: widget.onSalir,
        ),
        EstadoExamenTcpe.enCurso => _enCurso(context, s, n),
        _ => ResultadoExamen(clave: widget.clave, estado: estado, onSalir: widget.onSalir),
      },
    );
  }

  Widget _enCurso(BuildContext context, RendicionExamenState s, RendicionExamenNotifier n) {
    if (s.cargando && s.preguntas.isEmpty) {
      return const EsqueletoLista(filas: 4, altoFila: 64);
    }
    if (s.preguntas.isEmpty) {
      return MensajeError(error: s.error ?? 'El examen no tiene preguntas.', onReintentar: n.cargar);
    }
    return LayoutBuilder(
      builder: (context, r) {
        final amplio = r.maxWidth >= _anchoDosPaneles;
        final pregunta = _PanelPregunta(
          estado: s,
          notifier: n,
          compacto: !amplio,
          controlador: _controlador,
          onEntregar: () => _entregar(context, s, n),
        );
        final barra = _BarraRendicion(
          estado: s,
          compacto: !amplio,
          onEntregar: () => _entregar(context, s, n),
          onHoja: amplio ? null : () => _hojaEnHoja(context, s, n),
        );
        if (!amplio) {
          return Column(children: [barra, const Divider(height: 1), Expanded(child: pregunta)]);
        }
        return Column(
          children: [
            barra,
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Esp.l),
                      child: _HojaRespuestas(estado: s, onIr: n.irA),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: pregunta),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// En el teléfono la hoja abre abajo, con su propio «Revisar y entregar»:
  /// el de la barra no entra y el del pie solo aparece en la última pregunta.
  Future<void> _hojaEnHoja(BuildContext context, RendicionExamenState s, RendicionExamenNotifier n) async {
    final entregar = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (ctx) => Consumer(
            builder: (ctx, ref, _) {
              final s = ref.watch(rendicionExamenProvider(widget.clave));
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
                  child: _HojaRespuestas(
                    estado: s,
                    onIr: (i) {
                      n.irA(i);
                      Navigator.pop(ctx);
                    },
                    onEntregar: () => Navigator.pop(ctx, true),
                  ),
                ),
              );
            },
          ),
    );
    if (entregar == true && context.mounted) await _entregar(context, s, n);
  }

  Future<void> _entregar(BuildContext context, RendicionExamenState s, RendicionExamenNotifier n) async {
    final irA = await showDialog<int>(context: context, builder: (ctx) => _DialogoEntrega(clave: widget.clave));
    if (irA != null && irA >= 0) n.irA(irA);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RELOJ
// ═══════════════════════════════════════════════════════════════════════════

/// El tiempo que queda. Cambia de tono en los últimos 5 minutos y en el último.
class RelojExamen extends StatelessWidget {
  const RelojExamen({super.key, required this.segundos, this.grande = false});

  final int segundos;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra) =
        CronometroExamen.critico(segundos)
            ? (cs.errorContainer, cs.onErrorContainer)
            : CronometroExamen.enAviso(segundos)
            ? (cs.tertiaryContainer, cs.onTertiaryContainer)
            : (cs.surfaceContainerHighest, cs.onSurface);
    final texto = CronometroExamen.formato(segundos);
    return Semantics(
      label: 'Tiempo restante $texto',
      liveRegion: CronometroExamen.critico(segundos),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: grande ? Esp.m : Esp.s + 2, vertical: Esp.xs + 2),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(Esquina.chica)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: grande ? 20 : 16, color: letra),
            const SizedBox(width: Esp.xs + 2),
            Text(
              texto,
              style: TextStyle(
                fontFamily: fuenteFija,
                fontWeight: FontWeight.w700,
                fontSize: grande ? 20 : 15,
                color: letra,
                fontFeatures: cifrasTabulares,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EN CURSO
// ═══════════════════════════════════════════════════════════════════════════

class _BarraRendicion extends StatelessWidget {
  const _BarraRendicion({required this.estado, required this.compacto, required this.onEntregar, this.onHoja});

  final RendicionExamenState estado;
  final bool compacto;
  final VoidCallback onEntregar;
  final VoidCallback? onHoja;

  @override
  Widget build(BuildContext context) {
    final e = estado.estado!;
    final total = estado.preguntas.length;
    final hechas = estado.respondidas;
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          e.titulo ?? 'Examen',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${'$hechas'.padLeft('$total'.length, '0')}/$total',
                style: const TextStyle(
                  fontFamily: fuenteFija,
                  fontWeight: FontWeight.w700,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              const TextSpan(text: ' respondidas'),
            ],
          ),
          style: context.apagado(),
        ),
      ],
    );
    final entregar = FilledButton.icon(
      onPressed: estado.entregando ? null : onEntregar,
      icon: const Icon(Icons.outbox_outlined, size: 18),
      label: Text(compacto ? 'Entregar' : 'Revisar y entregar'),
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compacto ? Esp.m : Esp.l, Esp.m, compacto ? Esp.m : Esp.l, Esp.m),
            child: Row(
              children: [
                Expanded(child: titulo),
                const SizedBox(width: Esp.s),
                RelojExamen(segundos: estado.segundos, grande: !compacto),
                if (onHoja != null)
                  IconButton(
                    tooltip: 'Hoja de respuestas',
                    onPressed: onHoja,
                    icon: const Icon(Icons.grid_view_outlined),
                  ),
                if (!compacto) ...[const SizedBox(width: Esp.m), entregar],
              ],
            ),
          ),
          // La tira de la hoja: una casilla por pregunta, llena si ya se respondió.
          Padding(
            padding: EdgeInsets.fromLTRB(compacto ? Esp.m : Esp.l, 0, compacto ? Esp.m : Esp.l, Esp.s),
            child: TiraRespuestas(
              respondidas: [for (final p in estado.preguntas) estado.respondida(p)],
              actual: estado.actual,
            ),
          ),
        ],
      ),
    );
  }
}

class _HojaRespuestas extends StatelessWidget {
  const _HojaRespuestas({required this.estado, required this.onIr, this.onEntregar});

  final RendicionExamenState estado;
  final ValueChanged<int> onIr;

  /// Solo en la hoja del teléfono: el escritorio lo tiene en la barra.
  final VoidCallback? onEntregar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text('Hoja de respuestas', style: context.tituloSeccion())),
            Text(
              '${estado.respondidas}/${estado.preguntas.length}',
              style: TextStyle(
                fontFamily: fuenteFija,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                fontFeatures: cifrasTabulares,
              ),
            ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text('Toca un número para ir a esa pregunta.', style: context.apagado()),
        const SizedBox(height: Esp.m),
        Wrap(
          spacing: Esp.xs,
          runSpacing: Esp.xs,
          children: [
            for (var i = 0; i < estado.preguntas.length; i++)
              _Casilla(
                numero: i + 1,
                respondida: estado.respondida(estado.preguntas[i]),
                actual: i == estado.actual,
                guardando: estado.guardando.contains(estado.preguntas[i].codPreguntaH),
                onTap: () => onIr(i),
              ),
          ],
        ),
        const SizedBox(height: Esp.l),
        Wrap(
          spacing: Esp.l,
          runSpacing: Esp.xs,
          children: [
            for (final (marca, texto) in const [
              (MarcaBurbuja.marcada, 'Respondida'),
              (MarcaBurbuja.vacia, 'Sin responder'),
              (MarcaBurbuja.actual, 'La que ves'),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BurbujaHoja(texto: '', tamanio: 14, marca: marca),
                  const SizedBox(width: Esp.xs + 2),
                  Text(texto, style: context.apagado()),
                ],
              ),
          ],
        ),
        if (onEntregar != null) ...[
          const SizedBox(height: Esp.l),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: estado.entregando ? null : onEntregar,
              icon: const Icon(Icons.outbox_outlined, size: 18),
              label: const Text('Revisar y entregar'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.numero,
    required this.respondida,
    required this.actual,
    required this.guardando,
    required this.onTap,
  });

  final int numero;
  final bool respondida;
  final bool actual;
  final bool guardando;
  final VoidCallback onTap;

  /// La burbuja de 40 px dentro de un objetivo táctil de 48.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final marca =
        respondida
            ? MarcaBurbuja.marcada
            : actual
            ? MarcaBurbuja.actual
            : MarcaBurbuja.vacia;
    return Semantics(
      button: true,
      selected: actual,
      label: 'Pregunta $numero, ${respondida ? 'respondida' : 'sin responder'}',
      child: ExcludeSemantics(
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: DecoratedBox(
                // La actual respondida conserva el relleno y suma el anillo exterior.
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: actual && respondida ? Border.all(color: cs.onSurface, width: 2) : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(actual && respondida ? 2 : 0),
                  child: BurbujaHoja(
                    texto: '$numero',
                    tamanio: actual && respondida ? 36 : 40,
                    marca: marca,
                    hijo:
                        guardando
                            ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: respondida ? cs.onPrimary : cs.primary,
                              ),
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelPregunta extends StatelessWidget {
  const _PanelPregunta({
    required this.estado,
    required this.notifier,
    required this.compacto,
    required this.controlador,
    required this.onEntregar,
  });

  final RendicionExamenState estado;
  final RendicionExamenNotifier notifier;
  final bool compacto;
  final TextEditingController Function(BigInt cod, String inicial) controlador;
  final VoidCallback onEntregar;

  @override
  Widget build(BuildContext context) {
    final p = estado.preguntaActual!;
    final i = estado.actual;
    final total = estado.preguntas.length;
    final ultima = i == total - 1;
    final margen = compacto ? Esp.l : Esp.xxl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey('pregunta-${p.codPreguntaH}'),
            padding: EdgeInsets.fromLTRB(margen, Esp.xl, margen, Esp.xl),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PREGUNTA ${i + 1} DE $total',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontFamily: fuenteFija,
                            letterSpacing: 0.8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        _EstadoGuardado(
                          guardando: estado.guardando.contains(p.codPreguntaH),
                          respondida: estado.respondida(p),
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.m),
                    SelectableText(
                      p.pregunta ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: Esp.s),
                    Text(
                      p.esCerrada
                          ? 'Marca todas las opciones que correspondan.'
                          : 'Escribe tu respuesta. Se guarda sola mientras escribes.',
                      style: context.apagado(),
                    ),
                    const SizedBox(height: Esp.l),
                    if (p.esCerrada) ..._opciones(context, p) else _abierta(context, p),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compacto ? Esp.m : margen, vertical: Esp.s),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: i > 0 ? notifier.anterior : null,
                  icon: const Icon(Icons.chevron_left),
                  label: Text(compacto ? 'Anterior' : 'Pregunta anterior'),
                ),
                const Spacer(),
                if (ultima)
                  FilledButton.icon(
                    onPressed: estado.entregando ? null : onEntregar,
                    icon: const Icon(Icons.outbox_outlined, size: 18),
                    label: const Text('Revisar y entregar'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: notifier.siguiente,
                    icon: const Icon(Icons.chevron_right),
                    label: Text(compacto ? 'Siguiente' : 'Pregunta siguiente'),
                    iconAlignment: IconAlignment.end,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _opciones(BuildContext context, TcpePreguntaRendicionEntity p) {
    final cs = Theme.of(context).colorScheme;
    final opciones = estado.opciones[p.codPreguntaH] ?? const [];
    final marcadas = estado.marcadas[p.codPreguntaH] ?? const <BigInt>{};
    if (opciones.isEmpty) {
      return [const NotaDelDato(texto: 'Esta pregunta no tiene opciones cargadas.', tono: TonoNota.aviso)];
    }
    return [
      for (var k = 0; k < opciones.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.s),
          child: Builder(
            builder: (context) {
              final o = opciones[k];
              final si = marcadas.contains(o.codRsptaOpH);
              void alternar() {
                HapticFeedback.selectionClick();
                notifier.alternarOpcion(p.codPreguntaH, o.codRsptaOpH);
              }

              return AnimatedContainer(
                duration: duracionSuave(context, 160),
                decoration: BoxDecoration(
                  color: si ? cs.primaryContainer : cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Esquina.media),
                  border: Border.all(color: si ? cs.primary : cs.outlineVariant, width: si ? 1.5 : 1),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Esquina.media),
                    onTap: alternar,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
                      child: Row(
                        children: [
                          Checkbox(value: si, onChanged: (_) => alternar()),
                          Text(
                            '${String.fromCharCode(97 + k % 26)})',
                            style: TextStyle(
                              fontFamily: fuenteFija,
                              fontWeight: FontWeight.w600,
                              color: si ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Text(
                              o.opcionRspta ?? '',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(color: si ? cs.onPrimaryContainer : null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _abierta(BuildContext context, TcpePreguntaRendicionEntity p) {
    final c = controlador(p.codPreguntaH, estado.textos[p.codPreguntaH] ?? '');
    return TextField(
      key: ValueKey('abierta-${p.codPreguntaH}'),
      controller: c,
      minLines: 6,
      maxLines: 16,
      keyboardType: TextInputType.multiline,
      inputFormatters: [LengthLimitingTextInputFormatter(4000)],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Tu respuesta…',
        alignLabelWithHint: true,
      ),
      onChanged: (t) => notifier.escribir(p.codPreguntaH, t),
    );
  }
}

class _EstadoGuardado extends StatelessWidget {
  const _EstadoGuardado({required this.guardando, required this.respondida});

  final bool guardando;
  final bool respondida;

  @override
  Widget build(BuildContext context) {
    if (guardando) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: Esp.xs + 2),
          Text('Guardando…', style: context.apagado()),
        ],
      );
    }
    if (!respondida) return Text('Sin responder', style: context.apagado());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: Esp.xs),
        Text('Guardada', style: context.apagado()),
      ],
    );
  }
}

/// Resumen antes de entregar: cuántas faltan y cuáles. Devuelve el índice de
/// una pendiente si la persona quiere ir a responderla.
class _DialogoEntrega extends ConsumerWidget {
  const _DialogoEntrega({required this.clave});

  final ClaveRendicion clave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rendicionExamenProvider(clave));
    final n = ref.read(rendicionExamenProvider(clave).notifier);
    final pendientes = s.pendientes;
    final total = s.preguntas.length;
    return AlertDialog(
      icon: Icon(
        pendientes.isEmpty ? Icons.task_alt : Icons.pending_actions_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('¿Entregar el examen?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Respondiste ${total - pendientes.length} de $total preguntas.'),
              const SizedBox(height: Esp.s),
              if (pendientes.isEmpty)
                Text('No te falta ninguna.', style: context.apagado())
              else ...[
                Text(
                  pendientes.length == 1
                      ? 'Te falta 1 pregunta. Tócala para ir a responderla:'
                      : 'Te faltan ${pendientes.length} preguntas. Toca una para ir a responderla:',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.s),
                Wrap(
                  spacing: Esp.xs + 2,
                  runSpacing: Esp.xs + 2,
                  children: [
                    for (final i in pendientes)
                      ActionChip(
                        label: Text('${i + 1}', style: const TextStyle(fontFamily: fuenteFija)),
                        onPressed: () => Navigator.pop(context, i),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Esp.m),
              const NotaDelDato(
                texto: 'Una vez entregado ya no se pueden cambiar las respuestas.',
                tono: TonoNota.aviso,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: s.entregando ? null : () => Navigator.pop(context),
          child: const Text('Seguir respondiendo'),
        ),
        BotonAccion(
          etiqueta: 'Entregar examen',
          etiquetaOcupado: 'Entregando…',
          icono: Icons.outbox_outlined,
          ocupado: s.entregando,
          onPressed: () async {
            final ok = await n.entregar();
            if (ok && context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANTES Y DESPUÉS
// ═══════════════════════════════════════════════════════════════════════════

class _Portada extends StatelessWidget {
  const _Portada({required this.estado, required this.iniciando, required this.onComenzar, this.onSalir});

  final TcpeEstadoRendicionEntity estado;
  final bool iniciando;
  final Future<void> Function() onComenzar;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Tarjeta(
      children: [
        Text(
          (estado.nombreClasificacion ?? 'Examen').toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: fuenteFija,
            color: cs.primary,
            letterSpacing: 1.4,
            fontWeight: Peso.titulo,
          ),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          estado.titulo ?? 'Examen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.l),
        Wrap(
          spacing: Esp.xl,
          runSpacing: Esp.m,
          children: [
            CifraExamen(valor: '${estado.totalPreguntas}', rotulo: 'preguntas'),
            CifraExamen(valor: duracionTexto(estado.duracionMinutos), rotulo: 'de tiempo'),
            if (ventanaHorario(estado.inicioVentana, estado.finVentana) case final horario?)
              CifraExamen(valor: horario, rotulo: 'horario para empezar'),
          ],
        ),
        if ((estado.mensajeEstado ?? '').trim().isNotEmpty) NotaDelDato(texto: estado.mensajeEstado!.trim()),
        const SizedBox(height: Esp.l),
        for (final t in const [
          'El tiempo empieza a correr cuando tocas «Comenzar» y no se detiene, aunque cierres la ventana.',
          'Durante el examen no puedes salir de esta pantalla: sales al entregarlo o cuando se acaba el tiempo.',
          'Cada respuesta se guarda al instante: si se corta la conexión o recargas la página, sigues donde ibas.',
          'Puedes ir y volver entre las preguntas. Al terminar el tiempo, el examen se entrega solo.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check, size: 16, color: cs.primary)),
                const SizedBox(width: Esp.s),
                Expanded(child: Text(t)),
              ],
            ),
          ),
        const SizedBox(height: Esp.l),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            if (onSalir != null) TextButton(onPressed: onSalir, child: const Text('Volver')),
            BotonAccion(
              etiqueta: 'Comenzar examen',
              etiquetaOcupado: 'Preparando…',
              icono: Icons.play_arrow_rounded,
              ocupado: iniciando,
              onPressed: () async {
                final ok = await confirmar(
                  context,
                  titulo: '¿Comenzar ahora?',
                  detalle:
                      'Tienes ${duracionTexto(estado.duracionMinutos)} para responder '
                      '${estado.totalPreguntas} preguntas. El tiempo corre desde este momento.',
                  textoConfirmar: 'Comenzar',
                );
                if (ok) await onComenzar();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Cierre extends StatelessWidget {
  const _Cierre({required this.estado, required this.icono, required this.titulo, required this.detalle, this.onSalir});

  final TcpeEstadoRendicionEntity estado;
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Tarjeta(
      children: [
        Icon(icono, size: 40, color: cs.primary),
        const SizedBox(height: Esp.m),
        Text(estado.titulo ?? 'Examen', style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Text(titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo)),
        const SizedBox(height: Esp.s),
        Text(detalle),
        const SizedBox(height: Esp.l),
        Text('${estado.respondidas} de ${estado.totalPreguntas} preguntas respondidas', style: context.apagado()),
        if (onSalir != null) ...[
          const SizedBox(height: Esp.l),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(onPressed: onSalir, child: const Text('Volver a mis exámenes')),
          ),
        ],
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerLowest,
            shape: contornoSuperficie(cs),
            child: Padding(
              padding: const EdgeInsets.all(Esp.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

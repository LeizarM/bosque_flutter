/// Revisión de un examen entregado: las cerradas ya vienen corregidas; las
/// abiertas las marca el evaluador comparando con la respuesta modelo. Al no
/// quedar pendientes se cierra la calificación.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_revision_item_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

/// Abre la revisión. Devuelve true si algo cambió.
Future<bool> revisarExamen(BuildContext context, TcpeResultadoExamenEntity examen) async {
  final r = await mostrarFormulario<bool>(
    context,
    (completa) => RevisionExamen(examen: examen, completa: completa),
  );
  return r ?? false;
}

class RevisionExamen extends ConsumerStatefulWidget {
  const RevisionExamen({super.key, required this.examen, required this.completa});

  final TcpeResultadoExamenEntity examen;
  final bool completa;

  @override
  ConsumerState<RevisionExamen> createState() => _RevisionExamenState();
}

class _RevisionExamenState extends ConsumerState<RevisionExamen> {
  final Set<BigInt> _marcando = {};
  bool _cerrando = false;
  bool _cambio = false;

  BigInt get _cod => widget.examen.codExamen;

  Future<void> _marcar(TcpeRevisionItemEntity item, bool correcta) async {
    final codRespuestaH = item.codRespuestaH;
    if (codRespuestaH == null) return;
    setState(() => _marcando.add(item.codPreguntaH));
    try {
      await ref.read(examenesRepositoryProvider).marcarRespuesta(
        codExamen: _cod,
        codRespuestaH: codRespuestaH,
        esCorrecta: correcta,
      );
      _cambio = true;
      ref.invalidate(tcpeRevisionProvider(_cod));
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (mounted) setState(() => _marcando.remove(item.codPreguntaH));
    }
  }

  Future<void> _cerrar() async {
    final ok = await confirmar(
      context,
      titulo: 'Cerrar calificación',
      detalle: 'Se calcula la nota con las respuestas correctas sobre el total de preguntas.',
      textoConfirmar: 'Cerrar',
    );
    if (!ok || !mounted) return;
    setState(() => _cerrando = true);
    try {
      final msg = await ref.read(examenesRepositoryProvider).cerrarCalificacion(_cod);
      if (!mounted) return;
      avisar(context, msg ?? 'Calificación cerrada.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cerrando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(tcpeRevisionProvider(_cod));
    final lista = items.valueOrNull ?? const <TcpeRevisionItemEntity>[];
    final pendientes = lista.where((i) => i.pendiente).length;
    final entregado = EstadoExamenTcpe.desde(widget.examen.estado) != EstadoExamenTcpe.enCurso &&
        EstadoExamenTcpe.desde(widget.examen.estado) != EstadoExamenTcpe.sinIniciar;
    final nombre = (widget.examen.nombreCompleto ?? '').trim().isEmpty ? widget.examen.login : widget.examen.nombreCompleto;

    return MarcoFormulario(
      titulo: 'Revisión · ${nombre ?? ''}',
      icono: Icons.rate_review_outlined,
      completa: widget.completa,
      ancho: 760,
      cuerpo: items.when(
        skipLoadingOnReload: true,
        loading: () => const SizedBox(height: 320, child: EsqueletoLista(filas: 4, altoFila: 64)),
        error: (e, _) => MensajeError(error: e, compacto: true, onReintentar: () => ref.invalidate(tcpeRevisionProvider(_cod))),
        data:
            (lista) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pendientes == 0
                      ? 'No quedan respuestas escritas por marcar.'
                      : 'Quedan $pendientes ${pendientes == 1 ? 'respuesta escrita' : 'respuestas escritas'} por marcar.',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.m),
                if (lista.isEmpty)
                  const NotaDelDato(texto: 'Este examen todavía no tiene respuestas para revisar.'),
                for (final item in [...lista]..sort((a, b) => a.orden.compareTo(b.orden)))
                  _Item(
                    item: item,
                    marcando: _marcando.contains(item.codPreguntaH),
                    puedeMarcar: entregado,
                    onMarcar: (v) => _marcar(item, v),
                  ),
              ],
            ),
      ),
      acciones: [
        TextButton(onPressed: () => Navigator.pop(context, _cambio), child: const Text('Cerrar')),
        BotonAccion(
          etiqueta: 'Cerrar calificación',
          etiquetaOcupado: 'Calculando nota…',
          icono: Icons.verified_outlined,
          ocupado: _cerrando,
          onPressed: !entregado || !items.hasValue || pendientes > 0 ? null : _cerrar,
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.marcando, required this.puedeMarcar, required this.onMarcar});

  final TcpeRevisionItemEntity item;
  final bool marcando;
  final bool puedeMarcar;
  final ValueChanged<bool> onMarcar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icono, color, texto) = switch (item.esCorrecta) {
      true => (Icons.check_circle, cs.primary, 'Correcta'),
      false => (Icons.cancel, cs.error, 'Incorrecta'),
      null => (Icons.help_outline, cs.tertiary, 'Por marcar'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: Esp.m),
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: item.pendiente ? cs.tertiary : cs.outlineVariant, width: item.pendiente ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Text('${item.orden}.', style: const TextStyle(fontFamily: fuenteFija, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Text(item.pregunta ?? '', style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(width: Esp.s),
              Icon(icono, size: 18, color: color),
              const SizedBox(width: Esp.xs),
              Text(texto, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: Esp.s),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child:
                item.esCerrada
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Par('Marcó', item.marcadas?.isNotEmpty == true ? item.marcadas! : 'Nada'),
                        _Par('Válidas', item.correctas ?? '--'),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Par('Respondió', (item.respuestaU ?? '').trim().isEmpty ? 'Sin respuesta' : item.respuestaU!),
                        _Par('Modelo', item.respuestaModelo ?? '--'),
                        const SizedBox(height: Esp.s),
                        Row(
                          children: [
                            if (marcando)
                              const Padding(
                                padding: EdgeInsets.only(right: Esp.s),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            Flexible(
                              child: SegmentedButton<bool>(
                                emptySelectionAllowed: true,
                                segments: const [
                                  ButtonSegment(value: true, label: Text('Correcta'), icon: Icon(Icons.check)),
                                  ButtonSegment(value: false, label: Text('Incorrecta'), icon: Icon(Icons.close)),
                                ],
                                selected: {if (item.esCorrecta != null) item.esCorrecta!},
                                onSelectionChanged:
                                    !puedeMarcar || marcando
                                        ? null
                                        : (s) {
                                          if (s.isNotEmpty) onMarcar(s.first);
                                        },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _Par extends StatelessWidget {
  const _Par(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 84, child: Text(rotulo, style: context.apagado())),
        Expanded(child: SelectableText(valor)),
      ],
    ),
  );
}

/// Pide la nota manual de un examen escrito.
Future<double?> pedirNotaManual(BuildContext context, TcpeResultadoExamenEntity examen) =>
    showDialog<double>(context: context, builder: (_) => _DialogoNota(examen: examen));

class _DialogoNota extends StatefulWidget {
  const _DialogoNota({required this.examen});

  final TcpeResultadoExamenEntity examen;

  @override
  State<_DialogoNota> createState() => _DialogoNotaState();
}

class _DialogoNotaState extends State<_DialogoNota> {
  final _form = GlobalKey<FormState>();
  late final _nota = TextEditingController(
    text: widget.examen.resultado == null ? '' : nota(widget.examen.resultado),
  );

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.examen;
    return AlertDialog(
      title: const Text('Nota del examen escrito'),
      content: Form(
        key: _form,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text((e.nombreCompleto ?? '').trim().isEmpty ? (e.login ?? '') : e.nombreCompleto!, style: context.apagado()),
              const SizedBox(height: Esp.m),
              TextFormField(
                controller: _nota,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(6)],
                decoration: const InputDecoration(labelText: 'Nota', suffixText: '/ 100', border: OutlineInputBorder()),
                // Solo el formato: el rango lo valida el SP (N) con su propio mensaje.
                validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Escribe la nota' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, double.parse(_nota.text.replaceAll(',', '.')));
          },
          child: const Text('Guardar nota'),
        ),
      ],
    );
  }
}

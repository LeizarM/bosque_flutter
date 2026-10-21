/// Alta y edición de una pregunta de la semana: el texto que verá cada empleado
/// en su inicio, cómo se responde (abierta o de escala), el plazo y un título
/// opcional, con la vista previa. Las reglas las aplica `p_abm_tcpe_PreguntaSemana`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/pregunta_semana_inicio.dart';

/// Abre el editor; true si se guardó.
Future<bool> abrirEditorPreguntaSemana(BuildContext context, {TcpePreguntaSemanaEntity? pregunta}) async =>
    await mostrarFormulario<bool>(
      context,
      (completa) => EditorPreguntaSemana(completa: completa, pregunta: pregunta),
    ) ??
    false;

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

/// Desde este ancho las dos etiquetas de la escala van lado a lado.
const double _anchoEtiquetasJuntas = 480;

class EditorPreguntaSemana extends ConsumerStatefulWidget {
  const EditorPreguntaSemana({super.key, required this.completa, this.pregunta});

  final bool completa;

  /// Null = alta.
  final TcpePreguntaSemanaEntity? pregunta;

  @override
  ConsumerState<EditorPreguntaSemana> createState() => _EditorPreguntaSemanaState();
}

class _EditorPreguntaSemanaState extends ConsumerState<EditorPreguntaSemana> {
  final _pregunta = TextEditingController();
  final _titulo = TextEditingController();
  final _etiquetaMin = TextEditingController();
  final _etiquetaMax = TextEditingController();
  late DateTime _desde;

  /// Null = la propuesta: inicio + `preguntaSemanaDias` − 1, que sigue al inicio.
  DateTime? _hasta;

  /// `A` abierta o `E` escala.
  late String _tipo;

  /// Null = el de la pregunta o, en una nueva, el que propone la configuración.
  int? _min;
  int? _max;
  bool _guardando = false;

  bool get _editando => widget.pregunta != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pregunta;
    _desde = _soloDia(p?.fechaInicio ?? DateTime.now());
    _hasta = p?.fechaFin == null ? null : _soloDia(p!.fechaFin!);
    _pregunta.text = p?.pregunta ?? '';
    _titulo.text = p?.titulo ?? '';
    _tipo = p?.esEscala == true ? 'E' : 'A';
    _min = p?.escalaMin;
    _max = p?.escalaMax;
    _etiquetaMin.text = p?.etiquetaMin ?? '';
    _etiquetaMax.text = p?.etiquetaMax ?? '';
  }

  @override
  void dispose() {
    _pregunta.dispose();
    _titulo.dispose();
    _etiquetaMin.dispose();
    _etiquetaMax.dispose();
    super.dispose();
  }

  DateTime _hastaDe(TcpeConfiguracion cfg) => _hasta ?? _desde.add(Duration(days: cfg.preguntaSemanaDias - 1));

  int _minDe(TcpeConfiguracion cfg) => (_min ?? cfg.escalaMinSemana).clamp(0, cfg.escalaTopeSemana - 1);

  /// Siempre después del inicio y dentro del tope.
  int _maxDe(TcpeConfiguracion cfg) {
    final min = _minDe(cfg);
    final m = (_max ?? cfg.escalaMaxSemana).clamp(0, cfg.escalaTopeSemana);
    return m > min ? m : min + 1;
  }

  Future<void> _elegirFecha(bool desde, TcpeConfiguracion cfg) async {
    final actual = desde ? _desde : _hastaDe(cfg);
    final f = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (f == null) return;
    setState(() => desde ? _desde = _soloDia(f) : _hasta = _soloDia(f));
  }

  Future<void> _guardar(TcpeConfiguracion cfg) async {
    setState(() => _guardando = true);
    final base = widget.pregunta ?? TcpePreguntaSemanaEntity(codPreguntaSemana: BigInt.zero);
    final escala = _tipo == 'E';
    final pregunta = base.copyWith(
      pregunta: _pregunta.text.trim(),
      titulo: _titulo.text.trim(),
      tipo: _tipo,
      escalaMin: escala ? _minDe(cfg) : null,
      escalaMax: escala ? _maxDe(cfg) : null,
      etiquetaMin: escala ? _etiquetaMin.text.trim() : null,
      etiquetaMax: escala ? _etiquetaMax.text.trim() : null,
      fechaInicio: _desde,
      fechaFin: _hastaDe(cfg),
    );
    try {
      final msg = await ref.read(examenesRepositoryProvider).guardarPreguntaSemana(pregunta);
      if (!mounted) return;
      avisar(context, msg ?? 'Pregunta de la semana guardada.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(configExamenesProvider(OrigenRendicion.empleado)).valueOrNull ?? TcpeConfiguracion.respaldo;
    final respuestas = widget.pregunta?.respuestas ?? 0;
    final texto = _pregunta.text.trim();
    final titulo = _titulo.text.trim();
    final escala = _tipo == 'E';
    // Con respuestas el SP no deja cambiar el tipo ni la escala: aquí ni se ofrece.
    final bloqueado = respuestas > 0;
    final min = _minDe(cfg);
    final max = _maxDe(cfg);
    const borde = OutlineInputBorder();

    return MarcoFormulario(
      titulo: _editando ? 'Editar pregunta de la semana' : 'Nueva pregunta de la semana',
      icono: Icons.forum_outlined,
      completa: widget.completa,
      ancho: 640,
      acciones: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: _editando ? 'Guardar cambios' : 'Publicar',
          etiquetaOcupado: 'Guardando…',
          icono: Icons.check,
          ocupado: _guardando,
          onPressed: texto.isEmpty ? null : () => _guardar(cfg),
        ),
      ],
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pregunta', style: context.tituloSeccion()),
          const SizedBox(height: Esp.xs),
          Text('Cada empleado la ve en su inicio y, si quiere, la responde.', style: context.apagado()),
          if (respuestas > 0) ...[
            const SizedBox(height: Esp.xs),
            Text(
              respuestas == 1 ? 'Ya la respondió 1 persona.' : 'Ya la respondieron $respuestas personas.',
              style: context.apagado(),
            ),
          ],
          const SizedBox(height: Esp.m),
          TextField(
            controller: _pregunta,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Qué quieres preguntar',
              hintText:
                  escala ? 'Por ejemplo: ¿Cómo ves el ambiente laboral?' : 'Por ejemplo: ¿Qué tal tu día?',
              alignLabelWithHint: true,
              border: borde,
            ),
          ),
          const SizedBox(height: Esp.m),
          TextField(
            controller: _titulo,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Título (opcional)',
              helperText: 'Si lo dejas vacío, se muestra «${cfg.tituloPreguntaSemana}».',
              border: borde,
            ),
          ),
          const SizedBox(height: Esp.l),
          Text('Cómo se responde', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'A', icon: Icon(Icons.notes), label: Text('Abierta')),
              ButtonSegment(value: 'E', icon: Icon(Icons.linear_scale), label: Text('Escala')),
            ],
            selected: {_tipo},
            showSelectedIcon: false,
            onSelectionChanged: bloqueado ? null : (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: Esp.xs),
          Text(
            bloqueado
                ? 'Ya tiene respuestas: el tipo y la escala no cambian.'
                : escala
                ? 'Cada uno elige un número de la escala.'
                : 'Cada uno escribe con sus palabras.',
            style: context.apagado(),
          ),
          if (escala) ...[
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('desde-$min'),
                    value: min,
                    decoration: const InputDecoration(labelText: 'Desde', border: borde),
                    items: [
                      for (var v = 0; v < cfg.escalaTopeSemana; v++) DropdownMenuItem(value: v, child: Text('$v')),
                    ],
                    onChanged:
                        bloqueado
                            ? null
                            : (v) {
                              if (v == null) return;
                              setState(() {
                                _min = v;
                                if (max <= v) _max = v + 1;
                              });
                            },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('hasta-$min-$max'),
                    value: max,
                    decoration: const InputDecoration(labelText: 'Hasta', border: borde),
                    items: [
                      for (var v = min + 1; v <= cfg.escalaTopeSemana; v++)
                        DropdownMenuItem(value: v, child: Text('$v')),
                    ],
                    onChanged: bloqueado ? null : (v) => setState(() => _max = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.m),
            LayoutBuilder(
              builder: (context, r) {
                final campoMin = TextField(
                  controller: _etiquetaMin,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Qué significa el $min (opcional)',
                    hintText: 'Por ejemplo: Muy mal',
                    border: borde,
                  ),
                );
                final campoMax = TextField(
                  controller: _etiquetaMax,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Qué significa el $max (opcional)',
                    hintText: 'Por ejemplo: Excelente',
                    border: borde,
                  ),
                );
                if (r.maxWidth >= _anchoEtiquetasJuntas) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: campoMin),
                      const SizedBox(width: Esp.m),
                      Expanded(child: campoMax),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [campoMin, const SizedBox(height: Esp.m), campoMax],
                );
              },
            ),
          ],
          const SizedBox(height: Esp.l),
          Text('Plazo para responder', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _elegirFecha(true, cfg),
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text('Desde: ${fechaCorta(_desde)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _elegirFecha(false, cfg),
                icon: const Icon(Icons.event_available_outlined, size: 18),
                label: Text('Hasta: ${fechaCorta(_hastaDe(cfg))}'),
              ),
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text('Días completos: se puede responder el primer y el último día.', style: context.apagado()),
          const SizedBox(height: Esp.l),
          Text('Así se verá en el inicio', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          _VistaPrevia(
            titulo: titulo.isEmpty ? cfg.tituloPreguntaSemana : titulo,
            pregunta: texto,
            escala:
                escala
                    ? (min: min, max: max, etiquetaMin: _etiquetaMin.text, etiquetaMax: _etiquetaMax.text)
                    : null,
          ),
        ],
      ),
    );
  }
}

/// La tarjeta del inicio en chico, con lo que se va escribiendo.
class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.titulo, required this.pregunta, this.escala});

  final String titulo;
  final String pregunta;

  /// De escala: el rango y las etiquetas, para mostrar los botones.
  final ({int min, int max, String etiquetaMin, String etiquetaMax})? escala;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = escala;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.18), cs.surface),
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: LayoutBuilder(
          builder:
              (context, r) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: Peso.titulo),
                  ),
                  const SizedBox(height: Esp.s),
                  GloboSemana(
                    texto: pregunta.isEmpty ? 'Escribe la pregunta arriba.' : pregunta,
                    ancho: r.maxWidth * 0.85,
                  ),
                  if (e != null) ...[
                    const SizedBox(height: Esp.m),
                    SelectorEscalaSemana(
                      min: e.min,
                      max: e.max,
                      etiquetaMin: e.etiquetaMin,
                      etiquetaMax: e.etiquetaMax,
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }
}

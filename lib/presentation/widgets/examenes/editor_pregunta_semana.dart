/// Alta y edición de una pregunta de la semana: la pregunta del banco (las que
/// no se pueden elegir aparecen apagadas con su motivo), el plazo, el título y
/// si muestra la respuesta. Las reglas las aplica `p_abm_tcpe_PreguntaSemana`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_candidata_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';

/// Abre el editor; true si se guardó.
Future<bool> abrirEditorPreguntaSemana(BuildContext context, {TcpePreguntaSemanaEntity? pregunta}) async =>
    await mostrarFormulario<bool>(
      context,
      (completa) => EditorPreguntaSemana(completa: completa, pregunta: pregunta),
    ) ??
    false;

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

class EditorPreguntaSemana extends ConsumerStatefulWidget {
  const EditorPreguntaSemana({super.key, required this.completa, this.pregunta});

  final bool completa;

  /// Null = alta.
  final TcpePreguntaSemanaEntity? pregunta;

  @override
  ConsumerState<EditorPreguntaSemana> createState() => _EditorPreguntaSemanaState();
}

class _EditorPreguntaSemanaState extends ConsumerState<EditorPreguntaSemana> {
  final _buscar = TextEditingController();
  final _titulo = TextEditingController();
  Timer? _espera;
  BigInt? _codClasificacion;
  String _texto = '';
  BigInt? _codPregunta;
  String? _textoPregunta;
  late DateTime _desde;

  /// Null = la propuesta: inicio + `preguntaSemanaDias` − 1, que sigue al inicio.
  DateTime? _hasta;
  bool _mostrar = true;
  bool _guardando = false;

  bool get _editando => widget.pregunta != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pregunta;
    _desde = _soloDia(p?.fechaInicio ?? DateTime.now());
    _hasta = p?.fechaFin == null ? null : _soloDia(p!.fechaFin!);
    _codPregunta = p?.codPregunta;
    _textoPregunta = p?.pregunta;
    _codClasificacion = p?.codClasificacion;
    _titulo.text = p?.titulo ?? '';
    _mostrar = p?.mostrarRespuesta ?? true;
  }

  @override
  void dispose() {
    _espera?.cancel();
    _buscar.dispose();
    _titulo.dispose();
    super.dispose();
  }

  void _alEscribir(String t) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _texto = t.trim());
    });
  }

  DateTime _hastaDe(TcpeConfiguracion cfg) => _hasta ?? _desde.add(Duration(days: cfg.preguntaSemanaDias - 1));

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
    final pregunta = base.copyWith(
      codPregunta: _codPregunta,
      titulo: _titulo.text.trim(),
      fechaInicio: _desde,
      fechaFin: _hastaDe(cfg),
      mostrarRespuesta: _mostrar,
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
    final categorias = [
      for (final c in ref.watch(tcpeCategoriasProvider).valueOrNull ?? const [])
        if (c.activo || c.codClasificacion == _codClasificacion) c,
    ];
    final respondida = (widget.pregunta?.respuestas ?? 0) > 0;
    const borde = OutlineInputBorder();

    return MarcoFormulario(
      titulo: _editando ? 'Editar pregunta de la semana' : 'Nueva pregunta de la semana',
      icono: Icons.quiz_outlined,
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
          onPressed: _codPregunta == null ? null : () => _guardar(cfg),
        ),
      ],
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pregunta del banco', style: context.tituloSeccion()),
          const SizedBox(height: Esp.xs),
          Text('Se responde eligiendo una opción en el inicio de cada empleado.', style: context.apagado()),
          if (respondida) ...[
            const SizedBox(height: Esp.xs),
            Text('Ya la respondieron ${widget.pregunta!.respuestas} personas.', style: context.apagado()),
          ],
          const SizedBox(height: Esp.m),
          if (_codPregunta != null) ...[_Elegida(texto: _textoPregunta), const SizedBox(height: Esp.m)],
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.s,
            children: [
              SizedBox(
                width: widget.completa ? double.infinity : 260,
                child: DropdownButtonFormField<BigInt?>(
                  value: _codClasificacion,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría', isDense: true, border: borde),
                  items: [
                    const DropdownMenuItem<BigInt?>(value: null, child: Text('Todas')),
                    for (final c in categorias)
                      DropdownMenuItem<BigInt?>(
                        value: c.codClasificacion,
                        child: Text(c.nombre ?? '--', overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _codClasificacion = v),
                ),
              ),
              SizedBox(
                width: widget.completa ? double.infinity : 300,
                child: TextField(
                  controller: _buscar,
                  onChanged: _alEscribir,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Buscar en el texto',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: borde,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Esp.s),
          _Candidatas(
            filtro: (codClasificacion: _codClasificacion, texto: _texto),
            elegida: _codPregunta,
            onElegir:
                (c) => setState(() {
                  _codPregunta = c.codPregunta;
                  _textoPregunta = c.pregunta;
                }),
          ),
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
          TextField(
            controller: _titulo,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            decoration: InputDecoration(
              labelText: 'Título (opcional)',
              helperText: 'Si lo dejas vacío, se muestra «${cfg.tituloPreguntaSemana}».',
              border: borde,
            ),
          ),
          const SizedBox(height: Esp.s),
          CheckboxListTile(
            value: _mostrar,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Mostrar la respuesta correcta al responder'),
            subtitle: Text(
              _mostrar
                  ? 'Al responder, cada uno ve si acertó y cuál era la correcta.'
                  : 'Al responder, cada uno solo ve que su respuesta quedó registrada.',
              style: context.apagado(),
            ),
            onChanged: (v) => setState(() => _mostrar = v ?? true),
          ),
        ],
      ),
    );
  }
}

/// La pregunta elegida, a la vista aunque el filtro ya no la muestre.
class _Elegida extends StatelessWidget {
  const _Elegida({required this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.5), cs.surface),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BurbujaHoja(
            texto: '',
            marca: MarcaBurbuja.marcada,
            tamanio: 28,
            hijo: Icon(Icons.check, size: 16, color: cs.onPrimary),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elegida', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary)),
                Text(oGuion(texto), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Candidatas extends ConsumerWidget {
  const _Candidatas({required this.filtro, required this.elegida, required this.onElegir});

  final FiltroCandidatasSemana filtro;
  final BigInt? elegida;
  final ValueChanged<TcpeCandidataSemanaEntity> onElegir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filtro.codClasificacion == null && filtro.texto.isEmpty) {
      return _Nota(icono: Icons.manage_search, texto: 'Elige una categoría o busca por el texto de la pregunta.');
    }
    return ref
        .watch(tcpeCandidatasSemanaProvider(filtro))
        .when(
          skipLoadingOnReload: true,
          loading: () => const Padding(padding: EdgeInsets.all(Esp.l), child: LinearProgressIndicator()),
          error:
              (e, _) => _Nota(
                icono: Icons.cloud_off_outlined,
                texto: textoParaUsuario(e),
                accion: 'Reintentar',
                onAccion: () => ref.invalidate(tcpeCandidatasSemanaProvider(filtro)),
              ),
          data:
              (filas) =>
                  filas.isEmpty
                      ? _Nota(icono: Icons.search_off, texto: 'No hay preguntas con ese filtro.')
                      : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder:
                              (context, i) => _FilaCandidata(
                                c: filas[i],
                                elegida: filas[i].codPregunta == elegida,
                                onTap: filas[i].puedeElegirse ? () => onElegir(filas[i]) : null,
                              ),
                        ),
                      ),
        );
  }
}

class _FilaCandidata extends StatelessWidget {
  const _FilaCandidata({required this.c, required this.elegida, required this.onTap});

  final TcpeCandidataSemanaEntity c;
  final bool elegida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final apagada = !c.puedeElegirse;
    return Semantics(
      button: !apagada,
      selected: elegida,
      enabled: !apagada,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Esquina.chica),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.s + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BurbujaHoja(
                texto: '',
                tamanio: 24,
                marca:
                    elegida
                        ? MarcaBurbuja.marcada
                        : apagada
                        ? MarcaBurbuja.neutra
                        : MarcaBurbuja.vacia,
                hijo: elegida ? Icon(Icons.check, size: 14, color: cs.onPrimary) : const SizedBox.shrink(),
              ),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oGuion(c.pregunta),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: apagada ? cs.onSurfaceVariant : null,
                        fontWeight: elegida ? Peso.titulo : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apagada
                          ? oGuion(c.motivo)
                          : [
                            oGuion(c.nombreClasificacion),
                            '${c.cantOpciones} opciones',
                            if (c.vecesUsada > 0) 'ya usada ${c.vecesUsada} ${c.vecesUsada == 1 ? 'vez' : 'veces'}',
                          ].join(' · '),
                      style: context.apagado(),
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

class _Nota extends StatelessWidget {
  const _Nota({required this.icono, required this.texto, this.accion, this.onAccion});

  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.m),
    child: Row(
      children: [
        Icon(icono, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: context.apagado())),
        if (accion != null && onAccion != null) TextButton(onPressed: onAccion, child: Text(accion!)),
      ],
    ),
  );
}

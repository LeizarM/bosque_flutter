/// Alta y edición de una pregunta del banco: texto, categoría, si es abierta
/// (con su respuesta modelo) o cerrada (con sus opciones y cuáles valen).
/// Guarda todo junto por `/examenes/banco/guardar`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';

/// Abre el editor. Devuelve true si se guardó.
Future<bool> editarPregunta(
  BuildContext context, {
  TcpeBancoPreguntaEntity? pregunta,
  BigInt? codClasificacion,
  required List<TcpeClasificacionEntity> categorias,
}) async {
  final r = await mostrarFormulario<bool>(
    context,
    (completa) => EditorPregunta(
      pregunta: pregunta,
      codClasificacion: codClasificacion,
      categorias: categorias,
      completa: completa,
    ),
  );
  return r ?? false;
}

class _Opcion {
  _Opcion({required this.cod, String texto = '', this.valida = false, this.usada = false})
    : texto = TextEditingController(text: texto);

  final BigInt cod;
  final TextEditingController texto;
  bool valida;
  final bool usada;
}

class EditorPregunta extends ConsumerStatefulWidget {
  const EditorPregunta({
    super.key,
    required this.pregunta,
    required this.codClasificacion,
    required this.categorias,
    required this.completa,
  });

  final TcpeBancoPreguntaEntity? pregunta;
  final BigInt? codClasificacion;
  final List<TcpeClasificacionEntity> categorias;
  final bool completa;

  @override
  ConsumerState<EditorPregunta> createState() => _EditorPreguntaState();
}

class _EditorPreguntaState extends ConsumerState<EditorPregunta> {
  final _form = GlobalKey<FormState>();
  late final _texto = TextEditingController(text: widget.pregunta?.pregunta ?? '');
  late final _respuesta = TextEditingController(text: widget.pregunta?.respuesta ?? '');
  late BigInt? _codClasificacion = widget.pregunta?.codClasificacion ?? widget.codClasificacion;
  late bool _cerrada = widget.pregunta?.esCerrada ?? true;
  late bool _activo = widget.pregunta?.activo ?? true;
  final List<_Opcion> _opciones = [];
  bool _cargandoOpciones = false;
  bool _guardando = false;
  String? _errorOpciones;

  // Duplicados mientras se escribe (`Banco` D). Solo avisa: guardar lo valida el SP.
  Timer? _pausaDuplicados;
  int _consultaDuplicados = 0;
  String _ultimoBuscado = '';
  List<TcpeDuplicadoPreguntaEntity> _duplicados = const [];

  bool get _esNueva => widget.pregunta == null;

  @override
  void initState() {
    super.initState();
    _ultimoBuscado = _texto.text.trim();
    _texto.addListener(_programarDuplicados);
    if (_esNueva || !(widget.pregunta?.esCerrada ?? false)) {
      _opciones.addAll([_Opcion(cod: BigInt.zero), _Opcion(cod: BigInt.zero)]);
    } else {
      _cargarOpciones();
    }
  }

  Future<void> _cargarOpciones() async {
    setState(() => _cargandoOpciones = true);
    try {
      final lista = await ref
          .read(examenesRepositoryProvider)
          .listarOpciones(codPregunta: widget.pregunta!.codPregunta);
      if (!mounted) return;
      setState(() {
        _opciones
          ..clear()
          ..addAll([
            for (final o in lista)
              _Opcion(cod: o.codRsptaOp, texto: o.opcionRspta ?? '', valida: o.esValido, usada: o.usadaEnExamenes),
          ]);
        if (_opciones.length < 2) _opciones.add(_Opcion(cod: BigInt.zero));
        _cargandoOpciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoOpciones = false;
        _errorOpciones = textoParaUsuario(e);
      });
    }
  }

  /// Busca 600 ms después de la última tecla, con texto y categoría elegidos.
  void _programarDuplicados({bool forzar = false}) {
    final t = _texto.text.trim();
    if (!forzar && t == _ultimoBuscado) return;
    _ultimoBuscado = t;
    _pausaDuplicados?.cancel();
    if (t.length < 4 || _codClasificacion == null) {
      _consultaDuplicados++;
      if (_duplicados.isNotEmpty) setState(() => _duplicados = const []);
      return;
    }
    _pausaDuplicados = Timer(const Duration(milliseconds: 600), _buscarDuplicados);
  }

  Future<void> _buscarDuplicados() async {
    final cod = _codClasificacion;
    if (cod == null) return;
    final id = ++_consultaDuplicados;
    try {
      final lista = await ref.read(examenesRepositoryProvider).buscarDuplicados(cod, _texto.text.trim());
      // Gana la última consulta: una respuesta vieja no pisa a la nueva.
      if (!mounted || id != _consultaDuplicados) return;
      final propia = widget.pregunta?.codPregunta;
      setState(() => _duplicados = [for (final d in lista) if (d.codPregunta != propia) d]);
    } catch (_) {
      // El aviso es una ayuda: si falla, guardar sigue validando en el SP.
    }
  }

  Future<void> _abrirExistente(BigInt cod) async {
    try {
      final lista = await ref.read(examenesRepositoryProvider).listarPreguntas(codPregunta: cod);
      final p = lista.where((x) => x.codPregunta == cod).firstOrNull;
      if (!mounted) return;
      if (p == null) {
        avisar(context, 'La pregunta ya no está en el banco.', esError: true);
        return;
      }
      await editarPregunta(context, pregunta: p, categorias: widget.categorias);
      if (mounted) _programarDuplicados(forzar: true);
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  void dispose() {
    _pausaDuplicados?.cancel();
    _texto.removeListener(_programarDuplicados);
    _texto.dispose();
    _respuesta.dispose();
    for (final o in _opciones) {
      o.texto.dispose();
    }
    super.dispose();
  }

  static String _normal(String t) => t.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Las reglas de `p_abm_tcpe_Banco`, antes de viajar.
  String? _validarOpciones() {
    if (!_cerrada) return null;
    final llenas = _opciones.where((o) => o.texto.text.trim().isNotEmpty).toList();
    if (llenas.length < 2) return 'Una pregunta cerrada necesita al menos 2 opciones.';
    // El tope sale de la configuración (`maxOpcionesPorPregunta`).
    final maximo =
        (ref.read(configExamenesProvider(OrigenRendicion.empleado)).valueOrNull ?? TcpeConfiguracion.respaldo)
            .maxOpcionesPorPregunta;
    if (llenas.length > maximo) return 'Una pregunta admite como máximo $maximo opciones.';
    if (!llenas.any((o) => o.valida)) return 'Marca al menos una opción como válida.';
    final vistas = <String>{};
    for (final o in llenas) {
      if (!vistas.add(_normal(o.texto.text))) return 'Hay opciones repetidas: «${o.texto.text.trim()}».';
    }
    return null;
  }

  Future<void> _guardar() async {
    final okForm = _form.currentState!.validate();
    final errorOpc = _validarOpciones();
    setState(() => _errorOpciones = errorOpc);
    if (!okForm || errorOpc != null) return;

    final base = widget.pregunta ?? TcpeBancoPreguntaEntity(codPregunta: BigInt.zero);
    final pregunta = base.copyWith(
      codClasificacion: _codClasificacion,
      pregunta: _texto.text.trim(),
      activo: _activo,
      esCerrada: _cerrada,
      respuesta: _cerrada ? '' : _respuesta.text.trim(),
    );
    final opciones = [
      for (final o in _opciones)
        if (o.texto.text.trim().isNotEmpty)
          TcpeBancoOpcionEntity(codRsptaOp: o.cod, opcionRspta: o.texto.text.trim(), esValido: o.valida),
    ];
    setState(() => _guardando = true);
    try {
      await ref.read(examenesRepositoryProvider).guardarPregunta(pregunta, opciones);
      if (!mounted) return;
      avisar(context, _esNueva ? 'Pregunta agregada al banco.' : 'Pregunta guardada.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(configExamenesProvider(OrigenRendicion.empleado));
    final usada = widget.pregunta?.usada ?? false;
    final cs = Theme.of(context).colorScheme;
    // El tipo elegido tiñe su segmento: cerrada en principal, abierta en terciario.
    final tipo = coloresDeTono(cs, _cerrada ? TonoExamen.principal : TonoExamen.terciario);
    return MarcoFormulario(
      titulo: _esNueva ? 'Nueva pregunta' : 'Editar pregunta',
      icono: _esNueva ? Icons.post_add : Icons.edit_note,
      completa: widget.completa,
      ancho: 640,
      cuerpo: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (usada)
              const Padding(
                padding: EdgeInsets.only(bottom: Esp.m),
                child: NotaDelDato(
                  texto:
                      'Esta pregunta ya salió en exámenes. Los cambios valen para los '
                      'próximos: los exámenes generados conservan su versión.',
                ),
              ),
            DropdownButtonFormField<BigInt>(
              value: widget.categorias.any((c) => c.codClasificacion == _codClasificacion) ? _codClasificacion : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              items: [
                for (final c in widget.categorias)
                  DropdownMenuItem(
                    value: c.codClasificacion,
                    child: Text(c.nombre ?? '', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                setState(() => _codClasificacion = v);
                _programarDuplicados(forzar: true);
              },
              validator: (v) => v == null ? 'Elige la categoría' : null,
            ),
            const SizedBox(height: Esp.m),
            TextFormField(
              controller: _texto,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Pregunta', border: OutlineInputBorder(), alignLabelWithHint: true),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe la pregunta' : null,
            ),
            AnimatedSize(
              duration: duracionSuave(context),
              alignment: Alignment.topCenter,
              child:
                  _duplicados.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : AvisoDuplicados(duplicados: _duplicados, onAbrir: _abrirExistente),
            ),
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: tipo.fondo,
                    selectedForegroundColor: tipo.letra,
                  ),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Cerrada'), icon: Icon(Icons.checklist)),
                    ButtonSegment(value: false, label: Text('Abierta'), icon: Icon(Icons.notes)),
                  ],
                  selected: {_cerrada},
                  onSelectionChanged: (s) => setState(() {
                    _cerrada = s.first;
                    _errorOpciones = null;
                  }),
                ),
                FilterChip(
                  label: Text(_activo ? 'Activa' : 'Inactiva'),
                  avatar: _activo ? null : Icon(Icons.visibility_off_outlined, size: 18, color: cs.onSurfaceVariant),
                  selected: _activo,
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.onPrimaryContainer,
                  tooltip: _activo ? 'Entra en el sorteo de los exámenes' : 'No sale en exámenes nuevos',
                  onSelected: (v) => setState(() => _activo = v),
                ),
              ],
            ),
            const SizedBox(height: Esp.l),
            if (_cerrada) ..._seccionOpciones(context) else _seccionAbierta(),
          ],
        ),
      ),
      acciones: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        BotonAccion(
          etiqueta: 'Guardar pregunta',
          etiquetaOcupado: 'Guardando…',
          icono: Icons.save_outlined,
          ocupado: _guardando,
          onPressed: _cargandoOpciones ? null : _guardar,
        ),
      ],
    );
  }

  Widget _seccionAbierta() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _TituloSeccion(icono: Icons.lightbulb_outline, texto: 'Lo que se espera', tono: TonoExamen.terciario),
      const SizedBox(height: Esp.m),
      _campoRespuesta(),
    ],
  );

  Widget _campoRespuesta() => TextFormField(
    controller: _respuesta,
    minLines: 3,
    maxLines: 8,
    decoration: const InputDecoration(
      labelText: 'Respuesta modelo',
      helperText: 'La ve el evaluador al revisar. Quien rinde nunca la ve.',
      border: OutlineInputBorder(),
      alignLabelWithHint: true,
    ),
    validator: (v) => !_cerrada && (v ?? '').trim().isEmpty ? 'Escribe la respuesta modelo' : null,
  );

  List<Widget> _seccionOpciones(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_cargandoOpciones) {
      return const [SizedBox(height: 168, child: EsqueletoLista(filas: 3, altoFila: 40))];
    }
    final validas = _opciones.where((o) => o.valida).length;
    return [
      Row(
        children: [
          const Expanded(child: _TituloSeccion(icono: Icons.checklist, texto: 'Opciones')),
          if (validas > 0)
            PastillaExamen(
              texto: '$validas ${validas == 1 ? 'válida' : 'válidas'}',
              tono: TonoExamen.principal,
              icono: Icons.check_circle,
            )
          else
            Text('Toca la letra de las válidas', style: context.apagado()),
        ],
      ),
      const SizedBox(height: Esp.s),
      for (var i = 0; i < _opciones.length; i++)
        Padding(
          key: ObjectKey(_opciones[i]),
          padding: const EdgeInsets.only(bottom: Esp.s),
          child: Row(
            children: [
              _BurbujaValida(
                letra: String.fromCharCode(97 + i % 26),
                valida: _opciones[i].valida,
                onCambio: () => setState(() => _opciones[i].valida = !_opciones[i].valida),
              ),
              const SizedBox(width: Esp.xs),
              Expanded(
                child: TextField(
                  controller: _opciones[i].texto,
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: 'Opción ${String.fromCharCode(97 + i % 26)}',
                    filled: _opciones[i].valida,
                    fillColor: cs.primaryContainer.withValues(alpha: 0.4),
                    enabledBorder:
                        _opciones[i].valida ? OutlineInputBorder(borderSide: BorderSide(color: cs.primary)) : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: _opciones[i].usada ? 'Ya salió en exámenes: no se puede quitar' : 'Quitar opción',
                style: IconButton.styleFrom(foregroundColor: cs.error),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    _opciones[i].usada || _opciones.length <= 2
                        ? null
                        : () {
                          final quitada = _opciones[i];
                          setState(() => _opciones.removeAt(i));
                          // Se libera cuando su TextField ya salió del árbol.
                          WidgetsBinding.instance.addPostFrameCallback((_) => quitada.texto.dispose());
                        },
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: () => setState(() => _opciones.add(_Opcion(cod: BigInt.zero))),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar opción'),
        ),
      ),
      if (_errorOpciones != null) NotaDelDato(texto: _errorOpciones!, tono: TonoNota.error),
    ];
  }
}

/// El título de una sección del formulario, con su icono en el color del tono.
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.icono, required this.texto, this.tono = TonoExamen.principal});

  final IconData icono;
  final String texto;
  final TonoExamen tono;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icono, size: 18, color: coloresDeTono(Theme.of(context).colorScheme, tono).acento),
      const SizedBox(width: Esp.s),
      Flexible(child: Text(texto, style: context.tituloSeccion())),
    ],
  );
}

/// La letra de una opción como burbuja de la hoja: rellena si la opción es
/// válida. Se marca tocándola, igual que con lápiz.
class _BurbujaValida extends StatelessWidget {
  const _BurbujaValida({required this.letra, required this.valida, required this.onCambio});

  final String letra;
  final bool valida;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: valida,
    label: 'Opción $letra válida',
    excludeSemantics: true,
    child: Tooltip(
      message: valida ? 'Válida: toca para desmarcar' : 'Marcar como válida',
      child: InkResponse(
        onTap: onCambio,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: BurbujaHoja(texto: letra, tamanio: 32, marca: valida ? MarcaBurbuja.marcada : MarcaBurbuja.vacia),
          ),
        ),
      ),
    ),
  );
}

/// El aviso bajo el texto: una igual en la categoría (en alerta: no se puede
/// guardar) o hasta cinco parecidas (en terciario: se puede guardar igual),
/// cada una en su ficha con el botón para abrirla.
class AvisoDuplicados extends StatelessWidget {
  const AvisoDuplicados({super.key, required this.duplicados, required this.onAbrir});

  final List<TcpeDuplicadoPreguntaEntity> duplicados;
  final ValueChanged<BigInt> onAbrir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final igual = duplicados.where((d) => d.igual).firstOrNull;
    final parecidas = duplicados.where((d) => !d.igual).take(5).toList();
    final c = coloresDeTono(cs, igual != null ? TonoExamen.alerta : TonoExamen.terciario);
    final fichas = igual != null ? [igual] : parecidas;
    return EntradaSuave(
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          margin: const EdgeInsets.only(top: Esp.s),
          padding: const EdgeInsets.all(Esp.m),
          decoration: BoxDecoration(
            color: Color.alphaBlend(c.fondo.withValues(alpha: 0.55), cs.surface),
            borderRadius: BorderRadius.circular(Esquina.media),
            border: Border.all(color: c.acento.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // El icono en un círculo del acento: se ve antes de leer.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: c.acento, shape: BoxShape.circle),
                    child: Icon(
                      igual != null ? Icons.content_copy_outlined : Icons.manage_search_outlined,
                      size: 20,
                      color: cs.surface,
                    ),
                  ),
                  const SizedBox(width: Esp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Esp.s,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              igual != null ? 'Ya existe una pregunta igual en esta categoría' : 'Hay preguntas parecidas',
                              style: textos.titleSmall?.copyWith(color: c.letra, fontWeight: Peso.titulo),
                            ),
                            if (igual == null)
                              PastillaExamen(texto: '${parecidas.length}', tono: TonoExamen.terciario),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          igual != null
                              ? 'No se guardan dos iguales: ábrela y edítala si hace falta.'
                              : 'Revisa que no repitas una que ya está en el banco. Si es distinta, puedes guardarla.',
                          style: textos.bodySmall?.copyWith(color: c.letra),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Esp.m),
              for (final (i, d) in fichas.indexed) ...[
                if (i > 0) const SizedBox(height: Esp.s),
                _FichaParecida(pregunta: d, acento: c.acento, onAbrir: () => onAbrir(d.codPregunta)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Una pregunta del banco dentro del aviso: su texto, si está inactiva y el botón para abrirla.
class _FichaParecida extends StatelessWidget {
  const _FichaParecida({required this.pregunta, required this.acento, required this.onAbrir});

  final TcpeDuplicadoPreguntaEntity pregunta;
  final Color acento;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.xs, Esp.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: acento.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz_outlined, size: 18, color: acento),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oGuion(pregunta.pregunta),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!pregunta.activo) ...[
                    const SizedBox(height: 2),
                    const PastillaExamen(texto: 'Inactiva', icono: Icons.visibility_off_outlined),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: Esp.xs),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: acento, minimumSize: const Size(48, 48)),
            onPressed: onAbrir,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}

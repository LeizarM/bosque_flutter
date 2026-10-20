/// Formularios de lotes: generar (con destinatarios, ver
/// `destinatarios_lote.dart`), editar y agregar exámenes; el diálogo de
/// credenciales.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_generado_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/destinatarios_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/pdf_examenes.dart';

/// La configuración de exámenes del lado del empleado, o la de respaldo.
TcpeConfiguracion _config(WidgetRef ref) =>
    ref.watch(configExamenesProvider(OrigenRendicion.empleado)).valueOrNull ?? TcpeConfiguracion.respaldo;

/// Ancho del formulario cuando muestra la grilla de personas.
const double _anchoConPersonas = 820;

/// Lo que devuelven generar y agregar: el resultado, lo que se pidió y con qué
/// título y fecha imprimir las credenciales.
class LoteRecienGenerado {
  const LoteRecienGenerado(this.generado, this.titulo, this.fecha, {required this.esOnline, this.pedido});
  final TcpeLoteGeneradoEntity generado;
  final String titulo;
  final DateTime? fecha;

  /// Un escrito no tiene usuarios ni claves: se imprime.
  final bool esOnline;

  /// Externos y empleados pedidos (lote mixto).
  final TcpePedidoExamenesEntity? pedido;
}

/// Después de generar o agregar: las credenciales de los externos en un lote
/// en línea; en un escrito, solo el aviso de que hay que imprimirlos.
Future<void> avisarGenerados(BuildContext context, LoteRecienGenerado r) async {
  if (!r.esOnline) {
    final n = r.pedido?.total ?? 0;
    avisar(
      context,
      n == 0
          ? 'Exámenes escritos generados. Imprímelos con «Examen escrito».'
          : '$n ${n == 1 ? 'examen escrito generado' : 'exámenes escritos generados'}. Imprímelos con «Examen escrito».',
    );
    return;
  }
  await mostrarCredenciales(
    context,
    tituloLote: r.titulo,
    credenciales: r.generado.credenciales,
    fecha: r.fecha,
    empleados: r.pedido?.codEmpleados.length ?? 0,
  );
}

/// Genera un lote nuevo ([lote] null) o edita uno existente. Devuelve un
/// [LoteRecienGenerado] al generar o true al editar.
Future<Object?> abrirFormularioLote(BuildContext context, {TcpeLoteEntity? lote}) =>
    mostrarFormulario<Object>(context, (completa) => FormularioLote(lote: lote, completa: completa));

class FormularioLote extends ConsumerStatefulWidget {
  const FormularioLote({super.key, this.lote, required this.completa});

  final TcpeLoteEntity? lote;
  final bool completa;

  @override
  ConsumerState<FormularioLote> createState() => _FormularioLoteState();
}

class _FormularioLoteState extends ConsumerState<FormularioLote> {
  final _form = GlobalKey<FormState>();
  late final TcpeLoteEntity? _l = widget.lote;
  late final _titulo = TextEditingController(text: _l?.titulo ?? '');
  late final _observaciones = TextEditingController(text: _l?.observaciones ?? '');
  late final _ubicacion = TextEditingController(text: _l?.ubicacion ?? '');
  late final _duracion = TextEditingController(text: _duracionInicial());
  late final _cantidadPreg = TextEditingController(text: _l?.cantidadPreg?.toString() ?? '');
  late final _notaAprobacion = TextEditingController(
    text: nota(_l?.notaAprobacion ?? TcpeConfiguracion.respaldo.notaAprobacionDefecto),
  );
  bool _notaTocada = false;
  late bool _mostrarRespuestas = _l?.mostrarRespuestas ?? true;
  late BigInt? _codArea = _l?.codArea;
  late BigInt? _codClasificacion = _l?.codClasificacion;
  late String _modalidad = _l?.modalidad ?? 'O';
  late bool _enHoras = (_l?.duracionMinutos ?? 0) >= 60 && (_l!.duracionMinutos! % 60 == 0);
  late DateTime? _fecha = _l?.fecha ?? DateTime.now();
  late TimeOfDay? _inicio = _hora(_l?.horaInicio);
  late TimeOfDay? _fin = _hora(_l?.horaFin);
  final _destinatarios = ControladorDestinatarios();
  bool _conPersonas = false;
  int? _disponibles;
  bool _consultando = false;
  bool _guardando = false;

  bool get _editando => widget.lote != null;
  bool get _fijo => widget.lote?.algunoIniciado ?? false;

  /// La cantidad define el largo de cada examen: fija en cuanto hay exámenes.
  bool get _cantidadFija => (widget.lote?.examenes ?? 0) > 0;

  String _duracionInicial() {
    final m = widget.lote?.duracionMinutos;
    if (m == null) return '60';
    return (m >= 60 && m % 60 == 0) ? '${m ~/ 60}' : '$m';
  }

  static TimeOfDay? _hora(String? h) {
    if (h == null) return null;
    final p = h.split(':');
    if (p.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  static String? _horaJson(TimeOfDay? t) =>
      t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  /// Solo el ancho depende de los destinatarios; el selector se redibuja solo.
  void _alCambiarDestinatarios() {
    if (_destinatarios.conPersonas != _conPersonas) setState(() => _conPersonas = _destinatarios.conPersonas);
  }

  @override
  void initState() {
    super.initState();
    _destinatarios.addListener(_alCambiarDestinatarios);
    if (_codClasificacion != null && !_editando) _consultarDisponibles();
    // La nota por defecto de un lote nuevo sale de la configuración.
    if (!_editando) {
      ref.read(configExamenesProvider(OrigenRendicion.empleado).future).then((c) {
        if (mounted && !_notaTocada) _notaAprobacion.text = nota(c.notaAprobacionDefecto);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_titulo, _observaciones, _ubicacion, _duracion, _cantidadPreg, _notaAprobacion]) {
      c.dispose();
    }
    _destinatarios
      ..removeListener(_alCambiarDestinatarios)
      ..dispose();
    super.dispose();
  }

  Future<void> _consultarDisponibles() async {
    final cod = _codClasificacion;
    if (cod == null) return;
    setState(() {
      _consultando = true;
      _disponibles = null;
    });
    try {
      final n = await ref.read(examenesRepositoryProvider).preguntasDisponibles(cod);
      if (!mounted || cod != _codClasificacion) return;
      setState(() {
        _disponibles = n;
        _consultando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consultando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  int? get _duracionMinutos {
    final n = int.tryParse(_duracion.text.trim());
    if (n == null) return null;
    return _enHoras ? n * 60 : n;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (!_editando) {
      final error = _destinatarios.validar();
      if (error != null) {
        avisar(context, error, esError: true);
        return;
      }
    }
    final pedido = _destinatarios.pedido;
    final base = widget.lote ?? TcpeLoteEntity(codRolExamen: BigInt.zero);
    final lote = base.copyWith(
      codArea: _codArea,
      codClasificacion: _codClasificacion,
      titulo: _titulo.text.trim(),
      observaciones: _observaciones.text.trim(),
      modalidad: _modalidad,
      duracionMinutos: _duracionMinutos,
      cantidadPreg: int.tryParse(_cantidadPreg.text.trim()),
      fecha: _fecha,
      horaInicio: _horaJson(_inicio),
      horaFin: _horaJson(_fin),
      ubicacion: _ubicacion.text.trim(),
      notaAprobacion: double.tryParse(_notaAprobacion.text.trim().replaceAll(',', '.')),
      mostrarRespuestas: _mostrarRespuestas,
    );
    setState(() => _guardando = true);
    final repo = ref.read(examenesRepositoryProvider);
    try {
      if (_editando) {
        await repo.actualizarLote(lote);
        if (!mounted) return;
        avisar(context, 'Lote actualizado.');
        Navigator.pop(context, true);
        return;
      }
      final r = await repo.generarLote(lote, pedido);
      guardarCredencialesSesion(ref, r);
      if (!mounted) return;
      Navigator.pop(
        context,
        LoteRecienGenerado(r, lote.titulo ?? '', lote.fecha, esOnline: _modalidad != 'E', pedido: pedido),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(tcpeAreasProvider).valueOrNull ?? const [];
    final categorias = [
      for (final c in ref.watch(tcpeCategoriasProvider).valueOrNull ?? const [])
        if ((c.activo || c.codClasificacion == _codClasificacion) && (_codArea == null || c.codArea == _codArea)) c,
    ];
    const borde = OutlineInputBorder();
    final cfg = _config(ref);
    _destinatarios.personas.maximo = cfg.maxExamenesPorLote;

    return MarcoFormulario(
      titulo: _editando ? 'Editar lote' : 'Generar lote de exámenes',
      icono: _editando ? Icons.edit_note : Icons.inventory_2_outlined,
      completa: widget.completa,
      ancho: !_editando && _conPersonas ? _anchoConPersonas : 640,
      cuerpo: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fijo || _cantidadFija)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.m),
                child: NotaDelDato(
                  texto:
                      _fijo
                          ? 'Ya hay exámenes empezados: la duración y la cantidad de preguntas no cambian.'
                          : 'El lote ya tiene exámenes: la cantidad de preguntas no cambia.',
                  tono: TonoNota.aviso,
                ),
              ),
            if (!_editando) ...[
              _Fila(children: [
                DropdownButtonFormField<BigInt?>(
                  value: areas.any((a) => a.codArea == _codArea) ? _codArea : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Área', border: borde),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final a in areas)
                      DropdownMenuItem(value: a.codArea, child: Text(a.nombreArea ?? '', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() {
                    _codArea = v;
                    _codClasificacion = null;
                    _disponibles = null;
                  }),
                ),
                DropdownButtonFormField<BigInt>(
                  value: categorias.any((c) => c.codClasificacion == _codClasificacion) ? _codClasificacion : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría', border: borde),
                  items: [
                    for (final c in categorias)
                      DropdownMenuItem(value: c.codClasificacion, child: Text(c.nombre ?? '', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _codClasificacion = v;
                      final cat = categorias.where((c) => c.codClasificacion == v).firstOrNull;
                      _codArea ??= cat?.codArea;
                      if (cat?.modalidad == 'E' || cat?.modalidad == 'O') _modalidad = cat!.modalidad!;
                    });
                    _consultarDisponibles();
                  },
                  validator: (v) => v == null ? 'Elige la categoría' : null,
                ),
              ]),
              const SizedBox(height: Esp.xs),
              _disponiblesTexto(context),
              const SizedBox(height: Esp.m),
            ] else ...[
              Text(
                '${widget.lote!.nombreClasificacion ?? ''} · ${widget.lote!.nombreArea ?? ''}',
                style: context.apagado(),
              ),
              const SizedBox(height: Esp.m),
            ],
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título', border: borde),
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe el título del lote' : null,
            ),
            const SizedBox(height: Esp.m),
            TextFormField(
              controller: _observaciones,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: borde),
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
            ),
            const SizedBox(height: Esp.m),
            if (!_editando) ...[
              Text('Modalidad', style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'O', label: Text('En línea'), icon: Icon(Icons.computer)),
                  ButtonSegment(value: 'E', label: Text('Escrito'), icon: Icon(Icons.description_outlined)),
                ],
                selected: {_modalidad},
                onSelectionChanged: (s) => setState(() => _modalidad = s.first),
              ),
              const SizedBox(height: Esp.m),
            ],
            _Fila(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duracion,
                      enabled: !_fijo,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      decoration: const InputDecoration(labelText: 'Duración', border: borde),
                      validator: (_) {
                        final m = _duracionMinutos;
                        if (m == null || m < 1) return 'Indica la duración';
                        if (m > cfg.duracionMaxMinutos) return 'Máximo ${duracionTexto(cfg.duracionMaxMinutos)}';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: Esp.s),
                  Padding(
                    padding: const EdgeInsets.only(top: Esp.xs),
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('min')),
                        ButtonSegment(value: true, label: Text('horas')),
                      ],
                      selected: {_enHoras},
                      onSelectionChanged: _fijo ? null : (s) => setState(() => _enHoras = s.first),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _cantidadPreg,
                enabled: !_cantidadFija,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                decoration: InputDecoration(
                  labelText: 'Preguntas por examen',
                  border: borde,
                  helperText: _disponibles == null ? null : 'Máximo $_disponibles',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1) return 'Indica cuántas preguntas';
                  if (_disponibles != null && n > _disponibles!) return 'Solo hay $_disponibles disponibles';
                  return null;
                },
              ),
            ]),
            const SizedBox(height: Esp.l),
            Text('Ventana para rendir', style: context.tituloSeccion()),
            const SizedBox(height: Esp.xs),
            Text(
              _modalidad == 'E'
                  ? 'Cuándo y a qué hora se rinde en papel.'
                  : 'Desde la hora de inicio se puede empezar; pasada la de fin, quien no empezó queda ausente.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.s),
            _Fila(children: [
              _CampoSelector(
                etiqueta: 'Fecha',
                valor: _fecha == null ? '' : fechaCorta(_fecha),
                icono: Icons.event_outlined,
                onTap: () async {
                  final f = await showDatePicker(
                    context: context,
                    initialDate: _fecha ?? DateTime.now(),
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (f != null) setState(() => _fecha = f);
                },
              ),
              _CampoSelector(
                etiqueta: 'Hora de inicio',
                valor: _inicio?.format(context) ?? '',
                icono: Icons.schedule,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _inicio ?? const TimeOfDay(hour: 8, minute: 0));
                  if (t != null) setState(() => _inicio = t);
                },
                onLimpiar: () => setState(() => _inicio = null),
              ),
              _CampoSelector(
                etiqueta: 'Hora de fin',
                valor: _fin?.format(context) ?? '',
                icono: Icons.schedule,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _fin ?? const TimeOfDay(hour: 12, minute: 0));
                  if (t != null) setState(() => _fin = t);
                },
                onLimpiar: () => setState(() => _fin = null),
              ),
            ]),
            if (_modalidad == 'O' && _fin == null)
              const NotaDelDato(
                texto: 'Recomendado: indica la hora de fin. Sin ella, el examen se puede empezar en cualquier momento.',
                tono: TonoNota.aviso,
              ),
            const SizedBox(height: Esp.m),
            TextFormField(
              controller: _ubicacion,
              decoration: const InputDecoration(labelText: 'Lugar (opcional)', border: borde),
              inputFormatters: [LengthLimitingTextInputFormatter(150)],
            ),
            const SizedBox(height: Esp.l),
            Text('Calificación', style: context.tituloSeccion()),
            const SizedBox(height: Esp.s),
            _Fila(children: [
              TextFormField(
                controller: _notaAprobacion,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(6)],
                decoration: const InputDecoration(
                  labelText: 'Nota mínima de aprobación',
                  suffixText: '/ 100',
                  helperText: 'Aprueba quien saca esta nota o más.',
                  border: borde,
                ),
                onChanged: (_) => _notaTocada = true,
                // Solo el formato: el rango lo valida p_abm_tcpe_Lote (V, I y U) con su mensaje.
                validator: (v) =>
                    double.tryParse((v ?? '').trim().replaceAll(',', '.')) == null ? 'Indica la nota mínima' : null,
              ),
              CheckboxListTile(
                value: _mostrarRespuestas,
                onChanged: (v) => setState(() => _mostrarRespuestas = v ?? true),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Mostrar las respuestas correctas al terminar'),
                subtitle: Text(
                  _mostrarRespuestas
                      ? 'Al terminar, cada uno ve cuáles eran las correctas.'
                      : 'Al terminar, cada uno solo ve si acertó o falló.',
                ),
              ),
            ]),
            if (!_editando) ...[
              const SizedBox(height: Esp.l),
              Text('¿Quiénes rinden?', style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              Text('Activa uno o los dos: externos y empleados pueden rendir en el mismo lote.', style: context.apagado()),
              const SizedBox(height: Esp.s),
              SelectorDestinatarios(
                controlador: _destinatarios,
                escrito: _modalidad == 'E',
                maximo: cfg.maxExamenesPorLote,
              ),
            ],
          ],
        ),
      ),
      acciones: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        BotonAccion(
          etiqueta: _editando ? 'Guardar cambios' : 'Generar exámenes',
          etiquetaOcupado: _editando ? 'Guardando…' : 'Generando…',
          icono: _editando ? Icons.save_outlined : Icons.auto_awesome_motion_outlined,
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }

  Widget _disponiblesTexto(BuildContext context) {
    if (_codClasificacion == null) {
      return Text('Elige la categoría para ver cuántas preguntas hay para sortear.', style: context.apagado());
    }
    if (_consultando) return Text('Contando preguntas disponibles…', style: context.apagado());
    if (_disponibles == null) return const SizedBox.shrink();
    if (_disponibles == 0) {
      return const NotaDelDato(
        texto: 'Esta categoría no tiene preguntas activas con respuesta: no se pueden generar exámenes.',
        tono: TonoNota.error,
      );
    }
    return Text('$_disponibles preguntas disponibles para sortear.', style: context.apagado());
  }
}

/// Varios campos en fila en escritorio, uno debajo del otro en el teléfono.
class _Fila extends StatelessWidget {
  const _Fila({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, r) {
      if (r.maxWidth < 480) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: Esp.m),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Esp.m),
            Expanded(child: children[i]),
          ],
        ],
      );
    },
  );
}

class _CampoSelector extends StatelessWidget {
  const _CampoSelector({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.onTap,
    this.onLimpiar,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final VoidCallback onTap;

  /// Deja el campo vacío (las horas de la ventana son opcionales).
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
        suffixIcon:
            onLimpiar != null && valor.isNotEmpty
                ? IconButton(tooltip: 'Quitar', icon: const Icon(Icons.close, size: 18), onPressed: onLimpiar)
                : Icon(icono, size: 20),
      ),
      child: Text(valor.isEmpty ? '--' : valor, maxLines: 1),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AGREGAR EXÁMENES Y CREDENCIALES
// ═══════════════════════════════════════════════════════════════════════════

/// Guarda las credenciales recién generadas para reimprimirlas en la sesión.
void guardarCredencialesSesion(WidgetRef ref, TcpeLoteGeneradoEntity r) {
  final conClave = r.credenciales.where((c) => c.tieneClave).toList();
  if (conClave.isEmpty) return;
  final actual = ref.read(tcpeCredencialesSesionProvider);
  final previas = actual[r.codRolExamen] ?? const <TcpeCredencialEntity>[];
  final porLogin = {for (final c in [...previas, ...conClave]) c.login: c};
  ref.read(tcpeCredencialesSesionProvider.notifier).state = {
    ...actual,
    r.codRolExamen: porLogin.values.toList(),
  };
}

/// Agrega exámenes a [lote]: externos, empleados o ambos en el mismo paso.
Future<LoteRecienGenerado?> agregarExamenes(BuildContext context, TcpeLoteEntity lote) =>
    mostrarFormulario<LoteRecienGenerado>(context, (completa) => _AgregarExamenes(lote: lote, completa: completa));

class _AgregarExamenes extends ConsumerStatefulWidget {
  const _AgregarExamenes({required this.lote, required this.completa});

  final TcpeLoteEntity lote;
  final bool completa;

  @override
  ConsumerState<_AgregarExamenes> createState() => _AgregarExamenesState();
}

class _AgregarExamenesState extends ConsumerState<_AgregarExamenes> {
  final _form = GlobalKey<FormState>();
  final _destinatarios = ControladorDestinatarios();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Solo el ancho depende de los destinatarios: se ensancha con la grilla de personas.
    _destinatarios.addListener(_alCambiar);
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _destinatarios
      ..removeListener(_alCambiar)
      ..dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final error = _destinatarios.validar();
    if (error != null) {
      avisar(context, error, esError: true);
      return;
    }
    final pedido = _destinatarios.pedido;
    final l = widget.lote;
    setState(() => _guardando = true);
    try {
      final r = await ref.read(examenesRepositoryProvider).agregarExamenes(l.codRolExamen, pedido);
      guardarCredencialesSesion(ref, r);
      if (!mounted) return;
      Navigator.pop(context, LoteRecienGenerado(r, l.titulo ?? '', l.fecha, esOnline: l.esOnline, pedido: pedido));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config(ref);
    _destinatarios.personas.maximo = cfg.maxExamenesPorLote;
    return MarcoFormulario(
      titulo: 'Agregar exámenes',
      icono: Icons.group_add_outlined,
      completa: widget.completa,
      ancho: _destinatarios.conPersonas ? _anchoConPersonas : 640,
      cuerpo: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Al lote «${widget.lote.titulo ?? ''}». Cada examen nuevo sortea sus propias '
              '${widget.lote.cantidadPreg ?? ''} preguntas.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            SelectorDestinatarios(
              controlador: _destinatarios,
              escrito: !widget.lote.esOnline,
              maximo: cfg.maxExamenesPorLote,
              yaTiene: widget.lote.examenes,
              codRolExamen: widget.lote.codRolExamen,
            ),
          ],
        ),
      ),
      acciones: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        BotonAccion(
          etiqueta: 'Agregar',
          etiquetaOcupado: 'Generando…',
          icono: Icons.add,
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

/// Muestra las credenciales (la clave se ve solo aquí) con la opción de
/// imprimirlas para recortar.
Future<void> mostrarCredenciales(
  BuildContext context, {
  required String tituloLote,
  required List<TcpeCredencialEntity> credenciales,
  DateTime? fecha,
  String titulo = 'Credenciales generadas',
  int empleados = 0,
}) {
  final conClave = credenciales.where((c) => c.tieneClave).toList();
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (conClave.isEmpty)
                const NotaDelDato(
                  texto: 'Los empleados entran con su usuario de Bosque, en «Mis exámenes»: no reciben clave.',
                )
              else ...[
                const NotaDelDato(
                  texto:
                      'Las claves temporales se ven solo ahora: imprímelas o cópialas antes de cerrar. '
                      'Cada una deja de funcionar cuando la persona entrega su examen.',
                  tono: TonoNota.aviso,
                ),
                const SizedBox(height: Esp.m),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListaCredenciales(credenciales: conClave),
                ),
                // Lote mixto: los empleados no aparecen en la lista porque no reciben clave.
                if (empleados > 0) ...[
                  const SizedBox(height: Esp.m),
                  NotaDelDato(
                    texto:
                        empleados == 1
                            ? 'El empleado del lote entra con su usuario de Bosque, en «Mis exámenes»: no recibe clave.'
                            : 'Los $empleados empleados del lote entran con su usuario de Bosque, en «Mis exámenes»: no reciben clave.',
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          if (conClave.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: [
                      'Usuario\tNombre\tCI\tClave',
                      for (final c in conClave)
                        '${c.login ?? ''}\t${c.nombreCompleto ?? ''}\t${c.ci ?? ''}\t${c.password}',
                    ].join('\n'),
                  ),
                );
                if (ctx.mounted) avisar(ctx, 'Credenciales copiadas.');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
          if (conClave.isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                try {
                  final bytes = await pdfCredenciales(tituloLote: tituloLote, credenciales: conClave, fecha: fecha);
                  if (!ctx.mounted) return;
                  await mostrarPdf(ctx, bytes: bytes, titulo: 'Credenciales', nombreArchivo: 'credenciales_examen.pdf');
                } catch (e) {
                  if (ctx.mounted) avisar(ctx, textoParaUsuario(e), esError: true);
                }
              },
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Imprimir'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      );
    },
  );
}

/// Login, nombre, CI y clave temporal de cada credencial: tabla en escritorio
/// y tarjetas en el teléfono.
class ListaCredenciales extends StatelessWidget {
  const ListaCredenciales({super.key, required this.credenciales});

  final List<TcpeCredencialEntity> credenciales;

  static const _fija = TextStyle(fontFamily: fuenteFija, fontSize: 15);
  static const _clave = TextStyle(fontFamily: fuenteFija, fontSize: 15, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, r) {
        final tabla = r.maxWidth >= 520;
        final lista = ListView.separated(
          shrinkWrap: true,
          itemCount: credenciales.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (context, i) => tabla ? _fila(context, credenciales[i]) : _tarjeta(context, credenciales[i]),
        );
        if (!tabla) return lista;
        final estilo = context.apagado()?.copyWith(fontWeight: Peso.titulo);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.xs),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Usuario', style: estilo)),
                  Expanded(flex: 4, child: Text('Nombre', style: estilo)),
                  Expanded(flex: 2, child: Text('CI', style: estilo)),
                  Expanded(flex: 3, child: Text('Clave', style: estilo)),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            Flexible(child: lista),
          ],
        );
      },
    );
  }

  Widget _fila(BuildContext context, TcpeCredencialEntity c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: SelectableText(c.login ?? '--', style: _fija)),
        Expanded(flex: 4, child: Text(c.nombreCompleto ?? '--', maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: SelectableText(c.ci ?? '--')),
        Expanded(
          flex: 3,
          child: SelectableText(c.password ?? '', style: _clave),
        ),
      ],
    ),
  );

  Widget _tarjeta(BuildContext context, TcpeCredencialEntity c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SelectableText(c.login ?? '--', style: _clave)),
          ],
        ),
        if ((c.nombreCompleto ?? '').isNotEmpty) Text(c.nombreCompleto!),
        Text('CI ${c.ci ?? '--'}', style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Row(
          children: [
            Text('Clave  ', style: context.apagado()),
            Flexible(child: SelectableText(c.password ?? '', style: _fija)),
          ],
        ),
      ],
    ),
  );
}

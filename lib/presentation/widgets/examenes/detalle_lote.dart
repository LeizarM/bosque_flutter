/// El detalle de un lote: sus datos, el avance, los exámenes con su estado y
/// las salidas en papel (credenciales; examen escrito y solucionario en PDF
/// del backend). En los escritos, la nota de cada examen se carga en la fila.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/dialogos_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

class DetalleLote extends ConsumerStatefulWidget {
  const DetalleLote({
    super.key,
    required this.lote,
    required this.onVolver,
    required this.onCambio,
    this.onCalificar,
    this.onEnVivo,
  });

  final TcpeLoteEntity lote;
  final VoidCallback onVolver;

  /// El lote cambió (editado, exámenes agregados o eliminado): refrescar la lista.
  final VoidCallback onCambio;

  /// Ir a Resultados con este lote.
  final VoidCallback? onCalificar;

  /// Ir a "En vivo" con este lote (solo en línea).
  final VoidCallback? onEnVivo;

  @override
  ConsumerState<DetalleLote> createState() => _DetalleLoteState();
}

class _DetalleLoteState extends ConsumerState<DetalleLote> {
  String? _generando;

  TcpeLoteEntity get _l => widget.lote;

  @override
  Widget build(BuildContext context) {
    final examenes = ref.watch(tcpeResultadosProvider(_l.codRolExamen));
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        return Padding(
          padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, compacto ? 0 : Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(tooltip: 'Volver a los lotes', icon: const Icon(Icons.arrow_back), onPressed: widget.onVolver),
                  const SizedBox(width: Esp.xs),
                  if (!compacto) ...[
                    SelloExamen(
                      icono: _l.esOnline ? Icons.wifi : Icons.description_outlined,
                      tono: _tonoModalidad,
                      tamanio: 52,
                    ),
                    const SizedBox(width: Esp.l),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOTE N° ${_l.codRolExamen} · ${modalidadTexto(_l.modalidad).toUpperCase()}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontFamily: fuenteFija,
                            letterSpacing: 1.4,
                            fontWeight: Peso.titulo,
                            color: coloresDeTono(Theme.of(context).colorScheme, _tonoModalidad).acento,
                          ),
                        ),
                        const SizedBox(height: Esp.xs),
                        Semantics(
                          header: true,
                          child: Text(
                            _l.titulo ?? 'Lote',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
                          ),
                        ),
                        const SizedBox(height: Esp.s),
                        Wrap(
                          spacing: Esp.s,
                          runSpacing: Esp.xs,
                          children: [
                            if ((_l.nombreClasificacion ?? '').isNotEmpty)
                              PastillaExamen(texto: _l.nombreClasificacion!, icono: Icons.label_outline),
                            PastillaExamen(
                              texto: duracionTexto(_l.duracionMinutos),
                              tono: TonoExamen.secundario,
                              icono: Icons.timer_outlined,
                            ),
                            PastillaExamen(
                              texto: '${_l.cantidadPreg ?? 0} preguntas',
                              tono: TonoExamen.secundario,
                              icono: Icons.quiz_outlined,
                            ),
                            PastillaExamen(
                              texto: 'Ventana ${ventanaTexto(_l)}',
                              tono: TonoExamen.terciario,
                              icono: Icons.event_outlined,
                            ),
                            if ((_l.ubicacion ?? '').isNotEmpty)
                              PastillaExamen(texto: _l.ubicacion!, icono: Icons.place_outlined),
                            if (_l.esOnline && _l.mostrarRespuestas != null)
                              _l.mostrarRespuestas!
                                  ? const PastillaExamen(
                                    texto: 'Muestra las correctas al terminar',
                                    tono: TonoExamen.principal,
                                    icono: Icons.visibility_outlined,
                                  )
                                  : const PastillaExamen(
                                    texto: 'No muestra las correctas',
                                    icono: Icons.visibility_off_outlined,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // En el teléfono el menú del lote va arriba, como en una barra de aplicación.
                  if (compacto) _menuCompacto(context, examenes.valueOrNull),
                ],
              ),
              const SizedBox(height: Esp.m),
              Wrap(spacing: Esp.s, runSpacing: Esp.s, children: _acciones(context, compacto, examenes.valueOrNull)),
              const SizedBox(height: Esp.l),
              _Panel(lote: _l, compacto: compacto),
              const SizedBox(height: Esp.l),
              Expanded(
                child: examenes.when(
                  skipLoadingOnReload: true,
                  loading: () => const EsqueletoLista(),
                  error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(tcpeResultadosProvider)),
                  data: (lista) => _tabla(lista),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TonoExamen get _tonoModalidad => _l.esOnline ? TonoExamen.principal : TonoExamen.terciario;

  /// Un botón tonal en el color de su grupo de acciones.
  Widget _botonTonal(TonoExamen tono, {required VoidCallback? onPressed, required Widget icon, required String texto}) {
    final c = coloresDeTono(Theme.of(context).colorScheme, tono);
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(backgroundColor: c.fondo, foregroundColor: c.letra),
      onPressed: onPressed,
      icon: icon,
      label: Text(texto),
    );
  }

  List<Widget> _acciones(BuildContext context, bool compacto, List<TcpeResultadoExamenEntity>? examenes) {
    final ocupado = _generando != null;
    if (compacto) return _accionesCompactas(context);
    final cs = Theme.of(context).colorScheme;
    return [
      FilledButton.icon(
        onPressed: () => _agregar(context),
        icon: const Icon(Icons.group_add_outlined, size: 18),
        label: const Text('Agregar exámenes'),
      ),
      // Los papeles del lote, en secundario. Los escritos no tienen credenciales.
      if (_l.esOnline)
        _botonTonal(
          TonoExamen.secundario,
          onPressed: examenes == null ? null : () => _credenciales(context, examenes),
          icon: const Icon(Icons.key_outlined, size: 18),
          texto: 'Credenciales',
        ),
      _botonTonal(
        TonoExamen.secundario,
        onPressed: ocupado ? null : () => _pdf(context, conSolucion: false),
        icon: _iconoPdf('examen', Icons.description_outlined),
        texto: 'Examen escrito',
      ),
      _botonTonal(
        TonoExamen.secundario,
        onPressed: ocupado ? null : () => _pdf(context, conSolucion: true),
        icon: _iconoPdf('solucion', Icons.fact_check_outlined),
        texto: 'Solucionario',
      ),
      // El seguimiento, en terciario.
      if (_l.esOnline && widget.onEnVivo != null)
        _botonTonal(
          TonoExamen.terciario,
          onPressed: widget.onEnVivo,
          icon: const Icon(Icons.sensors_outlined, size: 18),
          texto: 'En vivo',
        ),
      if (widget.onCalificar != null)
        _botonTonal(
          TonoExamen.terciario,
          onPressed: widget.onCalificar,
          icon: const Icon(Icons.grading_outlined, size: 18),
          texto: 'Calificar',
        ),
      PopupMenuButton<int>(
        tooltip: 'Más acciones del lote',
        icon: const Icon(Icons.more_horiz),
        onSelected: (i) => i == 0 ? _editar(context) : _eliminar(context),
        itemBuilder:
            (ctx) => [
              PopupMenuItem(
                value: 0,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined, color: cs.primary),
                  title: const Text('Editar lote'),
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
                  title: Text('Eliminar lote', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              ),
            ],
      ),
    ];
  }

  /// En el teléfono: lo de todos los días a la vista; el resto, en [_menuCompacto].
  List<Widget> _accionesCompactas(BuildContext context) => [
    FilledButton.icon(
      onPressed: () => _agregar(context),
      icon: const Icon(Icons.group_add_outlined, size: 18),
      label: const Text('Agregar exámenes'),
    ),
    if (widget.onCalificar != null)
      _botonTonal(
        TonoExamen.terciario,
        onPressed: widget.onCalificar,
        icon: const Icon(Icons.grading_outlined, size: 18),
        texto: 'Calificar',
      ),
  ];

  Widget _menuCompacto(BuildContext context, List<TcpeResultadoExamenEntity>? examenes) {
    final ocupado = _generando != null;
    final menu = <(String, IconData, VoidCallback?, TonoExamen)>[
      if (_l.esOnline)
        (
          'Credenciales',
          Icons.key_outlined,
          examenes == null ? null : () => _credenciales(context, examenes),
          TonoExamen.secundario,
        ),
      ('Examen escrito', Icons.description_outlined, ocupado ? null : () => _pdf(context, conSolucion: false), TonoExamen.secundario),
      ('Solucionario', Icons.fact_check_outlined, ocupado ? null : () => _pdf(context, conSolucion: true), TonoExamen.secundario),
      if (_l.esOnline && widget.onEnVivo != null) ('En vivo', Icons.sensors_outlined, widget.onEnVivo, TonoExamen.terciario),
      ('Editar lote', Icons.edit_outlined, () => _editar(context), TonoExamen.principal),
      ('Eliminar lote', Icons.delete_outline, () => _eliminar(context), TonoExamen.alerta),
    ];
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
        tooltip: 'Más acciones del lote',
        icon: _generando == null ? const Icon(Icons.more_vert) : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        onSelected: (i) => menu[i].$3?.call(),
        itemBuilder:
            (_) => [
              for (final (i, (t, ic, f, tono)) in menu.indexed)
                PopupMenuItem(
                  value: i,
                  enabled: f != null,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(ic, color: coloresDeTono(cs, tono).acento),
                    title: Text(t, style: tono == TonoExamen.alerta ? TextStyle(color: cs.error) : null),
                  ),
                ),
            ],
    );
  }

  Widget _iconoPdf(String clave, IconData icono) =>
      _generando == clave
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icono, size: 18);

  Widget _tabla(List<TcpeResultadoExamenEntity> lista) => TablaExamenes<TcpeResultadoExamenEntity>(
    filas: lista,
    claveFila: (e) => e.codExamen,
    tonoFila: (e) => aspectoDeEstado(EstadoExamenTcpe.desde(e.estado)).$1,
    vacio: VacioExamenes(
      icono: Icons.inbox_outlined,
      titulo: 'Este lote no tiene exámenes',
      detalle: 'Cada persona recibe un examen distinto, sorteado del banco de la categoría.',
      accion: 'Agregar exámenes',
      iconoAccion: Icons.add,
      onAccion: () => _agregar(context),
    ),
    columnas: [
      ColumnaExamen(
        _l.esOnline ? 'Usuario' : 'Examen',
        (e) => Text(e.login ?? 'N° ${e.codExamen}', style: const TextStyle(fontFamily: fuenteFija)),
        flex: 2,
      ),
      ColumnaExamen('Nombre', (e) => CeldaTexto(e.nombreCompleto), flex: 4),
      ColumnaExamen('CI', (e) => CeldaTexto(e.ci), flex: 2),
      ColumnaExamen('Estado', (e) => EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)), flex: 2),
      if (_l.esOnline) ColumnaExamen('Inicio', (e) => CeldaTexto(fechaHora(e.fechaInicio), apagado: true), flex: 3),
      if (_l.esOnline)
        ColumnaExamen('Avance', (e) => CeldaNumero('${e.respondidas}/${e.totalPreguntas}'), flex: 2, alinear: Alignment.centerRight),
      if (_l.esOnline)
        ColumnaExamen(
          'Nota',
          (e) => CeldaNota(e.resultado, minima: e.notaAprobacion ?? _l.notaAprobacion),
          flex: 1,
          alinear: Alignment.centerRight,
        )
      else
        ColumnaExamen('Nota', (e) => _NotaEnLinea(examen: e, onGuardada: _alGuardarNota), flex: 3),
      ColumnaExamen('Resultado', (e) => EtiquetaAprobacion(e.aprobacion, enCelda: true), flex: 2),
    ],
    acciones: [
      AccionExamen(
        'Imprimir este examen',
        Icons.print_outlined,
        (e) => _pdf(context, conSolucion: false, codExamen: e.codExamen),
        tono: TonoExamen.secundario,
      ),
      AccionExamen(
        'Solucionario de este examen',
        Icons.fact_check_outlined,
        (e) => _pdf(context, conSolucion: true, codExamen: e.codExamen),
        tono: TonoExamen.terciario,
      ),
    ],
    accionesEnLinea: 2,
    tarjeta:
        (e) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.nombreCompleto?.trim().isNotEmpty == true ? e.nombreCompleto! : (e.login ?? 'Examen N° ${e.codExamen}'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)),
              ],
            ),
            const SizedBox(height: Esp.xs),
            Text(
              _l.esOnline
                  ? '${e.login ?? ''} · ${e.respondidas}/${e.totalPreguntas} respondidas · Nota ${nota(e.resultado)}'
                  : [if ((e.ci ?? '').isNotEmpty) 'CI ${e.ci}', 'Escrito'].join(' · '),
              style: context.apagado(),
            ),
            if (e.aprobacion != null) ...[const SizedBox(height: Esp.xs), EtiquetaAprobacion(e.aprobacion)],
            if (!_l.esOnline) ...[
              const SizedBox(height: Esp.s),
              _NotaEnLinea(examen: e, onGuardada: _alGuardarNota),
            ],
          ],
        ),
  );

  void _alGuardarNota() {
    ref.invalidate(tcpeResultadosProvider(_l.codRolExamen));
    widget.onCambio();
  }

  Future<void> _agregar(BuildContext context) async {
    final r = await agregarExamenes(context, _l);
    if (r == null || !context.mounted) return;
    ref.invalidate(tcpeResultadosProvider(_l.codRolExamen));
    widget.onCambio();
    await avisarGenerados(context, r);
  }

  Future<void> _editar(BuildContext context) async {
    final r = await abrirFormularioLote(context, lote: _l);
    if (r != null) widget.onCambio();
  }

  Future<void> _eliminar(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar lote',
      detalle:
          'Se borran el lote, sus ${_l.examenes} exámenes y los usuarios externos creados para él. '
          'Si algún examen ya empezó, no se puede.',
      textoConfirmar: 'Eliminar lote',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(examenesRepositoryProvider).eliminarLote(_l.codRolExamen);
      if (!context.mounted) return;
      avisar(context, 'Lote eliminado.');
      widget.onCambio();
      widget.onVolver();
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  /// Las de esta sesión si las hay; si no, ofrece regenerar las claves de los
  /// externos del lote (las anteriores dejan de servir).
  Future<void> _credenciales(BuildContext context, List<TcpeResultadoExamenEntity> examenes) async {
    final sesion = ref.read(tcpeCredencialesSesionProvider)[_l.codRolExamen];
    if (sesion != null && sesion.isNotEmpty) {
      await mostrarCredenciales(context, tituloLote: _l.titulo ?? '', credenciales: sesion, fecha: _l.fecha, titulo: 'Credenciales del lote');
      return;
    }
    final externos = [
      for (final e in examenes)
        if (!e.esEmpleado && e.codUsuario != null && !EstadoExamenTcpe.desde(e.estado).cerrado) e,
    ];
    if (externos.isEmpty) {
      avisar(context, 'No hay postulantes externos con exámenes pendientes en este lote.');
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Regenerar claves',
      detalle:
          'Las claves solo se ven al generarlas. Para imprimirlas de nuevo se crean claves nuevas '
          'para los ${externos.length} postulantes con examen pendiente; las anteriores dejan de servir.',
      textoConfirmar: 'Regenerar e imprimir',
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(examenesRepositoryProvider);
    final nuevas = <TcpeCredencialEntity>[];
    final progreso = ValueNotifier<int>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: ValueListenableBuilder<int>(
              valueListenable: progreso,
              builder:
                  (_, n, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(value: externos.isEmpty ? null : n / externos.length),
                      const SizedBox(height: Esp.m),
                      Text('Regenerando claves: $n de ${externos.length}'),
                    ],
                  ),
            ),
          ),
    );
    Object? fallo;
    for (final e in externos) {
      try {
        final c = await repo.regenerarClave(e.codUsuario!);
        nuevas.add(
          c.copyWith(
            codExamen: e.codExamen,
            login: c.login ?? e.login,
            ci: c.ci ?? e.ci,
            nombreCompleto: c.nombreCompleto ?? e.nombreCompleto,
          ),
        );
      } catch (err) {
        fallo = err;
        break;
      }
      progreso.value = nuevas.length;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    progreso.dispose();
    if (nuevas.isNotEmpty) {
      ref.read(tcpeCredencialesSesionProvider.notifier).state = {
        ...ref.read(tcpeCredencialesSesionProvider),
        _l.codRolExamen: nuevas,
      };
    }
    if (fallo != null) avisar(context, textoParaUsuario(fallo), esError: true);
    if (nuevas.isNotEmpty) {
      await mostrarCredenciales(context, tituloLote: _l.titulo ?? '', credenciales: nuevas, fecha: _l.fecha, titulo: 'Claves nuevas');
    }
  }

  /// El PDF lo arma el backend (Jasper): de todo el lote o de un examen.
  Future<void> _pdf(BuildContext context, {required bool conSolucion, BigInt? codExamen}) async {
    setState(() => _generando = conSolucion ? 'solucion' : 'examen');
    try {
      final bytes = await ref
          .read(examenesRepositoryProvider)
          .pdfEscrito(codRolExamen: _l.codRolExamen, codExamen: codExamen, solucionario: conSolucion);
      if (!context.mounted) return;
      if (bytes == null) {
        // 204: el backend no armó páginas (el lote o el examen no tiene preguntas).
        avisar(context, 'No hay exámenes con preguntas para imprimir.');
        return;
      }
      final nombre = conSolucion ? 'solucionario' : 'examen';
      await mostrarPdf(
        context,
        bytes: bytes,
        titulo: conSolucion ? 'Solucionario' : 'Examen escrito',
        nombreArchivo: codExamen == null ? '${nombre}_lote_${_l.codRolExamen}.pdf' : '${nombre}_$codExamen.pdf',
      );
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (mounted) setState(() => _generando = null);
    }
  }
}

/// El estado del lote de un vistazo: la tira de estados y, al lado, las
/// cuatro cifras que se comparan (exámenes, aprobados, promedio y mínima).
class _Panel extends StatelessWidget {
  const _Panel({required this.lote, required this.compacto});

  final TcpeLoteEntity lote;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fichas = [
      CifraExamen(
        valor: '${lote.examenes}',
        rotulo: 'exámenes',
        icono: Icons.assignment_outlined,
        tono: TonoExamen.secundario,
      ),
      CifraExamen(
        valor: '${lote.aprobados} / ${lote.reprobados}',
        rotulo: 'aprobados / reprobados',
        icono: Icons.how_to_reg_outlined,
        tono: TonoExamen.principal,
      ),
      CifraExamen(
        valor: nota(lote.promedio),
        rotulo: 'promedio',
        icono: Icons.insights_outlined,
        // El promedio se lee contra la mínima: alcanza o no alcanza.
        tono:
            lote.promedio == null || lote.notaAprobacion == null
                ? TonoExamen.neutro
                : (lote.promedio! >= lote.notaAprobacion! ? TonoExamen.principal : TonoExamen.alerta),
      ),
      CifraExamen(
        valor: nota(lote.notaAprobacion),
        rotulo: 'nota mínima',
        icono: Icons.flag_outlined,
        tono: TonoExamen.terciario,
      ),
    ];
    // En el teléfono, dos fichas por fila del mismo ancho; en el ancho, en línea.
    final cifras = LayoutBuilder(
      builder: (context, r) {
        final ancho = compacto ? (r.maxWidth - Esp.m) / 2 : null;
        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [for (final f in fichas) ancho == null ? f : SizedBox(width: ancho, child: f)],
        );
      },
    );
    final tira = TiraEstados(tramos: tramosDeLote(lote));
    return Container(
      padding: const EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      // Las cifras arriba, en fichas de color; la tira del avance debajo, a todo el ancho.
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cifras, const SizedBox(height: Esp.l), tira]),
    );
  }
}

/// La nota de un examen escrito, editable en la fila: se guarda con Enter o con
/// el botón (`/examenes/calificacion/nota`). El error es el del backend.
class _NotaEnLinea extends ConsumerStatefulWidget {
  const _NotaEnLinea({required this.examen, required this.onGuardada});

  final TcpeResultadoExamenEntity examen;
  final VoidCallback onGuardada;

  @override
  ConsumerState<_NotaEnLinea> createState() => _NotaEnLineaState();
}

class _NotaEnLineaState extends ConsumerState<_NotaEnLinea> {
  late final _nota = TextEditingController(text: widget.examen.resultado == null ? '' : nota(widget.examen.resultado));
  bool _guardando = false;
  String? _error;

  @override
  void didUpdateWidget(_NotaEnLinea anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.examen.resultado != widget.examen.resultado && !_guardando) {
      _nota.text = widget.examen.resultado == null ? '' : nota(widget.examen.resultado);
    }
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Solo el formato: el rango lo valida el SP (N) con su propio mensaje.
    final n = double.tryParse(_nota.text.trim().replaceAll(',', '.'));
    if (n == null) {
      setState(() => _error = 'Escribe un número');
      return;
    }
    if (n == widget.examen.resultado) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final msg = await ref.read(examenesRepositoryProvider).notaManual(widget.examen.codExamen, n);
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, msg ?? 'Nota guardada.');
      widget.onGuardada();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: TextField(
            controller: _nota,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(6)],
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontFamily: fuenteFija),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0-100',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _guardar(),
          ),
        ),
      ),
      const SizedBox(width: Esp.xs),
      _guardando
          ? const Padding(
            padding: EdgeInsets.all(Esp.s),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          )
          : IconButton(
            tooltip: 'Guardar nota',
            onPressed: _guardar,
            icon: const Icon(Icons.save_outlined, size: 20),
          ),
    ],
  );
}

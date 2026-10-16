/// Préstamos y bitácora de destrucción: las fichas para prestar (desde una
/// caja o una entrega de varias cajas), devolver y destruir, y las tarjetas que
/// dicen qué está afuera, qué volvió y qué se destruyó. Fecha y hora las pone
/// siempre el servidor: aquí solo se muestran.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

/// La situación de una línea en un chip; nada si está en la caja. El texto
/// completo (con la fecha) queda en el tooltip y para el lector de pantalla.
class ChipSituacion extends StatelessWidget {
  const ChipSituacion({super.key, required this.linea});

  final ContenidoCajaEntity linea;

  @override
  Widget build(BuildContext context) {
    if (linea.estaDestruida) {
      return Tooltip(
        message: 'Destruido el ${oGuion(linea.fechaDestruccion)}',
        child: const ChipTono(texto: 'Destruido', semilla: TonosArchivo.destruido, icono: Icons.delete_sweep_outlined),
      );
    }
    if (linea.estaPrestada) {
      return Tooltip(
        message: 'Prestado a ${oGuion(linea.prestadoA)} desde ${oGuion(linea.fechaPrestamo)}',
        child: ChipTono(
          texto: 'Prestado a ${oGuion(linea.prestadoA)}',
          semilla: TonosArchivo.prestamo,
          icono: Icons.outbox_outlined,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRESTAR O DESTRUIR
// ═══════════════════════════════════════════════════════════════════════════

enum Movimiento { prestar, destruir }

/// Por qué la caja no se puede mover completa, o null si se puede.
String? motivoSinCajaCompleta(CajaArchivoEntity c, Movimiento m) {
  if (c.destruida) return 'La caja fue destruida.';
  if (m == Movimiento.prestar && c.prestadaCompleta) return 'La caja ya está prestada completa.';
  if (c.prestados > 0) {
    return 'Hay documentos de la caja afuera: la caja completa se registra cuando vuelvan.';
  }
  return null;
}

class DialogoMovimiento extends ConsumerStatefulWidget {
  const DialogoMovimiento({
    super.key,
    required this.movimiento,
    required this.caja,
    required this.lineas,
    required this.onGuardar,
    this.inicial = const {},
    this.mostrarAsa = true,
  });

  final Movimiento movimiento;
  final CajaArchivoEntity caja;
  final List<ContenidoCajaEntity> lineas;

  /// Las líneas que llegan marcadas (desde el menú de una línea).
  final Set<int> inicial;
  final Future<void> Function(PedidoMovimientoCaja pedido) onGuardar;
  final bool mostrarAsa;

  @override
  ConsumerState<DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends ConsumerState<DialogoMovimiento> {
  late final TextEditingController _observacion = TextEditingController();
  late final Set<int> _elegidas = {
    for (final l in widget.lineas)
      if (widget.inicial.contains(l.codContenido) && l.estaEnLaCaja) l.codContenido,
  };
  late bool _cajaCompleta =
      _elegidas.isEmpty && _disponibles.isEmpty && motivoSinCajaCompleta(widget.caja, widget.movimiento) == null;
  int? _empleado;
  bool _guardando = false;
  bool _intento = false;
  String? _error;

  bool get _prestar => widget.movimiento == Movimiento.prestar;
  List<ContenidoCajaEntity> get _disponibles => [
    for (final l in widget.lineas)
      if (l.estaEnLaCaja) l,
  ];

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _intento = true);
    if (_prestar && _empleado == null) return;
    if (!_cajaCompleta && _elegidas.isEmpty) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final obs = _observacion.text.trim();
    try {
      await widget.onGuardar(
        PedidoMovimientoCaja(
          codCaja: widget.caja.codCaja,
          lineas: _cajaCompleta ? const [] : ([..._elegidas]..sort()),
          codEmpleado: _prestar ? _empleado : null,
          observacion: obs.isEmpty ? null : obs,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = humanizar(e).texto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final motivoCompleta = motivoSinCajaCompleta(widget.caja, widget.movimiento);
    final disponibles = _disponibles;
    final caja = tituloCaja(widget.caja).toLowerCase();
    final error = tt.bodySmall?.copyWith(color: cs.error);

    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: _prestar ? 'Prestar de la $caja' : 'Registrar destrucción en la $caja',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _guardando,
              icono: _prestar ? Icons.outbox_outlined : Icons.delete_sweep_outlined,
              semilla: _prestar ? TonosArchivo.prestamo : TonosArchivo.destruido,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.m),
                        child: NotaDelDato(texto: _error!, tono: TonoNota.error),
                      ),
                    if (!_prestar)
                      const Padding(
                        padding: EdgeInsets.only(bottom: Esp.l),
                        child: NotaDelDato(
                          texto:
                              'Queda en la bitácora de destrucción. Lo destruido sigue figurando en la caja, '
                              'ya no se presta ni se mueve, y sale de los reportes de inventario.',
                          tono: TonoNota.aviso,
                        ),
                      ),
                    if (_prestar) ...[
                      ComboEmpleadoActivo(valor: _empleado, onElegir: (v) => setState(() => _empleado = v)),
                      if (_intento && _empleado == null)
                        Padding(
                          padding: const EdgeInsets.only(top: Esp.xs, left: Esp.m),
                          child: Text('Elige a quién se le entrega.', style: error),
                        ),
                      const SizedBox(height: Esp.l),
                    ],
                    Text(_prestar ? 'Qué se presta' : 'Qué se destruye', style: context.tituloSeccion()),
                    const SizedBox(height: Esp.xs),
                    // Radios y no un SegmentedButton: con letra grande los textos bajan de línea.
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: false,
                      groupValue: _cajaCompleta,
                      onChanged: _guardando ? null : (_) => setState(() => _cajaCompleta = false),
                      title: const Text('Documentos de la caja'),
                      subtitle: Text(
                        disponibles.isEmpty
                            ? 'No queda ninguno en la caja.'
                            : 'Elige cuáles; ${disponibles.length == 1 ? 'hay 1 disponible' : 'hay ${disponibles.length} disponibles'}.',
                      ),
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      groupValue: _cajaCompleta,
                      onChanged:
                          _guardando || motivoCompleta != null ? null : (_) => setState(() => _cajaCompleta = true),
                      title: const Text('La caja completa'),
                      subtitle: Text(
                        motivoCompleta ??
                            (_prestar
                                ? 'Sale la caja entera: todos sus documentos quedan como prestados.'
                                : 'Se destruye la caja entera con todo lo que guarda.'),
                      ),
                    ),
                    if (!_cajaCompleta) ...[
                      const SizedBox(height: Esp.s),
                      _listaLineas(disponibles),
                      if (_intento && _elegidas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: Esp.xs, left: Esp.m),
                          child: Text('Elige al menos un documento.', style: error),
                        ),
                    ],
                    const SizedBox(height: Esp.l),
                    TextField(
                      controller: _observacion,
                      enabled: !_guardando,
                      maxLength: 200,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: _prestar ? 'Observación' : 'Motivo u observación',
                        hintText:
                            _prestar
                                ? 'Para qué se lleva, por ejemplo: revisión de auditoría'
                                : 'Plazo de guarda cumplido · triturado · acta 12/2026',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: Esp.xs),
                        Expanded(
                          child: Text('Se registra con la fecha y hora de este momento.', style: context.apagado()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PieFicha(
              etiqueta: _prestar ? 'Registrar préstamo' : 'Registrar destrucción',
              ocupado: _guardando,
              onGuardar: _guardar,
              semilla: _prestar ? TonosArchivo.prestamo : TonosArchivo.peligro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaLineas(List<ContenidoCajaEntity> disponibles) {
    final cs = Theme.of(context).colorScheme;
    final todas = disponibles.isNotEmpty && disponibles.every((l) => _elegidas.contains(l.codContenido));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: cs.surfaceContainerHigh,
            padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.xs, Esp.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_elegidas.length} de ${disponibles.length} elegidos',
                    style: context.numero(fuerte: true),
                  ),
                ),
                TextButton(
                  onPressed:
                      _guardando || disponibles.isEmpty
                          ? null
                          : () => setState(() {
                            if (todas) {
                              _elegidas.clear();
                            } else {
                              _elegidas.addAll(disponibles.map((l) => l.codContenido));
                            }
                          }),
                  child: Text(todas ? 'Quitar todos' : 'Elegir todos'),
                ),
              ],
            ),
          ),
          if (widget.lineas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: Text('La caja no tiene documentos registrados.', style: context.apagado()),
            ),
          for (final l in widget.lineas)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _elegidas.contains(l.codContenido),
              onChanged:
                  _guardando || !l.estaEnLaCaja
                      ? null
                      : (v) => setState(() => v == true ? _elegidas.add(l.codContenido) : _elegidas.remove(l.codContenido)),
              title: Text(l.detalle),
              subtitle:
                  l.estaEnLaCaja
                      ? Text(
                        [oGuion(l.nombreTipoDocumento), if ((l.gestion ?? '').trim().isNotEmpty) l.gestion!.trim()].join(' · '),
                      )
                      : Align(alignment: Alignment.centerLeft, child: ChipSituacion(linea: l)),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEVOLVER
// ═══════════════════════════════════════════════════════════════════════════

/// La devolución de un renglón o de todo lo que falta de una entrega.
class DialogoDevolucion extends StatefulWidget {
  const DialogoDevolucion({
    super.key,
    required this.queVuelve,
    required this.loTenia,
    required this.entregadoEl,
    required this.onGuardar,
    this.mostrarAsa = true,
  });

  final String queVuelve;
  final String loTenia;
  final String entregadoEl;

  /// La nota de la devolución (la de la entrega queda como estaba).
  final Future<void> Function(String? observacion) onGuardar;
  final bool mostrarAsa;

  @override
  State<DialogoDevolucion> createState() => _DialogoDevolucionState();
}

class _DialogoDevolucionState extends State<DialogoDevolucion> {
  final _observacion = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final obs = _observacion.text.trim();
    try {
      await widget.onGuardar(obs.isEmpty ? null : obs);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = humanizar(e).texto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: 'Registrar la devolución',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _guardando,
              icono: Icons.assignment_return_outlined,
              semilla: TonosArchivo.ubicacion,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.m),
                        child: NotaDelDato(texto: _error!, tono: TonoNota.error),
                      ),
                    _Renglon(rotulo: 'Qué vuelve', valor: widget.queVuelve),
                    _Renglon(rotulo: 'Lo tenía', valor: widget.loTenia),
                    _Renglon(rotulo: 'Entregado el', valor: widget.entregadoEl),
                    const SizedBox(height: Esp.l),
                    TextField(
                      controller: _observacion,
                      enabled: !_guardando,
                      maxLength: 200,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observación',
                        hintText: 'Por ejemplo: volvió completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: Esp.xs),
                        Expanded(
                          child: Text(
                            'La devolución se registra con la fecha y hora de este momento.',
                            style: context.apagado(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PieFicha(
              etiqueta: 'Registrar devolución',
              ocupado: _guardando,
              onGuardar: _guardar,
              semilla: TonosArchivo.ubicacion,
            ),
          ],
        ),
      ),
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: context.apagado()),
        Text(valor, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: Peso.titulo)),
      ],
    ),
  );
}

/// Qué salió en un renglón: la caja entera o el documento.
String queSePresto(PrestamoDocumentoEntity p) =>
    p.cajaCompleta ? 'La caja ${p.numeroCaja} completa' : oGuion(p.detalle);

/// «2 cajas y 3 documentos», «1 caja», «1 documento».
String cajasYDocumentos(int cajas, int documentos) => [
  if (cajas > 0) cajas == 1 ? '1 caja' : '$cajas cajas',
  if (documentos > 0) documentosLegible(documentos),
].join(' y ');

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

/// Un préstamo: qué salió, a quién, cuándo y, si volvió, cuándo volvió.
class TarjetaPrestamo extends StatelessWidget {
  const TarjetaPrestamo({
    super.key,
    required this.prestamo,
    this.mostrarCaja = true,
    this.onIrACaja,
    this.onDevolver,
    this.onAnular,
  });

  final PrestamoDocumentoEntity prestamo;

  /// En la caja abierta ya se sabe de qué caja es.
  final bool mostrarCaja;
  final VoidCallback? onIrACaja;
  final VoidCallback? onDevolver;
  final VoidCallback? onAnular;

  @override
  Widget build(BuildContext context) {
    final p = prestamo;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final subtitulo = [
      'Entrega N.º ${p.codEntrega}',
      if (mostrarCaja) 'Caja ${p.numeroCaja} · ${oGuion(p.nombreArchivo)}',
      if (!p.cajaCompleta) oGuion(p.nombreTipoDocumento),
      if (!p.cajaCompleta && (p.gestion ?? '').trim().isNotEmpty) p.gestion!.trim(),
    ].join(' · ');

    return _Marco(
      icono: p.abierto ? Icons.outbox_outlined : Icons.assignment_return_outlined,
      semilla: p.abierto ? TonosArchivo.prestamo : TonosArchivo.ubicacion,
      titulo: p.cajaCompleta ? 'La caja ${p.numeroCaja} completa' : oGuion(p.detalle),
      subtitulo: subtitulo,
      chips: [
        ChipTono(texto: oGuion(p.nombreEmpleado), semilla: TonosArchivo.prestamo, icono: Icons.person_outline),
        ChipTono(texto: 'Entregado ${oGuion(p.fechaEntrega)}', semilla: TonosArchivo.gestion, icono: Icons.event_outlined),
        p.abierto
            ? const ChipTono(texto: 'Todavía afuera', semilla: TonosArchivo.prestamo, icono: Icons.hourglass_top)
            : ChipTono(
              texto: 'Devuelto ${oGuion(p.fechaDevolucion)}',
              semilla: TonosArchivo.ubicacion,
              icono: Icons.check_circle_outline,
            ),
      ],
      observacion: p.observacionEntrega,
      notaDevolucion: p.observacionDevolucion,
      pie: (p.nombreUsuario ?? '').trim().isEmpty ? null : 'Último registro: ${p.nombreUsuario!.trim()}',
      acciones: [
        if (p.abierto && onDevolver != null)
          FilledButton.tonalIcon(
            style: estiloTonal(context, TonosArchivo.ubicacion),
            onPressed: onDevolver,
            icon: const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Registrar devolución'),
          ),
        if (onIrACaja != null)
          TextButton.icon(
            onPressed: onIrACaja,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text('Ver la caja ${p.numeroCaja}'),
          ),
        if (p.abierto && onAnular != null)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: onAnular,
            icon: const Icon(Icons.undo, size: 18),
            label: Text('Anular', style: tt.labelLarge?.copyWith(color: cs.error)),
          ),
      ],
    );
  }
}

/// Un registro de la bitácora de destrucción.
class TarjetaDestruccion extends StatelessWidget {
  const TarjetaDestruccion({
    super.key,
    required this.destruccion,
    this.mostrarCaja = true,
    this.onIrACaja,
    this.onAnular,
  });

  final DestruccionDocumentoEntity destruccion;
  final bool mostrarCaja;
  final VoidCallback? onIrACaja;
  final VoidCallback? onAnular;

  @override
  Widget build(BuildContext context) {
    final d = destruccion;
    final cs = Theme.of(context).colorScheme;
    final subtitulo = [
      if (mostrarCaja) 'Caja ${d.numeroCaja} · ${oGuion(d.nombreArchivo)}',
      if (!d.cajaCompleta) oGuion(d.nombreTipoDocumento),
      if (!d.cajaCompleta && (d.gestion ?? '').trim().isNotEmpty) d.gestion!.trim(),
    ].join(' · ');

    return _Marco(
      icono: Icons.delete_sweep_outlined,
      semilla: TonosArchivo.destruido,
      titulo: d.cajaCompleta ? 'La caja ${d.numeroCaja} completa' : oGuion(d.detalle),
      subtitulo: subtitulo,
      chips: [
        ChipTono(
          texto: 'Destruido ${oGuion(d.fechaDestruccion)}',
          semilla: TonosArchivo.destruido,
          icono: Icons.event_outlined,
        ),
      ],
      observacion: d.observacion,
      pie: (d.nombreUsuario ?? '').trim().isEmpty ? null : 'Registró: ${d.nombreUsuario!.trim()}',
      acciones: [
        if (onIrACaja != null)
          TextButton.icon(
            onPressed: onIrACaja,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text('Ver la caja ${d.numeroCaja}'),
          ),
        if (onAnular != null)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: onAnular,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Anular registro'),
          ),
      ],
    );
  }
}

/// El molde común de las dos tarjetas: ícono de color, qué, de dónde, chips,
/// la observación entre comillas y las acciones abajo (bajan de línea si no entran).
class _Marco extends StatelessWidget {
  const _Marco({
    required this.icono,
    required this.semilla,
    required this.titulo,
    required this.subtitulo,
    required this.chips,
    required this.acciones,
    this.observacion,
    this.notaDevolucion,
    this.pie,
  });

  final IconData icono;
  final Color semilla;
  final String titulo;
  final String subtitulo;
  final List<Widget> chips;
  final List<Widget> acciones;
  final String? observacion;

  /// Lo que se anotó al volver.
  final String? notaDevolucion;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final obs = (observacion ?? '').trim();
    final vuelta = (notaDevolucion ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: Esp.s),
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoTono(icono, semilla, lado: 36),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tt.titleSmall?.copyWith(fontWeight: Peso.dato)),
                if (subtitulo.isNotEmpty) Text(subtitulo, style: context.apagado()),
                const SizedBox(height: Esp.s),
                Wrap(spacing: Esp.s, runSpacing: Esp.xs, children: chips),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  Text('«$obs»', style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
                if (vuelta.isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  Text('Al volver: «$vuelta»', style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
                if (pie != null) ...[
                  const SizedBox(height: Esp.xs),
                  Text(pie!, style: context.apagado()),
                ],
                if (acciones.isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  Wrap(spacing: Esp.s, runSpacing: Esp.xs, children: acciones),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// A QUIÉN SE ENTREGA
// ═══════════════════════════════════════════════════════════════════════════

/// «Se le entrega a»: solo empleados activos, con su cargo. Los inactivos
/// llegan en la lista porque son responsables de algún archivo.
class ComboEmpleadoActivo extends ConsumerWidget {
  const ComboEmpleadoActivo({super.key, required this.valor, required this.onElegir});

  final int? valor;
  final ValueChanged<int?> onElegir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleados = ref.watch(empleadosArchivoProvider);
    return empleados.when(
      loading:
          () => const InputDecorator(
            decoration: InputDecoration(labelText: 'Se le entrega a *', border: OutlineInputBorder()),
            child: Text('Cargando empleados…'),
          ),
      error:
          (e, _) => NotaDelDato(
            texto: 'No se pudieron traer los empleados: ${textoParaUsuario(e)}',
            tono: TonoNota.error,
          ),
      data: (lista) {
        final activos = [
          for (final e in lista)
            if (e.activo) e,
        ]..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        return ComboBuscable<int>(
          etiqueta: 'Se le entrega a *',
          valor: valor,
          ayuda: 'Empleado activo que se lleva los documentos.',
          opciones: [for (final e in activos) DropdownMenuEntry(value: e.codEmpleado, label: e.rotulo)],
          onElegir: onElegir,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA ENTREGA
// ═══════════════════════════════════════════════════════════════════════════

/// Una entrega: a quién, cuándo, para qué y cada caja o documento que se llevó,
/// con lo que ya volvió. Devolver y anular la entrega van abajo; lo de cada
/// renglón, en su menú.
class TarjetaEntrega extends StatelessWidget {
  const TarjetaEntrega({
    super.key,
    required this.entrega,
    required this.renglones,
    this.onIrACaja,
    this.onDevolverTodo,
    this.onDevolver,
    this.onAnular,
    this.onAnularRenglon,
  });

  final EntregaDocumentoEntity entrega;
  final List<PrestamoDocumentoEntity> renglones;
  final void Function(int codCaja)? onIrACaja;
  final VoidCallback? onDevolverTodo;
  final void Function(PrestamoDocumentoEntity p)? onDevolver;
  final VoidCallback? onAnular;
  final void Function(PrestamoDocumentoEntity p)? onAnularRenglon;

  @override
  Widget build(BuildContext context) {
    final e = entrega;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final volvioAlgo = renglones.any((p) => !p.abierto);
    final obs = (e.observacion ?? '').trim();
    final devolver =
        volvioAlgo
            ? 'Devolver lo que falta (${e.pendientes})'
            : (e.pendientes == 1 ? 'Registrar devolución' : 'Devolver todo (${e.pendientes})');

    return Container(
      margin: const EdgeInsets.only(bottom: Esp.s),
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoTono(
            e.abierta ? Icons.outbox_outlined : Icons.assignment_turned_in_outlined,
            e.abierta ? TonosArchivo.prestamo : TonosArchivo.ubicacion,
            lado: 36,
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(oGuion(e.nombreEmpleado), style: tt.titleSmall?.copyWith(fontWeight: Peso.dato)),
                Text(
                  'Entrega N.º ${e.codEntrega} · ${cajasYDocumentos(e.cajas, e.documentos)}',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.s),
                Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.xs,
                  children: [
                    ChipTono(
                      texto: 'Entregado ${oGuion(e.fechaEntrega)}',
                      semilla: TonosArchivo.gestion,
                      icono: Icons.event_outlined,
                    ),
                    e.abierta
                        ? ChipTono(
                          texto: e.pendientes == e.renglones ? 'Todo afuera' : '${e.pendientes} de ${e.renglones} afuera',
                          semilla: TonosArchivo.prestamo,
                          icono: Icons.hourglass_top,
                        )
                        : ChipTono(
                          texto: 'Devuelta ${oGuion(e.fechaDevolucion)}',
                          semilla: TonosArchivo.ubicacion,
                          icono: Icons.check_circle_outline,
                        ),
                  ],
                ),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  Text('«$obs»', style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: Esp.s),
                const Divider(height: 1),
                for (final p in renglones)
                  _RenglonEntrega(
                    prestamo: p,
                    onIrACaja: onIrACaja == null ? null : () => onIrACaja!(p.codCaja),
                    onDevolver: onDevolver == null ? null : () => onDevolver!(p),
                    onAnular: onAnularRenglon == null ? null : () => onAnularRenglon!(p),
                  ),
                if ((e.nombreUsuario ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  Text('Registró: ${e.nombreUsuario!.trim()}', style: context.apagado()),
                ],
                if (e.abierta && (onDevolverTodo != null || onAnular != null)) ...[
                  const SizedBox(height: Esp.xs),
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    children: [
                      if (onDevolverTodo != null)
                        FilledButton.tonalIcon(
                          style: estiloTonal(context, TonosArchivo.ubicacion),
                          onPressed: onDevolverTodo,
                          icon: const Icon(Icons.assignment_return_outlined, size: 18),
                          label: Text(devolver),
                        ),
                      // Con algo devuelto ya es historial: se anula renglón por renglón.
                      if (!volvioAlgo && onAnular != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: cs.error),
                          onPressed: onAnular,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Anular entrega'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccionRenglon { devolver, verCaja, anular }

/// Un renglón de la entrega: la caja completa o el documento, de dónde es y si
/// volvió. Sus acciones van en un menú para que entre en cualquier ancho.
class _RenglonEntrega extends StatelessWidget {
  const _RenglonEntrega({required this.prestamo, this.onIrACaja, this.onDevolver, this.onAnular});

  final PrestamoDocumentoEntity prestamo;
  final VoidCallback? onIrACaja;
  final VoidCallback? onDevolver;
  final VoidCallback? onAnular;

  @override
  Widget build(BuildContext context) {
    final p = prestamo;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final titulo = p.cajaCompleta ? 'Caja ${p.numeroCaja} completa' : oGuion(p.detalle);
    final donde = [
      if (!p.cajaCompleta) 'Caja ${p.numeroCaja}',
      oGuion(p.nombreArchivo),
      if (!p.cajaCompleta) oGuion(p.nombreTipoDocumento),
      if (!p.cajaCompleta && (p.gestion ?? '').trim().isNotEmpty) p.gestion!.trim(),
    ].join(' · ');
    final vuelta = (p.observacionDevolucion ?? '').trim();
    final acciones = <PopupMenuEntry<_AccionRenglon>>[
      if (p.abierto && onDevolver != null)
        const PopupMenuItem(
          value: _AccionRenglon.devolver,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.assignment_return_outlined),
            title: Text('Registrar devolución'),
          ),
        ),
      if (onIrACaja != null)
        PopupMenuItem(
          value: _AccionRenglon.verCaja,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('Ver la caja ${p.numeroCaja}'),
          ),
        ),
      if (p.abierto && onAnular != null)
        PopupMenuItem(
          value: _AccionRenglon.anular,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.undo, color: cs.error),
            title: Text('Anular este renglón', style: TextStyle(color: cs.error)),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              p.cajaCompleta ? Icons.inventory_2_outlined : Icons.description_outlined,
              size: 18,
              color: tonoDe(context, p.cajaCompleta ? TonosArchivo.caja : TonosArchivo.documentos).fuerte,
            ),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo)),
                Text(donde, style: context.apagado()),
                const SizedBox(height: Esp.xs),
                p.abierto
                    ? const ChipTono(texto: 'Afuera', semilla: TonosArchivo.prestamo, icono: Icons.hourglass_top)
                    : ChipTono(
                      texto: 'Volvió ${oGuion(p.fechaDevolucion)}',
                      semilla: TonosArchivo.ubicacion,
                      icono: Icons.check_circle_outline,
                    ),
                if (vuelta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Esp.xs),
                    child: Text('Al volver: «$vuelta»', style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          if (acciones.isNotEmpty)
            PopupMenuButton<_AccionRenglon>(
              tooltip: 'Acciones de $titulo',
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => acciones,
              onSelected:
                  (a) => switch (a) {
                    _AccionRenglon.devolver => onDevolver?.call(),
                    _AccionRenglon.verCaja => onIrACaja?.call(),
                    _AccionRenglon.anular => onAnular?.call(),
                  },
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NUEVO PRÉSTAMO: CAJAS Y DOCUMENTOS DE VARIAS CAJAS
// ═══════════════════════════════════════════════════════════════════════════

/// Una entrega a un empleado en un solo paso: se buscan cajas (por número,
/// archivo o ubicación) y documentos (por lo que dicen) de todo el archivo, y
/// se agregan. Todo sale junto, con la misma fecha y hora.
class DialogoEntrega extends ConsumerStatefulWidget {
  const DialogoEntrega({super.key, required this.onGuardar, this.mostrarAsa = true});

  final Future<void> Function(PedidoEntrega pedido) onGuardar;
  final bool mostrarAsa;

  @override
  ConsumerState<DialogoEntrega> createState() => _DialogoEntregaState();
}

class _DialogoEntregaState extends ConsumerState<DialogoEntrega> {
  static const _maxCajas = 8;
  static const _maxDocumentos = 25;

  /// Hasta 3 cifras es el número de una caja; más largo (un año) se busca en el texto.
  static final _numeroDeCaja = RegExp(r'^\d{1,3}$');

  final _busqueda = TextEditingController();
  final _observacion = TextEditingController();
  final Set<int> _cajas = {};
  final Set<int> _lineas = {};
  String _texto = '';
  int? _empleado;
  bool _guardando = false;
  bool _intento = false;
  String? _error;

  @override
  void dispose() {
    _busqueda.dispose();
    _observacion.dispose();
    super.dispose();
  }

  List<String> get _palabras => [
    for (final p in normalizarBusqueda(_texto).split(' '))
      if (p.isNotEmpty && p != 'caja' && p != 'cajas') p,
  ];

  bool _cumple(List<String> palabras, String pajar, int numeroCaja) =>
      palabras.every((p) => _numeroDeCaja.hasMatch(p) ? '$numeroCaja' == p : pajar.contains(p));

  void _alternarCaja(CajaArchivoEntity c, List<ContenidoCajaEntity> suyas) => setState(() {
    if (_cajas.remove(c.codCaja)) return;
    _cajas.add(c.codCaja);
    // La caja completa ya lleva sus documentos: los sueltos de esa caja se quitan.
    _lineas.removeAll(suyas.map((l) => l.codContenido));
  });

  void _alternarLinea(int codContenido) => setState(() {
    if (!_lineas.remove(codContenido)) _lineas.add(codContenido);
  });

  String? _motivoLinea(ContenidoCajaEntity l) {
    if (_cajas.contains(l.codCaja)) return 'Va con su caja completa.';
    if (l.estaDestruida) return 'Destruido: ya no se presta.';
    if (l.estaPrestada) return 'Prestado a ${oGuion(l.prestadoA)}.';
    return null;
  }

  Future<void> _guardar() async {
    setState(() => _intento = true);
    if (_empleado == null || (_cajas.isEmpty && _lineas.isEmpty)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final obs = _observacion.text.trim();
    try {
      await widget.onGuardar(
        PedidoEntrega(
          codEmpleado: _empleado,
          cajas: [..._cajas]..sort(),
          lineas: [..._lineas]..sort(),
          observacion: obs.isEmpty ? null : obs,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = humanizar(e).texto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(archivoDocumentalProvider);
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_guardando,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.mostrarAsa ? MediaQuery.viewInsetsOf(context).bottom : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabezaFicha(
              titulo: 'Nuevo préstamo',
              mostrarAsa: widget.mostrarAsa,
              ocupado: _guardando,
              icono: Icons.outbox_outlined,
              semilla: TonosArchivo.prestamo,
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, c) {
                  final datos = [_quien(), const SizedBox(height: Esp.xl), _seleccion(estado)];
                  // Angosto: todo en una columna. Ancho: a la izquierda se busca, a la derecha lo elegido.
                  if (c.maxWidth < 760) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(Esp.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...datos.take(2),
                          _buscador(estado),
                          const SizedBox(height: Esp.xl),
                          datos.last,
                          const SizedBox(height: Esp.l),
                          _observacionYHora(),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
                    // Alto fijo: la ficha no salta de tamaño mientras se escribe.
                    height: math.min(c.maxHeight, 600),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: SingleChildScrollView(padding: const EdgeInsets.all(Esp.xl), child: _buscador(estado)),
                        ),
                        VerticalDivider(width: 1, color: cs.outlineVariant),
                        Expanded(
                          flex: 9,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(Esp.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [...datos, const SizedBox(height: Esp.l), _observacionYHora()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            PieFicha(
              etiqueta: 'Registrar préstamo',
              ocupado: _guardando,
              onGuardar: _guardar,
              semilla: TonosArchivo.prestamo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quien() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.m),
            child: NotaDelDato(texto: _error!, tono: TonoNota.error),
          ),
        ComboEmpleadoActivo(valor: _empleado, onElegir: (v) => setState(() => _empleado = v)),
        if (_intento && _empleado == null)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs, left: Esp.m),
            child: Text(
              'Elige a quién se le entrega.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }

  Widget _buscador(ArchivoDocumentalState estado) {
    final palabras = _palabras;
    final cajas = <CajaArchivoEntity>[];
    final lineas = <ContenidoCajaEntity>[];
    if (palabras.isNotEmpty) {
      for (final c in estado.cajas) {
        final pajar = normalizarBusqueda('${c.nombreArchivo ?? ''} ${c.estante ?? ''} ${c.fila ?? ''}');
        if (_cumple(palabras, pajar, c.numero)) cajas.add(c);
      }
      for (final l in estado.contenido) {
        final c = estado.caja(l.codCaja);
        if (c == null) continue;
        final pajar = normalizarBusqueda(
          [c.nombreArchivo, l.nombreTipoDocumento, l.detalle, l.gestion, l.nombreEmpresa, l.observacion]
              .whereType<String>()
              .join(' '),
        );
        if (_cumple(palabras, pajar, c.numero)) lineas.add(l);
      }
    }
    String dondeDe(ContenidoCajaEntity l) {
      final c = estado.caja(l.codCaja);
      return [
        'Caja ${c?.numero ?? '-'} · ${oGuion(c?.nombreArchivo)}',
        oGuion(l.nombreTipoDocumento),
        if ((l.gestion ?? '').trim().isNotEmpty) l.gestion!.trim(),
      ].join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Qué se lleva', style: context.tituloSeccion()),
        const SizedBox(height: Esp.s),
        TextField(
          controller: _busqueda,
          enabled: !_guardando,
          onChanged: (v) => setState(() => _texto = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'Busca una caja o un documento',
            hintText: 'Por ejemplo: achocalla 7 · facturas 2016',
            helperText: 'Un número es el de la caja; un año o una palabra se buscan en los documentos.',
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon:
                _texto.isEmpty
                    ? null
                    : IconButton(
                      tooltip: 'Borrar la búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _busqueda.clear();
                        setState(() => _texto = '');
                      },
                    ),
          ),
        ),
        const SizedBox(height: Esp.s),
        if (palabras.isEmpty)
          Text(
            'Escribe para ver cajas y documentos, y agrega los que se llevan: de una caja o de varias.',
            style: context.apagado(),
          )
        else if (cajas.isEmpty && lineas.isEmpty)
          Text('Nada coincide con «${_texto.trim()}».', style: context.apagado())
        else ...[
          if (cajas.isNotEmpty) ...[
            _Subtitulo('Cajas completas (${cajas.length})'),
            for (final c in cajas.take(_maxCajas))
              _FilaElegible(
                icono: Icons.inventory_2_outlined,
                semilla: TonosArchivo.caja,
                titulo: 'Caja ${c.numero} completa',
                subtitulo: '${oGuion(c.nombreArchivo)} · ${documentosLegible(c.lineas)}',
                motivo: _cajas.contains(c.codCaja) ? null : motivoSinCajaCompleta(c, Movimiento.prestar),
                elegido: _cajas.contains(c.codCaja),
                onAlternar: _guardando ? null : () => _alternarCaja(c, estado.lineasDe(c.codCaja)),
              ),
            if (cajas.length > _maxCajas) _Mas(cajas.length - _maxCajas, 'cajas'),
          ],
          if (lineas.isNotEmpty) ...[
            _Subtitulo('Documentos (${lineas.length})'),
            for (final l in lineas.take(_maxDocumentos))
              _FilaElegible(
                icono: Icons.description_outlined,
                semilla: TonosArchivo.documentos,
                titulo: l.detalle,
                subtitulo: dondeDe(l),
                motivo: _lineas.contains(l.codContenido) ? null : _motivoLinea(l),
                elegido: _lineas.contains(l.codContenido),
                onAlternar: _guardando ? null : () => _alternarLinea(l.codContenido),
              ),
            if (lineas.length > _maxDocumentos) _Mas(lineas.length - _maxDocumentos, 'documentos'),
          ],
        ],
      ],
    );
  }

  Widget _seleccion(ArchivoDocumentalState estado) {
    final cs = Theme.of(context).colorScheme;
    final cajas = [
      for (final c in estado.cajas)
        if (_cajas.contains(c.codCaja)) c,
    ];
    final lineas = [
      for (final l in estado.contenido)
        if (_lineas.contains(l.codContenido)) l,
    ];
    final nada = cajas.isEmpty && lineas.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Lo que se entrega', style: context.tituloSeccion()),
        Text(
          nada ? 'Todavía nada.' : cajasYDocumentos(cajas.length, lineas.length),
          style: context.numero(fuerte: !nada),
        ),
        const SizedBox(height: Esp.xs),
        for (final c in cajas)
          _FilaElegida(
            icono: Icons.inventory_2_outlined,
            semilla: TonosArchivo.caja,
            titulo: 'Caja ${c.numero} completa',
            subtitulo: '${oGuion(c.nombreArchivo)} · ${documentosLegible(c.lineas)}',
            onQuitar: _guardando ? null : () => setState(() => _cajas.remove(c.codCaja)),
          ),
        for (final l in lineas)
          _FilaElegida(
            icono: Icons.description_outlined,
            semilla: TonosArchivo.documentos,
            titulo: l.detalle,
            subtitulo: 'Caja ${estado.caja(l.codCaja)?.numero ?? '-'} · ${oGuion(estado.caja(l.codCaja)?.nombreArchivo)}',
            onQuitar: _guardando ? null : () => setState(() => _lineas.remove(l.codContenido)),
          ),
        if (_intento && nada)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs, left: Esp.m),
            child: Text(
              'Agrega al menos una caja o un documento.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }

  Widget _observacionYHora() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _observacion,
          enabled: !_guardando,
          maxLength: 200,
          minLines: 2,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Observación',
            hintText: 'Para qué se lleva, por ejemplo: revisión de auditoría',
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: Esp.xs),
            Expanded(child: Text('Se registra con la fecha y hora de este momento.', style: context.apagado())),
          ],
        ),
      ],
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.m, bottom: Esp.xs),
    child: Text(texto, style: context.numero(fuerte: true)),
  );
}

class _Mas extends StatelessWidget {
  const _Mas(this.cuantos, this.que);

  final int cuantos;
  final String que;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs),
    child: Text('Y $cuantos $que más: escribe algo más para acotar.', style: context.apagado()),
  );
}

/// Un resultado de la búsqueda: se agrega o se quita tocándolo. Lo que no se
/// puede prestar dice por qué en vez de lo que es.
class _FilaElegible extends StatelessWidget {
  const _FilaElegible({
    required this.icono,
    required this.semilla,
    required this.titulo,
    required this.subtitulo,
    required this.elegido,
    this.motivo,
    this.onAlternar,
  });

  final IconData icono;
  final Color semilla;
  final String titulo;
  final String subtitulo;
  final bool elegido;
  final String? motivo;
  final VoidCallback? onAlternar;

  @override
  Widget build(BuildContext context) {
    final puede = motivo == null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      enabled: puede,
      leading: IconoTono(icono, puede ? semilla : TonosArchivo.destruido, lado: 32),
      title: Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(motivo ?? subtitulo),
      onTap: puede ? onAlternar : null,
      trailing:
          !puede
              ? null
              : elegido
              ? IconButton.filled(
                tooltip: 'Quitar',
                style: estiloLleno(context, TonosArchivo.prestamo),
                onPressed: onAlternar,
                icon: const Icon(Icons.check),
              )
              : IconButton.filledTonal(
                tooltip: 'Agregar',
                style: estiloIconoTonal(context, TonosArchivo.prestamo),
                onPressed: onAlternar,
                icon: const Icon(Icons.add),
              ),
    );
  }
}

/// Algo que ya va en la entrega, con su botón para quitarlo.
class _FilaElegida extends StatelessWidget {
  const _FilaElegida({
    required this.icono,
    required this.semilla,
    required this.titulo,
    required this.subtitulo,
    this.onQuitar,
  });

  final IconData icono;
  final Color semilla;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icono, color: tonoDe(context, semilla).fuerte),
    title: Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(subtitulo),
    trailing: IconButton(tooltip: 'Quitar $titulo', onPressed: onQuitar, icon: const Icon(Icons.close)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// LA FICHA GENERAL
// ═══════════════════════════════════════════════════════════════════════════

/// Las entregas que tienen algo afuera, las que ya volvieron y la bitácora de
/// destrucción, de todas las cajas, con una búsqueda por persona, caja o
/// documento. Desde aquí se registra un préstamo de varias cajas.
class MovimientosArchivo extends ConsumerStatefulWidget {
  const MovimientosArchivo({
    super.key,
    required this.mostrarAsa,
    required this.onIrACaja,
    required this.onNuevaEntrega,
    required this.onDevolverEntrega,
    required this.onAnularEntrega,
    required this.onDevolver,
    required this.onAnularPrestamo,
    required this.onAnularDestruccion,
  });

  final bool mostrarAsa;
  final void Function(int codCaja) onIrACaja;
  final VoidCallback onNuevaEntrega;
  final void Function(EntregaDocumentoEntity e) onDevolverEntrega;
  final void Function(EntregaDocumentoEntity e) onAnularEntrega;
  final void Function(PrestamoDocumentoEntity p) onDevolver;
  final void Function(PrestamoDocumentoEntity p) onAnularPrestamo;
  final void Function(DestruccionDocumentoEntity d) onAnularDestruccion;

  @override
  ConsumerState<MovimientosArchivo> createState() => _MovimientosArchivoState();
}

class _MovimientosArchivoState extends ConsumerState<MovimientosArchivo> {
  final _busqueda = TextEditingController();
  String _texto = '';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  bool _cumple(List<String?> campos) {
    final palabras = normalizarBusqueda(_texto).split(' ').where((p) => p.isNotEmpty);
    if (palabras.isEmpty) return true;
    final pajar = normalizarBusqueda(campos.whereType<String>().join(' '));
    return palabras.every(pajar.contains);
  }

  bool _cumpleEntrega(EntregaDocumentoEntity e, List<PrestamoDocumentoEntity> renglones) => _cumple([
    e.nombreEmpleado,
    'entrega ${e.codEntrega}',
    e.observacion,
    for (final p in renglones) ...[
      'caja ${p.numeroCaja}',
      p.nombreArchivo,
      p.detalle,
      p.nombreTipoDocumento,
      p.gestion,
      p.observacionDevolucion,
    ],
  ]);

  bool _cumpleDestruccion(DestruccionDocumentoEntity d) => _cumple([
    'caja ${d.numeroCaja}',
    d.nombreArchivo,
    d.detalle,
    d.nombreTipoDocumento,
    d.gestion,
    d.observacion,
    d.nombreUsuario,
  ]);

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(archivoDocumentalProvider);
    final alto = MediaQuery.sizeOf(context).height * 0.85;
    final afuera = <(EntregaDocumentoEntity, List<PrestamoDocumentoEntity>)>[];
    final devueltas = <(EntregaDocumentoEntity, List<PrestamoDocumentoEntity>)>[];
    for (final e in estado.entregas) {
      final renglones = estado.renglonesDe(e.codEntrega);
      if (!_cumpleEntrega(e, renglones)) continue;
      (e.abierta ? afuera : devueltas).add((e, renglones));
    }
    final destruidos = [
      for (final d in estado.destrucciones)
        if (_cumpleDestruccion(d)) d,
    ];
    final buscando = _texto.trim().isNotEmpty;

    Widget lista(List<Widget> tarjetas, String vacio, String comoSeRegistra) =>
        tarjetas.isEmpty
            ? MensajeVacio(
              icono: Icons.inbox_outlined,
              titulo: buscando ? 'Nada coincide con «${_texto.trim()}»' : vacio,
              detalle: buscando ? 'Prueba con otra palabra.' : comoSeRegistra,
            )
            : ListView(padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.xl), children: tarjetas);

    Widget tarjeta((EntregaDocumentoEntity, List<PrestamoDocumentoEntity>) x) => TarjetaEntrega(
      entrega: x.$1,
      renglones: x.$2,
      onIrACaja: widget.onIrACaja,
      onDevolverTodo: () => widget.onDevolverEntrega(x.$1),
      onDevolver: widget.onDevolver,
      onAnular: () => widget.onAnularEntrega(x.$1),
      onAnularRenglon: widget.onAnularPrestamo,
    );

    final buscador = TextField(
      controller: _busqueda,
      onChanged: (v) => setState(() => _texto = v),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Busca por persona, caja o documento',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon:
            _texto.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Borrar la búsqueda',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _busqueda.clear();
                    setState(() => _texto = '');
                  },
                ),
      ),
    );
    final nuevo = FilledButton.icon(
      style: estiloLleno(context, TonosArchivo.prestamo),
      onPressed: widget.onNuevaEntrega,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo préstamo'),
    );

    return SizedBox(
      height: alto,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            CabezaFicha(
              titulo: 'Préstamos y destrucciones',
              mostrarAsa: widget.mostrarAsa,
              ocupado: false,
              icono: Icons.outbox_outlined,
              semilla: TonosArchivo.prestamo,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, 0),
              child: LayoutBuilder(
                builder:
                    (context, c) =>
                        c.maxWidth < 560
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [buscador, const SizedBox(height: Esp.s), nuevo],
                            )
                            : Row(children: [Expanded(child: buscador), const SizedBox(width: Esp.m), nuevo]),
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Afuera (${afuera.length})'),
                Tab(text: 'Devueltas (${devueltas.length})'),
                Tab(text: 'Destruidos (${destruidos.length})'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  lista(
                    [for (final x in afuera) tarjeta(x)],
                    'No hay nada prestado',
                    'Registra uno con «Nuevo préstamo» o desde la caja abierta.',
                  ),
                  lista(
                    [for (final x in devueltas) tarjeta(x)],
                    'Todavía no volvió ninguna entrega',
                    'Aquí quedan las entregas que ya volvieron enteras.',
                  ),
                  lista(
                    [
                      for (final d in destruidos)
                        TarjetaDestruccion(
                          destruccion: d,
                          onIrACaja: () => widget.onIrACaja(d.codCaja),
                          onAnular: () => widget.onAnularDestruccion(d),
                        ),
                    ],
                    'La bitácora de destrucción está vacía',
                    'Se registra desde la caja abierta.',
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

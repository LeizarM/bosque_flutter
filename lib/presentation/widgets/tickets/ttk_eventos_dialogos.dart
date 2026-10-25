/// Formularios y acciones de la pantalla de eventos: evento, tipo de vale,
/// participantes (empleado o invitado), cantidades de vales e impresión.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_pdf.dart';

/// Botones de la pantalla de eventos (`tb_vistaBtn.nombreBtn`).
abstract final class BotonTtkEvento {
  static const nuevo = 'btnTtkNuevoEvento';
  static const editar = 'btnTtkEditarEvento';
  static const eliminar = 'btnTtkEliminarEvento';
  static const emitir = 'btnTtkEmitirTickets';
  static const imprimir = 'btnTtkImprimirTickets';
}

/// Vuelve a pedir todo lo del evento después de una escritura.
void refrescarEventoTtk(WidgetRef ref, BigInt? codEvento) {
  ref.invalidate(ttkEventosProvider);
  if (codEvento != null) {
    ref.invalidate(ttkEventoProvider(codEvento));
    ref.invalidate(ttkTiposProvider(codEvento));
  }
  ref.invalidate(ttkParticipantesProvider);
  ref.invalidate(ttkValesParticipanteProvider);
}

/// Muestra una espera modal mientras corre [tarea] (armar un PDF, por ejemplo).
Future<T?> conEsperaTtk<T>(
  BuildContext context,
  String texto,
  Future<T> Function() tarea,
) async {
  final navegador = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder:
          (_) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: Esp.l),
                  Flexible(child: Text(texto)),
                ],
              ),
            ),
          ),
    ),
  );
  try {
    return await tarea();
  } finally {
    if (navegador.mounted) navegador.pop();
  }
}

/// Arma el PDF de los vales numerados (de todo el evento o de una persona).
Future<void> imprimirValesTtk(
  BuildContext context,
  WidgetRef ref, {
  required BigInt codEvento,
  BigInt? codParticipante,
  required String titulo,
}) async {
  final repo = ref.read(ttkTicketsRepositoryProvider);
  try {
    final bytes = await conEsperaTtk(
      context,
      'Preparando los vales…',
      () async {
        final vales = await repo.valesParaImprimir(
          codEvento,
          codParticipante: codParticipante,
        );
        return vales.isEmpty ? null : await ttkPdfVales(vales);
      },
    );
    if (!context.mounted) return;
    if (bytes == null) {
      mostrarAviso(
        context,
        'No hay vales numerados para imprimir.',
        tono: TonoAviso.aviso,
      );
      return;
    }
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: 'vales.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
  }
}

/// Las acciones de un evento según sus banderas `puede*` y los permisos.
List<AccionTtk> accionesEventoTtk(
  BuildContext context,
  WidgetRef ref,
  TtkEventoEntity e, {
  VoidCallback? abrir,
  VoidCallback? alEliminar,
}) {
  final repo = ref.read(ttkTicketsRepositoryProvider);
  final cod = e.codEvento!;
  Future<void> correr(Future<TtkRespuesta> Function() f) async {
    if (await ejecutarTtk(context, f)) refrescarEventoTtk(ref, cod);
  }

  return [
    if (abrir != null) AccionTtk('Abrir', Icons.open_in_new, abrir),
    if (e.puedeEditar)
      AccionTtk(
        'Editar',
        Icons.edit_outlined,
        () => editarEventoTtk(context, ref, evento: e),
        boton: BotonTtkEvento.editar,
      ),
    if (e.puedeEmitir)
      AccionTtk(
        'Emitir vales',
        Icons.confirmation_number_outlined,
        () async {
          final ok = await confirmar(
            context,
            titulo: 'Emitir los vales',
            detalle:
                'Se numeran los ${e.totalTickets} vales de «${e.nombre}» y la lista queda cerrada para cambios.',
            textoConfirmar: 'Emitir',
          );
          if (ok && context.mounted) await correr(() => repo.emitirEvento(cod));
        },
        boton: BotonTtkEvento.emitir,
      ),
    if (e.puedeVolverBorrador)
      AccionTtk('Volver a borrador', Icons.undo, () async {
        final ok = await confirmar(
          context,
          titulo: 'Volver a borrador',
          detalle: 'Se quita la numeración de los vales de «${e.nombre}».',
          textoConfirmar: 'Volver a borrador',
          destructiva: true,
        );
        if (ok && context.mounted) await correr(() => repo.volverBorrador(cod));
      }, boton: BotonTtkEvento.emitir),
    if (e.puedeImprimir)
      AccionTtk(
        'Imprimir vales',
        Icons.print_outlined,
        () => imprimirValesTtk(
          context,
          ref,
          codEvento: cod,
          titulo: 'Vales · ${e.nombre}',
        ),
        boton: BotonTtkEvento.imprimir,
      ),
    if (e.puedeCerrar)
      AccionTtk('Cerrar evento', Icons.lock_outline, () async {
        final ok = await confirmar(
          context,
          titulo: 'Cerrar el evento',
          detalle: '«${e.nombre}» queda cerrado y ya no se puede modificar.',
          textoConfirmar: 'Cerrar evento',
        );
        if (ok && context.mounted) await correr(() => repo.cerrarEvento(cod));
      }, boton: BotonTtkEvento.emitir),
    if (e.puedeEliminar)
      AccionTtk(
        'Eliminar',
        Icons.delete_outline,
        () async {
          final ok = await confirmar(
            context,
            titulo: 'Eliminar el evento',
            detalle:
                'Se borra «${e.nombre}» con su lista, sus tipos de vale y su bingo.',
            textoConfirmar: 'Eliminar',
            destructiva: true,
          );
          if (!ok || !context.mounted) return;
          if (await ejecutarTtk(context, () => repo.eliminarEvento(cod))) {
            refrescarEventoTtk(ref, null);
            alEliminar?.call();
          }
        },
        boton: BotonTtkEvento.eliminar,
        destructiva: true,
      ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENTO
// ═══════════════════════════════════════════════════════════════════════════

/// Alta o edición de un evento. Devuelve el id guardado (o null si se canceló).
Future<BigInt?> editarEventoTtk(
  BuildContext context,
  WidgetRef ref, {
  TtkEventoEntity? evento,
}) {
  return showDialog<BigInt?>(
    context: context,
    builder: (_) => _DialogoEvento(evento: evento),
  );
}

class _DialogoEvento extends ConsumerStatefulWidget {
  const _DialogoEvento({this.evento});

  final TtkEventoEntity? evento;

  @override
  ConsumerState<_DialogoEvento> createState() => _DialogoEventoState();
}

class _DialogoEventoState extends ConsumerState<_DialogoEvento> {
  late final _nombre = TextEditingController(text: widget.evento?.nombre);
  late final _descripcion = TextEditingController(
    text: widget.evento?.descripcion,
  );
  late final _lugar = TextEditingController(text: widget.evento?.lugar);
  late final _meses = TextEditingController(
    text: '${widget.evento?.mesesReciente ?? 3}',
  );
  late DateTime? _fecha = widget.evento?.fecha;
  late bool _usaTickets = widget.evento?.usaTickets ?? true;
  late bool _usaBingo = widget.evento?.usaBingo ?? false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _lugar.dispose();
    _meses.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 3),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final base = widget.evento ?? const TtkEventoEntity(nombre: '');
    final e = base.copyWith(
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      lugar: _lugar.text.trim(),
      fecha: _fecha,
      usaTickets: _usaTickets,
      usaBingo: _usaBingo,
      mesesReciente: int.tryParse(_meses.text.trim()) ?? base.mesesReciente,
    );
    BigInt? id;
    final ok = await ejecutarTtk(context, () async {
      final r = await ref.read(ttkTicketsRepositoryProvider).guardarEvento(e);
      id = r.id;
      return r;
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.evento?.codEvento);
      Navigator.of(context).pop(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text(widget.evento == null ? 'Nuevo evento' : 'Editar evento'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                autofocus: widget.evento == null,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del evento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.event),
                label: Text(
                  _fecha == null
                      ? 'Elegir la fecha'
                      : 'Fecha: ${fechaCorta(_fecha)}',
                ),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _lugar,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Lugar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _descripcion,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _meses,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Meses para considerar reciente a un empleado',
                  helperText:
                      'Quien entró a la empresa hace menos de estos meses (contados hasta la fecha del evento) queda como «Reciente» y recibe los vales de esa categoría.',
                  helperMaxLines: 3,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reparte vales'),
                subtitle: const Text(
                  'Cada participante recibe vales numerados (almuerzo, bebida, rifa…) para canjear en el evento.',
                ),
                value: _usaTickets,
                onChanged: (v) => setState(() => _usaTickets = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tiene bingo'),
                subtitle: const Text(
                  'Se crea un bingo para este evento. Lo armas después en «Configuración del bingo».',
                ),
                value: _usaBingo,
                onChanged: (v) => setState(() => _usaBingo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando…',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIPO DE VALE
// ═══════════════════════════════════════════════════════════════════════════

/// Colores sugeridos para el tipo de vale; se guardan en la base como #RRGGBB.
const List<String> ttkColoresSugeridos = [
  '#F4C430',
  '#7FB3D5',
  '#82C99A',
  '#F1948A',
  '#BB8FCE',
  '#F8C471',
  '#AAB7B8',
  '#76D7C4',
];

Future<void> editarTipoTtk(
  BuildContext context,
  WidgetRef ref, {
  required BigInt codEvento,
  TtkTipoTicketEntity? tipo,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoTipo(codEvento: codEvento, tipo: tipo),
);

class _DialogoTipo extends ConsumerStatefulWidget {
  const _DialogoTipo({required this.codEvento, this.tipo});

  final BigInt codEvento;
  final TtkTipoTicketEntity? tipo;

  @override
  ConsumerState<_DialogoTipo> createState() => _DialogoTipoState();
}

class _DialogoTipoState extends ConsumerState<_DialogoTipo> {
  late final _nombre = TextEditingController(text: widget.tipo?.nombre);
  late final _leyenda = TextEditingController(text: widget.tipo?.leyenda);
  late final _emp = TextEditingController(
    text: '${widget.tipo?.cantEmpleado ?? 1}',
  );
  late final _rec = TextEditingController(
    text: '${widget.tipo?.cantReciente ?? 0}',
  );
  late final _inv = TextEditingController(
    text: '${widget.tipo?.cantInvitado ?? 0}',
  );
  late String? _color = widget.tipo?.colorHex;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _leyenda, _emp, _rec, _inv]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final base =
        widget.tipo ??
        TtkTipoTicketEntity(nombre: '', codEvento: widget.codEvento);
    final t = base.copyWith(
      codEvento: widget.codEvento,
      nombre: _nombre.text.trim(),
      leyenda: _leyenda.text.trim(),
      cantEmpleado: int.tryParse(_emp.text) ?? 0,
      cantReciente: int.tryParse(_rec.text) ?? 0,
      cantInvitado: int.tryParse(_inv.text) ?? 0,
      colorHex: _color,
      quitarColor: _color == null,
    );
    final ok = await ejecutarTtk(
      context,
      () => ref.read(ttkTicketsRepositoryProvider).guardarTipo(t),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.codEvento);
      Navigator.of(context).pop();
    }
  }

  Widget _cantidad(TextEditingController c, String rotulo) => Expanded(
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: ttkFuenteNumeros,
        fontFeatures: cifrasTabulares,
      ),
      decoration: InputDecoration(
        labelText: rotulo,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final angosto = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text(
        widget.tipo == null ? 'Nuevo tipo de vale' : 'Editar tipo de vale',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                autofocus: widget.tipo == null,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Por ejemplo, Almuerzo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _leyenda,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Leyenda impresa en el vale',
                  helperText:
                      'Texto corto que sale impreso en el vale, por ejemplo «Válido solo el día del evento».',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.l),
              Text('Vales por persona', style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              Text(
                'Cuántos vales de este tipo recibe cada persona según su categoría. '
                'Después puedes ajustarlo persona por persona.',
                style: context.apagado(),
              ),
              const SizedBox(height: Esp.s),
              Row(
                children: [
                  _cantidad(_emp, 'Empleado'),
                  const SizedBox(width: Esp.s),
                  _cantidad(_rec, 'Reciente'),
                  const SizedBox(width: Esp.s),
                  _cantidad(_inv, 'Invitado'),
                ],
              ),
              const SizedBox(height: Esp.l),
              Text('Color del vale', style: context.tituloSeccion()),
              const SizedBox(height: Esp.s),
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: [
                  ChoiceChip(
                    label: const Text('Sin color'),
                    selected: _color == null,
                    onSelected: (_) => setState(() => _color = null),
                  ),
                  for (final hex in ttkColoresSugeridos)
                    Semantics(
                      label: 'Color $hex',
                      selected: _color?.toUpperCase() == hex,
                      button: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ttkColorHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _color?.toUpperCase() == hex
                                      ? cs.onSurface
                                      : cs.outlineVariant,
                              width: _color?.toUpperCase() == hex ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando…',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICIPANTES
// ═══════════════════════════════════════════════════════════════════════════

/// Busca un empleado activo que aún no está en la lista y lo agrega.
Future<void> agregarEmpleadoTtk(
  BuildContext context,
  WidgetRef ref,
  BigInt codEvento,
) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoEmpleado(codEvento: codEvento),
);

class _DialogoEmpleado extends ConsumerStatefulWidget {
  const _DialogoEmpleado({required this.codEvento});

  final BigInt codEvento;

  @override
  ConsumerState<_DialogoEmpleado> createState() => _DialogoEmpleadoState();
}

class _DialogoEmpleadoState extends ConsumerState<_DialogoEmpleado> {
  final _buscador = TextEditingController();
  Timer? _espera;
  String _buscar = '';
  TtkParticipanteEntity? _elegido;
  String? _categoria;
  bool _guardando = false;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  void _alEscribir(String t) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _buscar = t.trim());
    });
  }

  Future<void> _agregar() async {
    final e = _elegido;
    if (e == null) return;
    setState(() => _guardando = true);
    final p = TtkParticipanteEntity(
      codEvento: widget.codEvento,
      codEmpleado: e.codEmpleado,
      categoria: _categoria,
    );
    final ok = await ejecutarTtk(
      context,
      () => ref
          .read(ttkTicketsRepositoryProvider)
          .guardarParticipante(p, conCategoria: _categoria != e.categoria),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.codEvento);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final lista = ref.watch(
      ttkEmpleadosEventoProvider((
        codEvento: widget.codEvento,
        buscar: _buscar,
      )),
    );
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: const Text('Agregar empleado'),
      content: SizedBox(
        width: 520,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _buscador,
              autofocus: true,
              onChanged: _alEscribir,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Escribe parte del nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: Esp.s),
            Expanded(
              child: lista.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => MensajeError(error: e, compacto: true),
                data:
                    (empleados) =>
                        empleados.isEmpty
                            ? const MensajeVacio(
                              icono: Icons.person_search,
                              titulo: 'Nadie por agregar',
                              detalle:
                                  'Todos los empleados activos con ese nombre ya están en la lista.',
                            )
                            : ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: empleados.length,
                              itemBuilder: (_, i) {
                                final e = empleados[i];
                                final elegido =
                                    _elegido?.codEmpleado == e.codEmpleado;
                                return ListTile(
                                  selected: elegido,
                                  leading: Icon(
                                    elegido
                                        ? Icons.check_circle
                                        : Icons.person_outline,
                                  ),
                                  title: Text(e.nombreCompleto),
                                  subtitle: Text(
                                    '${ttkOGuion(e.cargo)} · ingreso ${fechaCorta(e.fechaIngreso)}',
                                  ),
                                  trailing: Etiqueta(texto: e.categoriaTexto),
                                  onTap:
                                      () => setState(() {
                                        _elegido = e;
                                        _categoria = e.categoria;
                                      }),
                                );
                              },
                            ),
              ),
            ),
            if (_elegido != null) ...[
              const SizedBox(height: Esp.s),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'E', label: Text('Empleado')),
                  ButtonSegment(value: 'R', label: Text('Reciente')),
                ],
                selected: {_categoria ?? 'E'},
                onSelectionChanged: (s) => setState(() => _categoria = s.first),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Agregar',
          etiquetaOcupado: 'Agregando…',
          ocupado: _guardando,
          onPressed: _elegido == null ? null : _agregar,
        ),
      ],
    );
  }
}

/// Alta o edición de un invitado, con el empleado que lo invita (opcional).
Future<void> editarInvitadoTtk(
  BuildContext context,
  WidgetRef ref, {
  required BigInt codEvento,
  required List<TtkParticipanteEntity> anfitriones,
  TtkParticipanteEntity? invitado,
}) => showDialog<void>(
  context: context,
  builder:
      (_) => _DialogoInvitado(
        codEvento: codEvento,
        anfitriones: anfitriones,
        invitado: invitado,
      ),
);

class _DialogoInvitado extends ConsumerStatefulWidget {
  const _DialogoInvitado({
    required this.codEvento,
    required this.anfitriones,
    this.invitado,
  });

  final BigInt codEvento;
  final List<TtkParticipanteEntity> anfitriones;
  final TtkParticipanteEntity? invitado;

  @override
  ConsumerState<_DialogoInvitado> createState() => _DialogoInvitadoState();
}

class _DialogoInvitadoState extends ConsumerState<_DialogoInvitado> {
  late final _nombre = TextEditingController(
    text: widget.invitado?.nombreInvitado,
  );
  late final _documento = TextEditingController(
    text: widget.invitado?.documento,
  );
  late final _observacion = TextEditingController(
    text: widget.invitado?.observacion,
  );
  late BigInt? _anfitrion = widget.invitado?.codEmpleadoAnfitrion;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final base =
        widget.invitado ??
        TtkParticipanteEntity(codEvento: widget.codEvento, categoria: 'I');
    final p = base.copyWith(
      codEvento: widget.codEvento,
      nombreInvitado: _nombre.text.trim(),
      documento: _documento.text.trim(),
      observacion: _observacion.text.trim(),
      codEmpleadoAnfitrion: _anfitrion,
      quitarAnfitrion: _anfitrion == null,
    );
    final ok = await ejecutarTtk(
      context,
      () => ref
          .read(ttkTicketsRepositoryProvider)
          .guardarParticipante(p, conCategoria: widget.invitado == null),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.codEvento);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final empleados = [
      for (final a in widget.anfitriones)
        if (!a.esInvitado) a,
    ];
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text(
        widget.invitado == null ? 'Agregar invitado' : 'Editar invitado',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                autofocus: widget.invitado == null,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _documento,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Documento (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.m),
              ComboBuscable<BigInt?>(
                etiqueta: 'Lo invita (opcional)',
                valor: _anfitrion,
                opciones: [
                  const DropdownMenuEntry<BigInt?>(value: null, label: 'Nadie'),
                  for (final a in empleados)
                    DropdownMenuEntry<BigInt?>(
                      value: a.codEmpleado,
                      label: a.nombreCompleto,
                    ),
                ],
                onElegir: (v) => setState(() => _anfitrion = v),
              ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _observacion,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Observación',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando…',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

/// Cambia la categoría de un empleado (queda como ajuste manual de RRHH).
Future<void> cambiarCategoriaTtk(
  BuildContext context,
  WidgetRef ref,
  TtkParticipanteEntity p,
) async {
  var categoria = p.categoria ?? 'E';
  final elegir = await showDialog<String>(
    context: context,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setLocal) => AlertDialog(
                title: const Text('Cambiar categoría'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(p.nombreCompleto),
                    const SizedBox(height: Esp.m),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'E', label: Text('Empleado')),
                        ButtonSegment(value: 'R', label: Text('Reciente')),
                      ],
                      selected: {categoria},
                      onSelectionChanged:
                          (s) => setLocal(() => categoria = s.first),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, categoria),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
        ),
  );
  if (elegir == null || !context.mounted) return;
  final ok = await ejecutarTtk(
    context,
    () => ref
        .read(ttkTicketsRepositoryProvider)
        .guardarParticipante(p.copyWith(categoria: elegir)),
  );
  if (ok) refrescarEventoTtk(ref, p.codEvento);
}

/// Las cantidades de vales de una persona por tipo, editables en borrador.
Future<void> editarValesTtk(
  BuildContext context,
  WidgetRef ref,
  TtkParticipanteEntity p,
) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoVales(participante: p),
);

class _DialogoVales extends ConsumerStatefulWidget {
  const _DialogoVales({required this.participante});

  final TtkParticipanteEntity participante;

  @override
  ConsumerState<_DialogoVales> createState() => _DialogoValesState();
}

class _DialogoValesState extends ConsumerState<_DialogoVales> {
  final Map<BigInt, int> _cambios = {};
  bool _guardando = false;

  BigInt get _cod => widget.participante.codParticipante!;

  Future<void> _guardar(List<TtkParticipanteTicketEntity> vales) async {
    setState(() => _guardando = true);
    final repo = ref.read(ttkTicketsRepositoryProvider);
    var ok = true;
    for (final v in vales) {
      final nueva = _cambios[v.codTipoTicket];
      if (nueva == null || nueva == v.cantidad) continue;
      ok = await ejecutarTtk(
        context,
        () => repo.cambiarVale(v.copyWith(cantidad: nueva)),
      );
      if (!ok || !mounted) break;
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.participante.codEvento);
      Navigator.of(context).pop();
    }
  }

  Future<void> _restablecer(TtkParticipanteTicketEntity v) async {
    final ok = await ejecutarTtk(
      context,
      () => ref
          .read(ttkTicketsRepositoryProvider)
          .restablecerVale(_cod, v.codTipoTicket!),
    );
    if (ok && mounted) {
      setState(() => _cambios.remove(v.codTipoTicket));
      refrescarEventoTtk(ref, widget.participante.codEvento);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final asincrono = ref.watch(ttkValesParticipanteProvider(_cod));
    final vales =
        asincrono.valueOrNull ?? const <TtkParticipanteTicketEntity>[];
    final editable = vales.isNotEmpty && vales.first.puedeEditar;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text('Vales de ${widget.participante.nombreCompleto}'),
      content: SizedBox(
        width: 520,
        child: asincrono.when(
          loading:
              () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
          error: (e, _) => MensajeError(error: e, compacto: true),
          data:
              (lista) =>
                  lista.isEmpty
                      ? const MensajeVacio(
                        icono: Icons.confirmation_number_outlined,
                        titulo: 'Sin tipos de vale',
                        detalle:
                            'Agrega tipos de vale al evento para repartirlos.',
                      )
                      : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final v in lista)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Esp.xs,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color:
                                            ttkColorHex(v.colorHex) ??
                                            cs.surfaceContainerHighest,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cs.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Esp.s),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.nombreTipo,
                                            style: context.tituloSeccion(),
                                          ),
                                          Text(
                                            v.cantidadManual
                                                ? 'Ajustado a mano · por defecto ${v.cantidadDefecto}'
                                                : '${v.rangoTexto} · por defecto ${v.cantidadDefecto}',
                                            style: context.apagado(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (editable && v.cantidadManual)
                                      IconButton(
                                        tooltip:
                                            'Volver a la cantidad por defecto',
                                        onPressed:
                                            _guardando
                                                ? null
                                                : () => _restablecer(v),
                                        icon: const Icon(Icons.restart_alt),
                                      ),
                                    _Contador(
                                      valor:
                                          _cambios[v.codTipoTicket] ??
                                          v.cantidad,
                                      habilitado: editable && !_guardando,
                                      alCambiar:
                                          (n) => setState(
                                            () =>
                                                _cambios[v.codTipoTicket!] = n,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: Text(editable ? 'Cancelar' : 'Cerrar'),
        ),
        if (editable)
          BotonAccion(
            etiqueta: 'Guardar',
            etiquetaOcupado: 'Guardando…',
            ocupado: _guardando,
            onPressed: _cambios.isEmpty ? null : () => _guardar(vales),
          ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.habilitado,
    required this.alCambiar,
  });

  final int valor;
  final bool habilitado;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Uno menos',
        onPressed: habilitado && valor > 0 ? () => alCambiar(valor - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$valor',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: ttkFuenteNumeros,
            fontFeatures: cifrasTabulares,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Uno más',
        onPressed: habilitado ? () => alCambiar(valor + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// VALES EN LOTE
// ═══════════════════════════════════════════════════════════════════════════

enum _Alcance { seleccionados, todos, categoria }

/// Un tipo de vale para muchos a la vez: cantidad fija o la de su categoría,
/// para los seleccionados, todos o una categoría. Devuelve si se aplicó.
Future<bool> valesEnLoteTtk(
  BuildContext context, {
  required BigInt codEvento,
  required Set<BigInt> seleccionados,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder:
        (_) => _DialogoLote(codEvento: codEvento, seleccionados: seleccionados),
  );
  return r ?? false;
}

class _DialogoLote extends ConsumerStatefulWidget {
  const _DialogoLote({required this.codEvento, required this.seleccionados});

  final BigInt codEvento;
  final Set<BigInt> seleccionados;

  @override
  ConsumerState<_DialogoLote> createState() => _DialogoLoteState();
}

class _DialogoLoteState extends ConsumerState<_DialogoLote> {
  BigInt? _tipo;
  bool _porDefecto = false;
  int _cantidad = 1;
  late _Alcance _alcance =
      widget.seleccionados.isEmpty ? _Alcance.todos : _Alcance.seleccionados;
  String _categoria = 'E';
  bool _guardando = false;

  Future<void> _aplicar() async {
    final tipo = _tipo;
    if (tipo == null) return;
    setState(() => _guardando = true);
    final ok = await ejecutarTtk(
      context,
      () => ref
          .read(ttkTicketsRepositoryProvider)
          .cambiarValesLote(
            codEvento: widget.codEvento,
            codTipoTicket: tipo,
            cantidad: _porDefecto ? null : _cantidad,
            participantes:
                _alcance == _Alcance.seleccionados
                    ? widget.seleccionados.toList()
                    : null,
            categoria: _alcance == _Alcance.categoria ? _categoria : null,
          ),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarEventoTtk(ref, widget.codEvento);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final tipos =
        ref.watch(ttkTiposProvider(widget.codEvento)).valueOrNull ?? const [];
    final n = widget.seleccionados.length;
    _tipo ??= tipos.isEmpty ? null : tipos.first.codTipoTicket;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: const Text('Vales en lote'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<BigInt>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de vale',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final t in tipos)
                    if (t.codTipoTicket != null)
                      DropdownMenuItem(
                        value: t.codTipoTicket,
                        child: Text(t.nombre, overflow: TextOverflow.ellipsis),
                      ),
                ],
                onChanged: (v) => setState(() => _tipo = v),
              ),
              const SizedBox(height: Esp.l),
              Text('Cantidad por persona', style: context.tituloSeccion()),
              const SizedBox(height: Esp.s),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Misma cantidad')),
                  ButtonSegment(value: true, label: Text('Según categoría')),
                ],
                selected: {_porDefecto},
                onSelectionChanged:
                    (s) => setState(() => _porDefecto = s.first),
              ),
              const SizedBox(height: Esp.s),
              if (_porDefecto)
                Text(
                  'Se deshacen los ajustes a mano: cada persona vuelve a la cantidad que '
                  'le da su categoría (empleado, reciente o invitado).',
                  style: context.apagado(),
                )
              else ...[
                Text(
                  'Todas las personas elegidas reciben esta cantidad de vales de este tipo.',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Contador(
                    valor: _cantidad,
                    habilitado: !_guardando,
                    alCambiar: (v) => setState(() => _cantidad = v),
                  ),
                ),
              ],
              const SizedBox(height: Esp.l),
              Text('A quiénes', style: context.tituloSeccion()),
              const SizedBox(height: Esp.s),
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: [
                  ChoiceChip(
                    label: Text('Los seleccionados ($n)'),
                    selected: _alcance == _Alcance.seleccionados,
                    onSelected:
                        n == 0
                            ? null
                            : (_) => setState(
                              () => _alcance = _Alcance.seleccionados,
                            ),
                  ),
                  ChoiceChip(
                    label: const Text('Toda la lista'),
                    selected: _alcance == _Alcance.todos,
                    onSelected:
                        (_) => setState(() => _alcance = _Alcance.todos),
                  ),
                  ChoiceChip(
                    label: const Text('Una categoría'),
                    selected: _alcance == _Alcance.categoria,
                    onSelected:
                        (_) => setState(() => _alcance = _Alcance.categoria),
                  ),
                ],
              ),
              if (_alcance == _Alcance.categoria) ...[
                const SizedBox(height: Esp.s),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'E', label: Text('Empleados')),
                    ButtonSegment(value: 'R', label: Text('Recientes')),
                    ButtonSegment(value: 'I', label: Text('Invitados')),
                  ],
                  selected: {_categoria},
                  onSelectionChanged:
                      (s) => setState(() => _categoria = s.first),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Aplicar',
          etiquetaOcupado: 'Aplicando…',
          ocupado: _guardando,
          onPressed: _tipo == null ? null : _aplicar,
        ),
      ],
    );
  }
}

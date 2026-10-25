/// Lo que comparten configuración y panel del bingo: el selector de bingo,
/// ver un cartón, asignarlo, imprimir cartones y editar la figura de un juego.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_eventos_dialogos.dart'
    show conEsperaTtk;
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_pdf.dart';

/// Botones de configuración y panel (`tb_vistaBtn.nombreBtn`).
abstract final class BotonTtkBingo {
  static const configurar = 'btnTtkConfigurarBingo';
  static const generar = 'btnTtkGenerarCartones';
  static const asignar = 'btnTtkAsignarCarton';
  static const imprimir = 'btnTtkImprimirCartones';
  static const marcar = 'btnTtkMarcarBolillo';
  static const confirmarGanador = 'btnTtkConfirmarGanador';
}

/// El bingo elegido entre los de la lista; si no hay elección, el primero.
TtkBingoEntity? bingoElegidoTtk(WidgetRef ref, List<TtkBingoEntity> bingos) {
  if (bingos.isEmpty) return null;
  final cod = ref.watch(ttkBingoElegidoProvider);
  for (final b in bingos) {
    if (b.codBingo == cod) return b;
  }
  return bingos.first;
}

/// Vuelve a pedir lo del bingo después de una escritura del encargado.
void refrescarBingoTtk(WidgetRef ref, BigInt codBingo) {
  ref.invalidate(ttkBingosProvider);
  ref.invalidate(ttkJuegosProvider(codBingo));
  ref.invalidate(ttkCartonesProvider);
  ref.invalidate(ttkGanadoresProvider(codBingo));
  ref.invalidate(ttkEmpleadosBingoProvider);
}

/// Lo mismo con el contenedor: sirve aunque el widget que actuó ya se haya
/// desmontado (p. ej. el aviso que se atendió). Si el panel está abierto, lo refresca.
void refrescarBingoEnTtk(ProviderContainer c, BigInt codBingo) {
  c.invalidate(ttkBingosProvider);
  c.invalidate(ttkJuegosProvider(codBingo));
  c.invalidate(ttkCartonesProvider);
  c.invalidate(ttkGanadoresProvider(codBingo));
  c.invalidate(ttkEmpleadosBingoProvider);
  final vivo = ttkVivoEncargadoProvider(codBingo);
  if (c.exists(vivo)) c.read(vivo.notifier).refrescar();
}

/// Combo para elegir el bingo (uno por evento).
class SelectorBingoTtk extends ConsumerWidget {
  const SelectorBingoTtk({super.key, required this.bingos});

  final List<TtkBingoEntity> bingos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = bingoElegidoTtk(ref, bingos);
    return LayoutBuilder(
      builder:
          (context, c) => DropdownMenu<BigInt>(
            key: ValueKey('ttk-selector-${actual?.codBingo}-${bingos.length}'),
            width: c.maxWidth < 480 ? c.maxWidth : 420,
            initialSelection: actual?.codBingo,
            label: const Text('Bingo'),
            leadingIcon: const Icon(Icons.casino_outlined),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            dropdownMenuEntries: [
              for (final b in bingos)
                DropdownMenuEntry(
                  value: b.codBingo!,
                  label: '${b.nombreEvento} · ${fechaCorta(b.fechaEvento)}',
                ),
            ],
            onSelected:
                (v) => ref.read(ttkBingoElegidoProvider.notifier).state = v,
          ),
    );
  }
}

/// Muestra un cartón con todos sus juegos. El encargado ve cualquiera.
Future<void> verCartonTtk(
  BuildContext context, {
  required BigInt codCarton,
  required int nroCarton,
  required bool encargado,
  String? letras,
  String? dueno,
}) => showDialog<void>(
  context: context,
  builder: (ctx) {
    final angosto = MediaQuery.sizeOf(ctx).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.s : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text('Cartón N° ${nroCarton.toString().padLeft(4, '0')}'),
      content: SizedBox(
        width: 920,
        child: Consumer(
          builder: (context, ref, _) {
            final celdas = ref.watch(
              ttkCeldasCartonProvider((
                codCarton: codCarton,
                encargado: encargado,
              )),
            );
            return celdas.when(
              loading:
                  () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (e, _) => MensajeError(error: e, compacto: true),
              data:
                  (lista) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((dueno ?? '').isNotEmpty) ...[
                          Text(
                            dueno!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: Esp.s),
                        ],
                        CartonCompletoTtk(celdas: lista, letras: letras),
                      ],
                    ),
                  ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
      ],
    );
  },
);

/// Arma el PDF de cartones (un cartón por hoja) y lo muestra.
Future<void> imprimirCeldasTtk(
  BuildContext context, {
  required Future<List<TtkBingoCeldaEntity>> Function() celdas,
  required String nombreEvento,
  String? letras,
}) async {
  try {
    final bytes = await conEsperaTtk(
      context,
      'Preparando los cartones…',
      () async {
        final lista = await celdas();
        return lista.isEmpty
            ? null
            : await ttkPdfCartones(
              lista,
              nombreEvento: nombreEvento,
              letras: letras,
            );
      },
    );
    if (!context.mounted) return;
    if (bytes == null) {
      mostrarAviso(
        context,
        'No hay cartones para imprimir con esa selección.',
        tono: TonoAviso.aviso,
      );
      return;
    }
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: 'Cartones · $nombreEvento',
      nombreArchivo: 'cartones.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
  }
}

/// Imprimir cartones por rango de números o por empleado.
Future<void> imprimirCartonesTtk(
  BuildContext context,
  WidgetRef ref,
  TtkBingoEntity bingo,
) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoImprimir(bingo: bingo),
);

class _DialogoImprimir extends ConsumerStatefulWidget {
  const _DialogoImprimir({required this.bingo});

  final TtkBingoEntity bingo;

  @override
  ConsumerState<_DialogoImprimir> createState() => _DialogoImprimirState();
}

class _DialogoImprimirState extends ConsumerState<_DialogoImprimir> {
  bool _porEmpleado = false;
  late final _desde = TextEditingController(text: '1');
  late final _hasta = TextEditingController(
    text: '${widget.bingo.cartonesGenerados}',
  );
  bool _soloAsignados = false;

  /// Con «ambos», de entrada solo los que se entregan impresos.
  late bool _soloImpresos =
      widget.bingo.formaPorCarton && widget.bingo.cartonesImpresos > 0;
  BigInt? _empleado;

  @override
  void dispose() {
    _desde.dispose();
    _hasta.dispose();
    super.dispose();
  }

  void _imprimir() {
    final b = widget.bingo;
    final repo = ref.read(ttkBingoRepositoryProvider);
    final desde = int.tryParse(_desde.text);
    final hasta = int.tryParse(_hasta.text);
    final porEmpleado = _porEmpleado;
    final empleado = _empleado;
    final solo = _soloAsignados;
    final impresos = b.formaPorCarton && _soloImpresos;
    final contexto = Navigator.of(context).context;
    Navigator.of(context).pop();
    imprimirCeldasTtk(
      contexto,
      nombreEvento: b.nombreEvento,
      letras: b.letras,
      celdas:
          () => repo.cartonesParaImprimir(
            b.codBingo!,
            codEmpleado: porEmpleado ? empleado : null,
            nroDesde: porEmpleado ? null : desde,
            nroHasta: porEmpleado ? null : hasta,
            soloAsignados: porEmpleado ? null : solo,
            soloImpresos: porEmpleado || !impresos ? null : true,
          ),
    );
  }

  Widget _numero(TextEditingController c, String rotulo) => Expanded(
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
    final empleados = ref.watch(
      ttkEmpleadosBingoProvider((codBingo: widget.bingo.codBingo!, buscar: '')),
    );
    final conCarton = [
      for (final e in empleados.valueOrNull ?? const [])
        if (e.cartonesAsignados > 0 && e.codEmpleado != null) e,
    ];
    return AlertDialog(
      title: const Text('Imprimir cartones'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Por números'),
                  icon: Icon(Icons.format_list_numbered),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Por empleado'),
                  icon: Icon(Icons.person_outline),
                ),
              ],
              selected: {_porEmpleado},
              onSelectionChanged: (s) => setState(() => _porEmpleado = s.first),
            ),
            const SizedBox(height: Esp.l),
            if (!_porEmpleado) ...[
              Row(
                children: [
                  _numero(_desde, 'Desde el N°'),
                  const SizedBox(width: Esp.s),
                  _numero(_hasta, 'Hasta el N°'),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _soloAsignados,
                onChanged: (v) => setState(() => _soloAsignados = v ?? false),
                title: const Text('Solo los que ya tienen dueño'),
              ),
              if (widget.bingo.formaPorCarton)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _soloImpresos,
                  onChanged: (v) => setState(() => _soloImpresos = v ?? false),
                  title: Text(
                    'Solo los que se entregan impresos (${widget.bingo.cartonesImpresos})',
                  ),
                ),
            ] else
              empleados.isLoading
                  ? const LinearProgressIndicator()
                  : ComboBuscable<BigInt>(
                    etiqueta: 'Empleado',
                    valor: _empleado,
                    opciones: [
                      for (final e in conCarton)
                        DropdownMenuEntry(
                          value: e.codEmpleado!,
                          label: '${e.nombreCompleto} (${e.cartonesAsignados})',
                        ),
                    ],
                    onElegir: (v) => setState(() => _empleado = v),
                  ),
            const SizedBox(height: Esp.s),
            Text(
              'Un cartón por hoja, con todos sus juegos.',
              style: context.apagado(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _porEmpleado && _empleado == null ? null : _imprimir,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Generar PDF'),
        ),
      ],
    );
  }
}

/// Asigna un cartón libre a un empleado (para quien no puede elegirlo solo).
Future<void> asignarCartonTtk(
  BuildContext context,
  WidgetRef ref,
  TtkBingoEntity bingo,
  TtkBingoCartonEntity carton,
) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoAsignar(bingo: bingo, carton: carton),
);

class _DialogoAsignar extends ConsumerStatefulWidget {
  const _DialogoAsignar({required this.bingo, required this.carton});

  final TtkBingoEntity bingo;
  final TtkBingoCartonEntity carton;

  @override
  ConsumerState<_DialogoAsignar> createState() => _DialogoAsignarState();
}

class _DialogoAsignarState extends ConsumerState<_DialogoAsignar> {
  final _buscador = TextEditingController();
  Timer? _espera;
  String _buscar = '';
  bool _guardando = false;

  /// Con «ambos»: quien recibe el cartón del encargado suele jugar en papel.
  bool _impreso = true;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _asignar(TtkEmpleadoBingoEntity e) async {
    setState(() => _guardando = true);
    final ok = await ejecutarTtk(
      context,
      () => ref
          .read(ttkBingoRepositoryProvider)
          .asignarCarton(
            widget.carton.codCarton!,
            codParticipante: e.codParticipante,
            codEmpleado: e.codParticipante == null ? e.codEmpleado : null,
            impreso: widget.bingo.formaPorCarton ? _impreso : null,
          ),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarBingoTtk(ref, widget.bingo.codBingo!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 600;
    final lista = ref.watch(
      ttkEmpleadosBingoProvider((
        codBingo: widget.bingo.codBingo!,
        buscar: _buscar,
      )),
    );
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text('Asignar el cartón N° ${widget.carton.nroCarton}'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.bingo.formaPorCarton) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Impreso'),
                    icon: Icon(Icons.print_outlined),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('En pantalla'),
                    icon: Icon(Icons.smartphone_outlined),
                  ),
                ],
                selected: {_impreso},
                onSelectionChanged: (s) => setState(() => _impreso = s.first),
              ),
              const SizedBox(height: Esp.m),
            ],
            TextField(
              controller: _buscador,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (t) {
                _espera?.cancel();
                _espera = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _buscar = t.trim());
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: Esp.s),
            if (_guardando) const LinearProgressIndicator(),
            Expanded(
              child: lista.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => MensajeError(error: e, compacto: true),
                data:
                    (empleados) =>
                        empleados.isEmpty
                            ? const MensajeVacio(
                              icono: Icons.person_search,
                              titulo: 'Sin coincidencias',
                              detalle: 'Prueba con otra parte del nombre.',
                            )
                            : ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: empleados.length,
                              itemBuilder: (_, i) {
                                final e = empleados[i];
                                return _FilaDueno(
                                  dueno: e,
                                  habilitado: e.puedeRecibir && !_guardando,
                                  alTocar: () => _asignar(e),
                                );
                              },
                            ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Nombre y figura de un juego, con el editor visual de casillas.
Future<void> editarFiguraTtk(
  BuildContext context,
  WidgetRef ref, {
  required TtkBingoEntity bingo,
  required TtkBingoJuegoEntity juego,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoFigura(bingo: bingo, juego: juego),
);

class _DialogoFigura extends ConsumerStatefulWidget {
  const _DialogoFigura({required this.bingo, required this.juego});

  final TtkBingoEntity bingo;
  final TtkBingoJuegoEntity juego;

  @override
  ConsumerState<_DialogoFigura> createState() => _DialogoFiguraState();
}

class _DialogoFiguraState extends ConsumerState<_DialogoFigura> {
  late final _nombre = TextEditingController(text: widget.juego.nombre);
  late String _figura = ttkMascara(
    widget.juego.figura,
    widget.juego.filas * widget.juego.columnas,
  );
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final j = widget.juego.copyWith(
      nombre: _nombre.text.trim(),
      figura: _figura,
    );
    final ok = await ejecutarTtk(
      context,
      () => ref.read(ttkBingoRepositoryProvider).guardarJuego(j),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      refrescarBingoTtk(ref, widget.bingo.codBingo!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.juego;
    final angosto = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: angosto ? Esp.m : Esp.xl,
        vertical: Esp.xl,
      ),
      title: Text('Juego ${j.nroJuego}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre del juego',
                  hintText: 'Por ejemplo, Letra L o Cartón lleno',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.l),
              Text(
                'Toca las casillas que forman la figura',
                style: context.tituloSeccion(),
              ),
              const SizedBox(height: Esp.s),
              EditorFiguraTtk(
                mascara: _figura,
                filas: j.filas,
                columnas: j.columnas,
                conComodin: j.conComodin,
                letras: widget.bingo.letras,
                alCambiar: (m) => setState(() => _figura = m),
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
          etiqueta: 'Guardar figura',
          etiquetaOcupado: 'Guardando…',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

/// Acciones de un cartón para el encargado (ver, asignar, liberar, imprimir).
List<AccionTtk> accionesCartonTtk(
  BuildContext context,
  WidgetRef ref,
  TtkBingoEntity bingo,
  TtkBingoCartonEntity k,
) {
  final repo = ref.read(ttkBingoRepositoryProvider);
  return [
    AccionTtk(
      'Ver cartón',
      Icons.grid_view,
      () => verCartonTtk(
        context,
        codCarton: k.codCarton!,
        nroCarton: k.nroCarton,
        encargado: true,
        letras: bingo.letras,
        dueno: k.nombreEmpleado,
      ),
    ),
    if (k.puedeAsignar)
      AccionTtk(
        'Asignar',
        Icons.person_add_alt,
        () => asignarCartonTtk(context, ref, bingo, k),
        boton: BotonTtkBingo.asignar,
      ),
    if (k.puedeLiberar)
      AccionTtk(
        'Liberar',
        Icons.person_remove_outlined,
        () async {
          final ok = await confirmar(
            context,
            titulo: 'Liberar el cartón',
            detalle:
                'El cartón N° ${k.nroCarton} deja de ser de su dueño actual y otra persona podrá elegirlo.',
            textoConfirmar: 'Liberar',
            destructiva: true,
          );
          if (!ok || !context.mounted) return;
          if (await ejecutarTtk(
            context,
            () => repo.liberarCarton(k.codCarton!),
          )) {
            refrescarBingoTtk(ref, bingo.codBingo!);
          }
        },
        boton: BotonTtkBingo.asignar,
        destructiva: true,
      ),
    if (k.puedeCambiarForma)
      AccionTtk(
        k.impreso ? 'Pasar a pantalla' : 'Pasar a impreso',
        k.impreso ? Icons.smartphone_outlined : Icons.local_printshop_outlined,
        () async {
          if (await ejecutarTtk(
            context,
            () => repo.cambiarFormaCarton(k.codCarton!, impreso: !k.impreso),
          )) {
            refrescarBingoTtk(ref, bingo.codBingo!);
          }
        },
        boton: BotonTtkBingo.asignar,
      ),
    AccionTtk(
      'Imprimir',
      Icons.print_outlined,
      () => imprimirCeldasTtk(
        context,
        nombreEvento: bingo.nombreEvento,
        letras: bingo.letras,
        celdas:
            () => repo.cartonesParaImprimir(
              bingo.codBingo!,
              nroDesde: k.nroCarton,
              nroHasta: k.nroCarton,
            ),
      ),
      boton: BotonTtkBingo.imprimir,
    ),
  ];
}

/// Una persona que puede recibir cartón: categoría (empleado o invitado),
/// vales de bingo y cartones que ya tiene.
class _FilaDueno extends StatelessWidget {
  const _FilaDueno({
    required this.dueno,
    required this.habilitado,
    required this.alTocar,
  });

  final TtkEmpleadoBingoEntity dueno;
  final bool habilitado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = dueno;
    final invitado = e.codEmpleado == null;
    return ListTile(
      enabled: habilitado,
      leading: Icon(invitado ? Icons.person_add_alt : Icons.person_outline),
      title: Text(e.nombreCompleto),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Esp.xs),
        child: Wrap(
          spacing: Esp.xs,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (e.categoriaTexto.isNotEmpty)
              Etiqueta(
                texto: e.categoriaTexto,
                tono: invitado ? TonoEtiqueta.aviso : TonoEtiqueta.neutro,
              ),
            Etiqueta(
              texto: '${e.valesBingo} ${e.valesBingo == 1 ? 'vale' : 'vales'}',
            ),
            Etiqueta(
              texto:
                  '${e.cartonesAsignados} ${e.cartonesAsignados == 1 ? 'cartón' : 'cartones'}',
              tono: e.puedeRecibir ? TonoEtiqueta.neutro : TonoEtiqueta.exito,
            ),
            if ((e.cargo ?? '').isNotEmpty)
              Text(e.cargo!, style: context.apagado()),
          ],
        ),
      ),
      onTap: alTocar,
    );
  }
}

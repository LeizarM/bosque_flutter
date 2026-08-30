import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/constants/talonarios_botones.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/talonarios_comunes.dart';

/// Entrega masiva de talonarios.
///
/// Se aplica una misma cabecera —destinatario, fecha, observación— a todos los
/// talonarios tildados, y se graba **todo o nada**. El wizard viejo lo hacía en
/// un bucle sin transacción y encima reportaba éxito aunque fallaran todos,
/// porque nunca ponía su bandera en `false`.
///
/// **El destinatario es excluyente**: sucursal o empleado, nunca los dos.
/// Verificado sobre las 954 entregas históricas: 546 a empleado, 408 a
/// sucursal, 0 con ambos.
///
/// La lista sale de `listarDisponibles`: solo los que nunca se cerraron y no
/// están en poder de nadie.
class TalonariosEntregaLoteScreen extends ConsumerStatefulWidget {
  const TalonariosEntregaLoteScreen({super.key});

  @override
  ConsumerState<TalonariosEntregaLoteScreen> createState() =>
      _TalonariosEntregaLoteScreenState();
}

enum _TipoDestinatario { empleado, sucursal }

class _TalonariosEntregaLoteScreenState
    extends ConsumerState<TalonariosEntregaLoteScreen> {
  _TipoDestinatario _tipo = _TipoDestinatario.empleado;
  int? _codEmpleado;
  int? _codSucursal;
  DateTime _fechaEvento = DateTime.now();
  final _observacion = TextEditingController();
  String _busqueda = '';

  final Set<BigInt> _seleccionados = <BigInt>{};
  bool _ocupado = false;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  bool get _hayDestinatario =>
      _tipo == _TipoDestinatario.empleado
          ? _codEmpleado != null
          : _codSucursal != null;

  bool get _hayTrabajo => _seleccionados.isNotEmpty || _hayDestinatario;

  String _nombreDestinatario(List<EmpleadoEntity> emps, List<dynamic> sucs) {
    if (_tipo == _TipoDestinatario.empleado) {
      final e = emps.where((x) => x.codEmpleado == _codEmpleado).firstOrNull;
      return e == null
          ? ''
          : nombreEmpleado(e.apPaterno, e.apMaterno, e.nombres);
    }
    final s = sucs.where((x) => x.codSucursal == _codSucursal).firstOrNull;
    return s?.nombre ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = ref.watch(talonariosDisponiblesProvider(null));

    return GuardiaDeSalida(
      hayCambios: _hayTrabajo && !_ocupado,
      mensaje:
          'Tenés ${_seleccionados.length} talonarios tildados. Si salís ahora '
          'se pierde la selección.',
      child: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);

          return Scaffold(
            appBar: AppBar(title: const Text('Asignar talonarios')),
            bottomNavigationBar: _barraInferior(aire),
            body: switch (aire) {
              // En ancho: destinatario a la izquierda, lista a la derecha.
              Aire.amplio => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 400, child: _cabecera(aire)),
                  const VerticalDivider(width: 1),
                  Expanded(child: _lista(disponibles, aire)),
                ],
              ),
              // En medio: apilado, pero con Flexible. **Ese Flexible es el
              // arreglo del overflow**: sin él, el Column le pide al
              // SingleChildScrollView su alto natural (~340 px de cabecera)
              // contra los ~314 px que quedan con el teclado abierto, y pinta
              // la franja amarilla y negra en lugar del formulario.
              Aire.medio => Column(
                children: [
                  Flexible(child: _cabecera(aire)),
                  const Divider(height: 1),
                  Expanded(child: _lista(disponibles, aire)),
                ],
              ),
              // En angosto: la lista se lleva la pantalla y el destinatario
              // vive en una hoja modal. Elimina el problema por construcción
              // justo en el tamaño donde ocurre.
              Aire.justo => Column(
                children: [
                  _resumenDestinatario(),
                  const Divider(height: 1),
                  Expanded(child: _lista(disponibles, aire)),
                ],
              ),
            },
          );
        },
      ),
    );
  }

  // ── Destinatario ──────────────────────────────────────────────────────────

  /// Barra tocable que resume a quién va, para el tamaño angosto.
  Widget _resumenDestinatario() {
    final emps = ref.watch(empleadosListProvider).valueOrNull ?? [];
    final sucs = ref.watch(sucursalesProvider).valueOrNull ?? [];
    final nombre = _nombreDestinatario(emps, sucs);

    return InkWell(
      onTap: _abrirHojaDestinatario,
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Row(
          children: [
            Icon(
              _tipo == _TipoDestinatario.empleado
                  ? Icons.person_outline
                  : Icons.store_outlined,
              size: 20,
              color: context.cs.primary,
            ),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre.isEmpty ? 'Elegí un destinatario' : nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: Peso.titulo,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_fechaEvento),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  void _abrirHojaDestinatario() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(child: _cabecera(Aire.justo)),
          ),
    );
  }

  Widget _cabecera(Aire aire) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Destinatario', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          SegmentedButton<_TipoDestinatario>(
            segments: const [
              ButtonSegment(
                value: _TipoDestinatario.empleado,
                icon: Icon(Icons.person_outline),
                label: Text('Empleado'),
              ),
              ButtonSegment(
                value: _TipoDestinatario.sucursal,
                icon: Icon(Icons.store_outlined),
                label: Text('Sucursal'),
              ),
            ],
            selected: {_tipo},
            onSelectionChanged:
                (s) => setState(() {
                  _tipo = s.first;
                  // Excluyente: cambiar de tipo limpia el otro.
                  _codEmpleado = null;
                  _codSucursal = null;
                }),
          ),
          const SizedBox(height: Esp.m),
          if (_tipo == _TipoDestinatario.empleado)
            _comboEmpleado()
          else
            _comboSucursal(),
          const SizedBox(height: Esp.l),
          CampoFecha(
            etiqueta: 'Fecha de entrega',
            valor: _fechaEvento,
            habilitado: !_ocupado,
            onElegir: (f) => setState(() => _fechaEvento = f),
          ),
          const SizedBox(height: Esp.m),
          TextField(
            controller: _observacion,
            enabled: !_ocupado,
            maxLength: 250,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observación',
              helperText: 'Opcional. Se aplica a todos los tildados.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comboEmpleado() {
    final async = ref.watch(empleadosListProvider);
    return async.when(
      // Un campo deshabilitado del mismo alto, no una barra que reemplaza el
      // campo entero: así la pantalla no salta cuando llega la lista.
      loading: () => const _CampoCargando(etiqueta: 'Empleado'),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(empleadosListProvider),
          ),
      data:
          (lista) => ComboBuscable<int>(
            etiqueta: 'Empleado',
            valor: _codEmpleado,
            opciones:
                lista
                    .map(
                      (e) => DropdownMenuEntry(
                        value: e.codEmpleado,
                        label: nombreEmpleado(
                          e.apPaterno,
                          e.apMaterno,
                          e.nombres,
                        ),
                      ),
                    )
                    .toList(),
            onElegir: (v) => setState(() => _codEmpleado = v),
          ),
    );
  }

  Widget _comboSucursal() {
    final async = ref.watch(sucursalesProvider);
    return async.when(
      loading: () => const _CampoCargando(etiqueta: 'Sucursal'),
      error:
          (e, _) => MensajeError(
            error: e,
            compacto: true,
            onReintentar: () => ref.invalidate(sucursalesProvider),
          ),
      data:
          (lista) => ComboBuscable<int>(
            etiqueta: 'Sucursal',
            valor: _codSucursal,
            opciones:
                lista
                    .map(
                      (s) => DropdownMenuEntry(
                        value: s.codSucursal,
                        label: s.nombre,
                      ),
                    )
                    .toList(),
            onElegir: (v) => setState(() => _codSucursal = v),
          ),
    );
  }

  // ── Lista de disponibles ──────────────────────────────────────────────────

  Widget _lista(AsyncValue<List<TalonarioEntity>> async, Aire aire) {
    return async.when(
      loading: () => const EsqueletoLista(altoFila: 56),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar:
                () => ref.invalidate(talonariosDisponiblesProvider(null)),
          ),
      data: (todos) {
        if (todos.isEmpty) {
          return const MensajeVacio(
            icono: Icons.inbox_outlined,
            titulo: 'No hay talonarios disponibles',
            detalle:
                'Solo aparecen los que nunca se cerraron y no están en poder '
                'de nadie. Devolvé alguno para poder entregarlo de nuevo.',
          );
        }

        final lista =
            _busqueda.isEmpty
                ? todos
                : todos
                    .where(
                      (t) =>
                          t.nroTalonario.toLowerCase().contains(_busqueda) ||
                          t.datoTipo.toLowerCase().contains(_busqueda),
                    )
                    .toList();

        final todosTildados =
            lista.isNotEmpty && _seleccionados.length == lista.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.s),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Buscar talonario',
                  border: OutlineInputBorder(),
                ),
                onChanged:
                    (v) => setState(() => _busqueda = v.trim().toLowerCase()),
              ),
            ),
            // El texto sale del estado vacío y queda siempre visible: explicar
            // qué lista la pantalla solo cuando no hay nada es al revés.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.m),
              child: const NotaDelDato(
                texto:
                    'Solo se listan los talonarios que nunca se cerraron y no '
                    'están en poder de nadie.',
              ),
            ),
            CheckboxListTile(
              value: _seleccionados.isEmpty ? false : (todosTildados ? true : null),
              // Tristate: con selección parcial el checkbox se ve a medias en
              // vez de mentir diciendo "ninguno".
              tristate: true,
              title: Text(
                '${lista.length} disponibles'
                '${_seleccionados.isEmpty ? '' : '  ·  ${_seleccionados.length} tildados'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              secondary:
                  _seleccionados.isEmpty
                      ? null
                      : TextButton(
                        onPressed: () => setState(_seleccionados.clear),
                        child: const Text('Quitar'),
                      ),
              // Con selección parcial el toque AGREGA todo, no borra: antes
              // hacía clear() incondicional y se llevaba puesta la selección
              // sin avisar.
              onChanged:
                  (_) => setState(() {
                    if (todosTildados) {
                      _seleccionados.clear();
                    } else {
                      _seleccionados.addAll(lista.map((t) => t.codTalonario));
                    }
                  }),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: aire.esChico ? Esp.l : Esp.s),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final t = lista[i];
                  return CheckboxListTile(
                    value: _seleccionados.contains(t.codTalonario),
                    enabled: !_ocupado,
                    title: Text(
                      t.nroTalonario,
                      style: TextStyle(
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                      ),
                    ),
                    subtitle: Text(
                      '${t.datoTipo}  ·  folios ${t.numeracionInicial}–${t.numeracionFinal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary:
                        t.estadoActual == 'Devuelto'
                            ? const Tooltip(
                              message: 'Estuvo entregado y fue devuelto',
                              child: Etiqueta(
                                texto: 'Reentrega',
                                tono: TonoEtiqueta.neutro,
                              ),
                            )
                            : null,
                    onChanged:
                        (v) => setState(() {
                          if (v == true) {
                            _seleccionados.add(t.codTalonario);
                          } else {
                            _seleccionados.remove(t.codTalonario);
                          }
                        }),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Barra inferior ────────────────────────────────────────────────────────

  Widget _barraInferior(Aire aire) {
    final falta =
        _seleccionados.isEmpty
            ? 'Tildá al menos un talonario'
            : (!_hayDestinatario ? 'Elegí un destinatario' : null);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La guía va afuera del botón: adentro quedaba pintada en color
            // deshabilitado y fuera del orden de foco de un lector de pantalla.
            if (falta != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.s),
                child: Text(
                  falta,
                  textAlign: TextAlign.center,
                  style: context.apagado(),
                ),
              ),
            PermissionWidget(
              buttonName: TalonariosBotones.editar,
              placeholder: Text(
                'No tenés permiso para asignar talonarios.',
                textAlign: TextAlign.center,
                style: context.apagado(),
              ),
              child: BotonAccion(
                etiqueta: 'Entregar ${_seleccionados.length} talonarios',
                etiquetaOcupado: 'Entregando…',
                icono: Icons.assignment_turned_in,
                ocupado: _ocupado,
                onPressed: falta == null ? _entregar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _entregar() async {
    final emps = ref.read(empleadosListProvider).valueOrNull ?? [];
    final sucs = ref.read(sucursalesProvider).valueOrNull ?? [];
    final nombre = _nombreDestinatario(emps, sucs);

    // Escribe la misma cantidad de filas que el alta y también es todo o nada,
    // pero el alta tiene su previsualización y esto no tenía equivalente.
    final sigue = await confirmar(
      context,
      titulo: 'Entregar ${_seleccionados.length} talonarios',
      detalle:
          'A $nombre, con fecha ${DateFormat('dd/MM/yyyy').format(_fechaEvento)}.\n\n'
          'Se graba todo o nada: si falla uno, no queda ninguno.',
      textoConfirmar: 'Entregar',
    );
    if (!sigue || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final ids = await ref
          .read(talonariosRepositoryProvider)
          .entregarLote(
            codTalonarios: _seleccionados.toList(),
            fechaEvento: _fechaEvento,
            codSucursal:
                _tipo == _TipoDestinatario.sucursal && _codSucursal != null
                    ? BigInt.from(_codSucursal!)
                    : null,
            codEmpleado:
                _tipo == _TipoDestinatario.empleado && _codEmpleado != null
                    ? BigInt.from(_codEmpleado!)
                    : null,
            observacion: _observacion.text,
            audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
          );
      if (!mounted) return;
      refrescarTalonarios(ref);
      mostrarAviso(context, 'Se entregaron ${ids.length} talonarios');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // El backend manda "No se guardó ningún registro. Falló …".
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}

/// Un campo deshabilitado del alto de un combo, para mientras carga.
class _CampoCargando extends StatelessWidget {
  const _CampoCargando({required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) => TextField(
    enabled: false,
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: const Padding(
        padding: EdgeInsets.all(Esp.m),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}

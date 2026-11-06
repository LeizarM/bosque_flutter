import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_asignacion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_asignacion.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// Desde este ancho de lista los asignables y el historial van en tabla.
const double anchoTablaAsignacionHex = 960;

/// Estados del historial para el filtro (nulo = todas).
const Map<String?, String> _estadosAsignacion = {
  null: 'Todas',
  'ACTIVA': 'Asignadas',
  'QUITADA': 'Quitadas',
};

/// `thexAsignacion/Asignar` (D37): el encargado, o el jefe con aprobación
/// directa, elige la jornada, a quiénes asigna horas extra y el motivo (D41,
/// pasa tal cual a sus reportes); ve los avisos antes, quita lo asignado y
/// revisa su historial. El SP decide todo.
class HexAsignacionScreen extends ConsumerStatefulWidget {
  const HexAsignacionScreen({super.key});

  @override
  ConsumerState<HexAsignacionScreen> createState() =>
      _HexAsignacionScreenState();
}

class _HexAsignacionScreenState extends ConsumerState<HexAsignacionScreen>
    with SingleTickerProviderStateMixin {
  static const int _tamano = 20;

  late final TabController _pestanas = TabController(length: 2, vsync: this);
  final ScrollController _desplazamiento = ScrollController();
  final TextEditingController _motivo = TextEditingController();
  final OcupadoHex _escritura = OcupadoHex();

  /// La jornada que se asigna; parte en hoy.
  DateTime _dia = DateUtils.dateOnly(DateTime.now());

  /// Los empleados elegidos para asignar en [_dia].
  final Set<BigInt> _elegidos = {};

  DateTime? _desde;
  DateTime? _hasta;
  String? _estado;
  int _pagina = 1;

  FiltroAsignacionesHex get _filtro => (
    desde: _desde,
    hasta: _hasta,
    estado: _estado,
    pagina: _pagina,
    tamano: _tamano,
  );

  bool get _enAsignar => _pestanas.index == 0;

  @override
  void initState() {
    super.initState();
    _pestanas.addListener(_alCambiarPestana);
  }

  @override
  void dispose() {
    _pestanas
      ..removeListener(_alCambiarPestana)
      ..dispose();
    _desplazamiento.dispose();
    _motivo.dispose();
    _escritura.dispose();
    super.dispose();
  }

  void _alCambiarPestana() {
    setState(() {});
    if (!_pestanas.indexIsChanging) _alInicio();
  }

  void _alInicio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) _desplazamiento.jumpTo(0);
    });
  }

  /// Lo que cambia al asignar o quitar: la lista del día y el historial.
  void _recargar() {
    ref
      ..invalidate(hexAsignablesProvider(_dia))
      ..invalidate(hexHistorialAsignacionProvider);
  }

  void _cambiarDia(DateTime dia) {
    final nuevo = DateUtils.dateOnly(dia);
    if (nuevo == _dia) return;
    HapticaHex.seleccion();
    setState(() {
      _dia = nuevo;
      _elegidos.clear();
    });
  }

  /// D42: el calendario empieza en [primero], la primera jornada que el SP
  /// deja asignar hoy; sin ese dato no se limita (el SP valida igual).
  Future<void> _elegirDia(DateTime? primero) async {
    final d = await pedirDiaHex(
      context,
      inicial: _dia,
      ayuda: 'Jornada',
      primero: primero == null ? null : DateUtils.dateOnly(primero),
    );
    if (d != null && mounted) _cambiarDia(d);
  }

  void _alternar(HexAsignableEntity a) {
    final cod = a.codEmpleado;
    if (cod == null || !a.puedeAsignar || _escritura.value) return;
    HapticaHex.seleccion();
    setState(() {
      if (!_elegidos.remove(cod)) _elegidos.add(cod);
    });
  }

  /// Los elegidos que el SP todavía deja asignar en la lista de ahora.
  List<BigInt> _validos(List<HexAsignableEntity> filas) => [
    for (final a in filas)
      if (a.puedeAsignar &&
          a.codEmpleado != null &&
          _elegidos.contains(a.codEmpleado))
        a.codEmpleado!,
  ];

  /// Todo o nada. Con avisos el SP pide confirmar y se reenvía el mismo
  /// cuerpo con `confirmado`; el mensaje del SP queda en el aviso. El motivo
  /// viaja siempre: si falta, el SP responde con su texto (D41).
  Future<void> _asignar(List<HexAsignableEntity> filas) async {
    final codigos = _validos(filas);
    if (codigos.isEmpty) return;
    final repo = ref.read(hexAsignacionRepositoryProvider);
    final motivo = _motivo.text.trim();
    final dia = _dia;
    final listo = await ejecutarHex(
      context,
      ocupado: _escritura,
      accion:
          (confirmado) => repo.asignar(
            codEmpleados: codigos,
            fechaJornada: dia,
            motivo: motivo,
            confirmado: confirmado,
          ),
      refrescar: _recargar,
    );
    if (listo && mounted) {
      setState(() {
        _elegidos.clear();
        _motivo.clear();
      });
    }
  }

  void _quitar(BigInt? id, String nombre, DateTime? jornada) {
    if (id == null) return;
    quitarAsignacionHex(
      context,
      ref,
      idAsignacion: id,
      nombreEmpleado: nombre,
      fechaJornada: jornada,
      refrescar: _recargar,
    );
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _desplazamiento,
    child: Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
          final anchoLista = c.maxWidth - 2 * relleno;
          final alto = math.max(c.maxHeight - 2 * relleno, hexAltoMinimoLista);
          final abajo = MediaQuery.paddingOf(context).bottom;
          return PaginaDesplazableHex(
            controlador: _desplazamiento,
            relleno: relleno,
            abajo: abajo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoHex(
                  titulo: 'Asignar horas extra',
                  detalle:
                      anchoLista >= hexAnchoTabla
                          ? 'Elige la jornada y a quiénes les asignas horas '
                              'extra. Solo con una asignación pueden marcar y '
                              'reportar.'
                          : null,
                ),
                const SizedBox(height: Esp.m),
                BarraPestanasHex(
                  controlador: _pestanas,
                  anchoMaximo: 420,
                  pestanas: [
                    pestanaHex(
                      icono: Icons.group_add_outlined,
                      texto: 'Asignar',
                    ),
                    pestanaHex(icono: Icons.history, texto: 'Historial'),
                  ],
                ),
                const SizedBox(height: Esp.l),
                if (_enAsignar)
                  _asignacion(anchoLista, alto)
                else
                  _historial(anchoLista, alto),
              ],
            ),
          );
        },
      ),
    ),
  );

  // ═════════════════════════════════════════════════════════════════════════
  // ASIGNAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _asignacion(double anchoLista, double alto) {
    final tabla = usaTablaHex(anchoLista, anchoTablaAsignacionHex);
    final asignables = ref.watch(hexAsignablesProvider(_dia));
    final filas = asignables.valueOrNull ?? const <HexAsignableEntity>[];
    final hoy = DateUtils.dateOnly(DateTime.now());
    final manana = hoy.add(const Duration(days: 1));
    // D42: la primera jornada asignable y el aviso de la regularización son
    // iguales en todas las filas; vienen del SP.
    final primera = filas.isEmpty ? null : filas.first;
    final regularizacion = primera?.textoRegularizacion?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: tabla ? 260 : anchoLista,
              child: CampoSelectorHex(
                etiqueta: 'Jornada',
                valor: fechaHex(_dia),
                icono: Icons.event_outlined,
                alTocar: () => _elegirDia(primera?.fechaMinimaAsignable),
              ),
            ),
            ChoiceChip(
              label: const Text('Hoy'),
              selected: _dia == hoy,
              onSelected: (_) => _cambiarDia(hoy),
            ),
            ChoiceChip(
              label: const Text('Mañana'),
              selected: _dia == manana,
              onSelected: (_) => _cambiarDia(manana),
            ),
          ],
        ),
        if (regularizacion.isNotEmpty) ...[
          const SizedBox(height: Esp.m),
          AvisoHex(
            texto: regularizacion,
            icono: Icons.event_repeat_outlined,
            tono: TonoHex.primario,
          ),
        ],
        const SizedBox(height: Esp.m),
        ValueListenableBuilder<bool>(
          valueListenable: _escritura,
          builder:
              (context, ocupado, _) => _BarraSeleccionHex(
                elegidos: _validos(filas).length,
                disponibles: filas.where((a) => a.puedeAsignar).length,
                ocupado: ocupado,
                compacta: !tabla,
                motivo: _motivo,
                alElegirTodos:
                    () => setState(() {
                      _elegidos.addAll([
                        for (final a in filas)
                          if (a.puedeAsignar && a.codEmpleado != null)
                            a.codEmpleado!,
                      ]);
                    }),
                alLimpiar: () => setState(_elegidos.clear),
                alAsignar: () => _asignar(filas),
              ),
        ),
        const SizedBox(height: Esp.m),
        asignables.when(
          skipLoadingOnReload: true,
          loading:
              () => const SizedBox(
                height: hexAltoEstado,
                child: EsqueletoLista(),
              ),
          error:
              (e, _) => SizedBox(
                height: hexAltoEstado,
                child: vistaErrorHex(
                  e,
                  reintentar: () => ref.invalidate(hexAsignablesProvider(_dia)),
                ),
              ),
          data:
              (lista) => cajaTablaHex(
                tabla: tabla,
                filas: lista.length,
                maximo: alto,
                lista: _listaAsignables(lista, tabla: tabla),
              ),
        ),
      ],
    );
  }

  List<AccionHex> _accionesAsignable(HexAsignableEntity a) => [
    if (a.puedeQuitar)
      AccionHex(
        'Quitar asignación',
        Icons.person_remove_outlined,
        () => _quitar(a.idAsignacion, a.nombreEmpleado, a.fechaJornada ?? _dia),
        destructiva: true,
      ),
  ];

  Widget _casilla(HexAsignableEntity a) {
    final cod = a.codEmpleado;
    return Checkbox(
      value: cod != null && _elegidos.contains(cod),
      onChanged: a.puedeAsignar ? (_) => _alternar(a) : null,
      semanticLabel: 'Elegir a ${a.nombreEmpleado}',
    );
  }

  Widget _listaAsignables(
    List<HexAsignableEntity> filas, {
    required bool tabla,
  }) {
    final t = Theme.of(context).textTheme;
    return ListadoHex<HexAsignableEntity>(
      filas: filas,
      anchoMinimoTabla: anchoTablaAsignacionHex,
      desplazamientoExterno: !tabla,
      alTocarFila: _alternar,
      vacio: const MensajeVacio(
        icono: Icons.group_off_outlined,
        titulo: 'No tienes a quién asignar',
        detalle:
            'Aquí aparecen las personas a las que das el visto bueno o, si '
            'apruebas directo, los encargados a tu cargo.',
      ),
      columnas: [
        BosqueColumn(label: '', flex: 1, cellBuilder: _casilla),
        BosqueColumn(
          label: 'Empleado',
          flex: 6,
          cellBuilder:
              (a) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    oGuionHex(a.nombreEmpleado),
                    style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  if ((a.cargo ?? '').trim().isNotEmpty)
                    Text(a.cargo!.trim(), style: context.apagado()),
                ],
              ),
        ),
        BosqueColumn(
          label: 'Sucursal',
          flex: 3,
          cellBuilder: (a) => Text(oGuionHex(a.nombreSucursal)),
        ),
        BosqueColumn(
          label: 'Estado',
          flex: 5,
          cellBuilder: (a) => _EstadoAsignableHex(a, compacto: true),
        ),
        BosqueColumn(
          label: 'Aviso',
          flex: 5,
          cellBuilder:
              (a) => AvisoAsignacionHex(tipo: a.tipoAviso, aviso: a.aviso),
        ),
        BosqueColumn(
          label: '',
          flex: 1,
          alignment: Alignment.centerRight,
          cellBuilder: (a) => AccionesHex(acciones: _accionesAsignable(a)),
        ),
      ],
      tarjeta:
          (a) => TarjetaHex(
            titulo: oGuionHex(a.nombreEmpleado),
            subtitulo: [
              a.cargo?.trim() ?? '',
              a.nombreSucursal?.trim() ?? '',
            ].where((p) => p.isNotEmpty).join(' · '),
            estado: a.puedeAsignar ? _casilla(a) : null,
            alTocar: a.puedeAsignar ? () => _alternar(a) : null,
            acciones: _accionesAsignable(a),
            contenido: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EstadoAsignableHex(a, compacto: false),
                if ((a.aviso ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  AvisoAsignacionHex(tipo: a.tipoAviso, aviso: a.aviso),
                ],
              ],
            ),
          ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HISTORIAL
  // ═════════════════════════════════════════════════════════════════════════

  void _filtrar(VoidCallback cambio) => setState(() {
    cambio();
    _pagina = 1;
  });

  void _irAPagina(int n) {
    setState(() => _pagina = n);
    _alInicio();
  }

  Widget _historial(double anchoLista, double alto) {
    final tabla = usaTablaHex(anchoLista, anchoTablaAsignacionHex);
    final filtro = _filtro;
    // Los filtros van dentro del listado: en el ancho la tabla toma el alto
    // de la ventana, como en Mis horas.
    Widget lista({PaginaHex<HexAsignacionEntity>? pagina, Widget? vacio}) {
      final listado = _listaHistorial(
        pagina?.filas ?? const <HexAsignacionEntity>[],
        total: pagina?.total ?? 0,
        tabla: tabla,
        vacio: vacio,
        alCambiarPagina: pagina == null ? null : _irAPagina,
      );
      return tabla ? SizedBox(height: alto, child: listado) : listado;
    }

    return ref
        .watch(hexHistorialAsignacionProvider(filtro))
        .when(
          skipLoadingOnReload: true,
          loading: () => lista(vacio: const EsqueletoLista()),
          error:
              (e, _) =>
                  e is SinPermisoHex
                      ? const SizedBox(
                        height: hexAltoEstado,
                        child: SinPermisoHexVista(),
                      )
                      : lista(
                        vacio: vistaErrorHex(
                          e,
                          reintentar:
                              () => ref.invalidate(
                                hexHistorialAsignacionProvider(filtro),
                              ),
                        ),
                      ),
          data: (p) => lista(pagina: p),
        );
  }

  Widget _filtros() => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FiltroRangoHex(
        desde: _desde,
        hasta: _hasta,
        explicacion: 'Las asignaciones cuya jornada cae entre estas fechas.',
        alCambiar:
            (desde, hasta) => _filtrar(() {
              _desde = desde;
              _hasta = hasta;
            }),
      ),
      MenuFiltroHex(
        valor: _estado,
        opciones: _estadosAsignacion,
        alElegir: (v) => _filtrar(() => _estado = v),
      ),
    ],
  );

  List<AccionHex> _accionesAsignacion(HexAsignacionEntity a) => [
    if (a.puedeQuitar)
      AccionHex(
        'Quitar asignación',
        Icons.person_remove_outlined,
        () => _quitar(a.idAsignacion, a.nombreEmpleado, a.fechaJornada),
        destructiva: true,
      ),
  ];

  Widget _listaHistorial(
    List<HexAsignacionEntity> filas, {
    required int total,
    required bool tabla,
    required ValueChanged<int>? alCambiarPagina,
    Widget? vacio,
  }) {
    final t = Theme.of(context).textTheme;
    final cifras = estiloCifrasHex(t.bodyMedium);
    return ListadoHex<HexAsignacionEntity>(
      filas: filas,
      pagina: _pagina,
      total: total,
      tamano: _tamano,
      alCambiarPagina: alCambiarPagina,
      filtros: _filtros(),
      anchoMinimoTabla: anchoTablaAsignacionHex,
      desplazamientoExterno: !tabla,
      vacio:
          vacio ??
          const MensajeVacio(
            icono: Icons.history_toggle_off,
            titulo: 'Sin asignaciones en esas fechas',
            detalle: 'Cambia el rango o el estado para ver otras.',
          ),
      columnas: [
        BosqueColumn(
          label: 'Jornada',
          flex: 2,
          cellBuilder:
              (a) => Text(
                fechaHex(a.fechaJornada),
                style: estiloCifrasHex(t.bodyMedium, fuerte: true),
              ),
        ),
        BosqueColumn(
          label: 'Empleado',
          flex: 4,
          cellBuilder:
              (a) => Text(
                oGuionHex(a.nombreEmpleado),
                style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              ),
        ),
        BosqueColumn(
          label: 'Estado',
          flex: 2,
          cellBuilder:
              (a) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EstadoAsignacionHex(a),
                  // D42: asignada después de su jornada (regularización).
                  if ((a.textoAtrasada ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: Esp.xs),
                    AtrasadaAsignacionHex(a.textoAtrasada),
                  ],
                  // Adenda D37: qué pasó con la asignación activa.
                  if ((a.resultado ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: Esp.xs),
                    ResultadoAsignacionHex(
                      resultado: a.resultado,
                      aviso: a.avisoResultado,
                      compacto: true,
                    ),
                  ],
                ],
              ),
        ),
        BosqueColumn(
          label: 'Asignó',
          flex: 4,
          cellBuilder:
              (a) => _QuienCuandoHex(a.nombreAsignador, a.fechaAsignacion),
        ),
        BosqueColumn(
          label: 'Quitó',
          flex: 4,
          cellBuilder:
              (a) =>
                  a.fechaQuitada == null && (a.nombreQuita ?? '').isEmpty
                      ? Text('—', style: context.apagado())
                      : _QuienCuandoHex(a.nombreQuita, a.fechaQuitada),
        ),
        BosqueColumn(
          label: 'Reportes',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder:
              (a) => Text(enteroHex(a.cantidadReportes), style: cifras),
        ),
        BosqueColumn(
          label: 'Motivo',
          flex: 4,
          cellBuilder:
              (a) => Text(
                oGuionHex(a.motivo),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        BosqueColumn(
          label: '',
          flex: 1,
          alignment: Alignment.centerRight,
          cellBuilder: (a) => AccionesHex(acciones: _accionesAsignacion(a)),
        ),
      ],
      tarjeta:
          (a) => TarjetaHex(
            titulo: oGuionHex(a.nombreEmpleado),
            subtitulo: 'Jornada ${fechaHex(a.fechaJornada)}',
            estado: _EstadoAsignacionHex(a),
            acciones: _accionesAsignacion(a),
            contenido: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignó ${oGuionHex(a.nombreAsignador)} · '
                  '${fechaHoraHex(a.fechaAsignacion)}',
                  style: context.apagado(),
                ),
                if ((a.textoAtrasada ?? '').trim().isNotEmpty)
                  AtrasadaAsignacionHex(a.textoAtrasada),
                if (a.fechaQuitada != null || (a.nombreQuita ?? '').isNotEmpty)
                  Text(
                    'Quitó ${oGuionHex(a.nombreQuita)} · '
                    '${fechaHoraHex(a.fechaQuitada)}',
                    style: context.apagado(),
                  ),
                Text(
                  cuentaHex(a.cantidadReportes, 'reporte', 'reportes'),
                  style: context.apagado(),
                ),
                if ((a.motivo ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  MotivoAsignacionHex(a.motivo!),
                ],
                if ((a.resultado ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Esp.s),
                  ResultadoAsignacionHex(
                    resultado: a.resultado,
                    aviso: a.avisoResultado,
                  ),
                ],
              ],
            ),
          ),
    );
  }
}

/// Cuántos hay elegidos, elegir a todos o limpiar, el motivo (D41: lo valida
/// el SP) y «Asignar horas extra». En el angosto va en columna.
class _BarraSeleccionHex extends StatelessWidget {
  const _BarraSeleccionHex({
    required this.elegidos,
    required this.disponibles,
    required this.ocupado,
    required this.compacta,
    required this.motivo,
    required this.alElegirTodos,
    required this.alLimpiar,
    required this.alAsignar,
  });

  final int elegidos;
  final int disponibles;
  final bool ocupado;
  final bool compacta;
  final TextEditingController motivo;
  final VoidCallback alElegirTodos;
  final VoidCallback alLimpiar;
  final VoidCallback alAsignar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cuenta = Text(
      elegidos == 0
          ? 'Elige a quiénes les asignas horas extra.'
          : cuentaHex(elegidos, 'persona elegida', 'personas elegidas'),
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
    );
    final seleccion = Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed:
              ocupado || disponibles == 0 || elegidos == disponibles
                  ? null
                  : alElegirTodos,
          icon: const Icon(Icons.select_all, size: 18),
          label: const Text('Elegir a todos'),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: ocupado || elegidos == 0 ? null : alLimpiar,
          icon: const Icon(Icons.deselect, size: 18),
          label: const Text('Limpiar'),
        ),
      ],
    );
    final campo = TextField(
      controller: motivo,
      enabled: !ocupado,
      minLines: 1,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Motivo',
        hintText: 'Qué trabajo harán en esas horas',
        helperText: 'Obligatorio. Lo verán tal cual en «Mis horas extra».',
        helperMaxLines: 2,
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
    final asignar = SizedBox(
      height: 48,
      child: BotonAccion(
        etiqueta: 'Asignar horas extra',
        etiquetaOcupado: 'Asignando…',
        icono: Icons.how_to_reg_outlined,
        ocupado: ocupado,
        onPressed: elegidos == 0 || ocupado ? null : alAsignar,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child:
          compacta
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cuenta,
                  seleccion,
                  const SizedBox(height: Esp.s),
                  campo,
                  const SizedBox(height: Esp.m),
                  asignar,
                ],
              )
              : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [cuenta, seleccion],
                    ),
                  ),
                  const SizedBox(width: Esp.l),
                  Expanded(flex: 4, child: campo),
                  const SizedBox(width: Esp.l),
                  asignar,
                ],
              ),
    );
  }
}

/// El estado de un asignable en palabras del SP, su reporte y, si la
/// asignación está activa, su resultado (adenda D37).
class _EstadoAsignableHex extends StatelessWidget {
  const _EstadoAsignableHex(this.a, {required this.compacto});

  final HexAsignableEntity a;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final estado = a.estadoReporte?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              a.estaAsignado
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 18,
              color:
                  a.estaAsignado
                      ? HexColores.de(context).exito
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Esp.xs),
            Flexible(child: Text(oGuionHex(a.textoEstado))),
          ],
        ),
        // D42: asignada después de su jornada (regularización).
        if ((a.textoAtrasada ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: Esp.xs),
          AtrasadaAsignacionHex(a.textoAtrasada),
        ],
        // D41: el motivo de la asignación, como lo verá el operario.
        if (a.estaAsignado && (a.motivo ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: Esp.xs),
          MotivoAsignacionHex(a.motivo!, lineas: compacto ? 2 : null),
        ],
        if (estado.isNotEmpty) ...[
          const SizedBox(height: Esp.xs),
          EtiquetaEstadoHex(estado, a.estadoReporteTexto ?? ''),
        ],
        if ((a.resultado ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: Esp.xs),
          ResultadoAsignacionHex(
            resultado: a.resultado,
            aviso: a.avisoResultado,
            compacto: compacto,
          ),
        ],
      ],
    );
  }
}

/// «Asignada» o «Quitada», como lo manda el SP.
class _EstadoAsignacionHex extends StatelessWidget {
  const _EstadoAsignacionHex(this.a);

  final HexAsignacionEntity a;

  @override
  Widget build(BuildContext context) {
    final activa = a.estado == 'ACTIVA';
    return ChipHex(
      texto: a.estadoTexto.trim().isEmpty ? a.estado : a.estadoTexto,
      icono: activa ? Icons.check_circle_outline : Icons.remove_circle_outline,
      tono: activa ? TonoHex.exito : TonoHex.neutro,
    );
  }
}

/// Quién y cuándo, en dos renglones.
class _QuienCuandoHex extends StatelessWidget {
  const _QuienCuandoHex(this.nombre, this.fecha);

  final String? nombre;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(oGuionHex(nombre)),
      Text(fechaHoraHex(fecha), style: estiloCifrasHex(context.apagado())),
    ],
  );
}

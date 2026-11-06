import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formularios_parametros.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_mapa_tramos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_simulador.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_vigencias.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// `thexParametros/Parametros`: los valores que deciden cuánto se paga
/// (parámetros, tramos y comidas) con sus vigencias (D33), el historial de
/// cada pestaña (D22) y el simulador de una jornada, que no guarda nada.
class HexParametrosScreen extends ConsumerStatefulWidget {
  const HexParametrosScreen({super.key});

  @override
  ConsumerState<HexParametrosScreen> createState() =>
      _HexParametrosScreenState();
}

class _HexParametrosScreenState extends ConsumerState<HexParametrosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 4, vsync: this);
  final ScrollController _desplazamiento = ScrollController();

  /// Una eliminación en curso: deshabilita las acciones y el «atrás».
  final OcupadoHex _eliminando = OcupadoHex();

  @override
  void initState() {
    super.initState();
    _pestanas.addListener(_alCambiarPestana);
    _eliminando.addListener(_alCambiarEliminando);
  }

  @override
  void dispose() {
    _pestanas
      ..removeListener(_alCambiarPestana)
      ..dispose();
    _eliminando
      ..removeListener(_alCambiarEliminando)
      ..dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alCambiarEliminando() {
    if (mounted) setState(() {});
  }

  /// Al cambiar de pestaña, la pantalla vuelve arriba.
  void _alCambiarPestana() {
    setState(() {});
    if (_pestanas.indexIsChanging) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) _desplazamiento.jumpTo(0);
    });
  }

  /// La entidad del historial; el simulador no tiene historial.
  String? get _entidad => switch (_pestanas.index) {
    0 => EntidadConfiguracionHex.parametro,
    1 => EntidadConfiguracionHex.tramo,
    2 => EntidadConfiguracionHex.comida,
    _ => null,
  };

  /// Se lee al tocar, no al dibujar.
  HexConfiguracionRepository get _repo =>
      ref.read(hexConfiguracionRepositoryProvider);

  /// Tras escribir: la lista de la pestaña y el historial, donde el cambio
  /// cae en la primera página.
  void _refrescar(ProviderOrFamily lista) {
    ref
      ..invalidate(lista)
      ..invalidate(hexHistorialConfiguracionProvider);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═════════════════════════════════════════════════════════════════════════

  /// Con una eliminación en curso la acción queda deshabilitada.
  VoidCallback? _libre(VoidCallback abrir) => _eliminando.value ? null : abrir;

  /// Las acciones de una vigencia, todas con el botón de editar (también
  /// eliminar, por contrato). Si se puede eliminar lo decide el SP; [extras]
  /// van antes de eliminar.
  List<AccionHex> _acciones({
    required VoidCallback nueva,
    required List<(String, VoidCallback)> leyendas,
    required VoidCallback eliminar,
    List<AccionHex> extras = const [],
  }) => [
    AccionHex(
      'Nueva vigencia',
      Icons.event_repeat,
      _libre(nueva),
      boton: BotonHex.editarParametro,
    ),
    for (final (etiqueta, abrir) in leyendas)
      AccionHex(
        etiqueta,
        Icons.edit_note,
        _libre(abrir),
        boton: BotonHex.editarParametro,
      ),
    ...extras,
    AccionHex(
      'Eliminar',
      Icons.delete_outline,
      _libre(eliminar),
      boton: BotonHex.editarParametro,
      destructiva: true,
    ),
  ];

  void _eliminar({
    required String codigo,
    required DateTime? desde,
    required Future<HexRespuesta> Function() eliminar,
    required VoidCallback refrescar,
  }) => eliminarVigenciaHex(
    context,
    ocupado: _eliminando,
    codigo: codigo,
    desde: desde,
    eliminar: eliminar,
    refrescar: refrescar,
  );

  /// Tras escribir un tramo también cambia el mapa del día.
  void _refrescarTramos() {
    _refrescar(hexTramosProvider);
    ref.invalidate(hexTramoMapaProvider);
  }

  /// Tras escribir un parámetro también cambia el aviso de obligatorios.
  void _refrescarParametros() {
    _refrescar(hexParametrosProvider);
    ref.invalidate(hexParametroCatalogoProvider);
  }

  /// «Dejar de usar desde…» solo si el SP lo permite en esa fila.
  List<AccionHex> _accionesParametro(HexParametroEntity p) {
    final id = p.idParametro;
    if (id == null) return const [];
    void refrescar() => _refrescarParametros();
    return _acciones(
      extras: [
        if (p.puedeDejarDeUsar)
          AccionHex(
            'Dejar de usar desde…',
            Icons.event_busy,
            _libre(
              () => dejarDeUsarParametroHex(
                context,
                ref,
                p,
                refrescar: refrescar,
              ),
            ),
            boton: BotonHex.editarParametro,
          ),
      ],
      // Con el catálogo, la empresa del organigrama se elige por su nombre.
      nueva:
          () => vigenciaParametroHex(
            context,
            ref,
            p,
            refrescar: refrescar,
            catalogo:
                ref.read(hexParametroCatalogoProvider).valueOrNull ?? const [],
          ),
      leyendas: [
        (
          'Editar leyenda',
          () => editarLeyendaHex(
            context,
            codigo: p.clave,
            leyenda: p.leyenda,
            guardar: (l) => _repo.editarLeyendaParametro(id, l),
            refrescar: refrescar,
          ),
        ),
      ],
      eliminar:
          () => _eliminar(
            codigo: p.clave,
            desde: p.vigenteDesde,
            eliminar: () => _repo.eliminarParametro(id),
            refrescar: refrescar,
          ),
    );
  }

  List<AccionHex> _accionesTramo(HexTramoEntity t) {
    final id = t.idTramo;
    if (id == null) return const [];
    void refrescar() => _refrescarTramos();
    return _acciones(
      nueva: () => vigenciaTramoHex(context, ref, t, refrescar: refrescar),
      leyendas: [
        (
          'Editar leyenda',
          () => editarLeyendaHex(
            context,
            codigo: t.codigo,
            leyenda: t.leyenda,
            guardar: (l) => _repo.editarLeyendaTramo(id, l),
            refrescar: refrescar,
          ),
        ),
      ],
      eliminar:
          () => _eliminar(
            codigo: t.codigo,
            desde: t.vigenteDesde,
            eliminar: () => _repo.eliminarTramo(id),
            refrescar: refrescar,
          ),
    );
  }

  /// La leyenda simple y la doble se editan por separado: el cuerpo lleva
  /// solo la que cambia.
  List<AccionHex> _accionesComida(HexComidaEntity c) {
    final id = c.idComida;
    if (id == null) return const [];
    void refrescar() => _refrescar(hexComidasProvider);
    return _acciones(
      nueva: () => vigenciaComidaHex(context, ref, c, refrescar: refrescar),
      leyendas: [
        (
          'Editar leyenda',
          () => editarLeyendaHex(
            context,
            codigo: c.codigo,
            leyenda: c.leyenda,
            guardar: (l) => _repo.editarLeyendaComida(id, leyenda: l),
            refrescar: refrescar,
          ),
        ),
        (
          'Editar leyenda doble',
          () => editarLeyendaHex(
            context,
            codigo: c.codigoDoble,
            leyenda: c.leyendaDoble,
            etiqueta: 'Leyenda doble',
            guardar: (l) => _repo.editarLeyendaComida(id, leyendaDoble: l),
            refrescar: refrescar,
          ),
        ),
      ],
      eliminar:
          () => _eliminar(
            codigo: c.codigo,
            desde: c.vigenteDesde,
            eliminar: () => _repo.eliminarComida(id),
            refrescar: refrescar,
          ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PANTALLA
  // ═════════════════════════════════════════════════════════════════════════

  /// Un solo desplazamiento para la pantalla; en el ancho las tablas van en
  /// cajas con el alto de sus filas, hasta el de la ventana.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_eliminando.value,
    child: PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
            final anchoLista = c.maxWidth - 2 * relleno;
            final alto = math.max(
              c.maxHeight - 2 * relleno,
              hexAltoMinimoLista,
            );
            final abajo = MediaQuery.paddingOf(context).bottom;
            final entidad = _entidad;
            return PaginaDesplazableHex(
              controlador: _desplazamiento,
              relleno: relleno,
              abajo: abajo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EncabezadoHex(titulo: 'Parámetros del cálculo'),
                  const SizedBox(height: Esp.m),
                  const NotaVigenciaHex(),
                  const SizedBox(height: Esp.m),
                  _barraPestanas(),
                  const SizedBox(height: Esp.l),
                  switch (_pestanas.index) {
                    0 => _parametros(anchoLista, alto),
                    1 => _tramos(anchoLista, alto),
                    2 => _comidas(anchoLista, alto),
                    _ => const SimuladorJornadaHex(),
                  },
                  if (entidad != null) ...[
                    const SizedBox(height: Esp.xxl),
                    HistorialConfiguracionHex(
                      key: ValueKey(entidad),
                      entidad: entidad,
                      altoMaximo: alto,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  /// Las cuatro pestañas, cada una con su ícono; no se desplazan de lado.
  Widget _barraPestanas() => BarraPestanasHex(
    controlador: _pestanas,
    anchoMaximo: 680,
    pestanas: [
      pestanaHex(icono: Icons.tune, texto: 'Parámetros'),
      pestanaHex(icono: Icons.schedule, texto: 'Tramos'),
      pestanaHex(icono: Icons.restaurant_outlined, texto: 'Comidas'),
      pestanaHex(icono: Icons.science_outlined, texto: 'Simulador'),
    ],
  );

  /// Una pestaña: qué es, su acción (si tiene), un [aviso] y la lista con
  /// sus estados.
  Widget _seccion<T>({
    required String explicacion,
    required AsyncValue<List<T>> valor,
    required ProviderOrFamily proveedor,
    required Widget Function(List<T> filas) lista,
    Widget? accion,
    Widget? aviso,
  }) {
    Widget enCaja(Widget hijo) => SizedBox(height: hexAltoEstado, child: hijo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.l,
          runSpacing: Esp.s,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(explicacion, style: context.apagado()),
            if (accion != null) accion,
          ],
        ),
        const SizedBox(height: Esp.m),
        if (aviso != null) ...[aviso, const SizedBox(height: Esp.m)],
        valor.when(
          skipLoadingOnReload: true,
          loading: () => enCaja(const EsqueletoLista()),
          error:
              (e, _) => enCaja(
                vistaErrorHex(e, reintentar: () => ref.invalidate(proveedor)),
              ),
          data: lista,
        ),
      ],
    );
  }

  /// Los avisos del catálogo (obligatorios sin valor vigente), en rojo. Si el
  /// catálogo no carga, la lista sigue igual sin aviso.
  Widget? _avisosObligatorios() {
    final avisos = [
      for (final c
          in ref.watch(hexParametroCatalogoProvider).valueOrNull ?? const [])
        if (textoUsableHex(c.aviso) case final aviso?) aviso,
    ];
    if (avisos.isEmpty) return null;
    return AvisoHex(
      tono: TonoHex.error,
      icono: Icons.error_outline,
      titulo:
          avisos.length == 1
              ? 'Falta un parámetro obligatorio'
              : 'Faltan parámetros obligatorios',
      texto: avisos.join('\n'),
    );
  }

  /// El botón de alta de una pestaña, con el permiso de editar parámetros.
  Widget _botonNuevo(String texto, IconData icono, VoidCallback? abrir) =>
      PermissionWidget(
        buttonName: BotonHex.editarParametro,
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: abrir == null ? null : _libre(abrir),
          icon: Icon(icono, size: 18),
          label: Text(texto),
        ),
      );

  Widget _parametros(double anchoLista, double alto) {
    final tabla = usaTablaHex(anchoLista, anchoTablaParametrosHex);
    // Las claves salen del catálogo del SP: sin catálogo no hay qué elegir.
    final catalogo =
        ref.watch(hexParametroCatalogoProvider).valueOrNull ?? const [];
    return _seccion<HexParametroEntity>(
      explicacion:
          'Divisor del costo hora, minutos mínimos y de alerta, y fechas del '
          'módulo.',
      valor: ref.watch(hexParametrosProvider),
      proveedor: hexParametrosProvider,
      accion: _botonNuevo(
        'Nuevo parámetro',
        Icons.add_circle_outline,
        catalogo.isEmpty
            ? null
            : () => nuevoParametroHex(
              context,
              ref,
              catalogo,
              refrescar: _refrescarParametros,
            ),
      ),
      aviso: _avisosObligatorios(),
      lista:
          (filas) => ListaVigenciasHex<HexParametroEntity>(
            filas: filas,
            clave: (p) => p.clave,
            franja:
                (g) => (
                  titulo: nombreGrupoParametroHex(g),
                  detalle: cuentaHex(g.length, 'vigencia', 'vigencias'),
                  codigo: g.first.clave,
                  familia: null,
                ),
            etiquetasFranja: etiquetasGrupoParametroHex,
            pieFranja: explicacionGrupoParametroHex,
            altoFila: altoFilaParametroHex,
            tabla: tabla,
            anchoMinimoTabla: anchoTablaParametrosHex,
            altoMaximo: alto,
            columnas: columnasParametrosHex(
              context,
              acciones: _accionesParametro,
            ),
            tarjeta:
                (p) => TarjetaParametroHex(p, acciones: _accionesParametro(p)),
            vacio: const MensajeVacio(
              icono: Icons.tune,
              titulo: 'No hay parámetros',
              detalle: 'Agrega el primero con «Nuevo parámetro».',
            ),
          ),
    );
  }

  /// El día 00–24 h de cada tipo de día; si no carga, la lista sigue.
  Widget _mapaTramos() => ref
      .watch(hexTramoMapaProvider)
      .when(
        skipLoadingOnReload: true,
        loading: () => const LinearProgressIndicator(),
        error:
            (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvisoHex(
                  tono: TonoHex.error,
                  icono: Icons.error_outline,
                  titulo: 'No se pudo cargar el mapa del día',
                  texto: textoErrorHex(e),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(hexTramoMapaProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
        data: MapaTramosHex.new,
      );

  Widget _tramos(double anchoLista, double alto) {
    final tabla = usaTablaHex(anchoLista, anchoTablaTramosHex);
    void refrescar() => _refrescarTramos();
    return _seccion<HexTramoEntity>(
      explicacion:
          'Rangos de hora con su factor por tipo de día. Un fin a las 00:00 '
          'son las 24:00.',
      valor: ref.watch(hexTramosProvider),
      proveedor: hexTramosProvider,
      accion: _botonNuevo(
        'Nuevo tramo',
        Icons.add_alarm_outlined,
        () => vigenciaTramoHex(context, ref, null, refrescar: refrescar),
      ),
      aviso: _mapaTramos(),
      lista:
          (filas) => ListaVigenciasHex<HexTramoEntity>(
            filas: filas,
            clave: claveTramoHex,
            franja:
                (g) => (
                  titulo: leyendaGrupoHex(
                    g,
                    leyenda: (t) => t.leyenda,
                    vigente:
                        (t) => t.estadoVigencia == 'VIGENTE' || t.esVigente,
                    clave: claveTramoHex(g.first),
                  ),
                  detalle:
                      '${tipoDiaHex(g.first.tipoDia)} · '
                      '${cuentaHex(g.length, 'vigencia', 'vigencias')}',
                  codigo: g.first.codigo,
                  familia: FamiliaCodigoHex.tramo,
                ),
            tabla: tabla,
            anchoMinimoTabla: anchoTablaTramosHex,
            altoMaximo: alto,
            columnas: columnasTramosHex(context, acciones: _accionesTramo),
            tarjeta: (t) => TarjetaTramoHex(t, acciones: _accionesTramo(t)),
            vacio: const MensajeVacio(
              icono: Icons.schedule,
              titulo: 'No hay tramos',
              detalle: 'Agrega el primero con «Nuevo tramo».',
            ),
          ),
    );
  }

  Widget _comidas(double anchoLista, double alto) {
    final tabla = usaTablaHex(anchoLista, anchoTablaComidasHex);
    void refrescar() => _refrescar(hexComidasProvider);
    return _seccion<HexComidaEntity>(
      explicacion: 'Monto de cada comida y el horario en que se gana.',
      valor: ref.watch(hexComidasProvider),
      proveedor: hexComidasProvider,
      accion: _botonNuevo(
        'Nueva comida',
        Icons.add_circle_outline,
        () => vigenciaComidaHex(context, ref, null, refrescar: refrescar),
      ),
      lista:
          (filas) => ListaVigenciasHex<HexComidaEntity>(
            filas: filas,
            clave: (c) => c.codigo,
            franja:
                (g) => (
                  titulo: leyendaGrupoHex(
                    g,
                    leyenda: (c) => c.leyenda,
                    vigente:
                        (c) => c.estadoVigencia == 'VIGENTE' || c.esVigente,
                    clave: g.first.codigo,
                  ),
                  detalle: cuentaHex(g.length, 'vigencia', 'vigencias'),
                  codigo: g.first.codigo,
                  familia: FamiliaCodigoHex.comida,
                ),
            tabla: tabla,
            anchoMinimoTabla: anchoTablaComidasHex,
            altoMaximo: alto,
            columnas: columnasComidasHex(context, acciones: _accionesComida),
            tarjeta: (c) => TarjetaComidaHex(c, acciones: _accionesComida(c)),
            vacio: const MensajeVacio(
              icono: Icons.restaurant_outlined,
              titulo: 'No hay comidas',
              detalle: 'Agrega la primera con «Nueva comida».',
            ),
          ),
    );
  }
}

/// Propuestas de precios: el listado con su circuito de autorizacion.
///
/// Es la pantalla principal del modulo y reemplaza la tabla `dtAutorizacion` de
/// `tprAutorizacion/Autorizacion.xhtml`. Lo que cambia respecto de aquella:
///
/// - **El estado se ve de un vistazo.** Antes era una columna de texto con un
///   `style` inline que pintaba verde y rojo fijos, ilegibles en modo oscuro.
///   Aca es un chip cuyo color sale del tema y cubre los CUATRO estados del
///   dominio, incluido En Espera, que el XHTML tenia que agregar a mano al
///   combo porque el catalogo del backend lo trae comentado.
/// - **Se puede buscar y filtrar por estado.** La grilla anterior mostraba las
///   ultimas cien propuestas y habia que recorrerlas a ojo.
/// - **Aprobar pide una confirmacion que dice que va a pasar.** En el sistema
///   anterior aprobar era elegir una opcion en un radio dentro de un panel
///   flotante: un toque, sin aviso, sobre la escritura que cambia los precios
///   de venta de toda la empresa.
/// - **Los botones que no corresponden dicen por que**, en vez de desaparecer.
///
/// **De donde sale el estado.** El listado llega como DTO de despliegue —un
/// mapa— y [PropuestaEnAutorizacion] lo parte en sus dos entities. Todo lo que
/// la pantalla decide sobre el circuito lo decide con
/// `AutorizacionPrecioEntity` y sus getters (`esPendiente`, `estaAprobada`,
/// `fueRechazada`, `estaEnEspera`), nunca comparando cadenas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/screens/precios/armado_propuesta_screen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogos_propuesta.dart';
import 'package:bosque_flutter/presentation/widgets/precios/generacion_propuesta.dart';
import 'package:bosque_flutter/presentation/widgets/precios/pdf_precios.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Los botones de `tb_vistaBtn` que gobiernan el circuito. Son los mismos
/// nombres que consultaba `wProductoNew.esAutorizado(...)`, asi que no hay que
/// dar de alta ningun permiso nuevo.
const String _btnAprobar = 'btnAprobar';
const String _btnEnEspera = 'btnPen';
const String _btnGenerar = 'btnGen';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO LOCAL DE LA PANTALLA
//
// Viven aqui y no en `precios_provider.dart` a proposito: son de esta grilla y
// de ninguna otra del modulo. Son autoDispose, asi que al salir se reinician y
// una visita no le deja la pagina 4 a la siguiente.
// ═══════════════════════════════════════════════════════════════════════════

/// Pagina visible de la planilla de escritorio, base cero.
final _paginaProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Cuantas filas por pagina. En el telefono no se usa: ahi la lista es una
/// sola y se recorre con el pulgar, que es mas rapido que tocar un paginador.
final _filasPorPaginaProvider = StateProvider.autoDispose<int>((ref) => 25);

const List<int> _opcionesDeFilas = [25, 50, 100];

// ═══════════════════════════════════════════════════════════════════════════
// LA PANTALLA
// ═══════════════════════════════════════════════════════════════════════════

class PropuestasScreen extends ConsumerStatefulWidget {
  const PropuestasScreen({super.key});

  @override
  ConsumerState<PropuestasScreen> createState() => _PropuestasScreenState();
}

class _PropuestasScreenState extends ConsumerState<PropuestasScreen> {
  final _buscarCtrl = TextEditingController();

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // ── Escrituras del circuito ───────────────────────────────────────────────

  /// Corre una escritura del circuito y cuenta como fue.
  ///
  /// El notifier ya invalida las lecturas que su escritura deja viejas -la
  /// grilla se refresca sola-, asi que aca solo queda el aviso. El mensaje de
  /// error es el del procedimiento, que viene listo para mostrar: traducirlo
  /// seria perder la unica explicacion que el usuario puede llevarle a quien
  /// administra el sistema.
  Future<void> _ejecutar(
    Future<bool> Function() accion, {
    required String exito,
  }) async {
    final notifier = ref.read(propuestaProvider.notifier);
    final ok = await accion();
    if (!mounted) return;

    if (ok) {
      avisar(context, exito);
      return;
    }
    avisar(
      context,
      ref.read(propuestaProvider).error ??
          'No se pudo completar la operación. Intente de nuevo.',
      esError: true,
    );
    notifier.limpiarError();
  }

  /// Aprobar: la escritura mas sensible del modulo. La confirmacion explicita
  /// esta en [confirmarAprobacion], que ademas de preguntar explica el alcance.
  Future<void> _aprobar(PropuestaEnAutorizacion fila) async {
    if (!await confirmarAprobacion(context, fila)) return;
    if (!mounted) return;
    await _ejecutar(
      () => ref
          .read(propuestaProvider.notifier)
          .resolverPropuesta(idPropuesta: fila.idPropuesta, esAprobada: 1),
      exito:
          fila.propuesta.tipo == 2
              ? 'Propuesta ${fila.numero} aprobada. Sus artículos quedaron '
                  'registrados con los precios de su familia.'
              : 'Propuesta ${fila.numero} aprobada. Los precios propuestos ya '
                  'son los vigentes.',
    );
  }

  Future<void> _rechazar(PropuestaEnAutorizacion fila) async {
    if (!await confirmarRechazo(context, fila)) return;
    if (!mounted) return;
    await _ejecutar(
      () => ref
          .read(propuestaProvider.notifier)
          .resolverPropuesta(idPropuesta: fila.idPropuesta, esAprobada: 2),
      exito: 'Propuesta ${fila.numero} rechazada. Ningún precio cambió.',
    );
  }

  Future<void> _enviarAEspera(PropuestaEnAutorizacion fila) async {
    if (!await confirmarEnviarAEspera(context, fila)) return;
    if (!mounted) return;
    await _ejecutar(
      () =>
          ref.read(propuestaProvider.notifier).marcarEnEspera(fila.idPropuesta),
      exito: 'Propuesta ${fila.numero} enviada a autorizar.',
    );
  }

  /// El "Generar" del sistema anterior: baja CambioDePrecios.xlsx y deja
  /// constancia de quien lo genero.
  Future<void> _generar(PropuestaEnAutorizacion fila) async {
    if (!await confirmarGeneracion(context, fila)) return;
    if (!mounted) return;
    await generarPropuesta(context, ref, fila);
  }

  void _ver(PropuestaEnAutorizacion fila) =>
      abrirDetallePropuesta(context, fila: fila);

  /// El "Exportar" del sistema anterior, para cualquier propuesta.
  void _pdf(PropuestaEnAutorizacion fila) =>
      verPdfDePropuesta(context, ref, fila);

  /// El "Editar" del sistema anterior: seguir armando una propuesta
  /// pendiente. Abre el mismo asistente que "Nueva propuesta", parado en el
  /// paso de familias o articulos; la vista preliminar y el envio a autorizar
  /// estan en su ultimo paso.
  void _editar(PropuestaEnAutorizacion fila) =>
      abrirArmadoExistente(context, fila);

  void _nueva() => abrirArmadoNuevo(context);

  // ── Dibujo ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final propuestas = ref.watch(propuestasParaAutorizarProvider);
    final busqueda = ref.watch(filtroBusquedaPrecioProvider);
    final estado = ref.watch(filtroEstadoPropuestaProvider);

    // Se observa el provider de permisos -tienePermisoDeBoton hace ref.watch-
    // porque llegan por red despues del primer dibujo: con una lectura suelta
    // la grilla se quedaba con los botones del estado inicial.
    final permisos = ref.watch(buttonPermissionsProvider);
    final tieneBtnAprobar = tienePermisoDeBoton(ref, _btnAprobar);
    final tieneBtnPen = tienePermisoDeBoton(ref, _btnEnEspera);
    final tieneBtnGen = tienePermisoDeBoton(ref, _btnGenerar);

    // Una sola escritura del circuito a la vez, sea cual sea la fila: el
    // notifier es uno solo y dos aprobaciones en vuelo dejan la grilla
    // contando una historia que no paso.
    final ocupado = ref.watch(propuestaProvider.select((e) => e.cargando));

    final manejadores = ManejadoresPropuesta(
      ver: _ver,
      pdf: _pdf,
      editar: _editar,
      aprobar: _aprobar,
      rechazar: _rechazar,
      enviarAEspera: _enviarAEspera,
      generar: _generar,
    );

    // El ancho del CAJON, no el de la ventana: adentro del dashboard el menu
    // lateral se come su parte y MediaQuery contaria ese espacio como
    // disponible. Se mide afuera del Scaffold porque el boton flotante del
    // telefono tambien depende de el.
    return LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);

        return Scaffold(
          // En el telefono la accion principal va abajo, al alcance del
          // pulgar; en pantallas anchas, en la cabecera.
          floatingActionButton:
              aire.esChico
                  ? FloatingActionButton.extended(
                    onPressed: _nueva,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva propuesta'),
                  )
                  : null,
          body: propuestas.when(
            loading:
                () => Column(
                  children: [
                    _Cabecera(
                      aire: aire,
                      total: 0,
                      enEspera: 0,
                      cargando: true,
                      onRecargar: _recargar,
                      onNueva: _nueva,
                    ),
                    const Expanded(child: EsqueletoLista(altoFila: 64)),
                  ],
                ),
            error:
                (e, _) => Column(
                  children: [
                    _Cabecera(
                      aire: aire,
                      total: 0,
                      enEspera: 0,
                      cargando: false,
                      onRecargar: _recargar,
                      onNueva: _nueva,
                    ),
                    Expanded(
                      child: MensajeError(error: e, onReintentar: _recargar),
                    ),
                  ],
                ),
            data: (crudas) {
              final todas =
                  crudas.map(PropuestaEnAutorizacion.desdeFila).toList();
              final visibles =
                  todas
                      .where((f) => f.coincideCon(busqueda))
                      .where(
                        (f) =>
                            estado == null ||
                            f.autorizacion.esAprobada == estado,
                      )
                      .toList();

              return Column(
                children: [
                  _Cabecera(
                    aire: aire,
                    total: todas.length,
                    enEspera:
                        todas.where((f) => f.autorizacion.estaEnEspera).length,
                    // Tambien mientras se recarga el listado: con
                    // `invalidate` la grilla se queda con los datos viejos a la
                    // vista -es lo correcto, reemplazarlos por un esqueleto
                    // hace parecer que se perdieron- y este es el unico aviso
                    // de que hay una consulta en vuelo.
                    cargando: permisos.isLoading || propuestas.isLoading,
                    onRecargar: _recargar,
                    onNueva: _nueva,
                  ),
                  _BarraFiltros(
                    aire: aire,
                    buscarCtrl: _buscarCtrl,
                    estado: estado,
                    onBuscar: (t) {
                      ref.read(filtroBusquedaPrecioProvider.notifier).state = t;
                      ref.read(_paginaProvider.notifier).state = 0;
                    },
                    onEstado: (e) {
                      ref.read(filtroEstadoPropuestaProvider.notifier).state =
                          e;
                      ref.read(_paginaProvider.notifier).state = 0;
                    },
                  ),
                  SizedBox(
                    height: 2,
                    child:
                        ocupado
                            ? const LinearProgressIndicator(minHeight: 2)
                            : null,
                  ),
                  Expanded(
                    child: _Listado(
                      aire: aire,
                      filas: visibles,
                      totalSinFiltrar: todas.length,
                      hayFiltro: busqueda.trim().isNotEmpty || estado != null,
                      ocupado: ocupado,
                      manejadores: manejadores,
                      acciones:
                          (f) => accionesDe(
                            autorizacion: f.autorizacion,
                            tieneBtnAprobar: tieneBtnAprobar,
                            tieneBtnPen: tieneBtnPen,
                            tieneBtnGen: tieneBtnGen,
                          ),
                      onLimpiarFiltros: _limpiarFiltros,
                      onNueva: _nueva,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _recargar() => ref.invalidate(propuestasParaAutorizarProvider);

  void _limpiarFiltros() {
    _buscarCtrl.clear();
    ref.read(filtroBusquedaPrecioProvider.notifier).state = '';
    ref.read(filtroEstadoPropuestaProvider.notifier).state = null;
    ref.read(_paginaProvider.notifier).state = 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.aire,
    required this.total,
    required this.enEspera,
    required this.cargando,
    required this.onRecargar,
    required this.onNueva,
  });

  final Aire aire;
  final int total;

  /// Cuantas esperan una decision. Es el unico numero que le dice a un
  /// autorizador si tiene algo que hacer hoy.
  final int enEspera;

  final bool cargando;
  final VoidCallback onRecargar;

  /// Abre el asistente. En el telefono no se dibuja aca: va en el boton
  /// flotante.
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Propuestas de precios',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        SizedBox(height: Esp.xs),
        Text(
          total == 0
              ? 'Las últimas cien propuestas del sistema'
              : '$total ${total == 1 ? "propuesta" : "propuestas"} · '
                  '$enEspera ${enEspera == 1 ? "espera" : "esperan"} autorización',
          style: context.apagado(),
        ),
      ],
    );

    final acciones = [
      if (cargando)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Esp.m),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      IconButton(
        onPressed: onRecargar,
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar el listado',
      ),
      if (!aire.esChico) ...[
        SizedBox(width: Esp.s),
        FilledButton.icon(
          onPressed: onNueva,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva propuesta'),
        ),
      ],
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titulo),
          Row(mainAxisSize: MainAxisSize.min, children: acciones),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

/// Buscador y estado.
///
/// **El combo de estados se arma aca y no con `estadosPropuestaProvider`.** Ese
/// catalogo sale de una constante del backend donde En Espera esta comentado,
/// asi que filtrar con el dejaria afuera justo el estado que le importa a quien
/// autoriza. Los cuatro valores son los del dominio y los define la entity.
class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.aire,
    required this.buscarCtrl,
    required this.estado,
    required this.onBuscar,
    required this.onEstado,
  });

  final Aire aire;
  final TextEditingController buscarCtrl;
  final int? estado;
  final ValueChanged<String> onBuscar;
  final ValueChanged<int?> onEstado;

  @override
  Widget build(BuildContext context) {
    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Número, título o persona',
        prefixIcon: const Icon(Icons.search, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon:
            buscarCtrl.text.isEmpty
                ? null
                : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    buscarCtrl.clear();
                    onBuscar('');
                  },
                ),
      ),
    );

    final combo = DropdownButtonFormField<int?>(
      value: estado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<int?>(value: null, child: Text('Todos')),
        // En el orden del circuito, no en el de los codigos: se arma, se manda
        // a autorizar, se decide.
        DropdownMenuItem<int?>(value: 0, child: Text('Pendiente')),
        DropdownMenuItem<int?>(value: 3, child: Text('En Espera')),
        DropdownMenuItem<int?>(value: 1, child: Text('Aprobada')),
        DropdownMenuItem<int?>(value: 2, child: Text('No Aprobada')),
      ],
      onChanged: onEstado,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        0,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      child:
          aire.esChico
              // En el telefono los filtros van uno debajo del otro y el estado
              // queda plegado en el combo: dos controles en fila dejan al
              // buscador en cien pixeles.
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [buscador, SizedBox(height: Esp.s), combo],
              )
              : Row(
                children: [
                  Expanded(flex: 3, child: buscador),
                  SizedBox(width: Esp.m),
                  SizedBox(width: 220, child: combo),
                ],
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

/// Elige la superficie segun el ancho disponible.
///
/// El corte es [Aire.amplio] —mil pixeles de cajon— y no "es un telefono": la
/// planilla pide unos mil setecientos pixeles y abajo de mil seria casi todo
/// scroll lateral. Una tablet en vertical y una ventana angosta en el monitor
/// tienen el mismo problema aunque el dispositivo sea distinto.
class _Listado extends ConsumerWidget {
  const _Listado({
    required this.aire,
    required this.filas,
    required this.totalSinFiltrar,
    required this.hayFiltro,
    required this.ocupado,
    required this.acciones,
    required this.manejadores,
    required this.onLimpiarFiltros,
    required this.onNueva,
  });

  final Aire aire;
  final List<PropuestaEnAutorizacion> filas;

  /// Cuantas trajo el backend antes de filtrar. Sirve para que el estado vacio
  /// diga cual de los dos vacios es.
  final int totalSinFiltrar;

  final bool hayFiltro;
  final bool ocupado;
  final AccionesPropuesta Function(PropuestaEnAutorizacion) acciones;
  final ManejadoresPropuesta manejadores;
  final VoidCallback onLimpiarFiltros;
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filas.isEmpty) {
      // Se distinguen los dos vacios: no hay propuestas, o las hay pero
      // ninguna pasa el filtro. Cada uno se resuelve en otro lado.
      return Column(
        children: [
          Expanded(
            child: MensajeVacio(
              icono: hayFiltro ? Icons.filter_alt_off : Icons.inbox_outlined,
              titulo:
                  hayFiltro
                      ? 'Ninguna propuesta coincide con el filtro'
                      : 'No hay propuestas cargadas',
              detalle:
                  hayFiltro
                      ? 'El listado trae $totalSinFiltrar propuestas, pero '
                          'ninguna coincide con lo que busca. Pruebe con otro '
                          'número, otro título o quite el filtro de estado.'
                      : 'El listado trae las últimas cien propuestas. Para '
                          'armar una, use «Nueva propuesta».',
            ),
          ),
          if (hayFiltro)
            Padding(
              padding: EdgeInsets.only(bottom: Esp.xxl),
              child: TextButton.icon(
                onPressed: onLimpiarFiltros,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Quitar filtros'),
              ),
            )
          // En el telefono el boton flotante ya esta a la vista.
          else if (!aire.esChico)
            Padding(
              padding: EdgeInsets.only(bottom: Esp.xxl),
              child: FilledButton.tonalIcon(
                onPressed: onNueva,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva propuesta'),
              ),
            ),
        ],
      );
    }

    final padding = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
    );

    if (aire != Aire.amplio) {
      return ListView.separated(
        // En el telefono la ultima tarjeta tiene que poder pasar por encima
        // del boton flotante.
        padding: padding.copyWith(
          top: Esp.xs,
          bottom: aire.esChico ? 88 : Esp.xxl,
        ),
        itemCount: filas.length,
        separatorBuilder: (_, _) => SizedBox(height: Esp.s),
        itemBuilder:
            (context, i) => TarjetaPropuestaAutorizacion(
              fila: filas[i],
              acciones: acciones(filas[i]),
              manejadores: manejadores,
              ocupado: ocupado,
            ),
      );
    }

    // ── Escritorio: planilla paginada ──
    final porPagina = ref.watch(_filasPorPaginaProvider);
    // Al menos una: aca la lista nunca esta vacia, el caso vacio ya salio.
    final totalPaginas = (filas.length / porPagina).ceil();
    // La pagina se ajusta en vez de reventar: al achicar el tamano de pagina o
    // al filtrar, la que se estaba mirando puede dejar de existir.
    final elegida = ref.watch(_paginaProvider);
    final pagina =
        elegida < 0
            ? 0
            : (elegida > totalPaginas - 1 ? totalPaginas - 1 : elegida);
    final desde = pagina * porPagina;
    final hasta =
        desde + porPagina > filas.length ? filas.length : desde + porPagina;

    return Column(
      children: [
        Expanded(
          child: TablaPropuestas(
            filas: filas.sublist(desde, hasta),
            acciones: acciones,
            manejadores: manejadores,
            ocupado: ocupado,
            padding: padding.copyWith(bottom: Esp.s),
          ),
        ),
        _Paginador(
          padding: padding,
          primera: desde + 1,
          ultima: hasta,
          total: filas.length,
          pagina: pagina,
          totalPaginas: totalPaginas,
          porPagina: porPagina,
          onPagina: (p) => ref.read(_paginaProvider.notifier).state = p,
          onPorPagina: (n) {
            ref.read(_filasPorPaginaProvider.notifier).state = n;
            ref.read(_paginaProvider.notifier).state = 0;
          },
        ),
      ],
    );
  }
}

/// El paginador de la planilla.
///
/// Propio y no `BosquePaginator`: aquel pinta el fondo con `Colors.white` fijo
/// y decide el ancho con `ResponsiveUtilsBosque`, dos cosas que en modo oscuro
/// y dentro del dashboard se ven mal. Este toma todo del tema y del ancho que
/// le pasa la pantalla.
class _Paginador extends StatelessWidget {
  const _Paginador({
    required this.padding,
    required this.primera,
    required this.ultima,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
  });

  final EdgeInsets padding;
  final int primera;
  final int ultima;
  final int total;
  final int pagina;
  final int totalPaginas;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onPorPagina;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLow,
      padding: padding.copyWith(top: Esp.s, bottom: Esp.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mostrando $primera a $ultima de $total',
              style: context.apagado(),
            ),
          ),
          Text('Filas', style: context.apagado()),
          SizedBox(width: Esp.s),
          DropdownButton<int>(
            value: _opcionesDeFilas.contains(porPagina) ? porPagina : 25,
            underline: const SizedBox(),
            isDense: true,
            borderRadius: BorderRadius.circular(Esquina.chica),
            items: [
              for (final n in _opcionesDeFilas)
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
            onChanged: (n) {
              if (n != null) onPorPagina(n);
            },
          ),
          SizedBox(width: Esp.l),
          IconButton(
            tooltip: 'Página anterior',
            onPressed: pagina > 0 ? () => onPagina(pagina - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${pagina + 1} / $totalPaginas',
            style: context.numero(fuerte: true),
          ),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed:
                pagina < totalPaginas - 1 ? () => onPagina(pagina + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

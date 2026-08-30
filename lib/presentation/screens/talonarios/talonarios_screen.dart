import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/constants/talonarios_botones.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/presentation/screens/talonarios/talonarios_alta_lote_screen.dart';
import 'package:bosque_flutter/presentation/screens/talonarios/talonarios_entrega_lote_screen.dart';
import 'package:bosque_flutter/presentation/screens/talonarios/talonarios_catalogos_screen.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/reportes_talonarios.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/formulario_talonario.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/talonarios_comunes.dart';

/// Listado de talonarios con su estado y el historial de cada uno.
///
/// **El estado no se calcula acá.** Viene resuelto del backend en `estadoActual`
/// y en los flags `puedeEntregar` / `puedeDevolver` / `puedeCerrar`, que salen
/// de contar el log de eventos. La UI solo los dibuja: duplicar esa regla en
/// Dart es garantizar que las dos versiones se separen.
///
/// **La entrega no se hace desde acá.** En la práctica es una operación en lote
/// —el 59% de las entregas históricas se hicieron así— y tiene su pantalla.
/// Acá quedan la devolución y el cierre, que son de a uno.
class TalonariosScreen extends ConsumerStatefulWidget {
  const TalonariosScreen({super.key});

  @override
  ConsumerState<TalonariosScreen> createState() => _TalonariosScreenState();
}

class _TalonariosScreenState extends ConsumerState<TalonariosScreen> {
  int? _estadoFiltro;
  String _busqueda = '';

  /// Rango de alta pedido al servidor. Null = sin límite.
  ///
  /// **Arranca en el mes en curso**, no en «todo». La tabla tiene 1045
  /// talonarios y traerlos enteros son 334 KB y 1045 objetos que construir en
  /// Dart para que alguien mire los últimos. El recorte por defecto lo deja en
  /// lo que se dio de alta este mes.
  ///
  /// Ojo al probar: el grueso de los datos es histórico —2020 a 2023— así que
  /// con el default la pantalla muestra pocas filas. No está rota; el chip del
  /// período dice el rango y se quita con un toque.
  DateTimeRange? _periodo = _mesEnCurso();

  /// Empresa pedida al servidor. Null = todas.
  int? _codEmpresa;

  static DateTimeRange _mesEnCurso() {
    final hoy = DateTime.now();
    return DateTimeRange(start: DateTime(hoy.year, hoy.month), end: hoy);
  }

  /// Los cerrados NO se traen al entrar: son terminales y el 54% de las filas.
  /// Se piden solo cuando alguien los busca explícitamente.
  bool _incluirCerrados = false;

  /// Los que tienen una escritura en vuelo.
  ///
  /// **Es lo que evita el doble cierre.** Cerrar es terminal e irreversible; sin
  /// este candado un segundo toque manda el mismo evento otra vez, y del otro
  /// lado no hay forma de deshacerlo.
  final Set<BigInt> _enCurso = <BigInt>{};

  static const Map<int, String> _estados = {
    1: 'Adquirido',
    2: 'Entregado',
    3: 'Devuelto',
    4: 'Cerrado',
  };

  @override
  Widget build(BuildContext context) {
    // Lo que va al SERVIDOR es solo el período y si entran los cerrados: eso
    // decide cuántas filas viajan. El estado y la búsqueda se resuelven en
    // cliente sobre lo ya cargado, porque si formaran parte de la clave del
    // family cada toque instanciaría otro FutureProvider en loading —cinco
    // chips, cinco parpadeos de pantalla completa y el scroll perdido.
    final async = ref.watch(talonariosProvider(_filtroServidor));

    return LayoutBuilder(
      builder: (context, cajon) {
        // El ancho del CAJÓN, no el de la ventana: adentro del dashboard el
        // sidebar se come su parte y MediaQuery miente.
        final aire = Aire.de(cajon.maxWidth);

        return Scaffold(
          floatingActionButton:
              aire.esChico
                  ? PermissionWidget(
                    buttonName: TalonariosBotones.nuevo,
                    child: FloatingActionButton.extended(
                      onPressed: _abrirAltaLote,
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo lote'),
                    ),
                  )
                  : null,
          body: SafeArea(
            child: Column(
              children: [
                _cabecera(aire, async.valueOrNull),
                _filtros(aire, async.valueOrNull),
                const Divider(height: 1),
                Expanded(child: _contenido(async, aire)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lo que se le pide al servidor.
  ///
  /// Estado, empresa y período van acá y no se filtran en Dart: el objetivo es
  /// que el backend devuelva menos filas, no que el cliente esconda las que ya
  /// viajaron. Lo único que queda del lado del cliente es la búsqueda por
  /// texto, que es incremental y no justifica una vuelta por tecla.
  FiltroTalonarios get _filtroServidor => (
    codTipoRecibo: null,
    codEmpresa: _codEmpresa == null ? null : BigInt.from(_codEmpresa!),
    codGrupo: null,
    codEstadoActual: _estadoFiltro,
    desde: _periodo?.start,
    hasta: _periodo?.end,
    incluirCerrados: _incluirCerrados,
  );

  // ── Cabecera ──────────────────────────────────────────────────────────────

  Widget _cabecera(Aire aire, List<TalonarioEntity>? datos) {
    final acciones = [
      PermissionWidget(
        buttonName: TalonariosBotones.nuevo,
        child: FilledButton.icon(
          onPressed: _abrirAltaLote,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo lote'),
        ),
      ),
      const SizedBox(width: Esp.s),
      PermissionWidget(
        buttonName: TalonariosBotones.editar,
        child: FilledButton.tonalIcon(
          onPressed: _abrirEntregaLote,
          icon: const Icon(Icons.assignment_turned_in, size: 18),
          label: const Text('Asignar'),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Talonarios', style: context.tituloSeccion()),
                    if (datos != null)
                      Text(
                        '${datos.length} cargados'
                        '${_incluirCerrados ? '' : '  ·  sin cerrados'}'
                        '${_codEmpresa == null ? '' : '  ·  una empresa'}'
                        '${_periodo == null ? '' : '  ·  ${fechaCorta(_periodo!.start)} a ${fechaCorta(_periodo!.end)}'}',
                        style: context.apagado(),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Recargar',
                icon: const Icon(Icons.refresh),
                onPressed: () => refrescarTalonarios(ref),
              ),
              // Se le pasa lo que hay cargado: el combo de la ficha ofrece
              // exactamente los talonarios que el usuario tiene delante, y
              // abrir el panel no dispara una segunda carga.
              PermissionWidget(
                buttonName: TalonariosBotones.reporte,
                child: IconButton(
                  tooltip: 'Reportes',
                  icon: const Icon(Icons.summarize_outlined),
                  onPressed:
                      () => mostrarReportesTalonarios(
                        context,
                        talonarios: datos ?? const [],
                      ),
                ),
              ),
              // Tipos de recibo y grupos. Se administran poco —7 y 3 filas—
              // pero la sigla arma el numero de talonario, asi que tiene que
              // poder editarse sin entrar a la base.
              IconButton(
                tooltip: 'Catálogos: tipos y grupos',
                icon: const Icon(Icons.tune),
                onPressed: _abrirCatalogos,
              ),
              // En pantalla chica las acciones viven en el FAB, para que no
              // compriman el título ni desborden.
              if (!aire.esChico) ...acciones,
            ],
          ),
          const SizedBox(height: Esp.m),
          TextField(
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Buscar por número, tipo o destinatario',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
          ),
        ],
      ),
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────────

  Widget _filtros(Aire aire, List<TalonarioEntity>? datos) {
    // El conteo por estado sale de la misma lista que ya está en memoria.
    int cuentaDe(int? estado) {
      if (datos == null) return 0;
      if (estado == null) return datos.length;
      return datos.where((t) => t.codEstadoActual == estado).length;
    }

    Widget chip(int? estado, String texto) {
      // Los cerrados no están cargados salvo que se los haya pedido: mostrar
      // "Cerrado 0" sería mentir. Sin número hasta que se traigan.
      final cerradosNoCargados = estado == 4 && !_incluirCerrados;
      // Con un estado elegido el servidor devuelve SOLO ese, así que los
      // conteos de los demás serían 0 y mentirían. Se muestran nada más
      // cuando está puesto «Todos», que es cuando de verdad se sabe.
      final sinConteo = datos == null || cerradosNoCargados || _estadoFiltro != null;
      final etiqueta = sinConteo ? texto : '$texto  ${cuentaDe(estado)}';

      return Padding(
        padding: const EdgeInsets.only(right: Esp.s),
        child: FilterChip(
          label: Text(etiqueta),
          avatar: cerradosNoCargados ? const Icon(Icons.download, size: 15) : null,
          selected: _estadoFiltro == estado,
          onSelected:
              (sel) => setState(() {
                _estadoFiltro = sel ? estado : null;
                // Pedir "Cerrado" trae los cerrados del servidor. Al soltarlo
                // no se descartan: ya viajaron, sacarlos obligaría a otra
                // vuelta para nada.
                if (sel && estado == 4) _incluirCerrados = true;
              }),
        ),
      );
    }

    final chips = [
      chip(null, 'Todos'),
      ..._estados.entries.map((e) => chip(e.key, e.value)),
      _chipEmpresa(),
      _chipPeriodo(),
    ];

    final pad = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
      vertical: Esp.s,
    );

    // En ancho los chips envuelven; en angosto scrollean, que es lo único que
    // entra sin apilar cinco filas.
    return aire.esChico
        ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: pad,
          child: Row(children: chips),
        )
        : Padding(
          padding: pad,
          child: Wrap(runSpacing: Esp.s, children: chips),
        );
  }

  /// Rango de **alta**, resuelto en el servidor.
  ///
  /// Es el filtro que de verdad baja el payload: recorta las filas antes de
  /// agrupar el log de eventos. Ojo con elegir un rango reciente: los datos son
  /// históricos —nada entre 2024 y 2025— así que "este año" puede devolver muy
  /// poco.
  /// Empresa, como chip que despliega la lista.
  ///
  /// Va de chip y no de combo suelto para que los cuatro recortes —estado,
  /// empresa, período y cerrados— se lean en una sola fila y se vea de un
  /// vistazo cuántos hay puestos. Tocarlo con una empresa ya elegida la quita,
  /// igual que el del período.
  Widget _chipEmpresa() {
    final empresas = ref.watch(empresasProvider);
    final nombre = empresas.maybeWhen(
      data: (lista) {
        for (final e in lista) {
          if (e.codEmpresa == _codEmpresa) return e.nombre;
        }
        return null;
      },
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.only(right: Esp.s),
      child: FilterChip(
        label: Text(nombre ?? 'Empresa'),
        avatar: const Icon(Icons.business_outlined, size: 15),
        selected: _codEmpresa != null,
        onSelected: (_) async {
          if (_codEmpresa != null) {
            setState(() => _codEmpresa = null);
            return;
          }
          final lista = empresas.valueOrNull;
          if (lista == null || lista.isEmpty) {
            if (mounted) {
              avisar(context, 'Todavía se están cargando las empresas.');
            }
            return;
          }
          final elegida = await showDialog<int>(
            context: context,
            builder:
                (ctx) => SimpleDialog(
                  title: const Text('Filtrar por empresa'),
                  children: [
                    for (final e in lista)
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, e.codEmpresa),
                        child: Text(e.nombre),
                      ),
                  ],
                ),
          );
          if (elegida != null && mounted) {
            setState(() => _codEmpresa = elegida);
          }
        },
      ),
    );
  }

  Widget _chipPeriodo() {
    final p = _periodo;
    final etiqueta =
        p == null
            ? 'Período'
            : '${fechaCorta(p.start)} – ${fechaCorta(p.end)}';

    return Padding(
      padding: const EdgeInsets.only(right: Esp.s),
      child: FilterChip(
        label: Text(etiqueta),
        avatar: const Icon(Icons.date_range, size: 15),
        selected: p != null,
        onSelected: (_) async {
          if (p != null) {
            setState(() => _periodo = null);
            return;
          }
          final r = await pedirRangoDeFechas(
            context,
            titulo: 'Período',
            explicacion: 'Acota por la fecha de alta del talonario.',
            minima: DateTime(2019),
            maxima: DateTime.now(),
            textoAceptar: 'Aplicar',
            iconoAceptar: Icons.filter_alt_outlined,
          );
          if (r != null && mounted) {
            setState(
              () => _periodo = DateTimeRange(start: r.desde, end: r.hasta),
            );
          }
        },
      ),
    );
  }

  // ── Contenido ─────────────────────────────────────────────────────────────

  Widget _contenido(AsyncValue<List<TalonarioEntity>> async, Aire aire) {
    return async.when(
      // Esqueleto y no spinner: reserva el lugar de las filas para que al
      // llegar los datos la página no salte.
      loading: () => const EsqueletoLista(),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(talonariosProvider(_filtroServidor)),
          ),
      data: (todos) {
        final lista = _filtrar(todos);

        if (lista.isEmpty) {
          // El período cuenta como filtro: es el que está puesto por
          // defecto, y sin nombrarlo el mensaje «todavía no hay talonarios»
          // haría pensar que el módulo está vacío cuando solo está acotado.
          final hayFiltro =
              _estadoFiltro != null ||
              _busqueda.isNotEmpty ||
              _codEmpresa != null ||
              _periodo != null;
          return RefreshIndicator(
            onRefresh: () async => refrescarTalonarios(ref),
            child: ListView(
              children: [
                SizedBox(
                  height: 320,
                  child: MensajeVacio(
                    icono:
                        hayFiltro
                            ? Icons.search_off
                            : Icons.receipt_long_outlined,
                    titulo:
                        hayFiltro
                            ? 'Ningún talonario coincide'
                            : 'Todavía no hay talonarios',
                    detalle:
                        hayFiltro
                            ? 'Probá con otro estado o borrá lo que escribiste en la búsqueda.'
                            : 'Los talonarios se dan de alta en lote, desde «Nuevo lote».',
                  ),
                ),
              ],
            ),
          );
        }

        // En pantalla ancha, tabla. No es solo estética: la tarjeta trae
        // superficie propia y ripple por fila, y con 480 filas eso traba el
        // scroll en web. La fila de tabla es un Row de Text.
        //
        // Y NO se usa `DataTable`: construye todas las filas de golpe. Acá la
        // cabecera va fija fuera del scroll y las filas por `ListView.builder`,
        // que arma solo las visibles.
        if (aire == Aire.amplio) {
          return Column(
            children: [
              const CabeceraTablaTalonarios(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => refrescarTalonarios(ref),
                  child: ListView.builder(
                    itemCount: lista.length,
                    itemExtent: 56,
                    itemBuilder: (_, i) {
                      final t = lista[i];
                      return FilaTablaTalonario(
                        talonario: t,
                        par: i.isEven,
                        onTap: () => _verHistorial(t),
                        acciones: _acciones(t),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refrescarTalonarios(ref),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              aire.esChico ? Esp.m : Esp.xl,
              Esp.s,
              aire.esChico ? Esp.m : Esp.xl,
              // Aire abajo para que el FAB no tape la última fila. Antes la
              // tapaba, y con ella su menú de acciones: no se podía cerrar el
              // último talonario de la lista.
              aire.esChico ? 88 : Esp.l,
            ),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
            itemBuilder: (_, i) {
              final t = lista[i];
              return TarjetaTalonario(
                talonario: t,
                onTap: () => _verHistorial(t),
                acciones: _acciones(t),
              );
            },
          ),
        );
      },
    );
  }

  List<TalonarioEntity> _filtrar(List<TalonarioEntity> todos) {
    return todos.where((t) {
      // El estado ya lo aplicó el servidor: filtrarlo otra vez acá no cambia
      // nada y esconde un bug si alguna vez dejan de coincidir.
      if (_busqueda.isEmpty) return true;
      return t.nroTalonario.toLowerCase().contains(_busqueda) ||
          t.datoTipo.toLowerCase().contains(_busqueda) ||
          t.datoDestinatario.toLowerCase().contains(_busqueda);
    }).toList();
  }

  // ── Acciones de una fila ──────────────────────────────────────────────────

  /// Doble condición para que aparezca el menú:
  ///
  /// 1. **Qué permite el estado** — `puedeDevolver` / `puedeCerrar` los calcula
  ///    el backend contando el log.
  /// 2. **Qué permite el usuario** — `btnTalonEditTal`, el botón que la base ya
  ///    tiene para modificar talonarios.
  ///
  /// Cuando no hay ninguna acción posible se dibuja un candado apagado en vez
  /// de no dibujar nada: que el menú aparezca y desaparezca sin explicación es
  /// peor que decir «cerrado, no admite más movimientos».
  Widget _acciones(TalonarioEntity t) {
    if (_enCurso.contains(t.codTalonario)) {
      return const Padding(
        padding: EdgeInsets.all(Esp.m),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // El menú siempre está: editar los datos del talonario no depende del
    // estado. Antes, un talonario cerrado no mostraba nada y no había forma de
    // corregirle ni la observación.
    return PermissionWidget(
      buttonName: TalonariosBotones.editar,
      placeholder:
          t.estaCerrado
              ? Tooltip(
                message: 'Cerrado: no admite más movimientos',
                child: Padding(
                  padding: const EdgeInsets.all(Esp.m),
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              )
              : const SizedBox.shrink(),
      child: PopupMenuButton<String>(
        tooltip: 'Acciones',
        onSelected: (opcion) {
          switch (opcion) {
            case 'editar':
              _editarTalonario(t);
            case 'devolver':
              _registrarEvento(t, 3);
            case 'cerrar':
              _registrarEvento(t, 4);
          }
        },
        itemBuilder:
            (_) => [
              const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar datos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (t.puedeDevolver || t.puedeCerrar) const PopupMenuDivider(),
              if (t.puedeDevolver)
                const PopupMenuItem(
                  value: 'devolver',
                  child: ListTile(
                    leading: Icon(Icons.assignment_return_outlined),
                    title: Text('Devolver'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (t.puedeCerrar)
                const PopupMenuItem(
                  value: 'cerrar',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Cerrar'),
                    subtitle: Text('Definitivo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
      ),
    );
  }

  Future<void> _editarTalonario(TalonarioEntity t) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FormularioTalonario(talonario: t),
    );
  }

  Future<void> _registrarEvento(TalonarioEntity t, int codEstado) async {
    final cierre = codEstado == 4;

    // El cierre es terminal: se confirma con su consecuencia escrita, no con un
    // «¿Está seguro?» que nadie lee.
    final sigue = await confirmar(
      context,
      titulo:
          cierre
              ? '¿Cerrar el talonario ${t.nroTalonario}?'
              : '¿Devolver el talonario ${t.nroTalonario}?',
      detalle:
          cierre
              ? 'El cierre es definitivo: después no admite entrega, devolución '
                  'ni ningún otro movimiento.'
              : 'Vuelve a quedar disponible para entregarse de nuevo.',
      textoConfirmar: cierre ? 'Cerrar definitivamente' : 'Devolver',
      destructiva: cierre,
    );
    if (!sigue || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _HojaEvento(
            talonario: t,
            codEstado: codEstado,
            onEscribir: (fecha, observacion) async {
              setState(() => _enCurso.add(t.codTalonario));
              try {
                await ref
                    .read(talonariosRepositoryProvider)
                    .registrarEvento(
                      TalonarioDetalleEntity(
                        codDetalle: BigInt.zero,
                        codTalonario: t.codTalonario,
                        codEstado: codEstado,
                        fechaEvento: fecha,
                        codSucursal: BigInt.zero,
                        codEmpleado: BigInt.zero,
                        observacion: observacion,
                        audUsuario: BigInt.from(
                          ref.read(userProvider)?.codUsuario ?? 0,
                        ),
                      ),
                    );
              } finally {
                if (mounted) setState(() => _enCurso.remove(t.codTalonario));
              }
            },
            alTerminar: () {
              refrescarTalonarios(ref);
              mostrarAviso(
                context,
                cierre
                    ? 'Talonario ${t.nroTalonario} cerrado'
                    : 'Talonario ${t.nroTalonario} devuelto',
              );
            },
          ),
    );
  }

  // ── Historial ─────────────────────────────────────────────────────────────

  void _verHistorial(TalonarioEntity t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            builder:
                (ctx, scroll) => Consumer(
                  builder: (context, ref, __) {
                    final eventos = ref.watch(
                      eventosTalonarioProvider(t.codTalonario),
                    );
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Esp.l,
                            0,
                            Esp.s,
                            Esp.s,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Historial de ${t.nroTalonario}',
                                  style: context.tituloSeccion(),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cerrar',
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: eventos.when(
                            loading:
                                () => const EsqueletoLista(
                                  filas: 3,
                                  altoFila: 56,
                                ),
                            error:
                                (e, _) => MensajeError(
                                  error: e,
                                  onReintentar:
                                      () => ref.invalidate(
                                        eventosTalonarioProvider(
                                          t.codTalonario,
                                        ),
                                      ),
                                ),
                            data:
                                (lista) =>
                                    lista.isEmpty
                                        // Antes esto pintaba una hoja
                                        // completamente en blanco.
                                        ? const MensajeVacio(
                                          icono: Icons.history,
                                          titulo: 'Sin movimientos',
                                          detalle:
                                              'Este talonario todavía no registra eventos.',
                                        )
                                        : ListView.separated(
                                          controller: scroll,
                                          padding: const EdgeInsets.all(Esp.m),
                                          itemCount: lista.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(height: Esp.s),
                                          itemBuilder:
                                              (_, i) => _filaEvento(lista[i]),
                                        ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
    );
  }

  Widget _filaEvento(TalonarioDetalleEntity ev) {
    final c = colorDeEstadoTalonario(context.cs, ev.codEstado);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono por estado, no el código crudo de la base: un lector de
        // pantalla leía «uno», «dos» al lado del texto.
        Container(
          padding: const EdgeInsets.all(Esp.s),
          decoration: BoxDecoration(
            color: c.fondo,
            borderRadius: BorderRadius.circular(Esquina.chica),
          ),
          child: Icon(
            iconoDeEstadoTalonario(ev.codEstado),
            size: 16,
            color: c.texto,
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ev.datoEstado,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: Peso.titulo,
                      ),
                    ),
                  ),
                  Text(
                    ev.datoFechaEvento.isNotEmpty
                        ? ev.datoFechaEvento
                        : fechaCorta(ev.fechaEvento),
                    style: context.numero(),
                  ),
                ],
              ),
              if (ev.datoDestinatario.isNotEmpty)
                Text(ev.datoDestinatario, style: context.apagado()),
              if (ev.observacion.isNotEmpty)
                Text(
                  ev.observacion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Navegación ────────────────────────────────────────────────────────────

  Future<void> _abrirAltaLote() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TalonariosAltaLoteScreen()),
    );
    // El refresco lo dispara la pantalla hija al guardar; acá no se repite.
  }

  Future<void> _abrirCatalogos() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TalonariosCatalogosScreen()),
    );
  }

  Future<void> _abrirEntregaLote() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TalonariosEntregaLoteScreen()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EL DIÁLOGO DE UN EVENTO
// ═══════════════════════════════════════════════════════════════════════════

/// Pide fecha y observación, **escribe adentro**, y solo se cierra si salió bien.
///
/// **Por qué no devuelve los datos y escribe el que llamó.** Así estaba antes:
/// el diálogo hacía `pop` con la fecha y el texto, y recién después venía el
/// `await`. Si el guardado fallaba —un talonario que otro ya cerró, la red— el
/// diálogo ya no existía y lo escrito se perdía. Ahora el error se muestra
/// acá arriba con todo intacto, y se puede reintentar.
class _HojaEvento extends StatefulWidget {
  const _HojaEvento({
    required this.talonario,
    required this.codEstado,
    required this.onEscribir,
    required this.alTerminar,
  });

  final TalonarioEntity talonario;
  final int codEstado;
  final Future<void> Function(DateTime fecha, String observacion) onEscribir;
  final VoidCallback alTerminar;

  @override
  State<_HojaEvento> createState() => _HojaEventoState();
}

class _HojaEventoState extends State<_HojaEvento> {
  DateTime _fecha = DateTime.now();
  final _observacion = TextEditingController();
  bool _ocupado = false;
  Object? _error;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  String get _accion => widget.codEstado == 4 ? 'Cerrar' : 'Devolver';

  Future<void> _guardar() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.onEscribir(_fecha, _observacion.text);
      if (!mounted) return;
      Navigator.pop(context);
      widget.alTerminar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('$_accion ${widget.talonario.nroTalonario}'),
    content: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              MensajeError(error: _error, compacto: true),
            if (_error != null) const SizedBox(height: Esp.m),
            CampoFecha(
              etiqueta: 'Fecha del evento',
              valor: _fecha,
              habilitado: !_ocupado,
              onElegir: (f) => setState(() => _fecha = f),
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _observacion,
              enabled: !_ocupado,
              maxLength: 250,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observación',
                helperText: 'Opcional',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _ocupado ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      BotonAccion(
        etiqueta: _accion,
        etiquetaOcupado: 'Guardando…',
        ocupado: _ocupado,
        destructiva: widget.codEstado == 4,
        onPressed: _guardar,
      ),
    ],
  );
}

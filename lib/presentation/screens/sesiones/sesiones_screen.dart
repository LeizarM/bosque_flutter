import 'package:bosque_flutter/core/state/sesiones_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/sesion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/sesiones/piezas_sesiones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Quién tiene la app abierta, el historial de entradas y el cierre de una sesión.
///
/// Solo administradores (el backend lo exige con ROLE_ADM). Una sesión cerrada desde aquí deja
/// de valer en el servidor: su app vuelve al login en la próxima acción o en el chequeo de 2 minutos.
class SesionesScreen extends ConsumerWidget {
  const SesionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: LayoutBuilder(
          builder: (context, cajon) {
            final aire = Aire.de(cajon.maxWidth);
            final margen = aire.esChico ? Esp.m : Esp.xl;
            final abiertas = ref.watch(sesionesAbiertasProvider).valueOrNull;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Encabezado(aire: aire, margen: margen),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: margen),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      // «Abiertas» y no «Conectados»: incluye las que están sin señal (app oculta).
                      Tab(text: abiertas == null ? 'Abiertas' : 'Abiertas (${abiertas.length})'),
                      const Tab(text: 'Historial'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Abiertas(aire: aire, margen: margen),
                      _Historial(aire: aire, margen: margen),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.aire, required this.margen});

  final Aire aire;
  final double margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sesiones', style: tt.titleLarge?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4)),
                if (!aire.esChico)
                  Text(
                    'Quién tiene la app abierta, desde qué equipo y desde cuándo. '
                    'Cerrar una sesión devuelve a esa persona al inicio de sesión.',
                    style: context.apagado(),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(sesionesAbiertasProvider);
              ref.invalidate(historialSesionesProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _Abiertas extends ConsumerWidget {
  const _Abiertas({required this.aire, required this.margen});

  final Aire aire;
  final double margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abiertas = ref.watch(sesionesAbiertasProvider);
    return abiertas.when(
      skipLoadingOnRefresh: true,
      loading: () => const EsqueletoLista(filas: 6, altoFila: 56),
      error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(sesionesAbiertasProvider)),
      data: (lista) {
        if (lista.isEmpty) {
          return const MensajeVacio(
            icono: Icons.devices_other_outlined,
            titulo: 'Nadie tiene la app abierta',
            detalle:
                'Cada inicio de sesión aparece aquí. Quien entró antes de esta versión no figura '
                'hasta que vuelva a iniciar sesión.',
          );
        }
        final conectadas = lista.where((s) => s.conectada).length;
        // El resumen es también la leyenda de los puntos de cada fila.
        Widget dato(bool conectada, String texto) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PuntoPresencia(conectada: conectada, abierta: true),
            const SizedBox(width: Esp.s),
            Flexible(child: Text(texto, style: context.apagado())),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.s),
              child: Wrap(
                spacing: Esp.l,
                runSpacing: Esp.xs,
                children: [
                  dato(true, '$conectadas con la app a la vista'),
                  dato(false, '${lista.length - conectadas} sin señal reciente'),
                ],
              ),
            ),
            Expanded(child: _Listado(lista: lista, aire: aire, margen: margen, historial: false)),
          ],
        );
      },
    );
  }
}

class _Historial extends ConsumerStatefulWidget {
  const _Historial({required this.aire, required this.margen});

  final Aire aire;
  final double margen;

  @override
  ConsumerState<_Historial> createState() => _HistorialState();
}

class _HistorialState extends ConsumerState<_Historial> {
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy');
  String _busqueda = '';
  bool _buscando = false;

  Future<void> _elegirRango() async {
    final actual = ref.read(rangoHistorialSesionesProvider);
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Historial de sesiones',
      explicacion: 'Las sesiones que empezaron entre estas dos fechas, hasta 31 días.',
      desde: actual.desde,
      hasta: actual.hasta,
      textoAceptar: 'Ver sesiones',
      iconoAceptar: Icons.history,
    );
    if (rango == null || !mounted) return;
    if (rango.hasta.difference(rango.desde).inDays >= 31) {
      avisar(context, 'Elige un rango de hasta 31 días.', esError: true);
      return;
    }
    ref.read(rangoHistorialSesionesProvider.notifier).state = rango;
  }

  bool _coincide(SesionEntity s) {
    final q = _busqueda.trim().toLowerCase();
    return q.isEmpty || s.nombreCompleto.toLowerCase().contains(q) || s.login.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final rango = ref.watch(rangoHistorialSesionesProvider);
    final historial = ref.watch(historialSesionesProvider);
    final textoRango =
        rango.desde == rango.hasta
            ? _fecha.format(rango.desde)
            : '${_fecha.format(rango.desde)} – ${_fecha.format(rango.hasta)}';

    final fechas = OutlinedButton.icon(
      onPressed: _elegirRango,
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(textoRango, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final buscador = TextField(
      autofocus: widget.aire.esChico,
      onChanged: (v) => setState(() => _busqueda = v),
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search),
        labelText: 'Buscar persona o usuario',
      ),
    );

    // En teléfono la búsqueda se despliega a pedido, para no quitarle alto a la lista.
    final Widget filtros =
        widget.aire.esChico
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: fechas)),
                    IconButton(
                      tooltip: _buscando ? 'Ocultar la búsqueda' : 'Buscar persona o usuario',
                      onPressed:
                          () => setState(() {
                            _buscando = !_buscando;
                            if (!_buscando) _busqueda = '';
                          }),
                      icon: Icon(_buscando ? Icons.search_off : Icons.search),
                    ),
                  ],
                ),
                if (_buscando) Padding(padding: const EdgeInsets.only(top: Esp.s), child: buscador),
              ],
            )
            : Wrap(
              spacing: Esp.m,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [fechas, SizedBox(width: 320, child: buscador)],
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: EdgeInsets.fromLTRB(widget.margen, Esp.m, widget.margen, Esp.s), child: filtros),
        Expanded(
          child: historial.when(
            skipLoadingOnRefresh: true,
            loading: () => const EsqueletoLista(filas: 6, altoFila: 56),
            error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(historialSesionesProvider)),
            data: (lista) {
              final visibles = lista.where(_coincide).toList();
              if (visibles.isEmpty) {
                return MensajeVacio(
                  icono: Icons.history,
                  titulo: lista.isEmpty ? 'No hubo sesiones en esas fechas' : 'Nadie coincide con la búsqueda',
                  detalle:
                      lista.isEmpty
                          ? 'Elige otro rango con el botón de fechas.'
                          : 'Revisa lo que escribiste o borra la búsqueda.',
                );
              }
              return _Listado(
                // La clave reinicia la página al cambiar el filtro o el rango.
                key: ValueKey('$textoRango|$_busqueda'),
                lista: visibles,
                aire: widget.aire,
                margen: widget.margen,
                historial: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Tabla con columnas cuando hay lugar, paginada de a 50; tarjetas en teléfono.
class _Listado extends StatefulWidget {
  const _Listado({
    super.key,
    required this.lista,
    required this.aire,
    required this.margen,
    required this.historial,
  });

  final List<SesionEntity> lista;
  final Aire aire;
  final double margen;
  final bool historial;

  @override
  State<_Listado> createState() => _ListadoState();
}

class _ListadoState extends State<_Listado> {
  static const int _porPagina = 50;
  int _pagina = 1;

  @override
  Widget build(BuildContext context) {
    final lista = widget.lista;
    if (widget.aire.esChico) {
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(widget.margen, Esp.xs, widget.margen, Esp.xxl),
        itemCount: lista.length,
        itemBuilder: (_, i) => TarjetaSesion(sesion: lista[i], historial: widget.historial),
      );
    }

    final paginas = ((lista.length - 1) ~/ _porPagina) + 1;
    // Al cerrar una sesión la lista se relee y puede quedar con menos páginas.
    final actual = _pagina.clamp(1, paginas);
    final desde = (actual - 1) * _porPagina;
    final hasta = (desde + _porPagina).clamp(0, lista.length);
    final pagina = lista.sublist(desde, hasta);
    final amplio = widget.aire == Aire.amplio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.margen),
          child: _CabeceraTabla(historial: widget.historial, amplio: amplio),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(widget.margen, 0, widget.margen, Esp.xl),
            itemCount: pagina.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder:
                (_, i) => FilaTablaSesion(sesion: pagina[i], historial: widget.historial, amplio: amplio),
          ),
        ),
        if (paginas > 1)
          BosquePaginator(
            currentPage: actual,
            totalPages: paginas,
            firstRow: desde + 1,
            lastRow: hasta,
            onPageChanged: (p) => setState(() => _pagina = p),
          ),
      ],
    );
  }
}

class _CabeceraTabla extends StatelessWidget {
  const _CabeceraTabla({required this.historial, required this.amplio});

  final bool historial;
  final bool amplio;

  @override
  Widget build(BuildContext context) {
    final estilo = context.apagado()?.copyWith(fontWeight: Peso.titulo);
    Text t(String s) => Text(s, style: estilo, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        children: [
          const SizedBox(width: 10 + Esp.m),
          Expanded(flex: 4, child: t('Persona')),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: t('Equipo')),
          if (amplio) ...[const SizedBox(width: Esp.m), Expanded(flex: 2, child: t('IP'))],
          if (amplio || historial) SizedBox(width: anchoEntradaSesion, child: t('Entró')),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: t(historial ? 'Terminó' : 'Última señal')),
          const SizedBox(width: anchoAccionSesion),
        ],
      ),
    );
  }
}

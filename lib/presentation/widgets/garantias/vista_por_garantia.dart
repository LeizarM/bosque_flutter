/// Vista «Por garantía» de la pantalla principal: todas las garantias, una por
/// fila y numeradas, con filtro entre fechas.
///
/// **Por que existe.** La vista «Por cliente» agrupa las garantias de cada
/// cliente en una fila, asi que no tiene una fecha por la cual filtrar. Cada
/// garantia si tiene tres: inicio, expiracion y registro. El backend filtra por
/// rango de **expiracion** y de **registro** (`/garantias/listar`, rama G), y
/// eso es lo que ofrece el filtro de fechas.
///
/// **La regla de vigencias.** En escritorio, la columna «Vigencia» dibuja el
/// plazo de cada garantia sobre un mismo eje de tiempo, con una linea en «hoy»
/// que cruza todas las filas: de un vistazo se ve cuales vencen juntas, cuales
/// ya vencieron y cuales recien empiezan. El eje es el rango del filtro de
/// fechas (o, sin filtro, de un año atras a un año adelante), asi que filtrar
/// por fechas es tambien mirar ese tramo del calendario.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/detalle_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DE LA VISTA
//
// autoDispose y aca: al salir del modulo se reinicia.
// ═══════════════════════════════════════════════════════════════════════════

/// Filtro de estado. «Por vencer» no es un estado del backend (es una vigente
/// a 30 dias o menos), por eso el estado se filtra en memoria.
enum _Estado { todas, vigentes, porVencer, caducadas, cerradas }

bool _pasaEstado(GarantiaVistaEntity g, _Estado e) => switch (e) {
  _Estado.todas => true,
  _Estado.vigentes => g.estaVigente,
  _Estado.porVencer => g.porVencer,
  _Estado.caducadas => g.estaCaducada,
  _Estado.cerradas => g.estaCerrada,
};

/// Por que fecha filtra el rango.
enum CampoFecha { expiracion, registro }

/// Un rango de fechas elegido, con el nombre con el que se muestra.
@immutable
class RangoFechas {
  const RangoFechas({
    required this.campo,
    required this.desde,
    required this.hasta,
    required this.nombre,
  });

  final CampoFecha campo;
  final DateTime desde;
  final DateTime hasta;

  /// «Vencen en los próximos 30 días», o el rango escrito si se eligio a mano.
  final String nombre;

  @override
  bool operator ==(Object other) =>
      other is RangoFechas &&
      other.campo == campo &&
      other.desde == desde &&
      other.hasta == hasta;

  @override
  int get hashCode => Object.hash(campo, desde, hasta);
}

final _textoProvider = StateProvider.autoDispose<String>((ref) => '');
final _estadoProvider = StateProvider.autoDispose<_Estado>(
  (ref) => _Estado.todas,
);
final _tipoProvider = StateProvider.autoDispose<String?>((ref) => null);
final _rangoProvider = StateProvider.autoDispose<RangoFechas?>((ref) => null);
final _paginaProvider = StateProvider.autoDispose<int>((ref) => 0);
final _porPaginaProvider = StateProvider.autoDispose<int>((ref) => 25);

DateTime _hoy() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _mesAnio(DateTime d) => '${_meses[d.month - 1]} ${d.year}';

// ═══════════════════════════════════════════════════════════════════════════
// LA VISTA
// ═══════════════════════════════════════════════════════════════════════════

class VistaPorGarantia extends ConsumerStatefulWidget {
  const VistaPorGarantia({super.key, required this.aire});

  final Aire aire;

  @override
  ConsumerState<VistaPorGarantia> createState() => _VistaPorGarantiaState();
}

class _VistaPorGarantiaState extends ConsumerState<VistaPorGarantia> {
  final _buscarCtrl = TextEditingController();
  bool _filtrosAbiertos = false;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _alPaginaCero() => ref.read(_paginaProvider.notifier).state = 0;

  void _limpiar() {
    _buscarCtrl.clear();
    ref.read(_textoProvider.notifier).state = '';
    ref.read(_estadoProvider.notifier).state = _Estado.todas;
    ref.read(_tipoProvider.notifier).state = null;
    ref.read(_rangoProvider.notifier).state = null;
    _alPaginaCero();
  }

  @override
  Widget build(BuildContext context) {
    final aire = widget.aire;
    final rango = ref.watch(_rangoProvider);
    final tipo = ref.watch(_tipoProvider);
    final estado = ref.watch(_estadoProvider);
    final texto = ref.watch(_textoProvider).trim().toLowerCase();

    // Lo que filtra el servidor: fechas y tipo de documento.
    final filtro = FiltroGarantias(
      tipoGarantia: tipo,
      vencDesde: rango?.campo == CampoFecha.expiracion ? rango!.desde : null,
      vencHasta: rango?.campo == CampoFecha.expiracion ? rango!.hasta : null,
      regDesde: rango?.campo == CampoFecha.registro ? rango!.desde : null,
      regHasta: rango?.campo == CampoFecha.registro ? rango!.hasta : null,
    );
    final lista = ref.watch(garantiasFiltradasProvider(filtro));

    final hayFiltro =
        rango != null ||
        tipo != null ||
        estado != _Estado.todas ||
        texto.isNotEmpty;

    final filtros = _Filtros(
      aire: aire,
      buscarCtrl: _buscarCtrl,
      estado: estado,
      tipo: tipo,
      rango: rango,
      abiertos: _filtrosAbiertos,
      onAbrir: () => setState(() => _filtrosAbiertos = !_filtrosAbiertos),
      onTexto: (t) {
        ref.read(_textoProvider.notifier).state = t;
        _alPaginaCero();
      },
      onEstado: (e) {
        ref.read(_estadoProvider.notifier).state = e;
        _alPaginaCero();
      },
      onTipo: (t) {
        ref.read(_tipoProvider.notifier).state = t;
        _alPaginaCero();
      },
      onRango: (r) {
        ref.read(_rangoProvider.notifier).state = r;
        _alPaginaCero();
      },
    );

    // stretch: la fila de filtros es un Wrap, que mide lo que ocupa; centrado
    // se corria de lugar cada vez que cambiaba el ancho de una pastilla.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filtros,
        Expanded(
          child: lista.when(
            skipLoadingOnRefresh: true,
            loading: () => const EsqueletoLista(altoFila: 56),
            error:
                (e, _) => MensajeError(
                  error: e,
                  onReintentar:
                      () => ref.invalidate(garantiasFiltradasProvider(filtro)),
                ),
            data: (todas) {
              final filtradas = [
                for (final g in todas)
                  if (_pasaEstado(g, estado) && _coincide(g, texto)) g,
              ];
              // Las cerradas al final, como los clientes con todo cerrado en
              // «Por cliente»: arriba queda lo que se sigue gestionando. Cada
              // grupo conserva el orden del servidor (cliente y expiracion).
              final visibles = [
                ...filtradas.where((g) => !g.estaCerrada),
                ...filtradas.where((g) => g.estaCerrada),
              ];
              if (visibles.isEmpty) {
                return _SinResultados(
                  hayFiltro: hayFiltro,
                  onLimpiar: _limpiar,
                );
              }
              return _Resultados(
                aire: aire,
                filas: visibles,
                eje: _Eje.para(rango),
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _coincide(GarantiaVistaEntity g, String t) =>
      t.isEmpty ||
      g.datoCliente.toLowerCase().contains(t) ||
      g.garantia.codClienteSAP.toLowerCase().contains(t) ||
      g.codGarantia.toString() == t.replaceAll(RegExp(r'[^0-9]'), '');
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

class _Filtros extends ConsumerWidget {
  const _Filtros({
    required this.aire,
    required this.buscarCtrl,
    required this.estado,
    required this.tipo,
    required this.rango,
    required this.abiertos,
    required this.onAbrir,
    required this.onTexto,
    required this.onEstado,
    required this.onTipo,
    required this.onRango,
  });

  final Aire aire;
  final TextEditingController buscarCtrl;
  final _Estado estado;
  final String? tipo;
  final RangoFechas? rango;
  final bool abiertos;
  final VoidCallback onAbrir;
  final ValueChanged<String> onTexto;
  final ValueChanged<_Estado> onEstado;
  final ValueChanged<String?> onTipo;
  final ValueChanged<RangoFechas?> onRango;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chico = aire == Aire.justo;
    final catalogo = ref.watch(tiposGarantiaProvider).valueOrNull ?? const [];

    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onTexto,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        // Corto para que entre entero; el codigo SAP tambien se busca.
        hintText: 'Cliente o N° de garantía',
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
                    onTexto('');
                  },
                ),
      ),
    );

    final estados = Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final (e, nombre) in const [
          (_Estado.todas, 'Todas'),
          (_Estado.vigentes, 'Vigentes'),
          (_Estado.porVencer, 'Por vencer'),
          (_Estado.caducadas, 'Caducadas'),
          (_Estado.cerradas, 'Cerradas'),
        ])
          ChoiceChip(
            label: Text(nombre),
            selected: estado == e,
            onSelected: (_) => onEstado(e),
          ),
      ],
    );

    // Mismo lenguaje que el filtro de fechas: boton mientras no hay tipo y
    // pastilla con cruz cuando lo hay. El desplegable de antes era mas alto
    // que los otros controles de la fila.
    String? nombreTipo;
    for (final t in catalogo) {
      if (t.codTipos == tipo) nombreTipo = t.nombre;
    }
    final tipoDoc = MenuAnchor(
      builder:
          (context, control, _) =>
              tipo == null
                  ? OutlinedButton.icon(
                    onPressed:
                        () => control.isOpen ? control.close() : control.open(),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Tipo de documento'),
                  )
                  : InputChip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: Text('Con ${(nombreTipo ?? tipo!).toLowerCase()}'),
                    selected: true,
                    showCheckmark: false,
                    onPressed:
                        () => control.isOpen ? control.close() : control.open(),
                    deleteButtonTooltipMessage: 'Quitar el filtro de tipo',
                    onDeleted: () => onTipo(null),
                  ),
      menuChildren: [
        for (final t in catalogo)
          MenuItemButton(
            onPressed: () => onTipo(t.codTipos),
            trailingIcon:
                t.codTipos == tipo ? const Icon(Icons.check, size: 18) : null,
            child: Text(t.nombre),
          ),
      ],
    );

    final fechas = _BotonFechas(rango: rango, onRango: onRango);

    final margen = EdgeInsets.fromLTRB(
      chico ? Esp.m : Esp.xl,
      Esp.m,
      chico ? Esp.m : Esp.xl,
      Esp.m,
    );

    if (chico) {
      return Padding(
        padding: margen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: buscador),
                const SizedBox(width: Esp.s),
                IconButton(
                  tooltip: abiertos ? 'Ocultar filtros' : 'Mostrar filtros',
                  onPressed: onAbrir,
                  isSelected: abiertos,
                  icon: Badge(
                    isLabelVisible:
                        estado != _Estado.todas ||
                        tipo != null ||
                        rango != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            // El rango elegido queda a la vista aunque los filtros esten
            // plegados: es el que mas cambia lo que se ve.
            if (rango != null && !abiertos) ...[
              const SizedBox(height: Esp.s),
              Align(alignment: Alignment.centerLeft, child: fechas),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child:
                  abiertos
                      ? Padding(
                        padding: const EdgeInsets.only(top: Esp.m),
                        child: Wrap(
                          spacing: Esp.s,
                          runSpacing: Esp.m,
                          children: [estados, tipoDoc, fechas],
                        ),
                      )
                      : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: margen,
      child: Wrap(
        spacing: Esp.m,
        runSpacing: Esp.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: aire == Aire.amplio ? 320 : 280, child: buscador),
          fechas,
          tipoDoc,
          estados,
        ],
      ),
    );
  }
}

/// Filtro entre fechas: atajos para lo comun y un rango a mano. Con un rango
/// elegido se muestra como una pastilla con su nombre y una cruz para quitarlo.
class _BotonFechas extends StatelessWidget {
  const _BotonFechas({required this.rango, required this.onRango});

  final RangoFechas? rango;
  final ValueChanged<RangoFechas?> onRango;

  List<RangoFechas> _atajos() {
    final hoy = _hoy();
    return [
      RangoFechas(
        campo: CampoFecha.expiracion,
        desde: hoy,
        hasta: hoy.add(const Duration(days: 30)),
        nombre: 'Vencen en los próximos 30 días',
      ),
      RangoFechas(
        campo: CampoFecha.expiracion,
        desde: hoy,
        hasta: hoy.add(const Duration(days: 90)),
        nombre: 'Vencen en los próximos 90 días',
      ),
      RangoFechas(
        campo: CampoFecha.expiracion,
        desde: hoy.subtract(const Duration(days: 90)),
        hasta: hoy.subtract(const Duration(days: 1)),
        nombre: 'Vencieron en los últimos 90 días',
      ),
      RangoFechas(
        campo: CampoFecha.registro,
        desde: DateTime(hoy.year, hoy.month),
        hasta: hoy,
        nombre: 'Registradas este mes',
      ),
      RangoFechas(
        campo: CampoFecha.registro,
        desde: DateTime(hoy.year),
        hasta: hoy,
        nombre: 'Registradas este año',
      ),
    ];
  }

  Future<void> _aMano(BuildContext context, CampoFecha campo) async {
    final hoy = _hoy();
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(hoy.year + 10),
      initialDateRange:
          rango?.campo == campo
              ? DateTimeRange(start: rango!.desde, end: rango!.hasta)
              : null,
      helpText:
          campo == CampoFecha.expiracion
              ? 'Vencen entre'
              : 'Se registraron entre',
      saveText: 'Aplicar',
    );
    if (elegido == null) return;
    final verbo = campo == CampoFecha.expiracion ? 'Vencen' : 'Registradas';
    onRango(
      RangoFechas(
        campo: campo,
        desde: elegido.start,
        hasta: elegido.end,
        nombre:
            '$verbo del ${fechaCorta(elegido.start)} al '
            '${fechaCorta(elegido.end)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atajos = _atajos();

    return MenuAnchor(
      builder:
          (context, control, _) =>
              rango == null
                  ? OutlinedButton.icon(
                    onPressed:
                        () => control.isOpen ? control.close() : control.open(),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Filtrar por fechas'),
                  )
                  : InputChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(rango!.nombre),
                    selected: true,
                    showCheckmark: false,
                    onPressed:
                        () => control.isOpen ? control.close() : control.open(),
                    deleteButtonTooltipMessage: 'Quitar el filtro de fechas',
                    onDeleted: () => onRango(null),
                  ),
      menuChildren: [
        for (final a in atajos)
          MenuItemButton(
            leadingIcon: Icon(
              a.campo == CampoFecha.expiracion
                  ? Icons.event_outlined
                  : Icons.inventory_2_outlined,
              size: 18,
            ),
            onPressed: () => onRango(a),
            child: Text(a.nombre),
          ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
          onPressed: () => _aMano(context, CampoFecha.expiracion),
          child: const Text('Elegir rango de vencimiento…'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
          onPressed: () => _aMano(context, CampoFecha.registro),
          child: const Text('Elegir rango de registro…'),
        ),
      ],
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.hayFiltro, required this.onLimpiar});

  final bool hayFiltro;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: MensajeVacio(
          icono: hayFiltro ? Icons.filter_alt_off : Icons.inbox_outlined,
          titulo:
              hayFiltro
                  ? 'Ninguna garantía cumple el filtro'
                  : 'Todavía no hay garantías registradas',
          detalle:
              hayFiltro
                  ? 'Pruebe con otro rango de fechas, otro estado o quite los '
                      'filtros.'
                  : 'Registre la primera con «Nueva garantía».',
        ),
      ),
      if (hayFiltro)
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.xxl),
          child: TextButton.icon(
            onPressed: onLimpiar,
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: const Text('Quitar filtros'),
          ),
        ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EL EJE DE TIEMPO
// ═══════════════════════════════════════════════════════════════════════════

/// El tramo de calendario que dibuja la columna «Vigencia».
@immutable
class _Eje {
  const _Eje(this.desde, this.hasta, this.hoy);

  /// El rango del filtro de fechas; sin filtro, un año atras y uno adelante.
  factory _Eje.para(RangoFechas? r) {
    final hoy = _hoy();
    if (r == null) {
      return _Eje(
        DateTime(hoy.year - 1, hoy.month, hoy.day),
        DateTime(hoy.year + 1, hoy.month, hoy.day),
        hoy,
      );
    }
    final hasta =
        r.hasta.isAfter(r.desde)
            ? r.hasta
            : r.desde.add(const Duration(days: 1));
    return _Eje(r.desde, hasta, hoy);
  }

  final DateTime desde;
  final DateTime hasta;
  final DateTime hoy;

  int get _dias => hasta.difference(desde).inDays.clamp(1, 1 << 30);

  /// Posicion de [d] en un ancho [w]; puede quedar fuera de 0..w.
  double x(DateTime d, double w) => d.difference(desde).inDays / _dias * w;
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULTADOS: TABLA (ESCRITORIO) O TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _Resultados extends ConsumerWidget {
  const _Resultados({
    required this.aire,
    required this.filas,
    required this.eje,
  });

  final Aire aire;
  final List<GarantiaVistaEntity> filas;
  final _Eje eje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = EdgeInsets.symmetric(
      horizontal: aire == Aire.justo ? Esp.m : Esp.xl,
    );

    void abrir(GarantiaVistaEntity g) =>
        abrirDetalleGarantia(context, g.codGarantia);

    if (aire != Aire.amplio) {
      return ListView.separated(
        padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl),
        itemCount: filas.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: Esp.s),
        itemBuilder:
            (context, i) =>
                i == 0
                    ? _Conteo(total: filas.length)
                    : _Tarjeta(n: i, g: filas[i - 1], onAbrir: abrir),
      );
    }

    final porPagina = ref.watch(_porPaginaProvider);
    final totalPaginas = (filas.length / porPagina).ceil();
    final pagina = ref.watch(_paginaProvider).clamp(0, totalPaginas - 1);
    final desde = pagina * porPagina;
    final hasta =
        desde + porPagina > filas.length ? filas.length : desde + porPagina;

    return Column(
      children: [
        Expanded(
          child: _Tabla(
            filas: filas.sublist(desde, hasta),
            primerNumero: desde + 1,
            eje: eje,
            padding: padding,
            onAbrir: abrir,
          ),
        ),
        PaginadorTabla(
          padding: padding,
          primera: desde + 1,
          ultima: hasta,
          total: filas.length,
          pagina: pagina,
          totalPaginas: totalPaginas,
          porPagina: porPagina,
          sustantivo: filas.length == 1 ? 'garantía' : 'garantías',
          onPagina: (p) => ref.read(_paginaProvider.notifier).state = p,
          onPorPagina: (n) {
            ref.read(_porPaginaProvider.notifier).state = n;
            ref.read(_paginaProvider.notifier).state = 0;
          },
        ),
      ],
    );
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$total', style: context.cifra(fuerte: true)),
          TextSpan(
            text: total == 1 ? ' garantía' : ' garantías',
            style: context.apagado(),
          ),
        ],
      ),
    ),
  );
}

/// Columnas de la tabla: nombre, flex y si va a la derecha. «#» y la flecha
/// tienen ancho fijo.
const _columnas = <(String, int, bool)>[
  ('Garantía', 3, false),
  ('Cliente', 5, false),
  ('Estado', 2, false),
  ('Valor', 3, true),
  ('Línea aprobada', 3, true),
  ('Vigencia', 6, false),
  ('Registro', 2, false),
];

const double _anchoNumero = 44;
const double _anchoFlecha = 40;

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.filas,
    required this.primerNumero,
    required this.eje,
    required this.padding,
    required this.onAbrir,
  });

  final List<GarantiaVistaEntity> filas;
  final int primerNumero;
  final _Eje eje;
  final EdgeInsets padding;
  final ValueChanged<GarantiaVistaEntity> onAbrir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    Widget encabezado(String t, int flex, bool derecha) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
        child:
            t == 'Vigencia'
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.m),
                  child: _EncabezadoEje(eje: eje, estilo: estilo),
                )
                : t == 'Valor'
                ? Align(
                  alignment: Alignment.centerRight,
                  child: EtiquetaConAyuda(
                    Glosario.valor,
                    estilo: estilo,
                    alDerecha: true,
                  ),
                )
                : t == 'Línea aprobada'
                ? Align(
                  alignment: Alignment.centerRight,
                  child: EtiquetaConAyuda(
                    Glosario.lineaAprobada,
                    estilo: estilo,
                    alDerecha: true,
                  ),
                )
                : Text(
                  t,
                  textAlign: derecha ? TextAlign.end : TextAlign.start,
                  style: estilo,
                ),
      ),
    );

    return Padding(
      padding: padding,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.s,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                SizedBox(width: _anchoNumero, child: Text('#', style: estilo)),
                for (final (t, flex, derecha) in _columnas)
                  encabezado(t, flex, derecha),
                const SizedBox(width: _anchoFlecha),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: Esp.s),
              itemCount: filas.length,
              itemBuilder:
                  (context, i) => _Fila(
                    n: primerNumero + i,
                    g: filas[i],
                    eje: eje,
                    onAbrir: onAbrir,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado de la columna «Vigencia»: los extremos del eje y la marca de hoy.
class _EncabezadoEje extends StatelessWidget {
  const _EncabezadoEje({required this.eje, required this.estilo});

  final _Eje eje;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chico = context.cifra(color: cs.onSurfaceVariant, tam: 10.5);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final xh = eje.x(eje.hoy, w);
        // «hoy» solo si cae dentro y no pisa los extremos.
        final mostrarHoy = xh > 70 && xh < w - 70;
        return SizedBox(
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Text('Vigencia', style: estilo),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(_mesAnio(eje.desde), style: chico),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Text(_mesAnio(eje.hasta), style: chico),
              ),
              if (mostrarHoy)
                Positioned(
                  left: xh - 20,
                  width: 40,
                  bottom: 0,
                  child: Text(
                    'hoy',
                    textAlign: TextAlign.center,
                    style: chico.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Fila extends StatefulWidget {
  const _Fila({
    required this.n,
    required this.g,
    required this.eje,
    required this.onAbrir,
  });

  final int n;
  final GarantiaVistaEntity g;
  final _Eje eje;
  final ValueChanged<GarantiaVistaEntity> onAbrir;

  @override
  State<_Fila> createState() => _FilaState();
}

class _FilaState extends State<_Fila> {
  bool _encima = false;

  Widget _celda(int flex, Widget hijo, {bool derecha = false}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
      child: Align(
        alignment: derecha ? Alignment.centerRight : Alignment.centerLeft,
        child: hijo,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = widget.g;
    final x = g.garantia;

    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: Material(
        color: _encima ? cs.surfaceContainerLow : Colors.transparent,
        child: InkWell(
          onTap: () => widget.onAbrir(g),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.s,
            ),
            child: Row(
              children: [
                NumeroFila(widget.n, ancho: _anchoNumero),
                _celda(
                  _columnas[0].$2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'N° ${g.codGarantia}',
                        style: context.cifra(fuerte: true),
                      ),
                      Text(
                        (g.tiposGarantia ?? '').trim().isEmpty
                            ? 'Sin documentos'
                            : g.tiposGarantia!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.apagado()?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _celda(
                  _columnas[1].$2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        g.datoCliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        x.codClienteSAP,
                        style: context.cifra(
                          color: cs.onSurfaceVariant,
                          tam: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _celda(_columnas[2].$2, ChipEstadoGarantia(garantia: g)),
                _celda(
                  _columnas[3].$2,
                  Text(monto(x.montoGarantia), style: context.cifra()),
                  derecha: true,
                ),
                _celda(
                  _columnas[4].$2,
                  Text(
                    monto(x.montoCredito),
                    style: context.cifra(fuerte: true),
                  ),
                  derecha: true,
                ),
                _celda(
                  _columnas[5].$2,
                  // Aire a los lados: la regla no se pega a las cifras.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Esp.m),
                    child: _ReglaVigencia(g: g, eje: widget.eje),
                  ),
                ),
                _celda(
                  _columnas[6].$2,
                  Text(
                    fechaCorta(g.fechaRegistro),
                    style: context.cifra(tam: 11.5),
                  ),
                ),
                SizedBox(
                  width: _anchoFlecha,
                  child: Icon(
                    Icons.chevron_right,
                    color: _encima ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El plazo de una garantia sobre el eje comun, con la marca de hoy. Si el
/// plazo se sale del eje, la barra llega al borde y termina en punta.
class _ReglaVigencia extends StatelessWidget {
  const _ReglaVigencia({required this.g, required this.eje});

  final GarantiaVistaEntity g;
  final _Eje eje;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final x = g.garantia;
    return Tooltip(
      message:
          'Vigencia: ${fechaCorta(x.fechaInicio)} → '
          '${fechaCorta(x.fechaExpiracion)} · ${cuentaRegresiva(g.diasParaVencer)}',
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: CustomPaint(
          painter: _PintorVigencia(
            eje: eje,
            inicio: x.fechaInicio,
            fin: x.fechaExpiracion,
            color: colorDeTono(context, tonoDe(g)),
            pista: cs.surfaceContainerHighest,
            hoy: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _PintorVigencia extends CustomPainter {
  _PintorVigencia({
    required this.eje,
    required this.inicio,
    required this.fin,
    required this.color,
    required this.pista,
    required this.hoy,
  });

  final _Eje eje;
  final DateTime? inicio;
  final DateTime? fin;
  final Color color;
  final Color pista;
  final Color hoy;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final y = size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..color = pista
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (inicio != null && fin != null) {
      final a = eje.x(inicio!, w);
      final b = eje.x(fin!, w);
      final pintura = Paint()..color = color;
      if (b < 0 || a > w) {
        // Todo el plazo cae fuera del eje: un punto en el borde de ese lado.
        canvas.drawCircle(Offset(b < 0 ? 3 : w - 3, y), 3, pintura);
      } else {
        final ia = a.clamp(0.0, w);
        final ib = b.clamp(0.0, w);
        final ancho = (ib - ia) < 4 ? 4.0 : ib - ia;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(ia, y - 4, ancho, 8),
            const Radius.circular(4),
          ),
          pintura,
        );
        // Punta si se sale del eje: sigue antes o despues de lo que se ve.
        if (a < 0) _punta(canvas, Offset(ia, y), -1, pintura);
        if (b > w) _punta(canvas, Offset(ib, y), 1, pintura);
      }
    }

    final xh = eje.x(eje.hoy, w);
    if (xh >= 0 && xh <= w) {
      final p =
          Paint()
            ..color = hoy
            ..strokeWidth = 1.5;
      // Punteada: marca, no dato.
      for (double yy = 0; yy < size.height; yy += 5) {
        canvas.drawLine(Offset(xh, yy), Offset(xh, yy + 2.5), p);
      }
    }
  }

  void _punta(Canvas canvas, Offset o, int dir, Paint p) {
    // La punta toca el borde y la base queda hacia adentro: no se mete en la
    // columna de al lado.
    final path =
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx - dir * 7, o.dy - 6)
          ..lineTo(o.dx - dir * 7, o.dy + 6)
          ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PintorVigencia old) =>
      old.eje != eje ||
      old.inicio != inicio ||
      old.fin != fin ||
      old.color != color ||
      old.pista != pista ||
      old.hoy != hoy;
}

/// Telefono y tablet: una tarjeta por garantia, con su numero de fila.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.n, required this.g, required this.onAbrir});

  final int n;
  final GarantiaVistaEntity g;
  final ValueChanged<GarantiaVistaEntity> onAbrir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final x = g.garantia;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: () => onAbrir(g),
        child: Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '#$n',
                    style: context.cifra(color: cs.onSurfaceVariant, tam: 11),
                  ),
                  Text(
                    'N° ${g.codGarantia}',
                    style: context.cifra(fuerte: true),
                  ),
                  ChipEstadoGarantia(garantia: g),
                ],
              ),
              const SizedBox(height: Esp.s),
              Text(
                g.datoCliente,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${x.codClienteSAP} · ${(g.tiposGarantia ?? '').trim().isEmpty ? 'Sin documentos' : g.tiposGarantia}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.apagado(),
              ),
              const SizedBox(height: Esp.m),
              BarraVigencia(garantia: g),
              const SizedBox(height: Esp.m),
              Wrap(
                spacing: Esp.xl,
                runSpacing: Esp.s,
                children: [
                  DatoFicha.termino(
                    Glosario.valor,
                    valor: monto(x.montoGarantia),
                    cifra: true,
                    ancho: 140,
                  ),
                  DatoFicha.termino(
                    Glosario.lineaAprobada,
                    valor: monto(x.montoCredito),
                    cifra: true,
                    ancho: 130,
                  ),
                  DatoFicha(
                    etiqueta: 'Registrada',
                    valor: fechaCorta(g.fechaRegistro),
                    cifra: true,
                    ancho: 110,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

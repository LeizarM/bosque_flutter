/// El listado de cheques: tabla con una columna por dato en escritorio y
/// tarjetas en movil. No conoce el estado ni abre nada: las acciones de cada
/// fila llegan por [AlElegirAccionCheque] y la paginacion, ya construida.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/domain/utils/situacion_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

/// Ancho del area de resultados desde el cual se usa tabla. Se mide el ancho del
/// contenedor y no el de la ventana: dentro del dashboard el menu lateral se
/// come su parte.
const double anchoMinimoTabla = 720;

/// Ancho minimo de una tarjeta; decide cuantas caben por fila.
const double anchoMinimoTarjeta = 340;

// ═══════════════════════════════════════════════════════════════════════════
// ACCIONES DE UNA FILA
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que se puede hacer con un cheque desde la grilla.
enum AccionFilaCheque {
  /// El lapiz: abre el formulario que corresponde al usuario y al cheque
  /// (`modoDeEdicionCheque`): el de administrador, el estandar o, en un cheque
  /// cerrado con el cobro fuera de rango, el de talonario con un aviso.
  editar('Editar', Icons.edit_outlined),

  /// Solo talonario y recibo (cheque cerrado), para quien no puede editar como
  /// administrador.
  editarTalonario('Editar talonario', Icons.receipt_long_outlined),

  /// Nueva fecha de cobro.
  fechaCobro('Fecha de cobro', Icons.event_repeat_outlined),

  /// Entrar al detalle y a sus acciones.
  completar('Completar', Icons.fact_check_outlined),

  /// El documento PDF del cheque: ver o descargar el cargado, cargar uno nuevo o
  /// reemplazarlo. Es la unica accion **sin permiso de boton**, como en el
  /// legacy: la ve cualquiera que vea la fila.
  documentoPdf('Documento PDF', Icons.picture_as_pdf_outlined);

  const AccionFilaCheque(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}

/// Las acciones que [permisos] deja ver para [cheque], en el orden del legacy:
/// «Completar» y, al final, «Documento PDF» (que no depende de ningun permiso y
/// siempre esta). Asi, en la tabla, el PDF queda siempre en el mismo borde.
///
/// Todas las reglas (ACL del boton, estado del cheque, administrador) las
/// resuelve [PermisosCheque]; aqui solo se enumeran.
///
/// Las variantes de administrador del legacy no son botones aparte. «Fecha
/// Cobro» abria el mismo dialogo, uno con tope de +-28 dias y otro sin el: aqui
/// el tope lo decide el permiso (`fechaCobroSinLimite`). «Editar» tambien es un
/// solo lapiz: quien puede editar como administrador abre ese formulario con el
/// mismo icono, y «Editar talonario» queda solo para quien no puede (btnEditar1CH
/// con el cheque cerrado). Que formulario abre el lapiz lo decide
/// `modoDeEdicionCheque`.
List<AccionFilaCheque> accionesDeFila(
  PermisosCheque permisos,
  ChequeFilaEntity cheque,
) {
  final estado = cheque.cheque.estado;
  final comoAdmin = permisos.puedeEditarComoAdmin(estado);
  return [
    if (comoAdmin || permisos.puedeEditar(estado)) AccionFilaCheque.editar,
    if (!comoAdmin && permisos.puedeEditarTalonario(estado))
      AccionFilaCheque.editarTalonario,
    if (permisos.puedeCambiarFechaCobro(estado) ||
        permisos.puedeCambiarFechaCobroComoAdmin(estado))
      AccionFilaCheque.fechaCobro,
    if (permisos.puedeCompletar) AccionFilaCheque.completar,
    AccionFilaCheque.documentoPdf,
  ];
}

typedef AlElegirAccionCheque =
    void Function(AccionFilaCheque accion, ChequeFilaEntity cheque);

// ═══════════════════════════════════════════════════════════════════════════
// ELEGIR TABLA O TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

/// Elige tabla o tarjetas segun el ancho que hay. [pie] (la paginacion) va
/// dentro de la tabla y debajo de las tarjetas.
class ListaCheques extends StatelessWidget {
  const ListaCheques({
    super.key,
    required this.filas,
    required this.primerNumero,
    required this.permisos,
    required this.onAccion,
    required this.pie,
    this.hoy,
  });

  final List<ChequeFilaEntity> filas;

  /// Numero de la primera fila de esta pagina en el total (21 en la pagina 2).
  final int primerNumero;

  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final Widget pie;

  /// El dia con el que se mide la situacion de cobro de cada fila (atrasado,
  /// cobra hoy, en 3 d). La pantalla lo toma de `relojChequesProvider`; sin el,
  /// el reloj del sistema.
  final DateTime? hoy;

  @override
  Widget build(BuildContext context) {
    final dia = hoy ?? DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoTabla) {
          return _TablaCheques(
            key: const ValueKey('lista-tabla'),
            filas: filas,
            primerNumero: primerNumero,
            permisos: permisos,
            onAccion: onAccion,
            pie: pie,
            hoy: dia,
          );
        }
        return _TarjetasCheques(
          key: const ValueKey('lista-tarjetas'),
          ancho: constraints.maxWidth,
          filas: filas,
          primerNumero: primerNumero,
          permisos: permisos,
          onAccion: onAccion,
          pie: pie,
          hoy: dia,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA (una columna por dato)
// ═══════════════════════════════════════════════════════════════════════════

class _Col {
  const _Col(
    this.id,
    this.titulo, {
    this.ancho,
    this.flex = 1,
    this.derecha = false,
    this.descarte = 0,
  });

  final String id;
  final String titulo;

  /// Ancho fijo; sin el, la columna reparte el resto por [flex].
  final double? ancho;
  final int flex;
  final bool derecha;

  /// 0 = esencial. Con un numero mayor, la columna se oculta antes cuando falta
  /// ancho: 6 es la primera que se va y 1 la ultima.
  final int descarte;

  /// Lo minimo que necesita: su ancho fijo o, en las de texto, [_unidadTexto]
  /// por cada unidad de flex.
  double get minimo => ancho ?? flex * _unidadTexto;
}

/// El ancho minimo, por unidad de flex, de una columna de texto.
const double _unidadTexto = 55;

/// Ancho de un icono de accion en la tabla y del boton ⋮ de la variante con
/// menu.
///
/// 28 y no 36: el icono del documento PDF es el cuarto de un administrador (lapiz,
/// fecha de cobro, completar y PDF). Con 36 el cuarto icono costaba 36 px y a
/// 1280 y 1400 px la tabla escondia una columna mas; con 28 cuatro iconos ocupan
/// 112 px contra los 108 de tres iconos de 36, y las columnas que se ven en los
/// anchos corrientes no cambian. El icono sigue en 20 px: son 4 px de aire por
/// lado, y la tabla es de mouse (en tablet angosta pasan a tarjetas).
const double _anchoIconoAccion = 28;
const double _anchoBotonMenu = 48;

/// La celda de acciones nunca baja de esto: es lo que necesita el rotulo
/// «Acciones» de la cabecera. Con el PDF todo usuario tiene al menos un icono.
const double _anchoMinimoAcciones = 88;

/// Los anchos fijos suman lo mismo que antes de poner la situacion de cobro bajo
/// la fecha (F. cobro +20; Nro. cheque -16 y Estado -4, que en mono y en
/// pastilla ocupan menos): los puntos en que `_planear` oculta columnas, y las
/// pruebas que los fijan, no se mueven.
///
/// Las columnas, en el orden en que se dibujan. Las que tienen [_Col.descarte]
/// se van ocultando, de mayor a menor, cuando el area no alcanza: primero las de
/// menos uso (el tipo casi nunca viene; el numero de fila es solo una ayuda) y
/// al final la fecha de recepcion. Lo oculto se ve en «Completar».
const List<_Col> _todas = [
  _Col('num', '#', ancho: 40, descarte: 5),
  _Col('recepcion', 'Recepción', ancho: 88, descarte: 1),
  _Col('cliente', 'Cliente', flex: 3),
  _Col('nro', 'Nro. cheque', ancho: 96),
  _Col('banco', 'Banco', flex: 2),
  _Col('orden', 'A la orden de', flex: 2, descarte: 2),
  _Col('monto', 'Monto', ancho: 124, derecha: true),
  _Col('fcheque', 'F. cheque', ancho: 88, descarte: 3),
  _Col('fcobro', 'F. cobro', ancho: 108),
  _Col('tipo', 'Tipo', ancho: 104, descarte: 6),
  _Col('estado', 'Estado', ancho: 108),
  _Col('entrega', 'Entregado por', flex: 2, descarte: 4),
];

/// Que columnas se dibujan y como, para un ancho dado.
class _PlanTabla {
  const _PlanTabla({
    required this.columnas,
    required this.ocultas,
    required this.menu,
    required this.anchoAcciones,
    required this.anchoCuerpo,
    required this.hayScroll,
  });

  final List<_Col> columnas;
  final List<_Col> ocultas;

  /// Las acciones van en un menu ⋮ y no en iconos sueltos.
  final bool menu;

  /// Ancho de la celda de acciones; 0 si nadie tiene acciones.
  final double anchoAcciones;

  /// Ancho del contenido; mayor que el visible solo si [hayScroll].
  final double anchoCuerpo;
  final bool hayScroll;

  /// Hueco que dejan las filas al final para que la celda pegada no tape datos
  /// cuando se llega al extremo derecho.
  double get reserva => anchoAcciones == 0 ? 0 : anchoAcciones + Esp.s;
}

double _necesario(List<_Col> cols, double anchoAcciones) {
  final reserva = anchoAcciones == 0 ? 0.0 : anchoAcciones + Esp.s;
  final datos = cols.fold<double>(0, (s, c) => s + c.minimo);
  return datos + Esp.s * (cols.length - 1) + reserva + Esp.l * 2;
}

/// Elige las columnas que entran en [viewport]: todas si caben; si no, se van
/// ocultando las de menos uso. Con solo las esenciales, varias acciones pasan a
/// un menu (ocupa menos que los iconos); si ni asi entra, la tabla se desplaza
/// de lado y las acciones quedan pegadas al borde.
_PlanTabla _planear(double viewport, int maxAcciones) {
  final iconos =
      maxAcciones == 0
          ? 0.0
          : math.max(
            _anchoMinimoAcciones,
            maxAcciones * _anchoIconoAccion + Esp.l,
          );
  final menu = maxAcciones == 0 ? 0.0 : _anchoBotonMenu + Esp.m;

  final columnas = [..._todas];
  final orden =
      _todas.where((c) => c.descarte > 0).toList()
        ..sort((a, b) => b.descarte.compareTo(a.descarte));

  _PlanTabla plan(double acciones, bool conMenu, double necesario) =>
      _PlanTabla(
        columnas: List.of(columnas),
        ocultas: [
          for (final c in _todas)
            if (!columnas.contains(c)) c,
        ],
        menu: conMenu,
        anchoAcciones: acciones,
        anchoCuerpo: math.max(necesario, viewport),
        hayScroll: necesario > viewport,
      );

  for (var i = 0; ; i++) {
    final n = _necesario(columnas, iconos);
    if (n <= viewport) return plan(iconos, false, n);
    if (i == orden.length) break;
    columnas.remove(orden[i]);
  }
  final conMenu = maxAcciones > 1;
  final acciones = conMenu ? menu : iconos;
  return plan(acciones, conMenu, _necesario(columnas, acciones));
}

/// Una fila con las celdas alineadas a las columnas del [plan] y, al final, el
/// hueco de las acciones. Sirve a cabecera y datos.
Widget _fila(_PlanTabla plan, Widget Function(_Col) celda) {
  final hijos = <Widget>[];
  for (var i = 0; i < plan.columnas.length; i++) {
    if (i > 0) hijos.add(const SizedBox(width: Esp.s));
    final c = plan.columnas[i];
    final contenido = Align(
      alignment: c.derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: celda(c),
    );
    hijos.add(
      c.ancho != null
          ? SizedBox(width: c.ancho, child: contenido)
          : Expanded(flex: c.flex, child: contenido),
    );
  }
  if (plan.reserva > 0) hijos.add(SizedBox(width: plan.reserva));
  return Row(children: hijos);
}

/// Lo que necesitan la cabecera y las filas para pegar las acciones al borde
/// visible de la tabla.
class _Pegado {
  const _Pegado({
    required this.controller,
    required this.viewport,
    required this.ancho,
    required this.hayScroll,
  });

  /// El scroll horizontal de la tabla.
  final ScrollController controller;

  /// Ancho visible de la tabla.
  final double viewport;

  /// Ancho de la celda de acciones; 0 si nadie tiene acciones.
  final double ancho;

  /// La tabla es mas ancha que lo visible.
  final bool hayScroll;
}

/// La celda de acciones **pegada al borde derecho visible**: acompana al scroll
/// para quedar siempre a la vista. Dejarla al final de una tabla ancha seria
/// esconder las acciones a quien tiene una ventana angosta.
class _AccionesPegadas extends StatelessWidget {
  const _AccionesPegadas({
    required this.pegado,
    required this.fondo,
    required this.hijo,
  });

  final _Pegado pegado;
  final Color fondo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = pegado.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final offset = c.hasClients ? c.offset : 0.0;
        final maximo =
            c.hasClients && c.position.hasContentDimensions
                ? c.position.maxScrollExtent
                : 0.0;
        // Una linea a la izquierda cuando hay columnas escondidas debajo.
        final hayOculto = pegado.hayScroll && offset < maximo - 1;
        return Positioned(
          left: offset + pegado.viewport - pegado.ancho,
          top: 0,
          bottom: 0,
          width: pegado.ancho,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fondo,
              border:
                  hayOculto
                      ? Border(left: BorderSide(color: cs.outlineVariant))
                      : null,
            ),
            child: Align(alignment: Alignment.centerRight, child: hijo),
          ),
        );
      },
    );
  }
}

class _TablaCheques extends StatefulWidget {
  const _TablaCheques({
    super.key,
    required this.filas,
    required this.primerNumero,
    required this.permisos,
    required this.onAccion,
    required this.pie,
    required this.hoy,
  });

  final List<ChequeFilaEntity> filas;
  final int primerNumero;
  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final Widget pie;
  final DateTime hoy;

  @override
  State<_TablaCheques> createState() => _TablaChequesState();
}

class _TablaChequesState extends State<_TablaCheques> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondoFila = cs.surfaceContainerLow;
    // La cabecera lleva un tinte del color principal del tema: separa los
    // rotulos de los datos sin inventar un color.
    final fondoCabecera = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.10),
      fondoFila,
    );
    final estiloCabecera = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: Peso.dato,
      color: cs.onSurface,
      letterSpacing: 0.1,
    );

    // Las acciones miden lo que la fila con mas: sin esto un administrador
    // (cuatro iconos) apretaria a quien solo ve dos.
    final maxAcciones = widget.filas.fold<int>(
      0,
      (m, f) => math.max(m, accionesDeFila(widget.permisos, f).length),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: fondoFila,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final viewport = constraints.maxWidth;
              final plan = _planear(viewport, maxAcciones);
              final pegado = _Pegado(
                controller: _horizontal,
                viewport: viewport,
                ancho: plan.anchoAcciones,
                hayScroll: plan.hayScroll,
              );

              final cuerpo = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: fondoCabecera,
                      border: Border(
                        bottom: BorderSide(
                          color: cs.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Esp.l,
                            vertical: Esp.m,
                          ),
                          child: _fila(
                            plan,
                            (c) => Text(
                              c.titulo,
                              style: estiloCabecera,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (plan.anchoAcciones > 0)
                          _AccionesPegadas(
                            pegado: pegado,
                            fondo: fondoCabecera,
                            hijo:
                                plan.menu
                                    ? const SizedBox.shrink()
                                    : Padding(
                                      padding: const EdgeInsets.only(
                                        right: Esp.l,
                                      ),
                                      child: Text(
                                        'Acciones',
                                        style: estiloCabecera,
                                      ),
                                    ),
                          ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < widget.filas.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                    _FilaCheque(
                      key: ValueKey('fila-${widget.filas[i].codCheque}'),
                      numero: widget.primerNumero + i,
                      indice: i,
                      cheque: widget.filas[i],
                      permisos: widget.permisos,
                      onAccion: widget.onAccion,
                      plan: plan,
                      pegado: pegado,
                      fondo: fondoFila,
                      hoy: widget.hoy,
                    ),
                  ],
                ],
              );

              final tabla =
                  !plan.hayScroll
                      ? cuerpo
                      // La barra va a la vista, no escondida: sin ella no se
                      // sabe que hay mas columnas a la derecha.
                      : ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thickness: const WidgetStatePropertyAll(10),
                          radius: const Radius.circular(5),
                          thumbColor: WidgetStatePropertyAll(
                            cs.primary.withValues(alpha: 0.6),
                          ),
                          trackColor: WidgetStatePropertyAll(
                            cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                          trackVisibility: const WidgetStatePropertyAll(true),
                        ),
                        child: Scrollbar(
                          controller: _horizontal,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontal,
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              // La barra queda en su propia franja y no se
                              // encima al texto de la ultima fila.
                              padding: const EdgeInsets.only(bottom: Esp.l),
                              child: SizedBox(
                                width: plan.anchoCuerpo,
                                child: cuerpo,
                              ),
                            ),
                          ),
                        ),
                      );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabla,
                  if (plan.ocultas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Esp.l,
                        Esp.s,
                        Esp.l,
                        Esp.xs,
                      ),
                      child: Text(
                        'Por falta de ancho no se muestran: '
                        '${plan.ocultas.map((c) => c.titulo).join(', ')}. '
                        'Están en «Completar» y en una ventana más ancha.',
                        key: const ValueKey('columnas-ocultas'),
                        style: context.apagado(),
                      ),
                    ),
                ],
              );
            },
          ),
          // La paginacion no se desplaza con las columnas.
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: widget.pie,
          ),
        ],
      ),
    );
  }
}

class _FilaCheque extends StatefulWidget {
  const _FilaCheque({
    super.key,
    required this.numero,
    required this.indice,
    required this.cheque,
    required this.permisos,
    required this.onAccion,
    required this.plan,
    required this.pegado,
    required this.fondo,
    required this.hoy,
  });

  final int numero;

  /// Posicion en la pagina, para el cebrado.
  final int indice;
  final ChequeFilaEntity cheque;
  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final _PlanTabla plan;
  final _Pegado pegado;
  final Color fondo;
  final DateTime hoy;

  @override
  State<_FilaCheque> createState() => _FilaChequeState();
}

class _FilaChequeState extends State<_FilaCheque> {
  /// El mouse esta sobre la fila: se resalta y sus iconos se tinen del primario.
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cheque;
    final plan = widget.plan;
    final pegado = widget.pegado;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cifras = context.cifraCheque();
    final acciones = accionesDeFila(widget.permisos, c);
    final situacion = situacionDeCheque(
      estado: c.cheque.estado,
      fechaCobrar: c.cheque.fechaCobrar,
      hoy: widget.hoy,
    );

    // Cebrado muy tenue en las filas impares y, bajo el mouse, un tinte del
    // primario. La celda de acciones pegada pinta el mismo fondo: si no, taparia
    // la fila con otro color.
    final base =
        widget.indice.isOdd
            ? Color.alphaBlend(
              cs.onSurface.withValues(alpha: 0.03),
              widget.fondo,
            )
            : widget.fondo;
    final fondo =
        _sobre
            ? Color.alphaBlend(cs.primary.withValues(alpha: 0.08), base)
            : base;

    Widget celda(_Col col) => switch (col.id) {
      'num' => Text(
        '${widget.numero}',
        style: cifras.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
      ),
      'recepcion' => Text(
        textoFecha(c.fechaRecepcion),
        style: cifras,
        maxLines: 1,
      ),
      'cliente' => _Texto(
        c.datoCliente,
        estilo: t.bodyMedium?.copyWith(fontWeight: Peso.dato),
        lineas: 3,
      ),
      'nro' => _Texto(c.cheque.nrocheque, estilo: context.cifraCheque(fuerte: true)),
      'banco' => BancoCheque(c.nombreBanco),
      'orden' => _Texto(textoODash(c.cheque.aOrdenDe), lineas: 3),
      'monto' => ImporteCheque(cheque: c),
      'fcheque' => Text(
        textoFecha(c.cheque.fechaCheque),
        style: cifras,
        maxLines: 1,
      ),
      // La fecha y, debajo, cuanto falta o cuanto se paso, en el color de la
      // situacion. Los cerrados no llevan nada: el estado ya lo dice.
      'fcobro' => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(textoFecha(c.cheque.fechaCobrar), style: cifras, maxLines: 1),
          TextoSituacionCheque(situacion: situacion),
        ],
      ),
      'tipo' => TipoCheque(c),
      'estado' => EtiquetaEstadoCheque(
        estado: c.cheque.estado,
        texto: c.descEstado,
      ),
      'entrega' => EntregadoPorCheque(cheque: c, texto: textoEntregadoPor(c)),
      _ => const SizedBox.shrink(),
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      child: Stack(
        children: [
          Container(
            color: fondo,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.s,
            ),
            child: _fila(plan, celda),
          ),
          // La franja de acento: el color de la situacion de cobro.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: FranjaCheque(color: colorFranjaCheque(context, situacion.situacion)),
          ),
          // Con acciones o sin ellas (otro estado, otros permisos) la celda
          // pegada tapa lo que quede debajo, sin dejar un hueco.
          if (pegado.ancho > 0)
            _AccionesPegadas(
              pegado: pegado,
              fondo: fondo,
              hijo:
                  plan.menu
                      ? (acciones.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                            padding: const EdgeInsets.only(right: Esp.xs),
                            child: MenuAccionesCheque(
                              opciones: [
                                for (final a in acciones)
                                  OpcionMenuCheque(
                                    a.etiqueta,
                                    a.icono,
                                    () => widget.onAccion(a, c),
                                  ),
                              ],
                            ),
                          ))
                      : Padding(
                        padding: const EdgeInsets.only(right: Esp.m),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final a in acciones)
                              IconButton(
                                tooltip: a.etiqueta,
                                onPressed: () => widget.onAccion(a, c),
                                icon: Icon(a.icono, size: 20),
                                // El tamano de un IconButton de Material 3 (40)
                                // no se acota con `constraints`: se fija en su
                                // estilo. Neutros, y del primario con el mouse
                                // sobre la fila.
                                style: IconButton.styleFrom(
                                  foregroundColor:
                                      _sobre ? cs.primary : cs.onSurfaceVariant,
                                  minimumSize: const Size.square(
                                    _anchoIconoAccion,
                                  ),
                                  maximumSize: const Size.square(
                                    _anchoIconoAccion,
                                  ),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                      ),
            ),
        ],
      ),
    );
  }
}

/// Texto con puntos suspensivos; el tooltip deja leer lo cortado.
class _Texto extends StatelessWidget {
  const _Texto(this.texto, {this.estilo, this.lineas = 1});

  final String texto;
  final TextStyle? estilo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      texto,
      style: estilo,
      maxLines: lineas,
      overflow: TextOverflow.ellipsis,
    );
    return texto.isEmpty ? t : Tooltip(message: texto, child: t);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _TarjetasCheques extends StatelessWidget {
  const _TarjetasCheques({
    super.key,
    required this.ancho,
    required this.filas,
    required this.primerNumero,
    required this.permisos,
    required this.onAccion,
    required this.pie,
    required this.hoy,
  });

  final double ancho;
  final List<ChequeFilaEntity> filas;
  final int primerNumero;
  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final Widget pie;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final columnas =
        ((ancho + Esp.m) / (anchoMinimoTarjeta + Esp.m)).floor().clamp(1, 3);
    // Hacia abajo: la suma nunca pasa del ancho y la ultima tarjeta no salta de
    // linea por un error de redondeo.
    final anchoTarjeta =
        ((ancho - Esp.m * (columnas - 1)) / columnas).floorToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (var i = 0; i < filas.length; i++)
              SizedBox(
                key: ValueKey('fila-${filas[i].codCheque}'),
                width: anchoTarjeta,
                child: _TarjetaCheque(
                  numero: primerNumero + i,
                  cheque: filas[i],
                  permisos: permisos,
                  onAccion: onAccion,
                  hoy: hoy,
                ),
              ),
          ],
        ),
        const SizedBox(height: Esp.m),
        pie,
      ],
    );
  }
}

class _TarjetaCheque extends StatelessWidget {
  const _TarjetaCheque({
    required this.numero,
    required this.cheque,
    required this.permisos,
    required this.onAccion,
    required this.hoy,
  });

  final int numero;
  final ChequeFilaEntity cheque;
  final PermisosCheque permisos;
  final AlElegirAccionCheque onAccion;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final c = cheque;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final acciones = accionesDeFila(permisos, c);
    final situacion = situacionDeCheque(
      estado: c.cheque.estado,
      fechaCobrar: c.cheque.fechaCobrar,
      hoy: hoy,
    );
    final tipo = (c.descTipo ?? '').trim();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Esp.l + 4,
              Esp.m,
              Esp.xs,
              Esp.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Esp.s,
                        runSpacing: Esp.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Insignia('#$numero'),
                          EtiquetaEstadoCheque(
                            estado: c.cheque.estado,
                            texto: c.descEstado,
                          ),
                          // El plazo del cobro, solo en los pendientes con
                          // fecha: «Atrasado 12 d», «Cobra hoy», «En 3 d».
                          if (situacion.tienePlazo)
                            PastillaSituacionCheque(situacion: situacion),
                        ],
                      ),
                    ),
                    if (acciones.isNotEmpty)
                      MenuAccionesCheque(
                        opciones: [
                          for (final a in acciones)
                            OpcionMenuCheque(
                              a.etiqueta,
                              a.icono,
                              () => onAccion(a, c),
                            ),
                        ],
                      )
                    else
                      const SizedBox(height: Esp.xl),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: Esp.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.datoCliente.isEmpty ? '—' : c.datoCliente,
                        style: t.titleSmall?.copyWith(fontWeight: Peso.dato),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Esp.s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MonogramaBanco(c.nombreBanco),
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textoODash(c.nombreBanco),
                                  style: t.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Cheque ${c.cheque.nrocheque}',
                                  style: context.cifraCheque(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.m),
                      ImporteCheque(
                        cheque: c,
                        tam: 22,
                        alineacion: Alignment.centerLeft,
                      ),
                      const SizedBox(height: Esp.m),
                      Divider(height: 1, color: cs.outlineVariant),
                      const SizedBox(height: Esp.s),
                      // Las tres fechas, lado a lado mientras entren.
                      Wrap(
                        spacing: Esp.l,
                        runSpacing: Esp.s,
                        children: [
                          _MiniFecha('Recepción', textoFecha(c.fechaRecepcion)),
                          _MiniFecha(
                            'Fecha cheque',
                            textoFecha(c.cheque.fechaCheque),
                          ),
                          // El plazo ya esta en la pastilla de arriba.
                          _MiniFecha(
                            'Fecha cobro',
                            textoFecha(c.cheque.fechaCobrar),
                          ),
                        ],
                      ),
                      const SizedBox(height: Esp.s),
                      _Campo('A la orden de', textoODash(c.cheque.aOrdenDe)),
                      if (tipo.isNotEmpty)
                        _Campo('Tipo', tipo, hijo: TipoCheque(c)),
                      _Campo(
                        'Entregado por',
                        textoEntregadoPor(c),
                        hijo: EntregadoPorCheque(
                          cheque: c,
                          texto: textoEntregadoPor(c),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // La franja de acento: el color de la situacion de cobro.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: FranjaCheque(
              color: colorFranjaCheque(context, situacion.situacion),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fecha de la tarjeta: la etiqueta chica arriba y la cifra en mono debajo.
class _MiniFecha extends StatelessWidget {
  const _MiniFecha(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: context.apagado()),
        const SizedBox(height: 2),
        Text(valor, style: context.cifraCheque(), maxLines: 1),
      ],
    );
  }
}

/// Fila «etiqueta: valor» de la tarjeta. Con texto muy grande la etiqueta pasa
/// arriba del valor: lado a lado se tocarian o el valor quedaria en una
/// columna de tres letras. [hijo] reemplaza al texto cuando el valor lleva
/// icono o pastilla.
class _Campo extends StatelessWidget {
  const _Campo(this.etiqueta, this.valor, {this.hijo});

  final String etiqueta;
  final String valor;
  final Widget? hijo;

  @override
  Widget build(BuildContext context) {
    final valorTexto = Text(
      valor,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final apilado = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child:
          apilado
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: context.apagado()),
                  hijo ?? valorTexto,
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(etiqueta, style: context.apagado()),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: hijo ?? valorTexto,
                    ),
                  ),
                ],
              ),
    );
  }
}

/// El `#n` de la tarjeta.
class _Insignia extends StatelessWidget {
  const _Insignia(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
        child: Text(
          texto,
          style: context.cifraCheque(
            fuerte: true,
            color: cs.onSurfaceVariant,
            tam: 11.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINACION
// ═══════════════════════════════════════════════════════════════════════════

/// «Pagina 2 de 7 · 135 cheques» y los botones de anterior y siguiente. En
/// anchos chicos los botones bajan a una segunda linea en vez de desbordar.
class PaginadorCheques extends StatelessWidget {
  const PaginadorCheques({
    super.key,
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final int pagina;
  final int totalPaginas;
  final int total;

  /// Null deshabilita el boton (no hay pagina anterior / siguiente).
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.l,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: Text(
            'Página $pagina de $totalPaginas · $total ${total == 1 ? 'cheque' : 'cheques'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: onAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: onSiguiente,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

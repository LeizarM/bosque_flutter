import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formulario_aprobador.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_grupos_aprobadores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_rama_aprobador.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Ancho de la tarjeta de un grupo desde el que sus encargados van en
/// columnas alineadas; por debajo, apilados.
const double anchoColumnasAprobadoresHex = 720;

/// La lista se pide entera: el filtro de empleado y las cerradas se aplican
/// en la app al agrupar (el SP solo filtra por aprobador).
const FiltroAprobadoresHex _todos = (codEmpleado: null, nivel: null);

// Proporciones de las columnas de un nodo en el ancho.
const int _flexQuien = 30;
const int _flexRama = 13;
const int _flexVigencia = 25;
const int _flexEstado = 14;

/// «Ver rama» con texto y el menú ⋮, a la derecha de cada nodo en el ancho.
const double _anchoAcciones = 176;

const String _sinRolEncargado =
    'No tiene rol de encargado vigente: no firma a su rama.';

/// `thexParametros/Aprobadores` agrupado por jefe de área: cada jefe con los
/// encargados que aprueba (D35) y, al final, los encargados sin jefe (D34).
/// Vigencias e historial de cambios (D22); lo que vale lo decide el SP.
class HexAprobadoresScreen extends ConsumerStatefulWidget {
  const HexAprobadoresScreen({super.key});

  @override
  ConsumerState<HexAprobadoresScreen> createState() =>
      _HexAprobadoresScreenState();
}

class _HexAprobadoresScreenState extends ConsumerState<HexAprobadoresScreen> {
  final ScrollController _desplazamiento = ScrollController();

  /// Una eliminación en curso: deshabilita las acciones y el «atrás».
  final OcupadoHex _eliminando = OcupadoHex();

  BigInt? _codEmpleado;
  bool _conCerradas = false;

  @override
  void initState() {
    super.initState();
    _eliminando.addListener(_alCambiarEliminando);
  }

  @override
  void dispose() {
    _eliminando
      ..removeListener(_alCambiarEliminando)
      ..dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alCambiarEliminando() {
    if (mounted) setState(() {});
  }

  /// Tras escribir: la lista y el historial, donde el cambio cae en la
  /// primera página.
  void _refrescar() {
    ref
      ..invalidate(hexAprobadoresProvider)
      ..invalidate(hexHistorialConfiguracionProvider);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═════════════════════════════════════════════════════════════════════════

  /// Con una eliminación en curso la acción queda deshabilitada.
  VoidCallback? _libre(VoidCallback abrir) => _eliminando.value ? null : abrir;

  void _asignar() => asignarAprobadorHex(context, ref, refrescar: _refrescar);

  /// «Ver rama» es lectura: la ve quien ve la lista. Sale del rol del
  /// encargado o, sin él, del par (la rama del encargado aprobado).
  AccionHex _verRama(NodoEncargadoHex n) {
    final fila = n.rol ?? n.par!;
    return AccionHex(
      'Ver rama',
      Icons.account_tree_outlined,
      codRamaAprobadorHex(fila) == null
          ? null
          : () => mostrarRamaAprobadorHex(context, fila),
    );
  }

  /// Cerrar y eliminar la fila del par (nivel 2 o 3) y la del rol (nivel 1), con
  /// el botón de editar. Si valen lo decide el SP.
  List<AccionHex> _acciones(NodoEncargadoHex n) => [
    if (n.par case final par? when par.idAprobador != null)
      ..._cerrarYEliminar(
        par,
        cerrar:
            par.nivel == 3
                ? 'Cerrar observación'
                : 'Cerrar aprobación del jefe',
        eliminar:
            par.nivel == 3
                ? 'Eliminar observación'
                : 'Eliminar aprobación del jefe',
      ),
    if (n.rol case final rol? when rol.idAprobador != null)
      ..._cerrarYEliminar(
        rol,
        cerrar: 'Cerrar rol de encargado',
        eliminar: 'Eliminar rol de encargado',
      ),
  ];

  List<AccionHex> _cerrarYEliminar(
    HexAprobadorEntity a, {
    required String cerrar,
    required String eliminar,
  }) => [
    AccionHex(
      cerrar,
      Icons.event_busy_outlined,
      _libre(() => cerrarAprobadorHex(context, ref, a, refrescar: _refrescar)),
      boton: BotonHex.editarAprobador,
    ),
    AccionHex(
      eliminar,
      Icons.delete_outline,
      _libre(
        () => eliminarAprobadorHex(
          context,
          ref,
          a,
          ocupado: _eliminando,
          refrescar: _refrescar,
        ),
      ),
      boton: BotonHex.editarAprobador,
      destructiva: true,
    ),
  ];

  // ═════════════════════════════════════════════════════════════════════════
  // PANTALLA
  // ═════════════════════════════════════════════════════════════════════════

  /// Un solo desplazamiento para la pantalla; en el ancho, filtros a la vista
  /// y en el angosto, plegados. Un 403 ocupa el lugar de filtros y grupos.
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
            final enFila = anchoLista >= hexAnchoTabla;
            final datos = ref.watch(hexAprobadoresProvider(_todos));
            final sinPermiso = datos.error is SinPermisoHex;
            return PaginaDesplazableHex(
              controlador: _desplazamiento,
              relleno: relleno,
              abajo: abajo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoHex(
                    titulo: 'Aprobadores',
                    detalle:
                        enFila
                            ? 'Los encargados dan el visto bueno a su rama: '
                                'todos los cargos debajo del suyo en el '
                                'organigrama. Los jefes de área aprueban lo que '
                                'firman los encargados que tienen asignados. '
                                'Cerrar o eliminar un rol queda en el '
                                'historial.'
                            : null,
                    acciones: [
                      PermissionWidget(
                        buttonName: BotonHex.editarAprobador,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: _libre(_asignar),
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 18,
                          ),
                          label: const Text('Asignar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Esp.l),
                  if (!sinPermiso) ...[
                    enFila ? _filtros(enFila: true) : _filtrosPlegables(),
                    const SizedBox(height: Esp.m),
                  ],
                  _lista(datos),
                  const SizedBox(height: Esp.xxl),
                  HistorialConfiguracionHex(
                    entidad: EntidadConfiguracionHex.aprobador,
                    altoMaximo: alto,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  /// Empleado (jefe o encargado) y «Mostrar cerradas»; se aplican en la app.
  Widget _filtros({required bool enFila}) {
    final empleado = CampoAgendaHex<BigInt>(
      etiqueta: 'Empleado',
      pista: 'Todos',
      valor: _codEmpleado,
      opciones: personasDeAgendaHex,
      textoQuitar: 'Quitar el filtro',
      alElegir: (v) => setState(() => _codEmpleado = v),
      alQuitar: () => setState(() => _codEmpleado = null),
    );
    final cerradas = FilterChip(
      label: const Text('Mostrar cerradas'),
      selected: _conCerradas,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (v) => setState(() => _conCerradas = v),
    );
    if (enFila) {
      return Wrap(
        spacing: Esp.m,
        runSpacing: Esp.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [SizedBox(width: 320, child: empleado), cerradas],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        empleado,
        const SizedBox(height: Esp.s),
        Align(alignment: Alignment.centerLeft, child: cerradas),
      ],
    );
  }

  /// En el angosto los filtros van dentro de «Filtros», plegados.
  Widget _filtrosPlegables() => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.tune, size: 20),
      title: const Text('Filtros'),
      childrenPadding: const EdgeInsets.only(bottom: Esp.s),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [_filtros(enFila: false)],
    ),
  );

  /// Mientras carga o si falla, un estado del alto de la lista; con datos,
  /// una tarjeta por grupo.
  Widget _lista(AsyncValue<List<HexAprobadorEntity>> datos) {
    Widget estado(Widget hijo) => SizedBox(height: hexAltoEstado, child: hijo);
    return datos.when(
      skipLoadingOnReload: true,
      loading: () => estado(const EsqueletoLista()),
      error:
          (e, _) => estado(
            e is SinPermisoHex
                ? const SinPermisoHexVista()
                : vistaErrorHex(
                  e,
                  reintentar: () => ref.invalidate(hexAprobadoresProvider),
                ),
          ),
      data: (filas) {
        final hoy = DateUtils.dateOnly(DateTime.now());
        final grupos = agruparAprobadoresHex(
          filas,
          hoy: hoy,
          conCerradas: _conCerradas,
          codEmpleado: _codEmpleado,
        );
        if (grupos.isEmpty) {
          return estado(
            MensajeVacio(
              icono: Icons.how_to_reg_outlined,
              titulo: 'No hay aprobadores',
              detalle:
                  filas.isNotEmpty || _codEmpleado != null
                      ? 'Cambia o quita los filtros.'
                      : 'Asigna el primero con «Asignar».',
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final g in grupos)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.m),
                child: _GrupoHex(
                  g,
                  hoy: hoy,
                  verRama: _verRama,
                  acciones: _acciones,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRUPO Y NODOS
// ═══════════════════════════════════════════════════════════════════════════

/// Un jefe de área (o «Sin jefe de área») en una tarjeta con borde: su
/// encabezado y sus encargados colgando de una guía de árbol.
class _GrupoHex extends StatelessWidget {
  const _GrupoHex(
    this.grupo, {
    required this.hoy,
    required this.verRama,
    required this.acciones,
  });

  final GrupoAprobadoresHex grupo;
  final DateTime hoy;
  final AccionHex Function(NodoEncargadoHex) verRama;
  final List<AccionHex> Function(NodoEncargadoHex) acciones;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth >= anchoColumnasAprobadoresHex;
        final sangria = columnas ? 28.0 : 20.0;
        final nodos = grupo.nodos;
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: contornoSuperficie(cs),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              columnas ? Esp.l : Esp.m,
              Esp.m,
              columnas ? Esp.s : Esp.xs,
              Esp.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Esp.s),
                  child: _CabeceraGrupoHex(grupo),
                ),
                const SizedBox(height: Esp.s),
                if (columnas) _TitulosColumnasHex(sangria: sangria),
                for (var i = 0; i < nodos.length; i++)
                  _NodoHex(
                    nodos[i],
                    hoy: hoy,
                    ultimo: i == nodos.length - 1,
                    columnas: columnas,
                    sangria: sangria,
                    verRama: verRama(nodos[i]),
                    acciones: acciones(nodos[i]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El jefe con su ficha y cuántos encargados y empleados aprueba; o el
/// título del grupo de encargados sin jefe.
class _CabeceraGrupoHex extends StatelessWidget {
  const _CabeceraGrupoHex(this.grupo);

  final GrupoAprobadoresHex grupo;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo);
    final jefe = grupo.jefe;
    if (jefe == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sin jefe de área', style: titulo),
          const SizedBox(height: 2),
          Text(
            'Ningún jefe de área tiene asignados a estos encargados.',
            style: context.apagado(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(oGuionHex(jefe.nombreAprobador), style: titulo),
            ChipHex(
              texto: oGuionHex(jefe.nivelTexto),
              icono:
                  grupo.esObservador
                      ? Icons.visibility_outlined
                      : Icons.supervisor_account_outlined,
              tono: grupo.esObservador ? TonoHex.neutro : TonoHex.terciario,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${grupo.esObservador ? 'Observa' : 'Aprueba'} a '
          '${cuentaHex(grupo.encargados, 'encargado', 'encargados')} · '
          '${cantidadRamaHex(grupo.empleados)}',
          style: context.apagado(),
        ),
        if (!jefe.aprobadorActivo) const _SinRelacionHex(),
      ],
    );
  }
}

/// Los títulos de las columnas de los nodos, alineados con ellas.
class _TitulosColumnasHex extends StatelessWidget {
  const _TitulosColumnasHex({required this.sangria});

  final double sangria;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    Widget titulo(int flex, String texto) =>
        Expanded(flex: flex, child: Text(texto, style: estilo));
    return Padding(
      padding: EdgeInsets.only(left: sangria, top: Esp.xs, bottom: Esp.xs),
      child: Row(
        children: [
          titulo(_flexQuien, 'Encargado'),
          const SizedBox(width: Esp.m),
          titulo(_flexRama, 'Rama'),
          const SizedBox(width: Esp.m),
          titulo(_flexVigencia, 'Vigencia'),
          const SizedBox(width: Esp.m),
          titulo(_flexEstado, 'Estado'),
          const SizedBox(width: _anchoAcciones),
        ],
      ),
    );
  }
}

/// Un encargado bajo su jefe: en el ancho, columnas con las acciones en
/// línea; en el angosto, apilado con «Ver rama» a la vista y el menú.
class _NodoHex extends StatelessWidget {
  const _NodoHex(
    this.nodo, {
    required this.hoy,
    required this.ultimo,
    required this.columnas,
    required this.sangria,
    required this.verRama,
    required this.acciones,
  });

  final NodoEncargadoHex nodo;
  final DateTime hoy;
  final bool ultimo;
  final bool columnas;
  final double sangria;
  final AccionHex verRama;
  final List<AccionHex> acciones;

  /// «Encargado desde 01/11/2026», del rol; nulo si no hay rol.
  String? get _desdeRol {
    final rol = nodo.rol;
    if (rol == null) return null;
    final que = textoUsableHex(rol.nivelTexto) ?? 'Encargado';
    return '$que ${_rango(rol)}';
  }

  /// «Con este jefe desde …» si el par rige distinto que el rol (o no hay rol).
  String? get _desdePar {
    final par = nodo.par;
    final rol = nodo.rol;
    if (par == null) return null;
    if (rol != null &&
        _mismoDia(par.vigenteDesde, rol.vigenteDesde) &&
        _mismoDia(par.vigenteHasta, rol.vigenteHasta)) {
      return null;
    }
    return 'Con este ${par.nivel == 3 ? 'observador' : 'jefe'} ${_rango(par)}';
  }

  static String _rango(HexAprobadorEntity a) {
    final hasta = a.vigenteHasta;
    final desde = 'desde ${fechaHex(a.vigenteDesde)}';
    return hasta == null ? desde : '$desde hasta ${fechaHex(hasta)}';
  }

  static bool _mismoDia(DateTime? a, DateTime? b) =>
      a == null ? b == null : b != null && DateUtils.isSameDay(a, b);

  /// Fichas solo si no rige hoy: «Programada» o «Cerrada», del rol y, si
  /// difiere, de la aprobación del jefe.
  List<Widget> _estados() {
    final rol = nodo.rol;
    final par = nodo.par;
    final r = rol == null ? null : estadoAprobadorHex(rol, hoy);
    final p = par == null ? null : estadoAprobadorHex(par, hoy);
    final rolDelPar = par?.nivel == 3 ? 'observación' : 'aprobación del jefe';
    return [
      if (r != null && r != EstadoAprobadorHex.vigente)
        _ficha(
          r,
          p == r ? 'Rol de encargado y $rolDelPar' : 'Rol de encargado',
        ),
      if (p != null && p != EstadoAprobadorHex.vigente && p != r)
        _ficha(p, par?.nivel == 3 ? 'Observación' : 'Aprobación del jefe'),
    ];
  }

  static Widget _ficha(EstadoAprobadorHex e, String ayuda) => switch (e) {
    EstadoAprobadorHex.cerrada => ChipHex(
      texto: 'Cerrada',
      icono: Icons.history,
      ayuda: ayuda,
    ),
    _ => ChipHex(
      texto: 'Programada',
      icono: Icons.update,
      tono: TonoHex.pendiente,
      ayuda: ayuda,
    ),
  };

  /// Nombre, cargo (o el aviso del SP) y los avisos que impiden firmar.
  Widget _quien(BuildContext context) {
    final rol = nodo.rol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          oGuionHex(nodo.nombre),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
        ),
        _CargoHex(nodo.datos),
        if (rol == null) ...[
          const SizedBox(height: 2),
          const AvisoCargoHex(_sinRolEncargado),
        ],
        if (rol != null && !rol.aprobadorActivo) const _SinRelacionHex(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _GuiaArbolHex(
        color: cs.outlineVariant,
        ultimo: ultimo,
        ancho: sangria,
        codo: columnas ? null : Esp.s + 10,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: sangria, top: Esp.s, bottom: Esp.s),
        child: columnas ? _enColumnas(context) : _apilado(context),
      ),
    );
  }

  Widget _enColumnas(BuildContext context) {
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
    final par = _desdePar;
    final estados = _estados();
    return Row(
      children: [
        Expanded(flex: _flexQuien, child: _quien(context)),
        const SizedBox(width: Esp.m),
        Expanded(
          flex: _flexRama,
          child: Text(cantidadRamaHex(nodo.datos.cantidadRama), style: cifras),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          flex: _flexVigencia,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_desdeRol case final rol?) Text(rol, style: cifras),
              if (par != null)
                Text(par, style: estiloCifrasHex(context.apagado())),
            ],
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          flex: _flexEstado,
          child: Wrap(spacing: Esp.xs, runSpacing: Esp.xs, children: estados),
        ),
        SizedBox(
          width: _anchoAcciones,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotonPrincipalHex(verRama),
                  AccionesHex(acciones: acciones, enMenu: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _apilado(BuildContext context) {
    final linea = [
      'Rama: ${cantidadRamaHex(nodo.datos.cantidadRama)}',
      if (_desdeRol case final rol?) rol,
      if (_desdePar case final par?) par,
    ].join(' · ');
    final estados = _estados();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _quien(context),
              const SizedBox(height: 2),
              Text(linea, style: context.apagado()),
              if (estados.isNotEmpty) ...[
                const SizedBox(height: Esp.xs),
                Wrap(spacing: Esp.xs, runSpacing: Esp.xs, children: estados),
              ],
              const SizedBox(height: Esp.s),
              BotonPrincipalHex(verRama),
            ],
          ),
        ),
        AccionesHex(acciones: acciones, enMenu: true),
      ],
    );
  }
}

/// La guía del árbol a la izquierda de un nodo: el tronco vertical (hasta el
/// codo en el último) y la rama hacia el nodo, en el trazo tenue del tema.
class _GuiaArbolHex extends CustomPainter {
  const _GuiaArbolHex({
    required this.color,
    required this.ultimo,
    required this.ancho,
    this.codo,
  });

  final Color color;
  final bool ultimo;
  final double ancho;

  /// Alto del codo; nulo: a media altura (la fila en columnas).
  final double? codo;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 6.0;
    final y = math.min(codo ?? size.height / 2, size.height);
    final trazo =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(const Offset(x, 0), Offset(x, ultimo ? y : size.height), trazo)
      ..drawLine(Offset(x, y), Offset(ancho - Esp.s, y), trazo);
  }

  @override
  bool shouldRepaint(_GuiaArbolHex old) =>
      old.color != color ||
      old.ultimo != ultimo ||
      old.ancho != ancho ||
      old.codo != codo;
}

/// El cargo vigente del encargado y, si no tiene, el aviso del SP en ámbar.
class _CargoHex extends StatelessWidget {
  const _CargoHex(this.a);

  final HexAprobadorEntity a;

  @override
  Widget build(BuildContext context) {
    final aviso = textoUsableHex(a.avisoCargo);
    final cargo = textoUsableHex(a.cargo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cargo != null || aviso == null) Text(oGuionHex(cargo)),
        if (aviso != null) AvisoCargoHex(aviso),
      ],
    );
  }
}

/// La persona ya no tiene relación laboral activa: su firma no cuenta.
class _SinRelacionHex extends StatelessWidget {
  const _SinRelacionHex();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.person_off_outlined, size: 16, color: cs.error),
          ),
          const SizedBox(width: Esp.xs),
          Flexible(
            child: Text(
              'Sin relación laboral activa: no firma',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

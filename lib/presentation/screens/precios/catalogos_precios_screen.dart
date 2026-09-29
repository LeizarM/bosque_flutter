import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/color_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/presentacion_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/formularios_catalogos.dart';
import 'package:bosque_flutter/presentation/widgets/precios/panel_catalogo.dart';
import 'package:bosque_flutter/presentation/widgets/precios/sincronizacion_sap.dart';

// Estado local de la pantalla

/// El filtro de activos / inactivos de cada pestaña. Vive aquí y no en
/// `precios_provider.dart`: es estado de ESTA pantalla. Es family porque cada
/// catálogo filtra por su cuenta y autoDispose porque un filtro puesto en una
/// visita no debe reaparecer en la siguiente.
final _filtroEstadoProvider = StateProvider.autoDispose.family<int, String>(
  (ref, catalogo) => estadoTodos,
);

const String _claveColores = 'colores';
const String _claveTipos = 'tipos';
const String _clavePresentaciones = 'presentaciones';

// Pantalla

/// Los seis catálogos simples del módulo de precios, en pestañas: colores, tipos
/// de papel, presentaciones, rangos de gramaje, grupos de familia SAP y
/// proveedores externos SAP. Van juntos: se administran a la vez y ninguno
/// justifica su entrada de menú.
///
/// El diseño cambia con el ancho del CAJÓN ([Aire] sobre `LayoutBuilder`, no
/// `MediaQuery`: en el DashboardScreen la barra lateral se come 260 px).
class CatalogosPreciosScreen extends ConsumerWidget {
  const CatalogosPreciosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);

        // Seis pestañas no entran repartidas en un teléfono (los títulos quedan
        // cortados): si el cajón no da para las seis, la barra se desliza.
        final desliza = aire != Aire.amplio;

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Encabezado(aire: aire),
                  TabBar(
                    isScrollable: desliza,
                    tabAlignment:
                        desliza ? TabAlignment.start : TabAlignment.fill,
                    tabs: [
                      for (final p in _pestanias)
                        desliza
                            ? Tab(text: p.titulo)
                            : Tab(icon: Icon(p.icono), text: p.titulo),
                    ],
                  ),
                  const Divider(height: 1),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _PanelColores(),
                        _PanelTipos(),
                        _PanelPresentaciones(),
                        _PanelRangosGramaje(),
                        _PanelGruposFamiliaSap(),
                        _PanelProveedoresSap(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// El orden de las pestanias: primero lo que describe al papel -color, tipo,
/// presentacion, gramaje- y despues lo que lo vincula con SAP.
const List<({String titulo, IconData icono})> _pestanias = [
  (titulo: 'Colores', icono: Icons.palette_outlined),
  (titulo: 'Tipos', icono: Icons.category_outlined),
  (titulo: 'Presentaciones', icono: Icons.inventory_2_outlined),
  (titulo: 'Rangos', icono: Icons.straighten_outlined),
  (titulo: 'Grupos SAP', icono: Icons.account_tree_outlined),
  (titulo: 'Proveedores', icono: Icons.local_shipping_outlined),
];

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.aire});

  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.s,
      ),
      // En una sola linea cuando entra: el titulo y la bajada apilados cuestan
      // unos 90px de alto util en una pantalla donde lo que importa es la tabla.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Esp.m,
        runSpacing: Esp.xs,
        children: [
          Text(
            'Catálogos de precios',
            style: tt.titleLarge?.copyWith(
              fontWeight: Peso.dato,
              letterSpacing: -0.4,
            ),
          ),
          // En un teléfono la bajada se come un tercio del alto útil y no dice
          // nada que no se sepa a la segunda visita.
          if (!aire.esChico)
            Text(
              'Los datos con los que se arma una familia de producto.',
              style: context.apagado(),
            ),
        ],
      ),
    );
  }
}

// Colores (tpr_color)

class _PanelColores extends ConsumerWidget {
  const _PanelColores();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<ColorProductoEntity>(
      datos: ref.watch(coloresProvider),
      esActivo: (c) => c.esActivo,
      estado: ref.watch(_filtroEstadoProvider(_claveColores)),
      onEstado:
          (v) =>
              ref.read(_filtroEstadoProvider(_claveColores).notifier).state = v,
      hintBuscador: 'Buscar color...',
      textoBuscable: (c) => c.nombreVisible,
      nombre: (c) => c.nombreVisible,
      contar: (n) => n == 1 ? '1 color' : '$n colores',
      onReintentar: () => ref.invalidate(coloresProvider),
      etiquetaNuevo: 'Nuevo color',
      onNuevo: () => _editarColor(context, ref, null),
      onEditar: (c) => _editarColor(context, ref, c),
      onEliminar: (c) => _eliminarColor(context, ref, c),
      iconoVacio: Icons.palette_outlined,
      tituloVacio: 'No hay colores cargados',
      detalleVacio:
          'El color es uno de los datos que describen a una familia de '
          'producto. Cree el primero con «Nuevo color».',
      resumen:
          (todos) => _resumenConEstado(
            total: todos.length,
            activos: todos.where((c) => c.esActivo).length,
            fechas: todos.map((c) => c.audFecha),
            rotuloTotal: 'Colores',
            icono: Icons.palette_outlined,
          ),
      columnas:
          (aire) => [
            ColumnaCatalogo<ColorProductoEntity>(
              'Color',
              ancho: 260,
              expande: true,
              celda: (c) => CeldaTexto(c.nombreVisible, fuerte: true),
            ),
            ColumnaCatalogo<ColorProductoEntity>(
              'Estado',
              ancho: 140,
              celda:
                  (c) => _EtiquetaEstado(
                    activo: c.esActivo,
                    texto: c.estadoLegible,
                  ),
            ),
            ColumnaCatalogo<ColorProductoEntity>(
              'Último movimiento',
              ancho: 170,
              celda: (c) => _Fecha(c.audFecha, conHora: c.audFechaLegible),
            ),
          ],
      tarjeta:
          (c) => TarjetaCatalogo(
            icono: Icons.palette_outlined,
            titulo: c.nombreVisible,
            etiqueta: _EtiquetaEstado(
              activo: c.esActivo,
              texto: c.estadoLegible,
            ),
            datos: [
              if (c.audFecha != null) 'Últ. movimiento ${c.audFechaLegible}',
            ],
            onEditar: () => _editarColor(context, ref, c),
            onEliminar: () => _eliminarColor(context, ref, c),
          ),
    );
  }
}

void _refrescarColores(WidgetRef ref) {
  ref.invalidate(coloresProvider);
  ref.invalidate(coloresActivosProvider);
}

Future<void> _editarColor(
  BuildContext context,
  WidgetRef ref,
  ColorProductoEntity? color,
) async {
  final esNuevo = color == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioNombreEstado(
          titulo: esNuevo ? 'Nuevo color' : 'Editar ${color.nombreVisible}',
          etiquetaCampo: 'Color',
          ayuda: 'No se puede repetir entre los colores activos.',
          maxLargo: 100,
          esNuevo: esNuevo,
          nombreInicial: color?.color ?? '',
          estadoInicial: color?.estado ?? 1,
          onGuardar: (nombre, estado) async {
            await ref
                .read(preciosRepositoryProvider)
                .registrarColor(
                  ColorProductoEntity(
                    idColor: color?.idColor ?? BigInt.zero,
                    color: nombre,
                    estado: estado,
                    // El backend toma el usuario del token JWT y descarta lo
                    // que venga en el cuerpo.
                    audUsuario: BigInt.zero,
                  ),
                );
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarColores(ref);
  mostrarAviso(context, esNuevo ? 'Color creado' : 'Color actualizado');
}

Future<void> _eliminarColor(
  BuildContext context,
  WidgetRef ref,
  ColorProductoEntity color,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar el color ${color.nombreVisible}?',
  detalle:
      'Si alguna familia de producto lo tiene asignado, el sistema va a '
      'rechazar la baja. En ese caso marque el color como inactivo: deja de '
      'ofrecerse sin tocar lo ya cargado.',
  clave: 'color:${color.idColor}',
  accion: () => ref.read(preciosRepositoryProvider).eliminarColor(color),
  refrescar: _refrescarColores,
  mensajeOk: 'Color eliminado',
);

// Tipos de papel (tpr_tipo)

class _PanelTipos extends ConsumerWidget {
  const _PanelTipos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<TipoProductoEntity>(
      datos: ref.watch(tiposProductoProvider),
      esActivo: (t) => t.esActivo,
      estado: ref.watch(_filtroEstadoProvider(_claveTipos)),
      onEstado:
          (v) =>
              ref.read(_filtroEstadoProvider(_claveTipos).notifier).state = v,
      hintBuscador: 'Buscar tipo de papel...',
      textoBuscable: (t) => t.nombreLegible,
      nombre: (t) => t.nombreLegible,
      contar: (n) => n == 1 ? '1 tipo de papel' : '$n tipos de papel',
      onReintentar: () => ref.invalidate(tiposProductoProvider),
      etiquetaNuevo: 'Nuevo tipo',
      onNuevo: () => _editarTipo(context, ref, null),
      onEditar: (t) => _editarTipo(context, ref, t),
      onEliminar: (t) => _eliminarTipo(context, ref, t),
      iconoVacio: Icons.category_outlined,
      tituloVacio: 'No hay tipos de papel cargados',
      detalleVacio:
          'El tipo de papel se cruza con el grupo de familia para decidir el '
          'rango de gramaje. Cree el primero con «Nuevo tipo».',
      resumen:
          (todos) => _resumenConEstado(
            total: todos.length,
            activos: todos.where((t) => t.esActivo).length,
            fechas: todos.map((t) => t.audFecha),
            rotuloTotal: 'Tipos de papel',
            icono: Icons.category_outlined,
          ),
      columnas:
          (aire) => [
            ColumnaCatalogo<TipoProductoEntity>(
              'Tipo de papel',
              ancho: 260,
              expande: true,
              celda: (t) => CeldaTexto(t.nombreLegible, fuerte: true),
            ),
            ColumnaCatalogo<TipoProductoEntity>(
              'Estado',
              ancho: 140,
              celda:
                  (t) => _EtiquetaEstado(
                    activo: t.esActivo,
                    texto: t.estadoLegible,
                  ),
            ),
            ColumnaCatalogo<TipoProductoEntity>(
              'Último movimiento',
              ancho: 170,
              celda: (t) => _Fecha(t.audFecha, conHora: t.audFechaLegible),
            ),
          ],
      tarjeta:
          (t) => TarjetaCatalogo(
            icono: Icons.category_outlined,
            titulo: t.nombreLegible,
            etiqueta: _EtiquetaEstado(
              activo: t.esActivo,
              texto: t.estadoLegible,
            ),
            datos: [
              if (t.audFecha != null) 'Últ. movimiento ${t.audFechaLegible}',
            ],
            onEditar: () => _editarTipo(context, ref, t),
            onEliminar: () => _eliminarTipo(context, ref, t),
          ),
    );
  }
}

void _refrescarTipos(WidgetRef ref) {
  ref.invalidate(tiposProductoProvider);
  ref.invalidate(tiposProductoActivosProvider);
}

Future<void> _editarTipo(
  BuildContext context,
  WidgetRef ref,
  TipoProductoEntity? tipo,
) async {
  final esNuevo = tipo == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioNombreEstado(
          titulo:
              esNuevo ? 'Nuevo tipo de papel' : 'Editar ${tipo.nombreLegible}',
          etiquetaCampo: 'Tipo de papel',
          // El procedimiento acepta 150 (antes truncaba en 50 en silencio).
          ayuda: 'Hasta 150 caracteres.',
          maxLargo: 150,
          esNuevo: esNuevo,
          nombreInicial: tipo?.tipo ?? '',
          estadoInicial: tipo?.estado ?? 1,
          onGuardar: (nombre, estado) async {
            await ref
                .read(preciosRepositoryProvider)
                .registrarTipo(
                  TipoProductoEntity(
                    idTipo: tipo?.idTipo ?? BigInt.zero,
                    tipo: nombre,
                    estado: estado,
                    audUsuario: BigInt.zero,
                  ),
                );
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarTipos(ref);
  mostrarAviso(context, esNuevo ? 'Tipo creado' : 'Tipo actualizado');
}

Future<void> _eliminarTipo(
  BuildContext context,
  WidgetRef ref,
  TipoProductoEntity tipo,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar el tipo ${tipo.nombreLegible}?',
  detalle:
      'Si el tipo está en uso -en una familia o en la configuración de '
      'gramajes- el sistema va a rechazar la baja. En ese caso márquelo como '
      'inactivo.',
  clave: 'tipo:${tipo.idTipo}',
  accion: () => ref.read(preciosRepositoryProvider).eliminarTipo(tipo),
  refrescar: _refrescarTipos,
  mensajeOk: 'Tipo eliminado',
);

// Presentaciones (tpr_presentacion)

class _PanelPresentaciones extends ConsumerWidget {
  const _PanelPresentaciones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<PresentacionProductoEntity>(
      datos: ref.watch(presentacionesProvider),
      esActivo: (p) => p.esActiva,
      estado: ref.watch(_filtroEstadoProvider(_clavePresentaciones)),
      etiquetaActivo: 'Activas',
      etiquetaInactivo: 'Inactivas',
      onEstado:
          (v) =>
              ref
                  .read(_filtroEstadoProvider(_clavePresentaciones).notifier)
                  .state = v,
      hintBuscador: 'Buscar presentación...',
      textoBuscable: (p) => p.nombreLegible,
      nombre: (p) => p.nombreLegible,
      contar: (n) => n == 1 ? '1 presentación' : '$n presentaciones',
      onReintentar: () => ref.invalidate(presentacionesProvider),
      etiquetaNuevo: 'Nueva presentación',
      onNuevo: () => _editarPresentacion(context, ref, null),
      onEditar: (p) => _editarPresentacion(context, ref, p),
      onEliminar: (p) => _eliminarPresentacion(context, ref, p),
      iconoVacio: Icons.inventory_2_outlined,
      tituloVacio: 'No hay presentaciones cargadas',
      detalleVacio:
          'La presentación es la forma en la que se vende el papel: resma, '
          'bobina, paquete. Cree la primera con «Nueva presentación».',
      resumen:
          (todos) => _resumenConEstado(
            total: todos.length,
            activos: todos.where((p) => p.esActiva).length,
            fechas: todos.map((p) => p.audFecha),
            rotuloTotal: 'Presentaciones',
            icono: Icons.inventory_2_outlined,
            femenino: true,
          ),
      columnas:
          (aire) => [
            ColumnaCatalogo<PresentacionProductoEntity>(
              'Presentación',
              ancho: 260,
              expande: true,
              celda: (p) => CeldaTexto(p.nombreLegible, fuerte: true),
            ),
            ColumnaCatalogo<PresentacionProductoEntity>(
              'Estado',
              ancho: 140,
              celda:
                  (p) => _EtiquetaEstado(
                    activo: p.esActiva,
                    texto: p.estadoLegible,
                  ),
            ),
            ColumnaCatalogo<PresentacionProductoEntity>(
              'Último movimiento',
              ancho: 170,
              celda: (p) => _Fecha(p.audFecha),
            ),
          ],
      tarjeta:
          (p) => TarjetaCatalogo(
            icono: Icons.inventory_2_outlined,
            titulo: p.nombreLegible,
            etiqueta: _EtiquetaEstado(
              activo: p.esActiva,
              texto: p.estadoLegible,
            ),
            datos: [
              if (p.audFecha != null)
                'Últ. movimiento ${fechaCorta(p.audFecha)}',
            ],
            onEditar: () => _editarPresentacion(context, ref, p),
            onEliminar: () => _eliminarPresentacion(context, ref, p),
          ),
    );
  }
}

void _refrescarPresentaciones(WidgetRef ref) {
  ref.invalidate(presentacionesProvider);
  ref.invalidate(presentacionesActivasProvider);
  ref.invalidate(presentacionesFiltradasProvider);
}

Future<void> _editarPresentacion(
  BuildContext context,
  WidgetRef ref,
  PresentacionProductoEntity? presentacion,
) async {
  final esNueva = presentacion == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioNombreEstado(
          titulo:
              esNueva
                  ? 'Nueva presentación'
                  : 'Editar ${presentacion.nombreLegible}',
          etiquetaCampo: 'Presentación',
          ayuda: 'Hasta 150 caracteres.',
          maxLargo: 150,
          esNuevo: esNueva,
          nombreInicial: presentacion?.presentacion ?? '',
          estadoInicial: presentacion?.estado ?? 1,
          textoActivo: 'Activa',
          textoInactivo: 'Inactiva',
          onGuardar: (nombre, estado) async {
            await ref
                .read(preciosRepositoryProvider)
                .registrarPresentacion(
                  PresentacionProductoEntity(
                    idPresentacion: presentacion?.idPresentacion ?? BigInt.zero,
                    presentacion: nombre,
                    estado: estado,
                    audUsuario: BigInt.zero,
                    audFecha: null,
                  ),
                );
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarPresentaciones(ref);
  mostrarAviso(
    context,
    esNueva ? 'Presentación creada' : 'Presentación actualizada',
  );
}

Future<void> _eliminarPresentacion(
  BuildContext context,
  WidgetRef ref,
  PresentacionProductoEntity presentacion,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar la presentación ${presentacion.nombreLegible}?',
  detalle:
      'Si hay familias que la usan, el sistema va a rechazar la baja. En ese '
      'caso márquela como inactiva: deja de ofrecerse sin tocar lo ya cargado.',
  clave: 'presentacion:${presentacion.idPresentacion}',
  accion:
      () => ref
          .read(preciosRepositoryProvider)
          .eliminarPresentacion(presentacion),
  refrescar: _refrescarPresentaciones,
  mensajeOk: 'Presentación eliminada',
);

// Rangos de gramaje (tpr_RangoGramaje)

class _PanelRangosGramaje extends ConsumerWidget {
  const _PanelRangosGramaje();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<RangoGramajeEntity>(
      datos: ref.watch(rangosGramajeProvider),
      hintBuscador: 'Buscar rango...',
      textoBuscable: (r) => '${r.rangoLegible} ${r.rangoConDecimales}',
      nombre: (r) => r.rangoLegible,
      contar: (n) => n == 1 ? '1 rango' : '$n rangos',
      onReintentar: () => ref.invalidate(rangosGramajeProvider),
      etiquetaNuevo: 'Nuevo rango',
      onNuevo: () => _editarRango(context, ref, null),
      onEditar: (r) => _editarRango(context, ref, r),
      onEliminar: (r) => _eliminarRango(context, ref, r),
      iconoVacio: Icons.straighten_outlined,
      tituloVacio: 'No hay rangos de gramaje cargados',
      detalleVacio:
          'Cada rango es un intervalo en gramos por metro cuadrado. Cree el '
          'primero con «Nuevo rango».',
      resumen: _resumenRangos,
      columnas:
          (aire) => [
            // El rango legible lo arma la entity: un texto para un dato que en la base son
            // dos columnas, el mismo en tabla, tarjeta y combos del módulo.
            ColumnaCatalogo<RangoGramajeEntity>(
              'Rango',
              ancho: 200,
              expande: true,
              celda: (r) => CeldaTexto(r.rangoLegible, fuerte: true),
            ),
            ColumnaCatalogo<RangoGramajeEntity>(
              'Mínimo',
              ancho: 110,
              alinear: Alignment.centerRight,
              celda: (r) => _Numero(r.min),
            ),
            ColumnaCatalogo<RangoGramajeEntity>(
              'Máximo',
              ancho: 110,
              alinear: Alignment.centerRight,
              celda: (r) => _Numero(r.max),
            ),
            if (aire == Aire.amplio)
              ColumnaCatalogo<RangoGramajeEntity>(
                'Amplitud',
                ancho: 110,
                alinear: Alignment.centerRight,
                ayuda: 'Cuántos gramos abarca el rango: máximo menos mínimo.',
                celda: (r) => _Numero(r.amplitud, apagado: true),
              ),
            ColumnaCatalogo<RangoGramajeEntity>(
              'Último movimiento',
              ancho: 170,
              celda: (r) => _Fecha(r.audFecha),
            ),
          ],
      tarjeta:
          (r) => TarjetaCatalogo(
            icono: Icons.straighten_outlined,
            titulo: r.rangoLegible,
            subtitulo: r.rangoConDecimales,
            datos: [
              if (r.audFecha != null)
                'Últ. movimiento ${fechaCorta(r.audFecha)}',
            ],
            onEditar: () => _editarRango(context, ref, r),
            onEliminar: () => _eliminarRango(context, ref, r),
          ),
    );
  }
}

void _refrescarRangos(WidgetRef ref) {
  ref.invalidate(rangosGramajeProvider);
  ref.invalidate(rangosGramajeComboProvider);
  ref.invalidate(rangosPorGrupoYTipoProvider);
}

Future<void> _editarRango(
  BuildContext context,
  WidgetRef ref,
  RangoGramajeEntity? rango,
) async {
  final esNuevo = rango == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioRangoGramaje(
          rango: rango,
          onGuardar: (nuevo) async {
            await ref
                .read(preciosRepositoryProvider)
                .registrarRangoGramaje(nuevo);
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarRangos(ref);
  mostrarAviso(context, esNuevo ? 'Rango creado' : 'Rango actualizado');
}

Future<void> _eliminarRango(
  BuildContext context,
  WidgetRef ref,
  RangoGramajeEntity rango,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar el rango ${rango.rangoLegible}?',
  detalle:
      'Si el rango está asignado a algún grupo de familia o a un producto, el '
      'sistema va a rechazar la baja.',
  clave: 'rango:${rango.idRangoGram}',
  accion: () => ref.read(preciosRepositoryProvider).eliminarRangoGramaje(rango),
  refrescar: _refrescarRangos,
  mensajeOk: 'Rango eliminado',
);

// Grupos de familia SAP (tpr_grupoFamiliaSap)

class _PanelGruposFamiliaSap extends ConsumerWidget {
  const _PanelGruposFamiliaSap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<GrupoFamiliaSapEntity>(
      datos: ref.watch(gruposFamiliaSapProvider),
      hintBuscador: 'Buscar grupo, alias o código...',
      textoBuscable:
          (g) =>
              '${g.grpFam} ${g.alias} ${g.codGrpFamSap} '
              '${g.codGrpFamSapEpp} ${g.codGrpFamSapProdPap}',
      nombre: (g) => g.nombreVisible,
      contar: (n) => n == 1 ? '1 grupo' : '$n grupos',
      onReintentar: () => ref.invalidate(gruposFamiliaSapProvider),
      etiquetaNuevo: 'Nuevo grupo',
      accionExtra: (compacto) => BotonSincronizarSap(compacto: compacto),
      onNuevo: () => _editarGrupo(context, ref, null),
      onEditar: (g) => _editarGrupo(context, ref, g),
      onEliminar: (g) => _eliminarGrupo(context, ref, g),
      iconoVacio: Icons.account_tree_outlined,
      tituloVacio: 'No hay grupos de familia SAP cargados',
      detalleVacio:
          'El grupo de familia es lo que hace corresponder una familia de '
          'producto con su código en cada SAP. Cree el primero con «Nuevo '
          'grupo».',
      resumen: _resumenGrupos,
      columnas:
          (aire) => [
            ColumnaCatalogo<GrupoFamiliaSapEntity>(
              'Grupo',
              ancho: 220,
              expande: true,
              celda: (g) => CeldaTexto(g.grpFam, fuerte: true),
            ),
            // Con el cajón apretado los tres códigos se resumen en una línea: cinco columnas
            // en 600 px dejan 120 px por columna y no entra ni el título.
            if (aire != Aire.amplio)
              ColumnaCatalogo<GrupoFamiliaSapEntity>(
                'Códigos SAP',
                ancho: 240,
                celda: (g) => CeldaTexto(_codigosSap(g), apagado: true),
              ),
            if (aire == Aire.amplio) ...[
              ColumnaCatalogo<GrupoFamiliaSapEntity>(
                'Alias',
                ancho: 180,
                celda: (g) => CeldaTexto(g.alias),
              ),
              ColumnaCatalogo<GrupoFamiliaSapEntity>(
                'IMPEXPAP',
                ancho: 110,
                celda: (g) => _Codigo(g.codGrpFamSap),
              ),
              ColumnaCatalogo<GrupoFamiliaSapEntity>(
                'ESPPAPEL',
                ancho: 110,
                celda: (g) => _Codigo(g.codGrpFamSapEpp),
              ),
              ColumnaCatalogo<GrupoFamiliaSapEntity>(
                'PRODUCTIVA',
                ancho: 110,
                celda: (g) => _Codigo(g.codGrpFamSapProdPap),
              ),
            ],
            ColumnaCatalogo<GrupoFamiliaSapEntity>(
              'Mapeo',
              ancho: 120,
              ayuda:
                  'En cuántas de las tres empresas SAP tiene código el grupo.',
              celda:
                  (g) => Etiqueta(
                    texto: '${g.empresasConfiguradas}/3 SAP',
                    tono: _tonoMapeo(g),
                  ),
            ),
          ],
      tarjeta:
          (g) => TarjetaCatalogo(
            icono: Icons.account_tree_outlined,
            titulo: g.nombreVisible,
            etiqueta: Etiqueta(
              texto: '${g.empresasConfiguradas}/3 SAP',
              tono: _tonoMapeo(g),
            ),
            subtitulo:
                g.aliasDistinto == null ? null : 'Alias: ${g.aliasDistinto}',
            datos: [_codigosSap(g)],
            onEditar: () => _editarGrupo(context, ref, g),
            onEliminar: () => _eliminarGrupo(context, ref, g),
          ),
    );
  }
}

TonoEtiqueta _tonoMapeo(GrupoFamiliaSapEntity g) {
  if (g.mapeoCompleto) return TonoEtiqueta.exito;
  if (g.sinMapeo) return TonoEtiqueta.error;
  return TonoEtiqueta.aviso;
}

void _refrescarGrupos(WidgetRef ref) {
  ref.invalidate(gruposFamiliaSapProvider);
  ref.invalidate(gruposFamiliaSapFiltradosProvider);
}

Future<void> _editarGrupo(
  BuildContext context,
  WidgetRef ref,
  GrupoFamiliaSapEntity? grupo,
) async {
  final esNuevo = grupo == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioGrupoFamiliaSap(
          grupo: grupo,
          onGuardar: (nuevo) async {
            await ref
                .read(preciosRepositoryProvider)
                .registrarGrupoFamiliaSap(nuevo);
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarGrupos(ref);
  mostrarAviso(context, esNuevo ? 'Grupo creado' : 'Grupo actualizado');
}

Future<void> _eliminarGrupo(
  BuildContext context,
  WidgetRef ref,
  GrupoFamiliaSapEntity grupo,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar el grupo ${grupo.nombreVisible}?',
  detalle:
      'Las familias que cuelgan de este grupo quedan sin correspondencia con '
      'SAP. Si alguna lo referencia, el sistema va a rechazar la baja.',
  clave: 'grupo:${grupo.idGrpFamiliaSap}',
  accion:
      () => ref
          .read(preciosRepositoryProvider)
          .eliminarGrupoFamiliaSap(grupo.idGrpFamiliaSap),
  refrescar: _refrescarGrupos,
  mensajeOk: 'Grupo eliminado',
);

// Proveedores externos SAP (tpr_proveedorExtSap)

class _PanelProveedoresSap extends ConsumerWidget {
  const _PanelProveedoresSap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelCatalogo<ProveedorExtSapEntity>(
      datos: ref.watch(proveedoresSapProvider),
      hintBuscador: 'Buscar proveedor o código...',
      textoBuscable: (p) => p.etiquetaCompleta,
      nombre: (p) => p.nombreLegible,
      contar: (n) => n == 1 ? '1 proveedor' : '$n proveedores',
      onReintentar: () => ref.invalidate(proveedoresSapProvider),
      etiquetaNuevo: 'Nuevo proveedor',
      accionExtra: (compacto) => BotonSincronizarSap(compacto: compacto),
      onNuevo: () => _editarProveedor(context, ref, null),
      onEditar: (p) => _editarProveedor(context, ref, p),
      onEliminar: (p) => _eliminarProveedor(context, ref, p),
      iconoVacio: Icons.local_shipping_outlined,
      tituloVacio: 'No hay proveedores cargados',
      detalleVacio:
          'El proveedor externo es el que figura en SAP para la familia de '
          'producto. Cree el primero con «Nuevo proveedor».',
      resumen: _resumenProveedores,
      columnas:
          (aire) => [
            // El codigo es varchar(20): texto. Se muestra tal cual viene, con
            // sus ceros a la izquierda, y nunca se convierte a numero.
            ColumnaCatalogo<ProveedorExtSapEntity>(
              'Código SAP',
              ancho: 140,
              celda: (p) => _Codigo(p.codProvExtSap),
            ),
            ColumnaCatalogo<ProveedorExtSapEntity>(
              'Proveedor',
              ancho: 300,
              expande: true,
              celda: (p) => CeldaTexto(p.nombreLegible, fuerte: true),
            ),
            ColumnaCatalogo<ProveedorExtSapEntity>(
              'Último movimiento',
              ancho: 170,
              celda: (p) => _Fecha(p.audFecha, conHora: p.audFechaLegible),
            ),
          ],
      tarjeta:
          (p) => TarjetaCatalogo(
            icono: Icons.local_shipping_outlined,
            titulo: p.nombreLegible,
            subtitulo:
                p.tieneCodigo
                    ? 'Código SAP ${p.codProvExtSap.trim()}'
                    : 'Sin código SAP',
            datos: [
              if (p.audFecha != null)
                'Últ. movimiento ${fechaCorta(p.audFecha)}',
            ],
            onEditar: () => _editarProveedor(context, ref, p),
            onEliminar: () => _eliminarProveedor(context, ref, p),
          ),
    );
  }
}

void _refrescarProveedores(WidgetRef ref) {
  ref.invalidate(proveedoresSapProvider);
  ref.invalidate(proveedoresSapComboProvider);
  ref.invalidate(proveedoresSapFiltradosProvider);
}

Future<void> _editarProveedor(
  BuildContext context,
  WidgetRef ref,
  ProveedorExtSapEntity? proveedor,
) async {
  final esNuevo = proveedor == null;
  final guardado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => FormularioProveedorSap(
          proveedor: proveedor,
          onGuardar: (nuevo) async {
            await ref.read(preciosRepositoryProvider).registrarProveedor(nuevo);
          },
        ),
  );

  if (guardado != true) return;
  if (!context.mounted) return;
  _refrescarProveedores(ref);
  mostrarAviso(context, esNuevo ? 'Proveedor creado' : 'Proveedor actualizado');
}

Future<void> _eliminarProveedor(
  BuildContext context,
  WidgetRef ref,
  ProveedorExtSapEntity proveedor,
) => _darDeBaja(
  context,
  ref,
  titulo: '¿Eliminar a ${proveedor.nombreLegible}?',
  detalle:
      'Si alguna familia de producto lo referencia, el sistema va a rechazar '
      'la baja.',
  clave: 'proveedor:${proveedor.idProveedorSap}',
  accion:
      () => ref.read(preciosRepositoryProvider).eliminarProveedor(proveedor),
  refrescar: _refrescarProveedores,
  mensajeOk: 'Proveedor eliminado',
);

// Piezas compartidas por las seis pestañas

/// Las filas con una baja en curso, por catálogo e id ("color:12"): sin esto, un
/// segundo "Eliminar" mandaba otra baja y terminaba en un "no existe".
final Set<String> _bajasEnCurso = <String>{};

/// La baja de cualquiera de los seis catálogos: confirma y, si el registro está
/// referenciado por una familia, el procedimiento devuelve un mensaje de negocio
/// (no el error de clave foránea) que se muestra tal cual.
Future<void> _darDeBaja(
  BuildContext context,
  WidgetRef ref, {
  required String clave,
  required String titulo,
  required String detalle,
  required Future<void> Function() accion,
  required void Function(WidgetRef ref) refrescar,
  required String mensajeOk,
}) async {
  if (_bajasEnCurso.contains(clave)) {
    mostrarAviso(
      context,
      'Ya se está eliminando: espere a que termine.',
      tono: TonoAviso.aviso,
    );
    return;
  }
  final sigue = await confirmar(
    context,
    titulo: titulo,
    detalle: detalle,
    textoConfirmar: 'Eliminar',
    destructiva: true,
  );
  if (!sigue || !_bajasEnCurso.add(clave)) return;

  try {
    await accion();
    if (!context.mounted) return;
    refrescar(ref);
    mostrarAviso(context, mensajeOk);
  } catch (e) {
    if (!context.mounted) return;
    mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
  } finally {
    _bajasEnCurso.remove(clave);
  }
}

/// La etiqueta de activo / inactivo, con el mismo tono en los seis catalogos.
class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.activo, required this.texto});

  final bool activo;
  final String texto;

  @override
  Widget build(BuildContext context) => Etiqueta(
    texto: texto,
    tono: activo ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
  );
}

/// El rojo de lo que falta: el mismo de las bajas.
const Color _matizRojo = Color(0xFFD32F2F);

/// La fecha mas reciente de un catalogo, o null si ninguna fila la trae.
DateTime? _ultimaFecha(Iterable<DateTime?> fechas) {
  DateTime? ultima;
  for (final f in fechas) {
    if (f != null && (ultima == null || f.isAfter(ultima))) ultima = f;
  }
  return ultima;
}

DatoResumen _datoUltimoMovimiento(Iterable<DateTime?> fechas) {
  final ultima = _ultimaFecha(fechas);
  return DatoResumen(
    rotulo: 'Último movimiento',
    valor: fechaCorta(ultima),
    detalle:
        ultima == null ? 'Sin fecha registrada' : 'La edición más reciente',
    matiz: matizVioleta,
    icono: Icons.history,
    corto: ultima == null ? null : 'Últ. movimiento ${fechaCorta(ultima)}',
  );
}

/// El resumen de los tres catalogos con activo / inactivo.
List<DatoResumen> _resumenConEstado({
  required int total,
  required int activos,
  required Iterable<DateTime?> fechas,
  required String rotuloTotal,
  required IconData icono,
  bool femenino = false,
}) {
  final inactivos = total - activos;
  final rotuloActivos = femenino ? 'Activas' : 'Activos';
  final rotuloInactivos = femenino ? 'Inactivas' : 'Inactivos';
  return [
    DatoResumen(
      rotulo: rotuloTotal,
      valor: '$total',
      detalle: 'En el catálogo',
      matiz: matizAzul,
      icono: icono,
    ),
    DatoResumen(
      rotulo: rotuloActivos,
      valor: '$activos',
      detalle: 'Se pueden elegir',
      matiz: matizVerde,
      icono: Icons.check_circle_outline,
      corto: _cuenta(
        activos,
        femenino ? 'activa' : 'activo',
        rotuloActivos.toLowerCase(),
      ),
    ),
    DatoResumen(
      rotulo: rotuloInactivos,
      valor: '$inactivos',
      detalle: 'Ya no se pueden elegir',
      matiz: matizNaranja,
      icono: Icons.pause_circle_outline,
      corto: _cuenta(
        inactivos,
        femenino ? 'inactiva' : 'inactivo',
        rotuloInactivos.toLowerCase(),
      ),
    ),
    _datoUltimoMovimiento(fechas),
  ];
}

List<DatoResumen> _resumenRangos(List<RangoGramajeEntity> todos) {
  var minimo = double.infinity;
  var maximo = double.negativeInfinity;
  for (final r in todos) {
    if (r.min < minimo) minimo = r.min;
    if (r.max > maximo) maximo = r.max;
  }
  final hay = todos.isNotEmpty;
  return [
    DatoResumen(
      rotulo: 'Rangos',
      valor: '${todos.length}',
      detalle: 'En el catálogo',
      matiz: matizAzul,
      icono: Icons.straighten_outlined,
    ),
    DatoResumen(
      rotulo: 'Gramaje más bajo',
      valor: hay ? '${_gramos(minimo)} g' : '--',
      detalle: 'Donde empieza el primer rango',
      matiz: matizVerde,
      icono: Icons.south,
      corto: hay ? 'Desde ${_gramos(minimo)} g' : null,
    ),
    DatoResumen(
      rotulo: 'Gramaje más alto',
      valor: hay ? '${_gramos(maximo)} g' : '--',
      detalle: 'Donde termina el último rango',
      matiz: matizNaranja,
      icono: Icons.north,
      corto: hay ? 'hasta ${_gramos(maximo)} g' : null,
    ),
    _datoUltimoMovimiento(todos.map((r) => r.audFecha)),
  ];
}

List<DatoResumen> _resumenGrupos(List<GrupoFamiliaSapEntity> todos) {
  final completos = todos.where((g) => g.mapeoCompleto).length;
  final sinMapeo = todos.where((g) => g.sinMapeo).length;
  final parciales = todos.length - completos - sinMapeo;
  return [
    DatoResumen(
      rotulo: 'Grupos SAP',
      valor: '${todos.length}',
      detalle: 'En el catálogo',
      matiz: matizAzul,
      icono: Icons.account_tree_outlined,
    ),
    DatoResumen(
      rotulo: 'Mapeo completo',
      valor: '$completos',
      detalle: 'Con código en las tres empresas',
      matiz: matizVerde,
      icono: Icons.task_alt,
      corto: _cuenta(completos, 'completo', 'completos'),
    ),
    DatoResumen(
      rotulo: 'Mapeo parcial',
      valor: '$parciales',
      detalle: 'Falta el código de alguna empresa',
      matiz: matizNaranja,
      icono: Icons.rule,
      corto: _cuenta(parciales, 'parcial', 'parciales'),
    ),
    DatoResumen(
      rotulo: 'Sin mapear',
      valor: '$sinMapeo',
      detalle: 'Sin código en ninguna empresa',
      matiz: _matizRojo,
      icono: Icons.link_off,
      corto: '$sinMapeo sin mapear',
    ),
  ];
}

List<DatoResumen> _resumenProveedores(List<ProveedorExtSapEntity> todos) {
  final conCodigo = todos.where((p) => p.tieneCodigo).length;
  return [
    DatoResumen(
      rotulo: 'Proveedores',
      valor: '${todos.length}',
      detalle: 'En el catálogo',
      matiz: matizAzul,
      icono: Icons.local_shipping_outlined,
    ),
    DatoResumen(
      rotulo: 'Con código SAP',
      valor: '$conCodigo',
      detalle: 'Listos para cargar en SAP',
      matiz: matizVerde,
      icono: Icons.qr_code_2,
      corto: '$conCodigo con código',
    ),
    DatoResumen(
      rotulo: 'Sin código SAP',
      valor: '${todos.length - conCodigo}',
      detalle: 'Hay que completarles el código',
      matiz: matizNaranja,
      icono: Icons.report_gmailerrorred_outlined,
      corto: '${todos.length - conCodigo} sin código',
    ),
    _datoUltimoMovimiento(todos.map((p) => p.audFecha)),
  ];
}

/// "1 activo", "3 activos".
String _cuenta(int n, String uno, String varios) =>
    '$n ${n == 1 ? uno : varios}';

/// Los codigos del grupo en una linea. Es el resumen de la entity con el texto
/// de "ninguno" acentuado.
String _codigosSap(GrupoFamiliaSapEntity g) =>
    g.sinMapeo ? 'Sin códigos SAP' : g.codigosResumen;

/// 80.00 como "80" y 80.50 como "80.5": el mismo criterio del rango legible.
String _gramos(double valor) {
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  final texto = valor.toStringAsFixed(2);
  return texto.endsWith('0') ? texto.substring(0, texto.length - 1) : texto;
}

/// Un gramaje en la tabla, alineado a la derecha con cifras tabulares.
class _Numero extends StatelessWidget {
  const _Numero(this.valor, {this.apagado = false});

  final double valor;
  final bool apagado;

  @override
  Widget build(BuildContext context) => Text(
    '${_gramos(valor)} g',
    maxLines: 1,
    style: context.numero(
      color: apagado ? Theme.of(context).colorScheme.onSurfaceVariant : null,
    ),
  );
}

/// La fecha del ultimo movimiento en la tabla: el dia a la vista y, cuando la
/// entity la trae, la hora en el tooltip.
class _Fecha extends StatelessWidget {
  const _Fecha(this.fecha, {this.conHora});

  final DateTime? fecha;
  final String? conHora;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      fechaCorta(fecha),
      maxLines: 1,
      style: context.numero(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final h = conHora;
    if (fecha == null || h == null || h.isEmpty) return texto;
    return Tooltip(message: h, child: texto);
  }
}

/// Un codigo SAP en la tabla: cifras tabulares para que columnas de codigos de
/// distinto largo no bailen, y un guion cuando la empresa no lo tiene cargado.
class _Codigo extends StatelessWidget {
  const _Codigo(this.valor);

  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = valor.trim();
    if (texto.isEmpty) {
      return Text('—', style: context.apagado());
    }
    return Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.numero(),
    );
  }
}

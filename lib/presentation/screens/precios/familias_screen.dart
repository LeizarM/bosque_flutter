/// El catalogo de familias de producto (`tpr_producto`), nucleo del modulo de
/// Precios: de la familia cuelgan los precios, los porcentajes y los costos
/// sugeridos.
///
/// Reemplaza a `dlgDtFam`, `dlgFam` y `dlgProdV` del monolito — tres dialogos
/// que editaban la misma fila y que entre los tres no daban una lista donde
/// buscar. Aca hay una sola lista, con los filtros del procedimiento, y una sola
/// ficha.
///
/// ## Lo que decide la resolucion
///
/// El corte se mide sobre el ancho del CAJON (`LayoutBuilder`) y no sobre el de
/// la ventana: adentro del `DashboardScreen` el sidebar se come 260 px y
/// `MediaQuery` miente. Con eso:
///
/// * **Web / escritorio:** la planilla de nueve columnas, los filtros a la
///   vista, paginacion y las acciones en la propia fila.
/// * **Movil:** tarjetas con el codigo, la descripcion compuesta y el estado;
///   los filtros adentro de un panel plegable, las acciones en un menu
///   contextual y ni un pixel de scroll horizontal.
///
/// No es la misma grilla achicada: son dos formas distintas de la misma
/// pregunta.
///
/// ## Alta y edicion
///
/// Desde el 2026-09-25 la ficha graba: `PreciosRepository.registrarFamilia`
/// sobre `/price/familia/registrar` y `/price/familia/actualizar`
/// (`p_abm_producto 'I'` y `'U'`). El alta tambien puede partir de otra
/// familia ("Nueva a partir de esta"), que es como nace casi toda familia: la
/// variante de otra con otro gramaje o color.
///
/// El listado arranca en las activas: son las que se reprecian.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/producto_familia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/acciones_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogo_asignar_sap.dart';
import 'package:bosque_flutter/presentation/widgets/precios/dialogo_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/filtros_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/historial_costo_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/pdf_precios.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tarjeta_familia.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Estado local de la pantalla
//
// Vive aca y no en `precios_provider.dart` a proposito: es estado que no debe
// filtrarse a las otras pantallas del modulo, que se estan escribiendo en
// paralelo. El filtro que SI viaja al backend usa `filtroFamiliasProvider`, que
// el provider del modulo declara justamente para esta busqueda.
// ═══════════════════════════════════════════════════════════════════════════

/// Texto libre del buscador. Se aplica del lado del cliente, sobre lo que ya se
/// descargo: el procedimiento del backend filtra por igualdad exacta de codigo o
/// por id de catalogo, no por "contiene".
final _busquedaProvider = StateProvider.autoDispose<String>((ref) => '');

/// Las familias del filtro, ya convertidas a la fila que dibuja la pantalla y
/// ordenadas por codigo.
///
/// La conversion esta aca y no en el `build` para que escribir en el buscador no
/// vuelva a parsear el listado entero en cada tecla: este provider solo se
/// recalcula cuando cambia lo que devolvio el backend.
final _filasProvider = FutureProvider.autoDispose
    .family<List<FamiliaVista>, FiltroFamilias>((ref, filtro) async {
      final crudas = await ref.watch(familiasProvider(filtro).future);
      return crudas.map(FamiliaVista.deMapa).toList()
        ..sort((a, b) => a.codigoFamilia.compareTo(b.codigoFamilia));
    });

// ═══════════════════════════════════════════════════════════════════════════
// La pantalla
// ═══════════════════════════════════════════════════════════════════════════

/// Las familias con una escritura de la fila en curso (baja, reactivacion o
/// eliminacion). Vive fuera de la pantalla, que no tiene estado propio.
final Set<int> _escribiendo = <int>{};

class FamiliasScreen extends ConsumerWidget {
  const FamiliasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        // El ancho del cajon, no el de la ventana.
        final compacto = Aire.de(restricciones.maxWidth).esChico;
        final margen = compacto ? Esp.l : Esp.xl;

        final filtro = ref.watch(filtroFamiliasProvider);
        final busqueda = ref.watch(_busquedaProvider);
        final asyncFilas = ref.watch(_filasProvider(filtro));

        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    onPressed: () => _abrirFicha(context, ref, compacto: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                  )
                  : null,
          // Con el teclado abierto en el telefono (el buscador) el encabezado y
          // los filtros no dejan lugar a la lista: CabezaYLista los acota.
          body: CabezaYLista(
            altoCompacto: 480,
            cabeza: [
              _Encabezado(
                compacto: compacto,
                margen: margen,
                onNueva: () => _abrirFicha(context, ref, compacto: false),
                onRefrescar: () => ref.invalidate(familiasProvider),
                reportes: _reportes(context, ref, filtro),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                child: FiltrosFamilias(
                  compacto: compacto,
                  filtro: filtro,
                  onFiltro:
                      (f) =>
                          ref.read(filtroFamiliasProvider.notifier).state = f,
                  busqueda: busqueda,
                  onBusqueda:
                      (t) => ref.read(_busquedaProvider.notifier).state = t,
                ),
              ),
              const Divider(height: 1),
            ],
            lista: asyncFilas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Padding(
                    padding: EdgeInsets.all(margen),
                    child: MensajeError(
                      error: e,
                      onReintentar: () => ref.invalidate(familiasProvider),
                    ),
                  ),
              data: (filas) {
                final visibles = _aplicarBusqueda(filas, busqueda);

                if (visibles.isEmpty) {
                  return MensajeVacio(
                    icono:
                        filas.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.search_off,
                    titulo:
                        filas.isEmpty
                            ? 'No hay familias con esos criterios'
                            : 'La búsqueda no encontró ninguna',
                    detalle:
                        filas.isEmpty
                            ? 'Pruebe quitando filtros: el código de familia '
                                'busca por igualdad exacta, no por parte del '
                                'número.'
                            : '"$busqueda" no aparece en ninguna de las '
                                '${filas.length} familias traídas. El '
                                'buscador mira solo lo ya listado.',
                  );
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    Esp.m,
                    margen,
                    // Deja pasar el boton flotante por encima de la ultima
                    // tarjeta. Sin boton, ese hueco es solo aire.
                    compacto ? 88 : Esp.l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResumenFamilias(filas: visibles),
                      const SizedBox(height: Esp.s),
                      Expanded(
                        child:
                            compacto
                                ? _ListaMovil(
                                  filas: visibles,
                                  onAbrir:
                                      (f) => _abrirFicha(
                                        context,
                                        ref,
                                        familia: f,
                                        compacto: true,
                                      ),
                                  onNuevaDesde:
                                      (f) => _abrirFicha(
                                        context,
                                        ref,
                                        plantilla: f,
                                        compacto: true,
                                      ),
                                  onAccion:
                                      (f, a) => _accion(context, ref, f, a),
                                )
                                : TablaFamilias(
                                  filas: visibles,
                                  onAbrir:
                                      (f) => _abrirFicha(
                                        context,
                                        ref,
                                        familia: f,
                                        compacto: false,
                                      ),
                                  onNuevaDesde:
                                      (f) => _abrirFicha(
                                        context,
                                        ref,
                                        plantilla: f,
                                        compacto: false,
                                      ),
                                  onAccion:
                                      (f, a) => _accion(context, ref, f, a),
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Los PDF del catalogo, los mismos que ofrecia el sistema anterior desde la
  /// pantalla de autorizacion ("Ver Familias", "Ver Precios" y el combo de
  /// grupo). El del grupo sale del grupo SAP por el que se esta filtrando.
  ReportesFamilias _reportes(
    BuildContext context,
    WidgetRef ref,
    FiltroFamilias filtro,
  ) {
    final repo = ref.read(preciosRepositoryProvider);
    final grupo = filtro.idGrpFamiliaSap;
    return ReportesFamilias(
      familiasActivas:
          () => verPdfDePrecios(
            context,
            generar: repo.reporteFamiliasActivas,
            titulo: 'Familias activas',
            nombreArchivo: 'familias-activas.pdf',
          ),
      preciosTodas:
          () => verPdfDePrecios(
            context,
            generar: repo.reportePreciosTodas,
            titulo: 'Precios por tonelada vigentes',
            nombreArchivo: 'precios-por-tonelada.pdf',
          ),
      preciosGrupo:
          grupo == null
              ? null
              : () => verPdfDePrecios(
                context,
                generar: () => repo.reportePreciosGrupo(grupo),
                titulo: 'Precios por tonelada del grupo',
                nombreArchivo: 'precios-por-tonelada-grupo-$grupo.pdf',
              ),
    );
  }

  /// El buscador mira todo el renglon: codigo, descripciones y estado. Se
  /// comparan minusculas de los dos lados porque nadie escribe "Bond" con
  /// mayuscula al buscar.
  List<FamiliaVista> _aplicarBusqueda(
    List<FamiliaVista> filas,
    String busqueda,
  ) {
    final texto = busqueda.trim().toLowerCase();
    if (texto.isEmpty) return filas;
    return [
      for (final f in filas)
        if (f.textoBuscable.contains(texto)) f,
    ];
  }

  /// Lo que se hace desde la fila sin abrir la ficha. Abrir, "nueva a partir
  /// de" y copiar los resuelven la tabla y la tarjeta.
  Future<void> _accion(
    BuildContext context,
    WidgetRef ref,
    FamiliaVista f,
    AccionFamilia accion,
  ) async {
    // El contenedor y no `ref`: los dialogos van sobre el navegador raiz y la
    // pantalla puede desmontarse mientras estan abiertos (el atras del
    // navegador, una sesion que vence). `ref` despues de eso lanza.
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final repo = contenedor.read(preciosRepositoryProvider);
    final codigo = f.codigoLegible;

    Future<void> escribir(Future<void> Function() op, String listo) async {
      // Un segundo toque mientras la primera escritura viaja reenviaria lo
      // mismo con datos viejos de la fila.
      if (!_escribiendo.add(f.codigoFamilia)) {
        if (context.mounted) {
          mostrarAviso(
            context,
            'La familia $codigo se está actualizando: espere un momento.',
            tono: TonoAviso.aviso,
          );
        }
        return;
      }
      try {
        await op();
        contenedor.invalidate(familiasProvider);
        if (context.mounted) avisar(context, listo);
      } catch (e) {
        if (context.mounted) {
          mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
        }
      } finally {
        _escribiendo.remove(f.codigoFamilia);
      }
    }

    switch (accion) {
      case AccionFamilia.historial:
        await mostrarHistorialCosto(context, f);
      case AccionFamilia.asignarSap:
        if (await mostrarAsignarSap(context, f)) {
          contenedor.invalidate(familiasProvider);
          if (context.mounted) {
            avisar(
              context,
              'Grupo y proveedor SAP de la familia $codigo actualizados.',
            );
          }
        }
      case AccionFamilia.cambiarEstado:
        final baja = f.esActiva;
        final ok = await confirmar(
          context,
          titulo:
              baja
                  ? 'Dar de baja la familia $codigo'
                  : 'Reactivar la familia $codigo',
          detalle:
              baja
                  ? 'Deja de figurar entre las activas y no entra en propuestas '
                      'nuevas. Sus precios, porcentajes y costo quedan como '
                      'están; puede reactivarla cuando quiera.'
                  : 'Vuelve a figurar entre las activas y se puede usar en '
                      'propuestas.',
          textoConfirmar: baja ? 'Dar de baja' : 'Reactivar',
        );
        if (!ok || !context.mounted) return;
        await escribir(
          () => repo.cambiarEstadoFamilia(f.codigoFamilia, activa: !baja),
          baja
              ? 'Familia $codigo dada de baja.'
              : 'Familia $codigo reactivada.',
        );
      case AccionFamilia.eliminar:
        final ok = await confirmar(
          context,
          titulo: 'Eliminar la familia $codigo',
          detalle:
              'Solo se puede eliminar una familia que nunca se usó, por ejemplo '
              'una creada por error: sin artículos, sin propuestas, sin costos y '
              'con sus precios en 0. Se borran también esos precios y sus '
              'porcentajes. Si ya tiene movimiento, el sistema no la elimina y '
              'le indica el motivo; en ese caso, puede darla de baja.',
          textoConfirmar: 'Eliminar',
          destructiva: true,
        );
        if (!ok || !context.mounted) return;
        await escribir(
          () => repo.eliminarFamilia(f.codigoFamilia),
          'Familia $codigo eliminada.',
        );
      case AccionFamilia.abrir:
      case AccionFamilia.nuevaDesde:
      case AccionFamilia.copiar:
        break;
    }
  }

  /// La ficha de la familia. En un telefono es una hoja modal que sube desde
  /// abajo —el gesto de cerrarla es el mismo que el de volver— y en escritorio
  /// un dialogo centrado de ancho acotado: una hoja estirada de punta a punta de
  /// un monitor de 1920 px deja los campos a medio metro uno del otro.
  Future<void> _abrirFicha(
    BuildContext context,
    WidgetRef ref, {
    FamiliaVista? familia,
    FamiliaVista? plantilla,
    required bool compacto,
  }) async {
    final alta = familia == null;
    final contenedor = ProviderScope.containerOf(context, listen: false);
    // Graba y deja que la ficha cierre; si el servidor rechaza, la ficha
    // muestra el motivo y queda abierta con lo cargado. Refresca aca y no al
    // cerrar: la ficha se puede cerrar de mas de una forma (arrastrando la
    // hoja, por ejemplo) y lo grabado tiene que aparecer igual.
    Future<void> guardar(
      ProductoFamiliaEntity f,
      List<PorcentajePrecioEntity>? porcentajes,
    ) async {
      await contenedor
          .read(preciosRepositoryProvider)
          .registrarFamilia(f, alta: alta, porcentajes: porcentajes);
      // Se invalida toda la familia de providers y no solo el filtro actual:
      // al crear o editar una familia cambian tambien los listados de los
      // otros filtros que quedaron en el cache. Y lo que ahora lee distinto la
      // pantalla Porcentajes.
      contenedor.invalidate(familiasProvider);
      contenedor.invalidate(porcentajesPorFamiliaProvider(f.codigoFamilia));
      if (context.mounted) {
        avisar(
          context,
          alta
              ? 'Familia ${f.codigoFamilia} registrada, con sus porcentajes y '
                  'un precio en 0 en cada lista activa.'
              : 'Familia ${f.codigoFamilia} actualizada.',
        );
      }
    }

    compacto
        ? await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder:
              (_) => DialogoFamilia(
                editar: familia,
                plantilla: plantilla,
                onGuardar: guardar,
              ),
        )
        : await showDialog<bool>(
          context: context,
          builder:
              (_) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Esquina.media),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: DialogoFamilia(
                    editar: familia,
                    plantilla: plantilla,
                    onGuardar: guardar,
                    mostrarAsa: false,
                  ),
                ),
              ),
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Encabezado
// ═══════════════════════════════════════════════════════════════════════════

/// Que hace cada opcion del menu de reportes.
@immutable
class ReportesFamilias {
  const ReportesFamilias({
    required this.familiasActivas,
    required this.preciosTodas,
    required this.preciosGrupo,
  });

  final VoidCallback familiasActivas;
  final VoidCallback preciosTodas;

  /// Null mientras no se filtra por un grupo SAP.
  final VoidCallback? preciosGrupo;
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.compacto,
    required this.margen,
    required this.onNueva,
    required this.onRefrescar,
    required this.reportes,
  });

  final bool compacto;
  final double margen;
  final VoidCallback onNueva;
  final VoidCallback onRefrescar;
  final ReportesFamilias reportes;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: Esp.l,
        runSpacing: Esp.s,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Familias de producto',
                style: tt.titleLarge?.copyWith(
                  fontWeight: Peso.dato,
                  letterSpacing: -0.4,
                ),
              ),
              // En un telefono la bajada cuesta un tercio del alto util y no
              // dice nada que no se sepa a la segunda visita.
              if (!compacto)
                Text(
                  'El catálogo del que cuelgan los precios, los porcentajes y '
                  'los costos sugeridos.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuReportes(reportes: reportes, compacto: compacto),
              IconButton(
                onPressed: onRefrescar,
                icon: const Icon(Icons.refresh),
                tooltip: 'Volver a traer el listado',
              ),
              if (!compacto) ...[
                const SizedBox(width: Esp.s),
                Tooltip(
                  message: 'Crear una familia nueva',
                  child: FilledButton.icon(
                    onPressed: onNueva,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva familia'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Los PDF del catalogo. En escritorio es un boton con rotulo, que es donde se
/// lo busca; en el telefono, el icono.
class _MenuReportes extends StatelessWidget {
  const _MenuReportes({required this.reportes, required this.compacto});

  final ReportesFamilias reportes;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<VoidCallback> item(
      IconData icono,
      String titulo,
      String detalle,
      VoidCallback? accion,
    ) => PopupMenuItem<VoidCallback>(
      value: accion,
      enabled: accion != null,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icono),
        title: Text(titulo),
        subtitle: Text(detalle),
      ),
    );

    return PopupMenuButton<VoidCallback>(
      tooltip: 'Reportes en PDF',
      onSelected: (accion) => accion(),
      itemBuilder:
          (_) => [
            item(
              Icons.list_alt_outlined,
              'Familias activas',
              'El catálogo con sus descripciones y costo',
              reportes.familiasActivas,
            ),
            item(
              Icons.price_change_outlined,
              'Precios por tonelada',
              'Todas las familias activas, por grupo',
              reportes.preciosTodas,
            ),
            item(
              Icons.account_tree_outlined,
              'Precios por tonelada del grupo',
              reportes.preciosGrupo == null
                  ? 'Filtre por un grupo SAP para verlo'
                  : 'Las familias del grupo SAP filtrado',
              reportes.preciosGrupo,
            ),
          ],
      child:
          compacto
              ? const Padding(
                padding: EdgeInsets.all(Esp.s),
                child: Icon(Icons.picture_as_pdf_outlined),
              )
              : IgnorePointer(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Reportes'),
                ),
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lista de movil
// ═══════════════════════════════════════════════════════════════════════════

/// Las tarjetas se entregan de a tandas: el catalogo completo son cientos de
/// familias y un telefono no necesita paginador con numeros —nadie salta a la
/// pagina 7 con el pulgar—, necesita no cargar de mas.
class _ListaMovil extends StatefulWidget {
  const _ListaMovil({
    required this.filas,
    required this.onAbrir,
    required this.onNuevaDesde,
    required this.onAccion,
  });

  final List<FamiliaVista> filas;
  final void Function(FamiliaVista familia) onAbrir;
  final void Function(FamiliaVista familia) onNuevaDesde;
  final void Function(FamiliaVista familia, AccionFamilia accion) onAccion;

  @override
  State<_ListaMovil> createState() => _ListaMovilState();
}

class _ListaMovilState extends State<_ListaMovil> {
  static const _tanda = 20;
  int _visibles = _tanda;

  @override
  void didUpdateWidget(_ListaMovil anterior) {
    super.didUpdateWidget(anterior);
    // Otro filtro, otra lista: volver a empezar de arriba.
    if (anterior.filas.length != widget.filas.length) _visibles = _tanda;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.filas.length;
    final hasta = _visibles.clamp(0, total);
    final hayMas = hasta < total;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: hasta + 1,
      itemBuilder: (context, i) {
        if (i == hasta) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.m),
            child: Center(
              child:
                  hayMas
                      ? OutlinedButton.icon(
                        onPressed: () => setState(() => _visibles += _tanda),
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text('Mostrar más (${total - hasta} restantes)'),
                      )
                      : Text(
                        total == 1 ? '1 familia' : '$total familias',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
            ),
          );
        }
        return TarjetaFamilia(
          familia: widget.filas[i],
          onAbrir: () => widget.onAbrir(widget.filas[i]),
          onNuevaDesde: () => widget.onNuevaDesde(widget.filas[i]),
          onAccion: (a) => widget.onAccion(widget.filas[i], a),
        );
      },
    );
  }
}

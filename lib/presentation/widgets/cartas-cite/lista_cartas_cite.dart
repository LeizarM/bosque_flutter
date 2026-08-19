import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/cartas_cite_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/esqueleto_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/identidad_cite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Nombres de los permisos por botón, los mismos que ya usa el sistema viejo
/// (`Loggin.autorizarBtn`), para no tener que dar de alta permisos nuevos.
const _btnEditar = 'btnEditar';
const _btnDuplicar = 'btnDuplicar';

/// El listado de documentos, en tabla o en tarjetas según el ancho.
///
/// El corte no es "es un teléfono" sino **cuánto entra**: la pantalla vive
/// adentro del dashboard, y con el sidebar abierto una ventana de escritorio
/// puede dejar menos lugar que una tablet en horizontal.
///
/// ## Las cuatro cosas que cambian respecto de la primera versión
///
/// - **Cada fila arranca con el sello de su tipo.** Seis tipos escritos con la
///   misma letra en la misma columna obligaban a leer para distinguirlos.
/// - **Mientras carga se dibuja la forma del resultado**, no un spinner: la
///   página deja de saltar cuando llegan los datos.
/// - **Una sola acción a la vista y el resto en el menú.** Antes había cinco
///   íconos por fila, incluida anular —la más rara y la única que no se
///   deshace— a un clic de distancia de la más común.
/// - **La pantalla vacía tiene botón.** Antes decía qué pasaba y dejaba al
///   usuario buscando dónde apretar.
class ListaCartasCite extends ConsumerWidget {
  final Aire aire;
  final CartasCiteState estado;
  final int codUsuario;

  final void Function(CartaCiteEntity) onVer;
  final void Function(CartaCiteEntity) onEditar;
  final void Function(CartaCiteEntity) onDuplicar;
  final void Function(CartaCiteEntity) onImprimir;
  final void Function(CartaCiteEntity) onAnular;

  final VoidCallback onNuevo;
  final VoidCallback onLimpiarFiltros;

  const ListaCartasCite({
    super.key,
    required this.aire,
    required this.estado,
    required this.codUsuario,
    required this.onVer,
    required this.onEditar,
    required this.onDuplicar,
    required this.onImprimir,
    required this.onAnular,
    required this.onNuevo,
    required this.onLimpiarFiltros,
  });

  /// Puede editar quien lo redactó; cualquier otro necesita el permiso.
  /// Es la regla del módulo viejo, que la calculaba con `verBtnxUser`.
  bool _puede(WidgetRef ref, CartaCiteEntity doc, String boton) {
    if (doc.esAutor == 1) return true;
    final user = ref.read(userProvider);
    if (user?.tipoUsuario == 'ROLE_ADM') return true;
    return ref.read(buttonPermissionsProvider).maybeWhen(
          data: (_) => ref.read(buttonPermissionsProvider.notifier).tienePermiso(boton),
          orElse: () => false,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Primera carga: no hay nada que conservar, así que se dibuja el esqueleto.
    if (estado.cargando && estado.items.isEmpty) {
      return EsqueletoListaCite(aire: aire);
    }

    if (estado.items.isEmpty) {
      return _Vacio(
        hayFiltro: estado.hayFiltroTexto,
        onNuevo: onNuevo,
        onLimpiarFiltros: onLimpiarFiltros,
      );
    }

    final padding = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
    );

    final contenido = aire == Aire.amplio
        ? _Tabla(
            padding: padding,
            estado: estado,
            onVer: onVer,
            acciones: (doc) => _accionesTabla(context, ref, doc),
          )
        : ListView.separated(
            padding: padding.copyWith(bottom: Esp.xxl + Esp.xxl),
            itemCount: estado.items.length,
            separatorBuilder: (_, __) => SizedBox(height: Esp.s),
            itemBuilder: (context, i) {
              final doc = estado.items[i];
              return _Tarjeta(
                doc: doc,
                onTap: () => onVer(doc),
                onImprimir: () => onImprimir(doc),
                menu: _menu(context, ref, doc, editarEstaAfuera: false),
              );
            },
          );

    // Cambio de página o de filtro con datos ya en pantalla: la lista vieja se
    // queda quieta y la espera se cuenta con la barra de arriba. Reemplazarla
    // por el esqueleto haría parpadear la pantalla entera por medio segundo.
    return Column(
      children: [
        SizedBox(
          height: 2,
          child: estado.cargando ? const LinearProgressIndicator(minHeight: 2) : null,
        ),
        Expanded(child: contenido),
      ],
    );
  }

  // ── acciones ────────────────────────────────────────────────────────────

  /// En la grilla quedan a la vista las dos de todos los días; el resto vive en
  /// el menú, incluida anular, que consume un número de CITE para siempre.
  List<Widget> _accionesTabla(BuildContext context, WidgetRef ref, CartaCiteEntity doc) {
    final puedeEditar = _puede(ref, doc, _btnEditar);

    return [
      IconButton(
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
        tooltip: 'Imprimir',
        visualDensity: VisualDensity.compact,
        onPressed: () => onImprimir(doc),
      ),
      if (puedeEditar)
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          visualDensity: VisualDensity.compact,
          onPressed: () => onEditar(doc),
        ),
      _menu(context, ref, doc, editarEstaAfuera: puedeEditar),
    ];
  }

  /// [editarEstaAfuera] evita repetir «Editar» adentro del menú cuando ya está
  /// como botón en la fila.
  Widget _menu(
    BuildContext context,
    WidgetRef ref,
    CartaCiteEntity doc, {
    required bool editarEstaAfuera,
  }) {
    final cs = Theme.of(context).colorScheme;
    final puedeEditar = _puede(ref, doc, _btnEditar);
    final puedeDuplicar = _puede(ref, doc, _btnDuplicar);

    return PopupMenuButton<String>(
      tooltip: 'Más acciones',
      icon: const Icon(Icons.more_vert, size: 20),
      position: PopupMenuPosition.under,
      onSelected: (v) {
        switch (v) {
          case 'ver':
            onVer(doc);
          case 'editar':
            onEditar(doc);
          case 'duplicar':
            onDuplicar(doc);
          case 'anular':
            onAnular(doc);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'ver',
          child: ListTile(
            leading: Icon(Icons.visibility_outlined),
            title: Text('Ver'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (puedeEditar && !editarEstaAfuera)
          const PopupMenuItem(
            value: 'editar',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (puedeDuplicar)
          const PopupMenuItem(
            value: 'duplicar',
            child: ListTile(
              leading: Icon(Icons.copy_all_outlined),
              title: Text('Duplicar'),
              subtitle: Text('Copia el texto y saca un número nuevo'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (puedeEditar) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'anular',
            child: ListTile(
              leading: Icon(Icons.block_outlined, color: cs.error),
              title: Text('Anular', style: TextStyle(color: cs.error)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

class _Tabla extends StatelessWidget {
  final EdgeInsets padding;
  final CartasCiteState estado;
  final void Function(CartaCiteEntity) onVer;
  final List<Widget> Function(CartaCiteEntity) acciones;

  const _Tabla({
    required this.padding,
    required this.estado,
    required this.onVer,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: padding.copyWith(bottom: Esp.l),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        // La tabla scrollea sola en horizontal si el cajón se angosta: el
        // cuerpo de la página nunca scrollea de costado.
        //
        // Con [ArrastreLateral] porque en web y escritorio ese scroll no se
        // podía mover: la rueda del mouse va al eje vertical y el arrastre con
        // el botón izquierdo viene deshabilitado. Las últimas columnas —entre
        // ellas la de acciones— quedaban fuera de alcance en una ventana con el
        // sidebar abierto.
        child: ScrollConfiguration(
          behavior: const ArrastreLateral(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                // La fila entera abre el documento: es lo que la gente intenta
                // primero y antes no pasaba nada al hacerlo. Sin la casilla de
                // selección, que acá no selecciona nada.
                showCheckboxColumn: false,
                columnSpacing: Esp.xl,
                horizontalMargin: Esp.l,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('DOCUMENTO')),
                  DataColumn(label: Text('FECHA')),
                  DataColumn(label: Text('DIRIGIDO A')),
                  DataColumn(label: Text('REFERENCIA / ASUNTO')),
                  DataColumn(label: Text('REDACTÓ')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('')),
                ],
                rows: estado.items.map((doc) {
                  return DataRow(
                    onSelectChanged: (_) => onVer(doc),
                    cells: [
                      DataCell(_CeldaDocumento(doc: doc)),
                      DataCell(Text(
                        doc.fechaDoc == null ? '-' : fmt.format(doc.fechaDoc!),
                        style: context.numero(),
                      )),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Text(
                          _sinNa(doc.dirigido).isEmpty ? '-' : _sinNa(doc.dirigido),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          _resumen(doc).isEmpty ? '-' : _resumen(doc),
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                      )),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          doc.redactadoPor,
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                      )),
                      DataCell(EstadoImpresionCite(impreso: doc.yaExportado)),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: acciones(doc))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La primera celda: sello, número y tipo juntos.
///
/// Antes eran dos columnas, «CITE» y «Tipo», separadas por el ancho de la
/// tabla. Son el mismo dato —qué documento es— y se leen de una sola mirada
/// cuando están pegados.
class _CeldaDocumento extends StatelessWidget {
  final CartaCiteEntity doc;
  const _CeldaDocumento({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelloTipoCite(idTipoDoc: doc.tipoDoc, tipo: doc.tipo, lado: 36),
        SizedBox(width: Esp.m),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.cite,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: Peso.dato,
                      fontFeatures: cifrasTabulares,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                doc.tipo,
                style: context.apagado(),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA
// ═══════════════════════════════════════════════════════════════════════════

class _Tarjeta extends StatelessWidget {
  final CartaCiteEntity doc;
  final VoidCallback onTap;
  final VoidCallback onImprimir;
  final Widget menu;

  const _Tarjeta({
    required this.doc,
    required this.onTap,
    required this.onImprimir,
    required this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd/MM/yyyy');
    final para = _sinNa(doc.dirigido);
    final resumen = _resumen(doc);

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          padding: EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.s, Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelloTipoCite(idTipoDoc: doc.tipoDoc, tipo: doc.tipo, lado: 44),
                  SizedBox(width: Esp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.cite,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: Peso.dato,
                                fontFeatures: cifrasTabulares,
                              ),
                        ),
                        Text(doc.tipo, style: context.apagado()),
                      ],
                    ),
                  ),
                  SizedBox(width: Esp.s),
                  EstadoImpresionCite(impreso: doc.yaExportado),
                ],
              ),
              if (para.isNotEmpty || resumen.isNotEmpty) SizedBox(height: Esp.m),
              if (para.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Para ', style: context.apagado()),
                    Expanded(
                      child: Text(
                        para,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: Peso.titulo),
                      ),
                    ),
                  ],
                ),
              if (resumen.isNotEmpty) ...[
                SizedBox(height: Esp.xs),
                Text(
                  resumen,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
              ],
              SizedBox(height: Esp.m),
              Wrap(
                spacing: Esp.m,
                runSpacing: Esp.xs,
                children: [
                  if (doc.fechaDoc != null)
                    DatoCite(
                      icono: Icons.event_outlined,
                      texto: fmt.format(doc.fechaDoc!),
                    ),
                  if (doc.empresa.isNotEmpty)
                    DatoCite(icono: Icons.business_outlined, texto: doc.empresa),
                  if (doc.redactadoPor.isNotEmpty)
                    DatoCite(icono: Icons.person_outline, texto: doc.redactadoPor),
                ],
              ),
              Divider(height: Esp.l, color: cs.outlineVariant),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onImprimir,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Imprimir'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  menu,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VACÍO
// ═══════════════════════════════════════════════════════════════════════════

/// La pantalla sin resultados, con la salida a mano.
///
/// Son dos situaciones distintas y antes decían casi lo mismo: «no hay nada
/// escrito todavía» pide redactar; «tu búsqueda no encontró nada» pide aflojar
/// el filtro. El botón cambia con el caso.
class _Vacio extends StatelessWidget {
  final bool hayFiltro;
  final VoidCallback onNuevo;
  final VoidCallback onLimpiarFiltros;

  const _Vacio({
    required this.hayFiltro,
    required this.onNuevo,
    required this.onLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Esp.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hayFiltro ? Icons.search_off : Icons.drafts_outlined,
                  size: 32,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: Esp.l),
              Text(
                hayFiltro
                    ? 'Ningún documento coincide con la búsqueda'
                    : 'Todavía no hay documentos en este período',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: Peso.titulo),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Esp.s),
              Text(
                hayFiltro
                    ? 'Probá con otro texto, o ampliá el período y el tipo.'
                    : 'Ampliá el período con los botones de arriba, o redactá el primero.',
                style: context.apagado(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Esp.l),
              if (hayFiltro)
                OutlinedButton.icon(
                  onPressed: onLimpiarFiltros,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar filtros'),
                )
              else
                FilledButton.icon(
                  onPressed: onNuevo,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Redactar documento'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El SP graba 'N/A' en los campos que el tipo de documento no usa; mostrarlo
/// en la grilla es ruido.
String _sinNa(String v) => v.trim().toUpperCase() == 'N/A' ? '' : v.trim();

String _resumen(CartaCiteEntity doc) {
  final ref = _sinNa(doc.referencia);
  if (ref.isNotEmpty) return ref;
  return _sinNa(doc.asunto);
}

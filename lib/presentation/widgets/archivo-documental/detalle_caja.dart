/// Una caja abierta: dónde está, sus fotos y lo que guarda. Reemplaza al
/// listado en todos los anchos (mismas acciones en teléfono y escritorio); los
/// documentos que coinciden con la búsqueda vigente se marcan en verde.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/fotos_caja.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/imagen_foto.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

enum AccionLinea { editar, eliminar }

class DetalleCaja extends StatelessWidget {
  const DetalleCaja({
    super.key,
    required this.caja,
    required this.lineas,
    required this.coinciden,
    required this.compacto,
    required this.margen,
    required this.semillaArchivo,
    required this.semillaEmpresa,
    this.sucursal,
    required this.onVolver,
    required this.onEditarCaja,
    required this.onEliminarCaja,
    required this.onAgregarLinea,
    required this.onAccionLinea,
  });

  final CajaArchivoEntity caja;
  final List<ContenidoCajaEntity> lineas;

  /// `codContenido` de los documentos que cumplen la búsqueda.
  final Set<int> coinciden;
  final bool compacto;
  final double margen;
  final Color semillaArchivo;

  /// El color de una empresa por su id.
  final Color Function(int codEmpresa) semillaEmpresa;

  /// «Sucursal 15 Achocalla · LA PAZ», si el archivo tiene una.
  final String? sucursal;
  final VoidCallback onVolver;
  final VoidCallback onEditarCaja;
  final VoidCallback onEliminarCaja;
  final VoidCallback onAgregarLinea;
  final void Function(ContenidoCajaEntity linea, AccionLinea accion) onAccionLinea;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final obs = (caja.observacion ?? '').trim();

    return ListView(
      padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.xxl),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver a las cajas',
              onPressed: onVolver,
            ),
            const SizedBox(width: Esp.s),
            EtiquetaCaja(caja: caja, semilla: semillaArchivo, lado: compacto ? 72 : 88),
            const SizedBox(width: Esp.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloCaja(caja),
                    style: tt.headlineSmall?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: Esp.xs),
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChipTono(
                        texto: oGuion(caja.nombreArchivo),
                        semilla: semillaArchivo,
                        icono: Icons.warehouse_outlined,
                      ),
                      Text(
                        (sucursal ?? '').isEmpty ? 'Sin sucursal asignada' : sucursal!,
                        style: context.apagado(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (compacto)
              PopupMenuButton<int>(
                tooltip: 'Acciones de la caja',
                onSelected: (v) => v == 0 ? onEditarCaja() : onEliminarCaja(),
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(
                        value: 0,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(Icons.edit_outlined, TonosArchivo.documentos, lado: 28),
                          title: Text('Editar caja'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const IconoTono(Icons.delete_outline, TonosArchivo.peligro, lado: 28),
                          title: Text('Eliminar caja', style: TextStyle(color: cs.error)),
                        ),
                      ),
                    ],
              )
            else ...[
              FilledButton.tonalIcon(
                style: estiloTonal(context, TonosArchivo.documentos),
                onPressed: onEditarCaja,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar caja'),
              ),
              const SizedBox(width: Esp.s),
              FilledButton.tonalIcon(
                style: estiloTonal(context, TonosArchivo.peligro),
                onPressed: onEliminarCaja,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar caja'),
              ),
            ],
          ],
        ),
        const SizedBox(height: Esp.l),
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            _Dato(
              icono: Icons.place_outlined,
              semilla: TonosArchivo.ubicacion,
              rotulo: 'Ubicación',
              valor: ubicacionLegible(caja),
            ),
            _Dato(
              icono: Icons.event_outlined,
              semilla: TonosArchivo.gestion,
              rotulo: 'Gestión',
              valor: rangoAnios(caja.anioDesde, caja.anioHasta),
            ),
            _Dato(
              icono: Icons.description_outlined,
              semilla: TonosArchivo.documentos,
              rotulo: 'Contenido',
              valor: documentosLegible(lineas.length),
            ),
            _Dato(
              icono: Icons.photo_camera_outlined,
              semilla: TonosArchivo.fotos,
              rotulo: 'Fotos',
              valor: '${caja.fotos} de 3',
            ),
          ],
        ),
        if (obs.isNotEmpty) ...[
          const SizedBox(height: Esp.m),
          _Observacion(texto: obs),
        ],
        const SizedBox(height: Esp.xl),
        const _TituloSeccion(
          icono: Icons.photo_library_outlined,
          semilla: TonosArchivo.fotos,
          titulo: 'Fotos',
          detalle: 'Opcionales, hasta 3: ayudan a reconocer la caja en el estante. Tócalas para verlas en grande.',
        ),
        const SizedBox(height: Esp.m),
        FotosCaja(caja: caja),
        const SizedBox(height: Esp.xl),
        _TituloSeccion(
          icono: Icons.description_outlined,
          semilla: TonosArchivo.documentos,
          titulo: 'Contenido',
          detalle: documentosLegible(lineas.length),
          accion: FilledButton.icon(
            style: estiloLleno(context, TonosArchivo.documentos),
            onPressed: onAgregarLinea,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar documento'),
          ),
        ),
        const SizedBox(height: Esp.m),
        // MensajeVacio trae su propio scroll y aquí ya estamos dentro de uno.
        if (lineas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.xl),
            child: Column(
              children: [
                const IconoTono(Icons.inventory_2_outlined, TonosArchivo.caja, lado: 56),
                const SizedBox(height: Esp.m),
                Text('La caja está vacía', style: tt.titleMedium),
                Text('Registra lo que guarda con «Agregar documento».', style: context.apagado()),
              ],
            ),
          )
        else if (compacto)
          for (final l in lineas)
            _TarjetaLinea(
              linea: l,
              coincide: coinciden.contains(l.codContenido),
              semillaEmpresa: semillaEmpresa,
              onAccion: (a) => onAccionLinea(l, a),
            )
        else
          _TablaLineas(
            lineas: lineas,
            coinciden: coinciden,
            semillaEmpresa: semillaEmpresa,
            onAccion: onAccionLinea,
          ),
      ],
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.icono,
    required this.semilla,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  final IconData icono;
  final Color semilla;
  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cabeza = Row(
      children: [
        IconoTono(icono, semilla, lado: 36),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.dato),
              ),
              Text(detalle, style: context.apagado()),
            ],
          ),
        ),
      ],
    );
    if (accion == null) return cabeza;
    // En un teléfono el botón baja a su propia línea: al lado apretaría el título.
    return LayoutBuilder(
      builder:
          (context, r) =>
              r.maxWidth < 480
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [cabeza, const SizedBox(height: Esp.s), accion!],
                  )
                  : Row(
                    children: [Expanded(child: cabeza), const SizedBox(width: Esp.m), accion!],
                  ),
    );
  }
}

/// Un dato de la caja en su mosaico de color: rótulo arriba, valor abajo.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.semilla,
    required this.rotulo,
    required this.valor,
  });

  final IconData icono;
  final Color semilla;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 168),
        padding: const EdgeInsets.fromLTRB(Esp.s, Esp.s, Esp.l, Esp.s),
        decoration: BoxDecoration(
          color: t.fondo,
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconoTono(icono, semilla, lado: 36),
            const SizedBox(width: Esp.m),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotulo, style: tt.labelSmall?.copyWith(color: t.texto.withValues(alpha: 0.85))),
                  Text(
                    valor,
                    style: tt.titleSmall?.copyWith(
                      color: t.texto,
                      fontWeight: Peso.dato,
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Observacion extends StatelessWidget {
  const _Observacion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, TonosArchivo.caja);
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: t.fondo.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: t.fuerte.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 18, color: t.fuerte),
          const SizedBox(width: Esp.s),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// La empresa de un documento como chip de su color, o «Sin empresa» en gris.
Widget _chipEmpresa(ContenidoCajaEntity l, Color Function(int) semillaEmpresa) =>
    l.codEmpresa == null
        ? const ChipTono(texto: 'Sin empresa', semilla: TonosArchivo.caja, neutro: true)
        : ChipTono(
          texto: l.nombreEmpresa ?? 'Empresa ${l.codEmpresa}',
          semilla: semillaEmpresa(l.codEmpresa!),
          icono: Icons.business_outlined,
        );

const _coincide = ChipTono(
  texto: 'Coincide con la búsqueda',
  semilla: TonosArchivo.ubicacion,
  icono: Icons.check_circle_outline,
);

class _TablaLineas extends StatelessWidget {
  const _TablaLineas({
    required this.lineas,
    required this.coinciden,
    required this.semillaEmpresa,
    required this.onAccion,
  });

  final List<ContenidoCajaEntity> lineas;
  final Set<int> coinciden;
  final Color Function(int) semillaEmpresa;
  final void Function(ContenidoCajaEntity linea, AccionLinea accion) onAccion;

  static const _flex = [3, 8, 2, 3];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final estilo = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: Peso.titulo,
      letterSpacing: 0.6,
    );

    Widget celda(int i, Widget hijo) => Expanded(
      flex: _flex[i],
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: Esp.s), child: hijo),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 40,
            color: cs.surfaceContainerHigh,
            child: Row(
              children: [
                for (final (i, r) in ['TIPO', 'DETALLE', 'GESTIÓN', 'EMPRESA'].indexed)
                  celda(i, Text(r, style: estilo)),
                SizedBox(width: 104, child: Center(child: Text('ACCIONES', style: estilo))),
              ],
            ),
          ),
          for (final (i, l) in lineas.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: Esp.s),
              decoration: BoxDecoration(
                color:
                    coinciden.contains(l.codContenido)
                        ? tonoDe(context, TonosArchivo.ubicacion).fondo.withValues(alpha: 0.3)
                        : (i.isEven ? Colors.transparent : cs.surfaceContainerLow),
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  celda(
                    0,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChipTono(
                        texto: oGuion(l.nombreTipoDocumento),
                        semilla: TonosArchivo.documentos,
                      ),
                    ),
                  ),
                  celda(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.detalle, style: tt.bodyMedium),
                        if ((l.observacion ?? '').isNotEmpty)
                          Text(l.observacion!, style: context.apagado()),
                        if (coinciden.contains(l.codContenido))
                          const Padding(padding: EdgeInsets.only(top: Esp.xs), child: _coincide),
                      ],
                    ),
                  ),
                  celda(
                    2,
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          (l.gestion ?? '').trim().isEmpty
                              ? Text('--', style: context.apagado())
                              : ChipTono(
                                texto: l.gestion!.trim(),
                                semilla: TonosArchivo.gestion,
                                icono: Icons.event_outlined,
                              ),
                    ),
                  ),
                  celda(3, Align(alignment: Alignment.centerLeft, child: _chipEmpresa(l, semillaEmpresa))),
                  SizedBox(
                    width: 104,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          style: estiloIconoTonal(context, TonosArchivo.documentos),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar el documento',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onAccion(l, AccionLinea.editar),
                        ),
                        const SizedBox(width: Esp.xs),
                        IconButton.filledTonal(
                          style: estiloIconoTonal(context, TonosArchivo.peligro),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Eliminar el documento',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onAccion(l, AccionLinea.eliminar),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaLinea extends StatelessWidget {
  const _TarjetaLinea({
    required this.linea,
    required this.coincide,
    required this.semillaEmpresa,
    required this.onAccion,
  });

  final ContenidoCajaEntity linea;
  final bool coincide;
  final Color Function(int) semillaEmpresa;
  final ValueChanged<AccionLinea> onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconoTono(Icons.description_outlined, TonosArchivo.documentos, lado: 36),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oGuion(linea.nombreTipoDocumento),
                    style: tt.titleSmall?.copyWith(fontWeight: Peso.dato),
                  ),
                  const SizedBox(height: Esp.xs),
                  Text(linea.detalle, style: tt.bodyMedium),
                  if ((linea.observacion ?? '').isNotEmpty)
                    Text(linea.observacion!, style: context.apagado()),
                  const SizedBox(height: Esp.s),
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    children: [
                      if ((linea.gestion ?? '').trim().isNotEmpty)
                        ChipTono(
                          texto: linea.gestion!.trim(),
                          semilla: TonosArchivo.gestion,
                          icono: Icons.event_outlined,
                        ),
                      _chipEmpresa(linea, semillaEmpresa),
                      if (coincide) _coincide,
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<AccionLinea>(
              icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
              tooltip: 'Acciones del documento',
              onSelected: onAccion,
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: AccionLinea.editar,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: IconoTono(Icons.edit_outlined, TonosArchivo.documentos, lado: 28),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: AccionLinea.eliminar,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const IconoTono(Icons.delete_outline, TonosArchivo.peligro, lado: 28),
                        title: Text('Eliminar', style: TextStyle(color: cs.error)),
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Una caja abierta: dónde está, sus fotos y PDF, lo que guarda y lo que salió
/// de ella. Reemplaza al listado en todos los anchos (mismas acciones en
/// teléfono y escritorio); los documentos que coinciden con la búsqueda vigente
/// se marcan en verde y los prestados o destruidos llevan su chip.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/fotos_caja.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/imagen_foto.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/movimientos_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

enum AccionLinea { editar, prestar, devolver, destruir, eliminar }

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
    this.prestamos = const [],
    this.destrucciones = const [],
    this.generandoReporte = false,
    required this.onVolver,
    required this.onEditarCaja,
    required this.onEliminarCaja,
    required this.onAgregarLinea,
    required this.onAccionLinea,
    required this.onPrestar,
    required this.onDestruir,
    required this.onReporte,
    required this.onDevolver,
    required this.onAnularPrestamo,
    required this.onAnularDestruccion,
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

  /// Los préstamos y destrucciones de esta caja.
  final List<PrestamoDocumentoEntity> prestamos;
  final List<DestruccionDocumentoEntity> destrucciones;

  /// El PDF de la caja se está armando: su botón espera.
  final bool generandoReporte;
  final VoidCallback onVolver;
  final VoidCallback onEditarCaja;
  final VoidCallback onEliminarCaja;
  final VoidCallback onAgregarLinea;
  final void Function(ContenidoCajaEntity linea, AccionLinea accion) onAccionLinea;
  final VoidCallback onPrestar;
  final VoidCallback onDestruir;
  final VoidCallback onReporte;
  final void Function(PrestamoDocumentoEntity p) onDevolver;
  final void Function(PrestamoDocumentoEntity p) onAnularPrestamo;
  final void Function(DestruccionDocumentoEntity d) onAnularDestruccion;

  /// El préstamo de la caja completa, si está afuera.
  PrestamoDocumentoEntity? get _prestamoCaja {
    for (final p in prestamos) {
      if (p.codPrestamo == caja.codPrestamoCaja) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final obs = (caja.observacion ?? '').trim();
    final abiertos = [
      for (final p in prestamos)
        if (p.abierto) p,
    ];
    final devueltos = [
      for (final p in prestamos)
        if (!p.abierto) p,
    ];
    final movimientos = prestamos.length + destrucciones.length;

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
              rotulo: 'Fotos y PDF',
              valor: '${caja.fotos} de 3',
            ),
            if (caja.prestados > 0)
              _Dato(
                icono: Icons.outbox_outlined,
                semilla: TonosArchivo.prestamo,
                rotulo: 'Afuera',
                valor: caja.prestados == 1 ? '1 prestado' : '${caja.prestados} prestados',
              ),
            if (caja.destruidos > 0)
              _Dato(
                icono: Icons.delete_sweep_outlined,
                semilla: TonosArchivo.destruido,
                rotulo: 'Destruidos',
                valor: documentosLegible(caja.destruidos),
              ),
          ],
        ),
        if (caja.destruida) ...[
          const SizedBox(height: Esp.m),
          _Aviso(
            icono: Icons.delete_sweep_outlined,
            semilla: TonosArchivo.destruido,
            texto: 'Caja destruida el ${oGuion(caja.fechaDestruccion)}. Ya no se le agregan, prestan ni mueven documentos.',
          ),
        ] else if (caja.prestadaCompleta) ...[
          const SizedBox(height: Esp.m),
          _Aviso(
            icono: Icons.outbox_outlined,
            semilla: TonosArchivo.prestamo,
            texto: 'La caja completa está prestada a ${oGuion(caja.prestadaA)} desde ${oGuion(caja.fechaPrestamo)}.',
            accion:
                _prestamoCaja == null
                    ? null
                    : FilledButton.tonalIcon(
                      style: estiloTonal(context, TonosArchivo.ubicacion),
                      onPressed: () => onDevolver(_prestamoCaja!),
                      icon: const Icon(Icons.assignment_return_outlined, size: 18),
                      label: const Text('Registrar devolución'),
                    ),
          ),
        ],
        if (obs.isNotEmpty) ...[
          const SizedBox(height: Esp.m),
          _Observacion(texto: obs),
        ],
        const SizedBox(height: Esp.xl),
        const _TituloSeccion(
          icono: Icons.photo_library_outlined,
          semilla: TonosArchivo.fotos,
          titulo: 'Fotos y PDF',
          detalle:
              'Opcionales, hasta 3 entre fotos y PDF: las fotos ayudan a reconocer la caja en el estante '
              'y un PDF puede ser su inventario. Tócalos para verlos.',
        ),
        const SizedBox(height: Esp.m),
        FotosCaja(caja: caja),
        const SizedBox(height: Esp.xl),
        _TituloSeccion(
          icono: Icons.description_outlined,
          semilla: TonosArchivo.documentos,
          titulo: 'Contenido',
          detalle: documentosLegible(lineas.length),
          acciones: [
            if (!caja.destruida) ...[
              FilledButton.icon(
                style: estiloLleno(context, TonosArchivo.documentos),
                onPressed: onAgregarLinea,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar documento'),
              ),
              FilledButton.tonalIcon(
                style: estiloTonal(context, TonosArchivo.prestamo),
                onPressed: onPrestar,
                icon: const Icon(Icons.outbox_outlined, size: 18),
                label: const Text('Prestar'),
              ),
              FilledButton.tonalIcon(
                style: estiloTonal(context, TonosArchivo.destruido),
                onPressed: onDestruir,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Destrucción'),
              ),
            ],
            FilledButton.tonalIcon(
              style: estiloTonal(context, TonosArchivo.reportes),
              onPressed: generandoReporte ? null : onReporte,
              icon:
                  generandoReporte
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(generandoReporte ? 'Generando…' : 'Reporte PDF'),
            ),
          ],
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
                Text(
                  caja.destruida ? 'Se destruyó completa.' : 'Registra lo que guarda con «Agregar documento».',
                  style: context.apagado(),
                ),
              ],
            ),
          )
        else if (compacto)
          for (final l in lineas)
            _TarjetaLinea(
              linea: l,
              coincide: coinciden.contains(l.codContenido),
              acciones: _accionesDe(l),
              semillaEmpresa: semillaEmpresa,
              onAccion: (a) => onAccionLinea(l, a),
            )
        else
          _TablaLineas(
            lineas: lineas,
            coinciden: coinciden,
            accionesDe: _accionesDe,
            semillaEmpresa: semillaEmpresa,
            onAccion: onAccionLinea,
          ),
        const SizedBox(height: Esp.xl),
        _TituloSeccion(
          icono: Icons.history,
          semilla: TonosArchivo.prestamo,
          titulo: 'Préstamos y destrucciones',
          detalle:
              movimientos == 0
                  ? 'Todavía no se prestó ni se destruyó nada de esta caja.'
                  : '${abiertos.length} afuera · ${devueltos.length} ${devueltos.length == 1 ? 'devuelto' : 'devueltos'}'
                      ' · ${destrucciones.length} en la bitácora',
        ),
        if (movimientos > 0) ...[
          const SizedBox(height: Esp.m),
          for (final p in abiertos)
            TarjetaPrestamo(
              prestamo: p,
              mostrarCaja: false,
              onDevolver: () => onDevolver(p),
              onAnular: () => onAnularPrestamo(p),
            ),
          for (final d in destrucciones)
            TarjetaDestruccion(destruccion: d, mostrarCaja: false, onAnular: () => onAnularDestruccion(d)),
          for (final p in devueltos) TarjetaPrestamo(prestamo: p, mostrarCaja: false),
        ],
      ],
    );
  }

  /// Lo que se puede hacer con una línea según dónde está.
  List<AccionLinea> _accionesDe(ContenidoCajaEntity l) => [
    AccionLinea.editar,
    if (l.estaEnLaCaja && !caja.destruida) AccionLinea.prestar,
    // La que salió con toda la caja vuelve con la caja (desde el aviso de arriba).
    if (l.estaPrestada && l.codPrestamo != null && l.codPrestamo != caja.codPrestamoCaja) AccionLinea.devolver,
    if (l.estaEnLaCaja && !caja.destruida) AccionLinea.destruir,
    AccionLinea.eliminar,
  ];
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.icono,
    required this.semilla,
    required this.titulo,
    required this.detalle,
    this.acciones = const [],
  });

  final IconData icono;
  final Color semilla;
  final String titulo;
  final String detalle;
  final List<Widget> acciones;

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
    if (acciones.isEmpty) return cabeza;
    final botones = Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones);
    // En un teléfono los botones bajan a su propia línea: al lado apretarían el título.
    return LayoutBuilder(
      builder:
          (context, r) =>
              r.maxWidth < 760
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [cabeza, const SizedBox(height: Esp.s), botones],
                  )
                  : Row(
                    children: [Expanded(child: cabeza), const SizedBox(width: Esp.m), Flexible(child: botones)],
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

/// La caja entera afuera o destruida: va arriba, sobre el fondo suave de su
/// tono, con la acción que corresponde (si hay una).
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.semilla, required this.texto, this.accion});

  final IconData icono;
  final Color semilla;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    final tt = Theme.of(context).textTheme;
    final mensaje = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoTono(icono, semilla, lado: 32),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Text(texto, style: tt.bodyLarge?.copyWith(color: t.texto, fontWeight: Peso.titulo)),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: t.fuerte.withValues(alpha: 0.5)),
      ),
      child:
          accion == null
              ? mensaje
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [mensaje, const SizedBox(height: Esp.s), Padding(padding: const EdgeInsets.only(left: 44), child: accion)],
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

/// Las acciones de una línea en un menú: siempre las mismas palabras en la
/// tabla y en las tarjetas.
List<PopupMenuEntry<AccionLinea>> _menuLinea(BuildContext context, List<AccionLinea> acciones) {
  final cs = Theme.of(context).colorScheme;
  PopupMenuItem<AccionLinea> item(AccionLinea a, IconData icono, Color semilla, String texto, {bool peligro = false}) =>
      PopupMenuItem(
        value: a,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: IconoTono(icono, semilla, lado: 28),
          title: Text(texto, style: peligro ? TextStyle(color: cs.error) : null),
        ),
      );
  return [
    for (final a in acciones)
      switch (a) {
        AccionLinea.editar => item(a, Icons.edit_outlined, TonosArchivo.documentos, 'Editar'),
        AccionLinea.prestar => item(a, Icons.outbox_outlined, TonosArchivo.prestamo, 'Prestar'),
        AccionLinea.devolver => item(a, Icons.assignment_return_outlined, TonosArchivo.ubicacion, 'Registrar devolución'),
        AccionLinea.destruir => item(a, Icons.delete_sweep_outlined, TonosArchivo.destruido, 'Registrar destrucción'),
        AccionLinea.eliminar => item(a, Icons.delete_outline, TonosArchivo.peligro, 'Eliminar', peligro: true),
      },
  ];
}

class _TablaLineas extends StatelessWidget {
  const _TablaLineas({
    required this.lineas,
    required this.coinciden,
    required this.accionesDe,
    required this.semillaEmpresa,
    required this.onAccion,
  });

  final List<ContenidoCajaEntity> lineas;
  final Set<int> coinciden;
  final List<AccionLinea> Function(ContenidoCajaEntity) accionesDe;
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
                        neutro: l.estaDestruida,
                      ),
                    ),
                  ),
                  celda(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.detalle,
                          style: tt.bodyMedium?.copyWith(color: l.estaDestruida ? cs.onSurfaceVariant : null),
                        ),
                        if ((l.observacion ?? '').isNotEmpty)
                          Text(l.observacion!, style: context.apagado()),
                        if (!l.estaEnLaCaja)
                          Padding(padding: const EdgeInsets.only(top: Esp.xs), child: ChipSituacion(linea: l)),
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
                                neutro: l.estaDestruida,
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
                        PopupMenuButton<AccionLinea>(
                          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                          tooltip: 'Más acciones del documento',
                          onSelected: (a) => onAccion(l, a),
                          itemBuilder:
                              (context) => _menuLinea(context, [
                                for (final a in accionesDe(l))
                                  if (a != AccionLinea.editar) a,
                              ]),
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
    required this.acciones,
    required this.semillaEmpresa,
    required this.onAccion,
  });

  final ContenidoCajaEntity linea;
  final bool coincide;
  final List<AccionLinea> acciones;
  final Color Function(int) semillaEmpresa;
  final ValueChanged<AccionLinea> onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final destruida = linea.estaDestruida;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconoTono(
              destruida ? Icons.delete_sweep_outlined : Icons.description_outlined,
              destruida ? TonosArchivo.destruido : TonosArchivo.documentos,
              lado: 36,
            ),
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
                  Text(
                    linea.detalle,
                    style: tt.bodyMedium?.copyWith(color: destruida ? cs.onSurfaceVariant : null),
                  ),
                  if ((linea.observacion ?? '').isNotEmpty)
                    Text(linea.observacion!, style: context.apagado()),
                  const SizedBox(height: Esp.s),
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    children: [
                      if (!linea.estaEnLaCaja) ChipSituacion(linea: linea),
                      if ((linea.gestion ?? '').trim().isNotEmpty)
                        ChipTono(
                          texto: linea.gestion!.trim(),
                          semilla: TonosArchivo.gestion,
                          icono: Icons.event_outlined,
                          neutro: destruida,
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
              itemBuilder: (context) => _menuLinea(context, acciones),
            ),
          ],
        ),
      ),
    );
  }
}

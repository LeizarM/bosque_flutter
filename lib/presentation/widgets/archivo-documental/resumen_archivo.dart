/// La cabecera del archivo: cuánto hay (cajas, documentos, fotos) y en qué
/// archivo físico, con los mismos colores que después repiten la tabla y las
/// tarjetas. Los chips de archivo son el filtro más usado: van a la vista.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

/// Las cifras del archivo elegido (o de todos). No cambian con la búsqueda:
/// describen el archivo, no el resultado.
class CifrasArchivo extends StatelessWidget {
  const CifrasArchivo({
    super.key,
    required this.cajas,
    required this.documentos,
    required this.archivos,
    required this.compacto,
  });

  final List<CajaArchivoEntity> cajas;
  final int documentos;
  final int archivos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final conFotos = cajas.where((c) => c.fotos > 0).length;
    final ubicadas = cajas.where((c) => c.tieneUbicacion).length;
    final cifras = [
      _Cifra(
        icono: Icons.inventory_2_outlined,
        semilla: TonosArchivo.caja,
        valor: '${cajas.length}',
        rotulo: cajas.length == 1 ? 'caja' : 'cajas',
        detalle: archivos == 1 ? 'en 1 archivo' : 'en $archivos archivos',
      ),
      _Cifra(
        icono: Icons.description_outlined,
        semilla: TonosArchivo.documentos,
        valor: '$documentos',
        rotulo: documentos == 1 ? 'documento' : 'documentos',
        detalle: 'registrados',
      ),
      _Cifra(
        icono: Icons.place_outlined,
        semilla: TonosArchivo.ubicacion,
        valor: '$ubicadas',
        rotulo: 'con estante',
        detalle: 'de ${cajas.length} cajas',
      ),
      _Cifra(
        icono: Icons.photo_camera_outlined,
        semilla: TonosArchivo.fotos,
        valor: '$conFotos',
        rotulo: 'con fotos',
        detalle: 'de ${cajas.length} cajas',
      ),
    ];

    // En el teléfono van en una fila que se desliza: apiladas le quitarían
    // media pantalla a la lista, que es lo que se vino a ver.
    if (compacto) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in cifras) ...[
              SizedBox(width: 200, child: c),
              if (c != cifras.last) const SizedBox(width: Esp.s),
            ],
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, r) {
        // Cuatro en fila si entran a ~190 px cada una; si no, de a dos.
        final columnas = r.maxWidth >= 4 * 190 ? 4 : 2;
        final ancho = (r.maxWidth - (columnas - 1) * Esp.m) / columnas;
        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [for (final c in cifras) SizedBox(width: ancho, child: c)],
        );
      },
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.icono,
    required this.semilla,
    required this.valor,
    required this.rotulo,
    required this.detalle,
  });

  final IconData icono;
  final Color semilla;
  final String valor;
  final String rotulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: '$valor $rotulo, $detalle',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Esp.m),
        // Borde parejo: Flutter no admite radio con un borde de un solo lado.
        decoration: BoxDecoration(
          color: t.fondo,
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: t.fuerte.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            IconoTono(icono, semilla, lado: 40),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: valor,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: Peso.dato,
                            color: t.texto,
                            fontFeatures: cifrasTabulares,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: '  $rotulo',
                          style: tt.bodyMedium?.copyWith(color: t.texto, fontWeight: Peso.titulo),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: t.texto.withValues(alpha: 0.8)),
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

/// Un chip por archivo físico, cada uno de su color, más «Todos». Elegir uno
/// filtra la lista; el color es el mismo de sus cajas.
class ChipsArchivo extends StatelessWidget {
  const ChipsArchivo({
    super.key,
    required this.archivos,
    required this.cajas,
    required this.elegido,
    required this.onElegir,
  });

  final List<ArchivoFisicoEntity> archivos;
  final List<CajaArchivoEntity> cajas;
  final int? elegido;
  final ValueChanged<int?> onElegir;

  @override
  Widget build(BuildContext context) {
    final codigos = [for (final a in archivos) a.codArchivo];
    final porArchivo = <int, int>{};
    for (final c in cajas) {
      porArchivo[c.codArchivo] = (porArchivo[c.codArchivo] ?? 0) + 1;
    }
    final cs = Theme.of(context).colorScheme;

    Widget chip({
      required String texto,
      required int cuantas,
      required bool sel,
      required VoidCallback onTap,
      Color? semilla,
      String? ayuda,
    }) {
      final t = semilla == null ? null : tonoDe(context, semilla);
      final avatar = CircleAvatar(
        backgroundColor: t?.fuerte ?? cs.onSurfaceVariant,
        child: Icon(
          semilla == null ? Icons.all_inbox_outlined : Icons.warehouse_outlined,
          size: 14,
          color: t?.sobreFuerte ?? cs.surface,
        ),
      );
      final c = ChoiceChip(
        selected: sel,
        showCheckmark: false,
        avatar: avatar,
        label: Text('$texto  $cuantas'),
        labelStyle: TextStyle(
          color: sel ? (t?.texto ?? cs.onSurface) : cs.onSurface,
          fontWeight: sel ? Peso.dato : Peso.titulo,
          fontFeatures: cifrasTabulares,
        ),
        selectedColor: t?.fondo ?? cs.surfaceContainerHighest,
        side: BorderSide(color: sel ? (t?.fuerte ?? cs.outline) : cs.outlineVariant),
        onSelected: (_) => onTap(),
      );
      return ayuda == null ? c : Tooltip(message: ayuda, child: c);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            texto: 'Todos',
            cuantas: cajas.length,
            sel: elegido == null,
            onTap: () => onElegir(null),
          ),
          for (final a in archivos) ...[
            const SizedBox(width: Esp.s),
            chip(
              texto: a.nombre,
              cuantas: porArchivo[a.codArchivo] ?? 0,
              sel: elegido == a.codArchivo,
              semilla: semillaDeArchivo(a.codArchivo, codigos),
              ayuda: (a.nombreSucursal ?? '').trim().isEmpty
                  ? 'Sin sucursal asignada'
                  : 'Sucursal: ${a.nombreSucursal}${(a.ciudadSucursal ?? '').isEmpty ? '' : ' · ${a.ciudadSucursal}'}',
              onTap: () => onElegir(elegido == a.codArchivo ? null : a.codArchivo),
            ),
          ],
        ],
      ),
    );
  }
}

/// El encabezado: el ícono del módulo en kraft, título y las acciones, cada
/// una de su color (crear en kraft, reportes en cian, préstamos en ámbar).
class EncabezadoArchivo extends StatelessWidget {
  const EncabezadoArchivo({
    super.key,
    required this.compacto,
    required this.cargando,
    required this.onNueva,
    required this.onReportes,
    required this.onCatalogos,
    required this.onRefrescar,
    required this.onPrestamos,
    this.prestados = 0,
  });

  final bool compacto;
  final bool cargando;
  final VoidCallback onNueva;
  final VoidCallback onReportes;
  final VoidCallback onCatalogos;
  final VoidCallback onRefrescar;
  final VoidCallback onPrestamos;

  /// Préstamos (entregas) con algo todavía afuera: el número va en el botón.
  final int prestados;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final titulo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconoTono(Icons.archive_outlined, TonosArchivo.caja, lado: compacto ? 40 : 48),
        const SizedBox(width: Esp.m),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Almacenaje de documentos',
                maxLines: compacto ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(fontWeight: Peso.dato, letterSpacing: -0.4),
              ),
              if (!compacto)
                Text(
                  'Busca un documento y te dice en qué sucursal, caja y estante está.',
                  style: tt.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );

    final refrescar = IconButton(
      onPressed: cargando ? null : onRefrescar,
      icon: const Icon(Icons.refresh),
      tooltip: 'Volver a traer el archivo',
    );

    final ayudaPrestamos =
        prestados == 0
            ? 'Préstamos y destrucciones: no hay nada prestado'
            : 'Préstamos y destrucciones: ${prestados == 1 ? '1 préstamo afuera' : '$prestados préstamos afuera'}';

    // En el teléfono quedan a la vista préstamos y reportes; refrescar y los
    // catálogos (de uso raro) van al menú: cuatro botones apretarían el título.
    if (compacto) {
      return Row(
        children: [
          Expanded(child: titulo),
          Badge(
            isLabelVisible: prestados > 0,
            label: Text('$prestados'),
            backgroundColor: tonoDe(context, TonosArchivo.prestamo).fuerte,
            textColor: tonoDe(context, TonosArchivo.prestamo).sobreFuerte,
            child: IconButton.filledTonal(
              style: estiloIconoTonal(context, TonosArchivo.prestamo),
              onPressed: onPrestamos,
              icon: const Icon(Icons.outbox_outlined),
              tooltip: ayudaPrestamos,
            ),
          ),
          const SizedBox(width: Esp.xs),
          IconButton.filledTonal(
            style: estiloIconoTonal(context, TonosArchivo.reportes),
            onPressed: onReportes,
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Reportes en PDF',
          ),
          PopupMenuButton<int>(
            tooltip: 'Más acciones',
            onSelected: (v) => v == 0 ? onCatalogos() : onRefrescar(),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 0,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: IconoTono(Icons.category_outlined, TonosArchivo.archivos[1], lado: 28),
                      title: const Text('Catálogos'),
                      subtitle: const Text('Archivos y tipos de documento'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    enabled: !cargando,
                    child: const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: IconoTono(Icons.refresh, TonosArchivo.caja, lado: 28),
                      title: Text('Volver a traer el archivo'),
                    ),
                  ),
                ],
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: Esp.l,
      runSpacing: Esp.s,
      children: [
        titulo,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            refrescar,
            const SizedBox(width: Esp.s),
            FilledButton.tonalIcon(
              style: estiloTonal(context, TonosArchivo.archivos[1]),
              onPressed: onCatalogos,
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Catálogos'),
            ),
            const SizedBox(width: Esp.s),
            Tooltip(
              message: ayudaPrestamos,
              child: FilledButton.tonalIcon(
                style: estiloTonal(context, TonosArchivo.prestamo),
                onPressed: onPrestamos,
                icon: const Icon(Icons.outbox_outlined, size: 18),
                label: Text(prestados == 0 ? 'Préstamos' : 'Préstamos ($prestados)'),
              ),
            ),
            const SizedBox(width: Esp.s),
            FilledButton.tonalIcon(
              style: estiloTonal(context, TonosArchivo.reportes),
              onPressed: onReportes,
              icon: const Icon(Icons.assessment_outlined, size: 18),
              label: const Text('Reportes'),
            ),
            const SizedBox(width: Esp.s),
            FilledButton.icon(
              style: estiloLleno(context, TonosArchivo.caja),
              onPressed: onNueva,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva caja'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Textos y piezas que comparten la tabla, las tarjetas y el detalle de una
/// caja, para que digan lo mismo (y con el mismo color) en todos los anchos.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

/// Con menos ancho que esto las columnas no se leen: tarjetas.
const double anchoMinimoTabla = 720;

String oGuion(String? v) {
  final t = v?.trim() ?? '';
  return t.isEmpty ? '--' : t;
}

String tituloCaja(CajaArchivoEntity c) => 'Caja ${c.numero}';

/// «Estante 1 · Fila 2», o «Sin ubicación» explícito: una celda vacía parece un error.
String ubicacionLegible(CajaArchivoEntity c) {
  final partes = [
    if ((c.estante ?? '').trim().isNotEmpty) 'Estante ${c.estante!.trim()}',
    if ((c.fila ?? '').trim().isNotEmpty) 'Fila ${c.fila!.trim()}',
  ];
  return partes.isEmpty ? 'Sin ubicación' : partes.join(' · ');
}

String rangoAnios(int? desde, int? hasta) {
  if (desde == null) return '--';
  return hasta == null || hasta == desde ? '$desde' : '$desde – $hasta';
}

/// Los tipos de documento de la caja, del que más se repite al que menos.
List<String> tiposPorFrecuencia(List<ContenidoCajaEntity> lineas) {
  final cuenta = <String, int>{};
  for (final l in lineas) {
    final t = oGuion(l.nombreTipoDocumento);
    cuenta[t] = (cuenta[t] ?? 0) + 1;
  }
  return cuenta.keys.toList()..sort((a, b) => cuenta[b]!.compareTo(cuenta[a]!));
}

/// Los tres tipos de documento que más se repiten en la caja.
String resumenTipos(List<ContenidoCajaEntity> lineas) {
  if (lineas.isEmpty) return 'Caja vacía';
  final orden = tiposPorFrecuencia(lineas);
  final resto = orden.length - 3;
  return orden.take(3).join(', ') + (resto > 0 ? ' y $resto más' : '');
}

/// Una fila del Excel es un documento (o un legajo) guardado en la caja.
String documentosLegible(int n) => n == 1 ? '1 documento' : '$n documentos';

// ═══════════════════════════════════════════════════════════════════════════
// COLOR
// ═══════════════════════════════════════════════════════════════════════════

/// Botón lleno en el tono de su acción (Nueva caja en kraft, Reportes en cian).
ButtonStyle estiloLleno(BuildContext context, Color semilla) {
  final t = tonoDe(context, semilla);
  return FilledButton.styleFrom(backgroundColor: t.fuerte, foregroundColor: t.sobreFuerte);
}

/// Botón tonal: el fondo suave del tono y la letra que contrasta con él.
ButtonStyle estiloTonal(BuildContext context, Color semilla) {
  final t = tonoDe(context, semilla);
  return FilledButton.styleFrom(backgroundColor: t.fondo, foregroundColor: t.texto);
}

/// Lo mismo que [estiloTonal] para un `IconButton.filledTonal`.
ButtonStyle estiloIconoTonal(BuildContext context, Color semilla) {
  final t = tonoDe(context, semilla);
  return IconButton.styleFrom(backgroundColor: t.fondo, foregroundColor: t.texto);
}

/// Un ícono sobre un cuadrado de su color pleno: la seña de cada dato.
class IconoTono extends StatelessWidget {
  const IconoTono(this.icono, this.semilla, {super.key, this.lado = 32});

  final IconData icono;
  final Color semilla;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: t.fuerte,
        borderRadius: BorderRadius.circular(lado >= 40 ? Esquina.media : Esquina.chica),
      ),
      child: Icon(icono, size: lado * 0.56, color: t.sobreFuerte),
    );
  }
}

/// Píldora con ícono y texto en el tono del dato. Nunca solo color: el texto
/// dice lo mismo.
class ChipTono extends StatelessWidget {
  const ChipTono({
    super.key,
    required this.texto,
    required this.semilla,
    this.icono,
    this.neutro = false,
  });

  final String texto;
  final Color semilla;
  final IconData? icono;

  /// Para lo que no tiene dueño («Sin empresa»): gris del tema.
  final bool neutro;

  @override
  Widget build(BuildContext context) {
    final t = neutro ? tonoNeutro(context) : tonoDe(context, semilla);
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: t.texto,
      fontWeight: Peso.titulo,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(icono == null ? Esp.s : 6, 3, Esp.s, 3),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: t.texto),
            const SizedBox(width: Esp.xs),
          ],
          Flexible(
            child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo),
          ),
        ],
      ),
    );
  }
}

/// Un dato corto con su ícono de color («Estante 1 · Fila 2» con el pin
/// verde). El rótulo queda para el lector de pantalla.
class DatoTono extends StatelessWidget {
  const DatoTono({
    super.key,
    required this.icono,
    required this.semilla,
    required this.rotulo,
    required this.valor,
    this.apagado = false,
  });

  final IconData icono;
  final Color semilla;
  final String rotulo;
  final String valor;

  /// Para «Sin ubicación» y parecidos: se lee, pero no compite.
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: apagado ? cs.onSurfaceVariant : t.fuerte),
          const SizedBox(width: Esp.xs),
          Flexible(
            child: Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: apagado ? cs.onSurfaceVariant : cs.onSurface,
                fontFeatures: cifrasTabulares,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FICHAS
// ═══════════════════════════════════════════════════════════════════════════

/// Hoja desde abajo en teléfono (cerrarla es el gesto de volver) y diálogo de
/// ancho acotado en escritorio.
Future<T?> abrirFicha<T>(
  BuildContext context, {
  required bool compacto,
  required Widget Function(bool mostrarAsa) builder,
  double anchoMaximo = 640,
}) {
  if (compacto) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => builder(true),
    );
  }
  return showDialog<T>(
    context: context,
    builder:
        (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: anchoMaximo),
            child: builder(false),
          ),
        ),
  );
}

/// Encabezado común de las fichas: asa en móvil, ícono de color, título y cerrar.
class CabezaFicha extends StatelessWidget {
  const CabezaFicha({
    super.key,
    required this.titulo,
    required this.mostrarAsa,
    required this.ocupado,
    this.icono,
    this.semilla = TonosArchivo.caja,
  });

  final String titulo;
  final bool mostrarAsa;
  final bool ocupado;
  final IconData? icono;
  final Color semilla;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarAsa)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: Esp.s),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.s, Esp.s),
          child: Row(
            children: [
              if (icono != null) ...[
                IconoTono(icono!, semilla, lado: 36),
                const SizedBox(width: Esp.m),
              ],
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: Peso.dato),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar sin guardar',
                onPressed: ocupado ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Pie común de las fichas: Cancelar y la acción principal, en el tono de la
/// ficha, con su espera.
class PieFicha extends StatelessWidget {
  const PieFicha({
    super.key,
    required this.etiqueta,
    required this.ocupado,
    required this.onGuardar,
    this.semilla = TonosArchivo.caja,
  });

  final String etiqueta;
  final bool ocupado;
  final VoidCallback onGuardar;
  final Color semilla;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(Esp.l),
        // Wrap y no Row: con letra grande en un teléfono el botón principal baja de línea en vez de desbordar.
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            TextButton(
              onPressed: ocupado ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: estiloLleno(context, semilla),
              onPressed: ocupado ? null : onGuardar,
              icon:
                  ocupado
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check, size: 18),
              label: Text(etiqueta),
            ),
          ],
        ),
      ),
    ],
  );
}

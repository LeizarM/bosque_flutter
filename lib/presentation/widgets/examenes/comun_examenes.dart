/// Piezas que comparten las pantallas del módulo de exámenes.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';

/// Debajo de este ancho de contenedor la lista pasa a tarjetas.
const double anchoTablaExamenes = 760;

/// Ancho de los diálogos de formulario en escritorio.
const double anchoDialogoExamenes = 560;

/// Las credenciales y el reloj van en ancho fijo: `IPX12` y una clave de diez
/// caracteres se dictan y se copian a mano, y el reloj no baila al correr.
const String fuenteFija = 'JetBrainsMono';

String fechaHora(DateTime? f) {
  if (f == null) return '--';
  final h = f.hour.toString().padLeft(2, '0');
  final m = f.minute.toString().padLeft(2, '0');
  return '${fechaCorta(f)} $h:$m';
}

/// `HH:mm:ss` → `HH:mm`.
String horaCorta(String? hora) {
  if (hora == null || hora.isEmpty) return '--';
  final p = hora.split(':');
  return p.length >= 2 ? '${p[0]}:${p[1]}' : hora;
}

String nota(double? valor) {
  if (valor == null) return '--';
  return valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toStringAsFixed(2);
}

/// Un porcentaje de 0 a 100 con un decimal: `87.5` → `87,5 %`, `75` → `75 %`.
String porcentajeTexto(double p) =>
    '${p == p.roundToDouble() ? p.toInt() : p.toStringAsFixed(1).replaceAll('.', ',')} %';

String duracionTexto(int? minutos) {
  final m = minutos ?? 0;
  if (m <= 0) return '--';
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  final r = m % 60;
  return r == 0 ? '$h h' : '$h h $r min';
}

/// La ventana de un lote: `dd/mm/aaaa HH:mm–HH:mm`, o solo lo que haya.
String ventanaTexto(TcpeLoteEntity l) {
  final ventana = ventanaHorario(l.inicioVentana, l.finVentana);
  if (ventana != null) return ventana;
  if (l.fecha == null) return '--';
  final horas = [l.horaInicio, l.horaFin].whereType<String>().map(horaCorta).join('–');
  return horas.isEmpty ? fechaCorta(l.fecha) : '${fechaCorta(l.fecha)} $horas';
}

/// `inicioVentana` y `finVentana` como texto; null si el lote no tiene horario.
String? ventanaHorario(DateTime? inicio, DateTime? fin) {
  String hora(DateTime f) => '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  if (inicio != null && fin != null) return '${fechaCorta(inicio)} ${hora(inicio)}–${hora(fin)}';
  if (inicio != null) return 'Desde ${fechaHora(inicio)}';
  if (fin != null) return 'Hasta ${fechaHora(fin)}';
  return null;
}

String modalidadTexto(String? modalidad) => switch (modalidad) {
  'O' => 'En línea',
  'E' => 'Escrito',
  _ => '--',
};

// ═══════════════════════════════════════════════════════════════════════════
// COLOR CON SIGNIFICADO
// ═══════════════════════════════════════════════════════════════════════════

/// Qué clase de cosa dice un dato. Sale de los roles del tema, así que sirve
/// con las nueve semillas y en oscuro; el color nunca va solo: lleva icono o texto.
enum TonoExamen {
  /// Lo logrado o lo principal: calificado, aprobado, activa, cerrada.
  principal,

  /// Lo que acompaña: en curso, documentos, cantidades.
  secundario,

  /// Lo que pide atención sin ser un problema: por revisar, abierta, escrito.
  terciario,

  /// El problema real: vencido, ausente, reprobado, borrar.
  alerta,

  /// Lo que todavía no cuenta: sin iniciar, inactiva.
  neutro,
}

/// El fondo, la letra y el acento (icono, franja) de un tono.
({Color fondo, Color letra, Color acento}) coloresDeTono(ColorScheme cs, TonoExamen t) => switch (t) {
  TonoExamen.principal => (fondo: cs.primaryContainer, letra: cs.onPrimaryContainer, acento: cs.primary),
  TonoExamen.secundario => (fondo: cs.secondaryContainer, letra: cs.onSecondaryContainer, acento: cs.secondary),
  TonoExamen.terciario => (fondo: cs.tertiaryContainer, letra: cs.onTertiaryContainer, acento: cs.tertiary),
  TonoExamen.alerta => (fondo: cs.errorContainer, letra: cs.onErrorContainer, acento: cs.error),
  TonoExamen.neutro => (fondo: cs.surfaceContainerHighest, letra: cs.onSurfaceVariant, acento: cs.outline),
};

/// Una pastilla con icono: el estado de algo en una palabra y un color.
class PastillaExamen extends StatelessWidget {
  const PastillaExamen({super.key, required this.texto, this.tono = TonoExamen.neutro, this.icono});

  final String texto;
  final TonoExamen tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = coloresDeTono(Theme.of(context).colorScheme, tono);
    return Container(
      padding: EdgeInsets.fromLTRB(icono == null ? Esp.s : 6, 3, Esp.s + 2, 3),
      decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(Esquina.pastilla)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 14, color: c.letra), const SizedBox(width: Esp.xs)],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.letra, fontWeight: Peso.titulo),
            ),
          ),
        ],
      ),
    );
  }
}

/// El sello del membrete y de los diálogos: el icono de la pantalla sobre su
/// color, como el timbre de una hoja de examen.
class SelloExamen extends StatelessWidget {
  const SelloExamen({super.key, required this.icono, this.tono = TonoExamen.principal, this.tamanio = 44});

  final IconData icono;
  final TonoExamen tono;
  final double tamanio;

  @override
  Widget build(BuildContext context) {
    final c = coloresDeTono(Theme.of(context).colorScheme, tono);
    return ExcludeSemantics(
      child: Container(
        width: tamanio,
        height: tamanio,
        decoration: BoxDecoration(
          color: c.fondo,
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: c.acento.withValues(alpha: 0.35)),
        ),
        child: Icon(icono, size: tamanio * 0.5, color: c.letra),
      ),
    );
  }
}

/// El tono y el icono de cada estado de un examen.
(TonoExamen, IconData) aspectoDeEstado(EstadoExamenTcpe estado) => switch (estado) {
  EstadoExamenTcpe.calificado => (TonoExamen.principal, Icons.verified_outlined),
  EstadoExamenTcpe.porRevisar => (TonoExamen.terciario, Icons.rate_review_outlined),
  EstadoExamenTcpe.enCurso => (TonoExamen.secundario, Icons.timelapse),
  EstadoExamenTcpe.vencido => (TonoExamen.alerta, Icons.timer_off_outlined),
  EstadoExamenTcpe.ausente => (TonoExamen.alerta, Icons.person_off_outlined),
  EstadoExamenTcpe.sinIniciar => (TonoExamen.neutro, Icons.schedule),
  EstadoExamenTcpe.desconocido => (TonoExamen.neutro, Icons.help_outline),
};

/// El estado de un examen como etiqueta: el tono codifica qué hay que hacer.
class EtiquetaEstadoExamen extends StatelessWidget {
  const EtiquetaEstadoExamen(this.estado, {super.key});

  final EstadoExamenTcpe estado;

  @override
  Widget build(BuildContext context) {
    final (tono, icono) = aspectoDeEstado(estado);
    return PastillaExamen(texto: estado.etiqueta, tono: tono, icono: icono);
  }
}

/// Aprobado o Reprobado según la nota mínima del lote; `--` sin nota.
class EtiquetaAprobacion extends StatelessWidget {
  const EtiquetaAprobacion(this.aprobado, {super.key, this.enCelda = false});

  final bool? aprobado;

  /// En una celda de tabla: icono y texto en color que se recorta, sin pastilla.
  final bool enCelda;

  @override
  Widget build(BuildContext context) {
    final a = aprobado;
    if (a == null) return Text('--', style: context.apagado());
    final texto = a ? 'Aprobado' : 'Reprobado';
    final icono = a ? Icons.check_circle : Icons.cancel;
    if (enCelda) {
      final cs = Theme.of(context).colorScheme;
      final color = a ? cs.primary : cs.error;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: Esp.xs),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: Peso.titulo),
            ),
          ),
        ],
      );
    }
    return PastillaExamen(texto: texto, tono: a ? TonoExamen.principal : TonoExamen.alerta, icono: icono);
  }
}

/// La modalidad de un lote: en línea (principal) o escrito (terciario).
class PastillaModalidad extends StatelessWidget {
  const PastillaModalidad(this.modalidad, {super.key});

  final String? modalidad;

  @override
  Widget build(BuildContext context) => switch (modalidad) {
    'O' => PastillaExamen(texto: modalidadTexto(modalidad), tono: TonoExamen.principal, icono: Icons.wifi),
    'E' => PastillaExamen(texto: modalidadTexto(modalidad), tono: TonoExamen.terciario, icono: Icons.description_outlined),
    _ => Text('--', style: context.apagado()),
  };
}

/// Una nota coloreada contra la mínima: en principal si alcanza, en alerta si no.
class CeldaNota extends StatelessWidget {
  const CeldaNota(this.valor, {super.key, this.minima});

  final double? valor;
  final double? minima;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = valor;
    final m = minima;
    final color = v == null || m == null ? null : (v >= m ? cs.primary : cs.error);
    return Text(nota(v), maxLines: 1, style: context.numero(fuerte: true, color: color));
  }
}

/// Texto de un dato para mostrar: `null`, `"null"` o vacío se ven como `--`.
String oGuion(String? texto) {
  final t = (texto ?? '').trim();
  return t.isEmpty || t.toLowerCase() == 'null' ? '--' : t;
}

/// El membrete de la pantalla, como el de una hoja de examen: folio en letra
/// fija ([ceja]), título, una línea de guía y las acciones a la derecha
/// (debajo en el teléfono).
class EncabezadoExamenes extends StatelessWidget {
  const EncabezadoExamenes({
    super.key,
    required this.titulo,
    required this.detalle,
    this.acciones = const [],
    this.compacto = false,
    this.ceja = 'Exámenes',
    this.icono,
  });

  final String titulo;
  final String detalle;
  final List<Widget> acciones;
  final bool compacto;
  final String ceja;

  /// El de la pantalla, en el sello a la izquierda del título.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soloTextos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ceja.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: fuenteFija,
            letterSpacing: 1.4,
            fontWeight: Peso.titulo,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: Esp.xs),
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: (compacto ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(fontWeight: Peso.titulo, letterSpacing: -0.2),
          ),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          detalle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
    final textos =
        icono == null
            ? soloTextos
            : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SelloExamen(icono: icono!, tamanio: compacto ? 40 : 52),
                ),
                SizedBox(width: compacto ? Esp.m : Esp.l),
                Expanded(child: soloTextos),
              ],
            );
    if (compacto || acciones.isEmpty) {
      // En el teléfono los iconos (actualizar) quedan junto al título y el resto debajo.
      final iconos = acciones.whereType<IconButton>().toList();
      final otras = acciones.where((w) => w is! IconButton).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: textos), ...iconos]),
          if (otras.isNotEmpty) ...[
            const SizedBox(height: Esp.m),
            Wrap(spacing: Esp.s, runSpacing: Esp.s, children: otras),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: textos),
        const SizedBox(width: Esp.l),
        Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones),
      ],
    );
  }
}

/// Filtros a la vista en escritorio; en el teléfono, plegados detrás de un
/// botón que dice cuántos hay activos.
class FiltrosExamenes extends StatefulWidget {
  const FiltrosExamenes({
    super.key,
    required this.compacto,
    required this.campos,
    this.activos = 0,
    this.onLimpiar,
  });

  final bool compacto;
  final List<Widget> campos;
  final int activos;
  final VoidCallback? onLimpiar;

  @override
  State<FiltrosExamenes> createState() => _FiltrosExamenesState();
}

class _FiltrosExamenesState extends State<FiltrosExamenes> {
  bool _abiertos = false;

  @override
  Widget build(BuildContext context) {
    final limpiar =
        widget.activos > 0 && widget.onLimpiar != null
            ? TextButton.icon(
              onPressed: widget.onLimpiar,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Quitar filtros'),
            )
            : null;
    if (!widget.compacto) {
      return Wrap(
        spacing: Esp.m,
        runSpacing: Esp.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [...widget.campos, if (limpiar != null) limpiar],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => setState(() => _abiertos = !_abiertos),
                icon: Icon(_abiertos ? Icons.expand_less : Icons.tune, size: 18),
                label: Text(
                  widget.activos == 0 ? 'Filtros' : 'Filtros (${widget.activos})',
                ),
              ),
            ),
            if (limpiar != null) limpiar,
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child:
              _abiertos
                  ? Padding(
                    padding: const EdgeInsets.only(top: Esp.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final c in widget.campos)
                          Padding(padding: const EdgeInsets.only(bottom: Esp.s), child: c),
                      ],
                    ),
                  )
                  : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Un combo de filtro con ancho fijo en escritorio y completo en el teléfono.
class ComboFiltro<T> extends StatelessWidget {
  const ComboFiltro({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    this.ancho = 220,
    this.textoTodos = 'Todos',
  });

  final String etiqueta;
  final T? valor;
  final List<(T, String)> opciones;
  final ValueChanged<T?> onCambio;
  final double ancho;
  final String textoTodos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final existe = valor == null || opciones.any((o) => o.$1 == valor);
    // Un filtro puesto se tiñe: de un vistazo se ve qué recorta la lista.
    final puesto = valor != null && existe;
    final combo = DropdownButtonFormField<T?>(
      value: existe ? valor : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: etiqueta,
        isDense: true,
        border: const OutlineInputBorder(),
        filled: puesto,
        fillColor: cs.primaryContainer.withValues(alpha: 0.45),
        enabledBorder: puesto ? OutlineInputBorder(borderSide: BorderSide(color: cs.primary)) : null,
        labelStyle: puesto ? TextStyle(color: cs.primary, fontWeight: Peso.titulo) : null,
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(textoTodos)),
        for (final (v, t) in opciones)
          DropdownMenuItem<T?>(
            value: v,
            child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onCambio,
    );
    return LayoutBuilder(
      builder:
          (context, r) => SizedBox(
            width: r.maxWidth.isFinite && r.maxWidth < ancho ? r.maxWidth : ancho,
            child: combo,
          ),
    );
  }
}

/// Una cifra con su rótulo, para las cabeceras de detalle. Con [icono], va
/// en una ficha teñida del [tono]: la cifra se lee en su color.
class CifraExamen extends StatelessWidget {
  const CifraExamen({super.key, required this.valor, required this.rotulo, this.icono, this.tono = TonoExamen.neutro});

  final String valor;
  final String rotulo;
  final IconData? icono;
  final TonoExamen tono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = coloresDeTono(cs, tono);
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: Peso.dato,
            fontFeatures: cifrasTabulares,
            color: icono == null || tono == TonoExamen.neutro ? null : c.acento,
          ),
        ),
        Text(rotulo, style: context.apagado()),
      ],
    );
    if (icono == null) return textos;
    return Container(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.l, Esp.s),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.fondo.withValues(alpha: 0.45), cs.surface),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelloExamen(icono: icono!, tono: tono, tamanio: 36),
          const SizedBox(width: Esp.m),
          Flexible(child: textos),
        ],
      ),
    );
  }
}

/// Abre un formulario en diálogo (escritorio) o a pantalla completa
/// (teléfono). [builder] recibe `completa` para que el formulario arme su
/// [MarcoFormulario] con el mismo contenido en los dos casos.
Future<T?> mostrarFormulario<T>(
  BuildContext context,
  Widget Function(bool completa) builder,
) {
  // Sin esto, el teclado del campo que tenía el foco vuelve al cerrar el formulario.
  FocusManager.instance.primaryFocus?.unfocus();
  if (MediaQuery.sizeOf(context).width < 600) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => builder(true)),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (_) => builder(false),
  );
}

/// El marco de un formulario: `AlertDialog` en escritorio, `Scaffold` con las
/// acciones abajo en el teléfono.
class MarcoFormulario extends StatelessWidget {
  const MarcoFormulario({
    super.key,
    required this.titulo,
    required this.completa,
    required this.cuerpo,
    required this.acciones,
    this.ancho = anchoDialogoExamenes,
    this.icono,
  });

  final String titulo;
  final bool completa;
  final Widget cuerpo;
  final List<Widget> acciones;
  final double ancho;

  /// El sello junto al título del diálogo.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    if (!completa) {
      return AlertDialog(
        title:
            icono == null
                ? Text(titulo)
                : Row(
                  children: [
                    SelloExamen(icono: icono!, tamanio: 40),
                    const SizedBox(width: Esp.m),
                    Expanded(child: Text(titulo)),
                  ],
                ),
        // Aire arriba: la etiqueta flotante del primer campo sobresale de su
        // borde y el desplazamiento la recortaba.
        content: SizedBox(
          width: ancho,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: Esp.s),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: cuerpo,
          ),
        ),
        actions: acciones,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (icono != null) ...[SelloExamen(icono: icono!, tamanio: 32), const SizedBox(width: Esp.m)],
            Expanded(child: Text(titulo, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.l),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: cuerpo,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: acciones,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

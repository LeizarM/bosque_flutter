// Destino final: lib/presentation/widgets/tareas-rutinarias/pagina_tareas.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:flutter/material.dart';

/// Las piezas de página que comparten las pantallas del módulo Tareas
/// Rutinarias.
///
/// **Por qué existe.** Cada pantalla había resuelto por su cuenta el
/// encabezado, el margen, el estado vacío y la barra de acción. Vistas una al
/// lado de la otra (capturas del 2026-09-11) parecían de aplicaciones
/// distintas: títulos sueltos sin nada que dijera de qué tarea eran, tablas
/// pegadas al borde en unas y con margen en otras, una docena de estados
/// vacíos distintos y el botón principal a veces arriba, a veces en una barra
/// de 1400 px y a veces flotando encima de la última columna.
///
/// **La identidad es la insignia.** El mismo icono y el mismo tono que la
/// tarea tiene en su fila de "Mis tareas" encabezan la pantalla a la que se
/// entra al tocarla. El color no decora: dice qué tipo de trabajo es.
///
/// **Se mide el cajón, no la ventana.** Todas estas pantallas se dibujan
/// dentro del dashboard, al lado de un sidebar de 260 px: `MediaQuery` dice el
/// ancho de la ventana y miente. Por eso las decisiones de ancho de este
/// archivo usan `LayoutBuilder` y [Aire], igual que el resto de `core/ui`.

/// El margen de las páginas del módulo.
///
/// Sin ancho máximo, a propósito: en escritorio el contenido usa todo el
/// espacio (Marcelo, 2026-09-08: "no me quites espacio de la pantalla").
class MargenPaginaTareas extends StatelessWidget {
  final Widget child;

  /// Sin margen de abajo para las listas que corren hasta el borde.
  final bool abajo;

  const MargenPaginaTareas({super.key, required this.child, this.abajo = true});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cajon) {
        final h = Aire.de(cajon.maxWidth).esChico ? Esp.m : Esp.l;
        return Padding(
          padding: EdgeInsets.fromLTRB(h, Esp.m, h, abajo ? Esp.m : 0),
          child: child,
        );
      },
    );
  }
}

/// El icono de un tipo de tarea sobre su tono.
class InsigniaTarea extends StatelessWidget {
  final IconData icono;
  final Color fondo;
  final Color color;
  final double tam;

  const InsigniaTarea({
    super.key,
    required this.icono,
    required this.fondo,
    required this.color,
    this.tam = 40,
  });

  /// La de un tipo de tarea (idATR): el mismo icono que muestra su fila en
  /// "Mis tareas".
  factory InsigniaTarea.deTipo(
    BuildContext context,
    int? idATR, {
    IconData? icono,
    double tam = 40,
  }) {
    return InsigniaTarea(
      icono:
          icono ??
          TareaPendienteTile.tipoDeAccion(idATR)?.icono ??
          Icons.task_alt,
      fondo: TareasColors.tipoTarea(context, idATR),
      color: TareasColors.tipoTareaTexto(context, idATR),
      tam: tam,
    );
  }

  /// La de una pantalla del módulo que no es de un tipo de tarea (bitácora,
  /// mi equipo, catálogo): el tono secundario del tema.
  factory InsigniaTarea.modulo(
    BuildContext context,
    IconData icono, {
    double tam = 40,
  }) => InsigniaTarea.deTipo(context, null, icono: icono, tam: tam);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Icon(icono, size: tam * 0.55, color: color),
    );
  }
}

/// El encabezado de una pantalla del módulo: insignia, título y una línea de
/// contexto (la fecha de la tarea, cuántas faltan).
class AppBarTareas extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? insignia;
  final List<Widget>? acciones;
  final PreferredSizeWidget? bottom;

  const AppBarTareas({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.insignia,
    this.acciones,
    this.bottom,
  });

  static const double _alto = 68;

  @override
  Size get preferredSize =>
      Size.fromHeight(_alto + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AppBar(
      toolbarHeight: _alto,
      titleSpacing: Esp.l,
      shape: Border(bottom: BorderSide(color: tema.colorScheme.outlineVariant)),
      title: Row(
        children: [
          if (insignia != null) ...[insignia!, const SizedBox(width: Esp.m)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: Peso.titulo,
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [...?acciones, const SizedBox(width: Esp.s)],
      bottom: bottom,
    );
  }
}

enum TonoEstadoTareas { neutro, error, listo, aviso }

/// El estado de una pantalla sin nada que mostrar: vacía, con error de
/// lectura, o con todo resuelto.
///
/// Es la variante del módulo de `MensajeVacio` y `MensajeError` (core/ui):
/// agrega el tono de estado y, sobre todo, una acción — casi todos los vacíos
/// de este módulo son accionables ("Sin novedad", "Sin pendientes").
///
/// **Un error nunca se muestra como vacío.** "No hay traspasos" habilita dar
/// el día por revisado; "no se pudo leer" no. Por eso el error tiene su propio
/// constructor y su propio tono, y siempre ofrece reintentar.
class EstadoTareas extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;
  final TonoEstadoTareas tono;

  const EstadoTareas({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.tono = TonoEstadoTareas.neutro,
  });

  /// Una lectura que falló.
  ///
  /// Con [error] y sin [detalle], el detalle es el error traducido para una
  /// persona (`textoParaUsuario`), no el "DioException [bad response]…" crudo.
  factory EstadoTareas.error({
    Key? key,
    required String titulo,
    String? detalle,
    Object? error,
    required VoidCallback onReintentar,
  }) => EstadoTareas(
    key: key,
    icono: Icons.cloud_off_outlined,
    titulo: titulo,
    detalle: detalle ?? (error == null ? null : textoParaUsuario(error)),
    tono: TonoEstadoTareas.error,
    accion: FilledButton.tonalIcon(
      onPressed: onReintentar,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Reintentar'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final (Color fondo, Color color) = switch (tono) {
      TonoEstadoTareas.neutro => (
        tema.colorScheme.surfaceContainerHighest,
        tema.colorScheme.onSurfaceVariant,
      ),
      TonoEstadoTareas.error => (
        TareasColors.vencido(context),
        TareasColors.vencidoTexto(context),
      ),
      TonoEstadoTareas.listo => (
        TareasColors.realizado(context),
        TareasColors.realizadoTexto(context),
      ),
      TonoEstadoTareas.aviso => (
        TareasColors.pendiente(context),
        TareasColors.pendienteTexto(context),
      ),
    };

    // Scrollea si no entra: en un teléfono con teclado abierto el hueco puede
    // ser de un centenar de píxeles (mismo motivo que MensajeVacio).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
                child: Icon(icono, size: 36, color: color),
              ),
              const SizedBox(height: Esp.l),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: Peso.titulo,
                ),
              ),
              if (detalle != null) ...[
                const SizedBox(height: Esp.xs),
                Text(
                  detalle!,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (accion != null) ...[const SizedBox(height: Esp.l), accion!],
            ],
          ),
        ),
      ),
    );
  }
}

/// La barra de la acción que cierra el trabajo de la pantalla ("Cerrar
/// arqueo", "Confirmar y cerrar").
///
/// En escritorio el resumen va a la izquierda y el botón a la derecha con un
/// ancho razonable: un botón de 1400 px no se lee como botón. En un cajón
/// angosto el botón ocupa todo el ancho, debajo del resumen.
class BarraAccionTareas extends StatelessWidget {
  final Widget? resumen;
  final Widget accion;

  const BarraAccionTareas({super.key, this.resumen, required this.accion});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Material(
      color: tema.colorScheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: tema.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: LayoutBuilder(
              builder: (context, cajon) {
                if (Aire.de(cajon.maxWidth).esChico) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (resumen != null) ...[
                        resumen!,
                        const SizedBox(height: Esp.s),
                      ],
                      accion,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: resumen ?? const SizedBox.shrink()),
                    const SizedBox(width: Esp.l),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 240),
                      child: accion,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Aire de abajo para que un botón flotante no tape la última fila.
///
/// Un FAB extendido mide 56 de alto y queda a 16 del borde: sin este margen,
/// en escritorio tapaba justo la columna de acciones de la última fila
/// ("Respuesta", el menú de cada tarea, "Copiar").
const double aireBajoFab = 88;

/// Una píldora de estado o de frecuencia: "Cerrada", "Cuadra", "Semanal".
///
/// La auditoría del 2026-09-11 encontró seis hechas a mano, con cuatro
/// rellenos, tres radios y tres tamaños de letra distintos: la misma
/// "Diario" se veía de tres maneras según la pantalla.
///
/// Son las medidas que ya usaba la píldora de verificación de traspasos:
/// relleno de 8 y 3, esquina de pastilla y `labelMedium` seminegrita.
class PildoraTareas extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;
  final IconData? icono;
  final String? tooltip;

  const PildoraTareas({
    super.key,
    required this.texto,
    required this.fondo,
    required this.color,
    this.icono,
    this.tooltip,
  });

  /// La de una frecuencia, con sus tonos.
  factory PildoraTareas.frecuencia(
    BuildContext context,
    int idFrec,
    String texto,
  ) => PildoraTareas(
    texto: texto,
    fondo: TareasColors.frecuencia(context, idFrec),
    color: TareasColors.frecuenciaTexto(context, idFrec),
  );

  @override
  Widget build(BuildContext context) {
    final nombre = Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: Peso.titulo,
      ),
    );
    final pildora = DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
        child:
            icono == null
                ? nombre
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 14, color: color),
                    const SizedBox(width: Esp.xs),
                    nombre,
                  ],
                ),
      ),
    );
    return tooltip == null ? pildora : Tooltip(message: tooltip!, child: pildora);
  }
}

/// Un botón de respuesta: Sí, No, No aplica, Llegó, No llegó.
///
/// Borde y letra del tono de la respuesta, relleno cuando es la elegida. La
/// auditoría del 2026-09-11 encontró la misma pregunta de sí o no hecha de tres
/// maneras: botones con borde de color en "Mis tareas", y en Coches un par
/// relleno y de contorno con el color del tema, con icono en la tarjeta y sin
/// icono en la tabla.
class BotonRespuestaTareas extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final Color tono;
  final bool elegido;
  final VoidCallback? onPressed;

  const BotonRespuestaTareas({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.tono,
    this.elegido = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Deshabilitado se atenúa: con el color fijo, un botón que no responde se
    // veía igual que uno que sí.
    Color segun(Set<WidgetState> estados, Color color) =>
        estados.contains(WidgetState.disabled)
            ? color.withValues(alpha: 0.38)
            : color;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Esp.m),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (e) => segun(e, elegido ? scheme.onPrimary : tono),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (e) => elegido ? segun(e, tono) : Colors.transparent,
        ),
        side: WidgetStateProperty.resolveWith(
          (e) => BorderSide(color: segun(e, tono)),
        ),
      ),
      icon: Icon(icono, size: 16),
      label: Text(etiqueta, style: const TextStyle(fontWeight: Peso.titulo)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter/services.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Estados de una vista de datos: cargando, vacia y con error.
///
/// Los tres comparten alto y composicion para que la tabla no salte cuando el
/// estado cambia. En Bosque v2 la pantalla quedaba en blanco durante la carga y
/// el usuario volvia a pulsar Desplegar creyendo que se habia colgado.
class EstadoVista {
  const EstadoVista._();

  /// Alto minimo compartido por los tres estados.
  static const double _alto = 240;

  /// Carga de una tabla: la silueta de la tabla, no un circulo girando.
  ///
  /// Un spinner centrado no dice nada salvo "espera", y al llegar los datos la
  /// pantalla salta de golpe. La silueta ocupa desde el principio el sitio que
  /// van a ocupar las filas: no hay salto, y se entiende que lo que viene es
  /// una tabla y cuanta.
  static Widget cargandoTabla(
    BuildContext context, {
    int filas = 6,
    int columnas = 5,
  }) => EsqueletoTabla(filas: filas, columnas: columnas);

  /// Spinner con la accion que se esta ejecutando.
  ///
  /// Para esperas sin forma conocida -ejecutar un calculo, guardar-. Si lo que
  /// se espera es una tabla, va cargandoTabla.
  static Widget cargando(BuildContext context, {String mensaje = 'Cargando'}) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: _alto,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista sin resultados. El mensaje dice que hacer, no solo que no hay datos.
  static Widget vacio(
    BuildContext context, {
    required String titulo,
    required String indicacion,
    IconData icono = Icons.inbox_outlined,
    String? textoAccion,
    VoidCallback? alPulsarAccion,
    // El icono de la accion era Icons.add clavado, que solo sirve cuando la
    // accion es «crear». En un vacio que ofrece MIRAR algo, un «+» promete un
    // formulario que no existe.
    IconData iconoAccion = Icons.add,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: _alto,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 40, color: cs.outline),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                indicacion,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (textoAccion != null && alPulsarAccion != null) ...[
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: alPulsarAccion,
                  icon: Icon(iconoAccion, size: 18),
                  label: Text(textoAccion),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Error de carga con reintento. Muestra el mensaje del backend tal cual.
  static Widget error(
    BuildContext context, {
    required Object error,
    VoidCallback? alReintentar,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mensaje = error.toString().replaceFirst('Exception: ', '');

    return SizedBox(
      height: _alto,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: cs.error),
              const SizedBox(height: 14),
              Text(
                'No se pudieron cargar los datos',
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (alReintentar != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: alReintentar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta compacta de porcentaje.
///
/// El porcentaje es el dato que se lee primero en todas las tablas del modulo,
/// asi que se distingue del resto del texto en vez de quedar como una columna mas.
class ChipPorcentaje extends StatelessWidget {
  const ChipPorcentaje({
    super.key,
    required this.valor,
    this.fondoTono,
    this.textoTono,
  });

  /// Porcentaje en base 100.
  final double valor;

  /// Colores propios, para cuando el chip codifica algo mas que su valor
  /// (en el preliminar, el tramo al que pertenece la fila). Si van en null se
  /// usan los del tema, que es el comportamiento de siempre.
  final Color? fondoTono;
  final Color? textoTono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = fondoTono ?? cs.surfaceContainerHighest;
    final texto = textoTono ?? cs.onSurface;

    return Container(
      // vertical 5 y height 1.2: con esto la caja mide lo mismo que ChipEstado
      // y los dos conviven en un Wrap sin escalonarse.
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: ComisionesTema.brChip,
      ),
      child: Text(
        '${valor.toStringAsFixed(2)} %',
        style: ComisionesTema.numeroCelda(
          context,
          fuerte: true,
        )?.copyWith(color: texto, fontSize: 12, height: 1.2),
      ),
    );
  }
}

/// Indicador de vigencia. Verde vigente, gris cerrado.
class ChipVigencia extends StatelessWidget {
  const ChipVigencia({super.key, required this.vigente});

  final bool vigente;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = vigente ? Colors.green.shade700 : cs.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          vigente ? 'Vigente' : 'Cerrado',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Silueta de una tabla mientras cargan los datos.
///
/// El brillo que recorre la silueta no es decoracion: sin movimiento, unas
/// barras grises quietas se leen como contenido roto o como una tabla vacia.
/// Moviendose se leen como "viene en camino".
class EsqueletoTabla extends StatefulWidget {
  const EsqueletoTabla({super.key, this.filas = 6, this.columnas = 5});

  /// Filas a dibujar cuando el alto disponible es ilimitado -dentro de un
  /// scroll, por ejemplo-. Con alto acotado manda el alto: se dibujan las que
  /// entren.
  ///
  /// Antes era un numero fijo y cada pestania elegia el suyo. El Preliminar
  /// pedia ocho, que necesitan 393px, y su Expanded daba 340: se desbordaba
  /// por 52. Un contador fijo no puede saber cuanto espacio le van a dar.
  final int filas;
  final int columnas;

  /// Techo cuando sobra alto: sin el, en un monitor alto saldrian treinta
  /// barras grises, que es ruido y no informacion.
  static const int maximo = 12;

  @override
  State<EsqueletoTabla> createState() => _EsqueletoTablaState();
}

class _EsqueletoTablaState extends State<EsqueletoTabla>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Anchos desparejos, no todos iguales: una rejilla perfectamente regular se
  /// lee como un patron de carga generico. Desparejo se lee como una tabla.
  static const _anchos = <double>[0.34, 0.14, 0.12, 0.2, 0.2];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final base = cs.onSurface.withValues(alpha: oscuro ? 0.09 : 0.07);
    final brillo = cs.onSurface.withValues(alpha: oscuro ? 0.16 : 0.13);

    Widget barra(double fraccion, double alto) => LayoutBuilder(
      builder:
          (_, c) => Container(
            width: c.maxWidth * fraccion,
            height: alto,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
    );

    Widget celda(int i, double alto) => Expanded(
      flex: (_anchos[i % _anchos.length] * 100).round(),
      child: Align(
        // Las dos ultimas columnas son importes y en la tabla van a la
        // derecha; la silueta respeta esa alineacion.
        alignment:
            i >= widget.columnas - 2
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: barra(i == 0 ? 0.8 : 0.6, alto),
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      builder:
          (context, hijo) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback:
                (rect) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [base, brillo, base],
                  // El punto de brillo cruza de un borde al otro; los stops se
                  // recortan para que no se salgan del rango valido.
                  stops: [
                    (_c.value - 0.25).clamp(0.0, 1.0),
                    _c.value.clamp(0.0, 1.0),
                    (_c.value + 0.25).clamp(0.0, 1.0),
                  ],
                ).createShader(rect),
            child: hijo,
          ),
      child: Semantics(
        label: 'Cargando datos',
        child: LayoutBuilder(
          builder: (_, c) {
            // Cuantas filas entran de verdad. El encabezado y el divisor ya
            // ocupan lo suyo, asi que se descuentan antes de dividir.
            final libre = c.maxHeight - ComisionesTema.altoEncabezado - 1;
            final filas =
                c.maxHeight.isFinite
                    ? (libre / ComisionesTema.altoFila).floor().clamp(
                      1,
                      EsqueletoTabla.maximo,
                    )
                    : widget.filas;

            // El scroll no scrollea: da alto ilimitado a la Column para que
            // nunca pueda desbordar, y recorta lo que sobre. La cuenta de
            // arriba ya hace que normalmente no sobre nada; esto cubre el caso
            // raro de un hueco mas bajo que el propio encabezado.
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: ComisionesTema.altoEncabezado,
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.columnas; i++) celda(i, 8),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  for (var f = 0; f < filas; f++)
                    SizedBox(
                      height: ComisionesTema.altoFila,
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.columnas; i++)
                            celda(i, 11),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// El número de un documento, copiable de un clic.
///
/// Existe porque estos números se transcriben a SAP a mano. Seleccionar ocho
/// dígitos dentro de una celda de tabla —donde la fila además captura gestos—
/// es más trabajo que un clic, y en un teléfono la selección de texto pelea con
/// el scroll de la lista.
///
/// Avisa que copió: sin confirmación, quien hace clic no sabe si funcionó y lo
/// vuelve a hacer.
class NumeroCopiable extends StatelessWidget {
  const NumeroCopiable({
    super.key,
    required this.valor,
    this.estilo,
    this.etiqueta = 'Documento',
  });

  /// Lo que se muestra y lo que se copia. En null o vacío se dibuja un guion y
  /// deja de ser interactivo: no hay nada que copiar.
  final String? valor;
  final TextStyle? estilo;

  /// Cómo se nombra en el aviso: «Documento 262370660 copiado».
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return Text('—', style: estilo ?? TextStyle(color: cs.onSurfaceVariant));
    }

    return Tooltip(
      message: 'Clic para copiar',
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: texto));
          if (context.mounted) avisar(context, '$etiqueta $texto copiado');
        },
        borderRadius: ComisionesTema.brChip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texto, style: estilo),
              const SizedBox(width: 6),
              Icon(Icons.copy_outlined, size: 13, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

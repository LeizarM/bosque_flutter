/// Piezas compartidas por las pestañas del Rol de Turnos de Sábado.
library;

import 'dart:math' as math;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart'
    as compartido;
import 'package:flutter/material.dart';

export 'package:bosque_flutter/core/ui/tokens_bosque.dart' show Aire;

// `MensajeVacio`, `Etiqueta`, `TonoEtiqueta`, `ComboBuscable` y `fechaCorta`
// viven en `core/ui/piezas_bosque.dart`; se re-exportan para los widgets de
// sábados.
export 'package:bosque_flutter/core/ui/piezas_bosque.dart';

String fechaHora(DateTime? f) =>
    f == null
        ? '--'
        : '${fechaCorta(f)} ${f.hour.toString().padLeft(2, '0')}:'
            '${f.minute.toString().padLeft(2, '0')}';

/// Convierte el `#RRGGBB` de `trs_EstadoTurno.color`. null si viene vacío o mal
/// formado: mejor un fondo neutro que un crash por un color cargado a mano.
Color? colorDesdeHex(String hex) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

// El aviso

/// Muestra el resultado de una acción, ya traducido para quien usa la app (ver
/// [humanizar]).
///
/// Los éxitos de los SPs explican el siguiente paso («ejecuta REGENERAR») y se
/// muestran en vez de un «Guardado»; los errores técnicos se reemplazan por un
/// aviso corto y el detalle va a la consola. El dibujo (tarjeta en el Overlay
/// raíz, sobre los diálogos) es de `shared/aviso.dart`.
void avisar(BuildContext context, String mensaje, {bool esError = false}) =>
    compartido.avisar(context, humanizar(mensaje).texto, esError: esError);

/// Envuelve una acción: corta el doble tap, cierra la hoja y avisa.
Future<bool> ejecutarAccion(
  BuildContext context,
  Future<void> Function() accion, {
  required String exito,
  bool cerrar = false,
}) async {
  try {
    await accion();
    if (!context.mounted) return true;
    if (cerrar) Navigator.of(context).pop();
    avisar(context, exito);
    return true;
  } catch (e) {
    if (context.mounted) avisar(context, '$e', esError: true);
    return false;
  }
}

// Medidas según el dispositivo

// `Aire` (cortes de 600 y 1000) vive en `core/ui/tokens_bosque.dart` y se
// re-exporta arriba.

/// Medidas de la matriz, calculadas del ancho real disponible (no de la
/// pantalla: el dashboard tiene un sidebar).
///
/// [anchoCelda] y [anchoNombre] son los **mínimos** para ser legible con el
/// ancho justo; cuando sobra, [repartir] decide hasta dónde crece cada uno.
class MedidasGrilla {
  final double anchoNombre;
  final double anchoCelda;

  /// Hasta dónde puede engordar una celda cuando sobra ancho.
  ///
  /// **Hay tope y no se estira hasta llenar:** la celda tiene UNA letra; con 5
  /// columnas en 1900 px serían de 300 px con un `1` perdido. 64 px es el ancho por
  /// defecto de una columna de Excel (la hoja que este módulo reemplaza) y cerca
  /// del doble del alto de fila. Es el mismo para los tres tamaños.
  final double anchoCeldaMax;

  final double altoFila;
  final double altoCabecera;

  const MedidasGrilla({
    required this.anchoNombre,
    required this.anchoCelda,
    this.anchoCeldaMax = 64,
    required this.altoFila,
    required this.altoCabecera,
  });

  /// Cuánto mide cada cosa con el ancho que realmente hay.
  ///
  /// El sobrante se gasta según lo que cada pixel compra para leer: 1) la columna
  /// de nombres hasta [idealNombre] (evita los «…», la pérdida más cara); 2) las
  /// celdas hasta [anchoCeldaMax] (mismo ancho en un mes de 4 y uno de 5 sábados);
  /// 3) el resto es margen, centrado. Con «Todo el año» (52 columnas) todo queda
  /// en los mínimos y la matriz scrollea.
  ({double nombre, double celda}) repartir({
    required double disponible,
    required int columnas,
    required double idealNombre,
  }) {
    // Los nombres se miden con las celdas en su ancho MÍNIMO: primero se resuelve
    // si sobra y con el resto se engordan las celdas; al revés, unas celdas anchas
    // se comerían el lugar del apellido.
    final libre = disponible - columnas * anchoCelda;
    final nombre =
        libre <= anchoNombre
            ? anchoNombre
            : (libre < idealNombre ? libre : idealNombre);

    final porColumna = (disponible - nombre) / columnas;
    final celda =
        porColumna < anchoCelda
            ? anchoCelda
            : (porColumna > anchoCeldaMax ? anchoCeldaMax : porColumna);

    // A pixel entero: bordes de media unidad en posición fraccionaria salen
    // borrosos, y son 52 en fila.
    return (nombre: nombre, celda: celda.floorToDouble());
  }

  factory MedidasGrilla.para(double ancho) {
    final aire = Aire.de(ancho);
    return switch (aire) {
      // En "medio" se recortan los nombres antes que las celdas: perder una columna
      // cuesta más que perder letras del apellido.
      Aire.medio => const MedidasGrilla(
        anchoNombre: 150,
        anchoCelda: 36,
        altoFila: 32,
        altoCabecera: 48,
      ),
      Aire.amplio => const MedidasGrilla(
        anchoNombre: 210,
        anchoCelda: 42,
        altoFila: 34,
        altoCabecera: 52,
      ),
      // En "justo" la matriz no se muestra; las medidas quedan por si se fuerza la
      // vista de matriz a mano.
      Aire.justo => const MedidasGrilla(
        anchoNombre: 120,
        anchoCelda: 32,
        altoFila: 30,
        altoCabecera: 46,
      ),
    };
  }
}

// Piezas de la grilla

/// `ene`, `feb`, … Sin `intl`: son doce palabras y se usan en tres lugares (el
/// mes debe escribirse igual en todas las vistas).
String mesCorto(int mes) {
  const meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return (mes >= 1 && mes <= 12) ? meses[mes - 1] : '';
}

/// `Enero`, `Febrero`, … Mismo criterio que [mesCorto]: los doce nombres viven
/// en un solo lugar. Con mayúscula inicial: los usos son de rótulo.
String mesLargo(int mes) {
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return (mes >= 1 && mes <= 12) ? meses[mes - 1] : '';
}

/// «25 sábados de 26 en todo el año»: lo que lleva trabajado una persona contra
/// su meta.
///
/// Existe para que la grilla («25/26») y «Grupos» digan igual el MISMO número.
/// **«en todo el año» no es relleno**: la grilla arranca filtrada por mes y sin
/// esas palabras el contador parece del mes en pantalla. Con meta 0 se omite:
/// «de 0» se leería como una meta de cero sábados.
String sabadosDelAnio({required int turnos, required int meta}) =>
    meta > 0
        ? '$turnos sábados de $meta en todo el año'
        : '$turnos sábados en todo el año';

/// El círculo con la A o la B.
///
/// El grupo decide qué sábados le tocan a alguien; una sola definición para que
/// el mismo color signifique lo mismo en matriz, agenda y grupos.
class InsigniaGrupo extends StatelessWidget {
  const InsigniaGrupo({super.key, required this.grupo, this.diametro = 18});

  final String grupo;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esA = grupo == 'A';
    return Container(
      width: diametro,
      height: diametro,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: esA ? cs.primaryContainer : cs.secondaryContainer,
      ),
      child: Text(
        grupo.isEmpty ? '?' : grupo,
        style: TextStyle(
          fontSize: diametro * 0.56,
          fontWeight: FontWeight.w700,
          color: esA ? cs.onPrimaryContainer : cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// El color de fondo de una celda, o null si está libre.
///
/// **null es un dato**: el libre es la ausencia de la fila, así que el cuadrito
/// sin pintar significa «ese día no le tocaba».
Color? fondoDeCelda(BuildContext context, CeldaTurnoEntity? celda) =>
    colorDeCelda(Theme.of(context).colorScheme, celda)?.fondo;

/// La letra de la celda. Sólo la letra.
///
/// La marca de intervención NO va aquí: ver [MarcaDeIntervencion].
class LetraDeCelda extends StatelessWidget {
  const LetraDeCelda({super.key, required this.celda, this.estiloTexto});

  final CeldaTurnoEntity? celda;
  final TextStyle? estiloTexto;

  @override
  Widget build(BuildContext context) {
    final c = celda;
    if (c == null) return const SizedBox.shrink();
    final color = colorDeEstado(Theme.of(context).colorScheme, c.codigoExcel);

    return Text(
      c.codigoExcel,
      // El color sale del mismo lugar que el fondo, no del tema: el fondo lleva un
      // tono aplicado y el par se decide junto.
      style: (estiloTexto ?? context.numero(fuerte: true))?.copyWith(
        color: color.texto,
      ),
    );
  }
}

/// La esquinita que marca una celda escrita por una persona.
///
/// Significa origen 'M' o 'P': una **regeneración no la va a pisar**. Igual en
/// matriz y agenda. Es un triángulo en la esquina y no un punto sobre la letra
/// (el Stack se encogía a ~10×14 px, el punto caía ENCIMA y una `C` se leía `€`).
class MarcaDeIntervencion extends StatelessWidget {
  const MarcaDeIntervencion({super.key, required this.color, this.lado = 7});

  final Color color;
  final double lado;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(lado, lado), painter: _Esquinita(color));
}

class _Esquinita extends CustomPainter {
  const _Esquinita(this.color);
  final Color color;

  @override
  void paint(Canvas lienzo, Size tam) {
    final camino =
        Path()
          ..moveTo(tam.width, 0)
          ..lineTo(tam.width, tam.height)
          ..lineTo(0, 0)
          ..close();
    lienzo.drawPath(camino, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Esquinita anterior) => anterior.color != color;
}

/// La esquinita que marca una celda que salió de un cambio aprobado.
///
/// **Abajo a la izquierda**, opuesta a la [MarcaDeIntervencion] (toda celda de
/// cambio es origen 'M'): en 42 px es el único lugar sin pisarse ni tapar la
/// letra. Hace falta porque el `1` de quien cubre es idéntico al de un sábado
/// por rotación. **`cs.tertiary` y no `secondary`:** con `colorSchemeSeed`
/// secondary sale del mismo tono que primary; `tertiary` rota el tono.
class MarcaDeCambio extends StatelessWidget {
  const MarcaDeCambio({super.key, required this.color, this.lado = 7});

  final Color color;
  final double lado;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: math.pi,
    child: CustomPaint(size: Size(lado, lado), painter: _Esquinita(color)),
  );
}

/// Texto chico y apagado: dato de apoyo de otro más importante.
class Dato extends StatelessWidget {
  const Dato(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
  );
}

/// Las personas en orden alfabético, listas para un [ComboBuscable].
///
/// **El orden llega hecho, aquí no se rehace:** `p_list_trs_Participante`
/// (`@ACCION='L'`) ya viene por apellido (script `17`, colación
/// `Modern_Spanish_CI_AS`: CÁCERES entre BUITRAGO y CALLANCHO, la Ñ tras la N).
/// El `compareTo` de Dart compara code units y mandaría CÁCERES, LECOÑA y SIÑANI
/// tras la Z. Filtrar no cambia el orden.
List<DropdownMenuEntry<int>> entradasDePersonas(
  List<ParticipanteTurnoEntity> personas, {
  bool mostrarGrupo = true,
}) {
  return [
    for (final p in personas)
      DropdownMenuEntry(
        value: p.codEmpleado,
        label:
            mostrarGrupo ? '${p.nombreRol}  (${p.grupoRotacion})' : p.nombreRol,
      ),
  ];
}

/// Cuánto necesita la columna de nombres para que entren completos.
///
/// Se mide y no se estima (los apellidos van de «RAMOS RODRIGO» a «BALDERRAMA
/// CRISTHIAN ALEJANDRO»). Se mide **uno solo**, el más largo en caracteres: es
/// buena aproximación y 85 `TextPainter` por `build` no lo son.
double anchoParaNombres(
  BuildContext context,
  List<ParticipanteTurnoEntity> personas, {
  required double minimo,
  double maximo = 380,
}) {
  if (personas.isEmpty) return minimo;

  final masLargo = personas
      .map((p) => p.nombreRol)
      .reduce((a, b) => b.length > a.length ? b : a);

  final medida = TextPainter(
    text: TextSpan(
      text: masLargo,
      style: Theme.of(context).textTheme.bodySmall,
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  // insignia + separación + nombre + separación + contador «26/26» + padding
  final necesario = 18 + Esp.s + medida.width + Esp.s + 46 + Esp.m * 2;
  return necesario < minimo
      ? minimo
      : (necesario > maximo ? maximo : necesario);
}

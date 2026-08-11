/// Piezas compartidas por las pestañas del Rol de Turnos de Sábado.
library;

import 'dart:math' as math;

import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart'
    as compartido;
import 'package:flutter/material.dart';

/// `dd/MM/yyyy`, o `--` si no hay fecha. Sin `intl` para no arrastrar locale
/// por tres usos.
String fechaCorta(DateTime? f) =>
    f == null
        ? '--'
        : '${f.day.toString().padLeft(2, '0')}/'
            '${f.month.toString().padLeft(2, '0')}/${f.year}';

String fechaHora(DateTime? f) =>
    f == null
        ? '--'
        : '${fechaCorta(f)} ${f.hour.toString().padLeft(2, '0')}:'
            '${f.minute.toString().padLeft(2, '0')}';

/// Convierte el `#RRGGBB` de `trs_EstadoTurno.color`.
/// null si viene vacío o mal formado: mejor un fondo neutro que un crash por un
/// color cargado a mano.
Color? colorDesdeHex(String hex) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Estado vacío o de error, con una explicación de qué significa.
class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 44, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

/// Etiqueta de estado. El color viene del significado, no del texto.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    this.tono = TonoEtiqueta.neutro,
  });

  final String texto;
  final TonoEtiqueta tono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra) = switch (tono) {
      TonoEtiqueta.exito => (cs.primaryContainer, cs.onPrimaryContainer),
      TonoEtiqueta.aviso => (cs.tertiaryContainer, cs.onTertiaryContainer),
      TonoEtiqueta.error => (cs.errorContainer, cs.onErrorContainer),
      TonoEtiqueta.neutro => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: letra,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum TonoEtiqueta { neutro, exito, aviso, error }

// ═══════════════════════════════════════════════════════════════════════════
// EL AVISO
// ═══════════════════════════════════════════════════════════════════════════

/// Muestra el resultado de una acción, ya traducido al idioma de quien usa la
/// app (ver [humanizar]).
///
/// Los mensajes de éxito de los SPs explican el siguiente paso —«corré
/// REGENERAR», «quedó sin sucursal»— y por eso se muestran en lugar de un
/// «Guardado» genérico. Los de error se reescriben, y si son técnicos se
/// reemplazan por un aviso corto y el detalle va a la consola.
///
/// **Lo único que agrega este envoltorio es [humanizar].** El dibujo —la
/// tarjeta arriba de todo, en el Overlay raíz, por encima de los diálogos y de
/// sus velos— lo pone `shared/aviso.dart`, que es de toda la app: el problema
/// que resolvía este archivo resultó no ser de este módulo. Acá queda la
/// traducción, que sí es de acá: está escrita mirando los `RAISERROR` de los
/// `trs_sp_`, y aplicársela a los textos que el resto de la app ya tiene
/// escritos en castellano los reescribiría sin motivo.
///
/// La firma es la de siempre a propósito: cambia cómo se dibuja, no cómo se
/// llama, así que sus diez llamadores no se enteran.
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

// ═══════════════════════════════════════════════════════════════════════════
// MEDIDAS SEGÚN EL DISPOSITIVO
// ═══════════════════════════════════════════════════════════════════════════

/// Cuánto espacio hay, medido en lo que el módulo necesita.
///
/// No se usa `ResponsiveUtilsBosque` directamente en los widgets porque acá el
/// corte no es "es un teléfono": es **cuántas columnas de la matriz entran**.
/// Una tablet en vertical y un teléfono en horizontal necesitan tratos
/// distintos aunque el paquete los clasifique igual.
enum Aire {
  /// Menos de ~7 columnas visibles: la matriz no se puede leer.
  justo,

  /// Entra la matriz, pero apretada.
  medio,

  /// Entra cómoda.
  amplio;

  static Aire de(double ancho) {
    if (ancho < 600) return Aire.justo;
    if (ancho < 1000) return Aire.medio;
    return Aire.amplio;
  }

  bool get esChico => this == Aire.justo;
}

/// Medidas de la matriz. Se calculan del ancho real disponible, no del tamaño
/// de pantalla: dentro del dashboard hay un sidebar que se come su parte.
///
/// [anchoCelda] y [anchoNombre] son los **mínimos**: lo que la matriz necesita
/// para ser legible cuando el ancho está justo. Cuando sobra, [repartir] decide
/// hasta dónde crece cada uno.
class MedidasGrilla {
  final double anchoNombre;
  final double anchoCelda;

  /// Hasta dónde puede engordar una celda cuando sobra ancho.
  ///
  /// **Por qué hay un tope y no se estira hasta llenar.** La celda tiene UNA
  /// letra. Cinco columnas en un panel de 1900 px darían celdas de 300 px con
  /// un `1` perdido en el medio: la letra deja de pertenecer a su fila y a su
  /// columna, que es justo lo que una planilla tiene que dejar claro.
  ///
  /// El número sale de dos lados que coinciden: 64 px es el ancho por defecto
  /// de una columna de Excel —la hoja que este módulo reemplaza— y es también
  /// cerca del doble del alto de fila, la proporción a partir de la cual un
  /// glifo solo empieza a flotar.
  ///
  /// **Es el mismo para los tres tamaños**, y a propósito: los mínimos cambian
  /// con el dispositivo porque cambia cuánto hay que apretar, pero el punto en
  /// que una celda deja de leerse mejor no depende de la pantalla. En un panel
  /// chico el tope simplemente no se alcanza.
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
  /// El sobrante se gasta **en orden de lo que cada pixel compra para leer**:
  ///
  /// 1. la columna de nombres, hasta [idealNombre] —lo que necesita el apellido
  ///    más largo, medido por [anchoParaNombres]—. Cada pixel acá borra unos
  ///    puntos suspensivos, que es la pérdida de información más cara de la
  ///    grilla: dos personas distintas se ven iguales.
  /// 2. las celdas, hasta [anchoCeldaMax]: aire alrededor de la letra y las
  ///    columnas separadas entre sí.
  /// 3. nada más. Lo que quede es margen, y la matriz lo centra.
  ///
  /// **Por qué un tope y no un reparto proporcional.** Con el tope, un mes de
  /// cuatro sábados y uno de cinco dibujan celdas del MISMO ancho en la misma
  /// pantalla. Repartiendo proporcionalmente, febrero se vería más gordo que
  /// marzo y la grilla cambiaría de forma cada vez que se cambia de mes.
  ///
  /// Con «Todo el año» —52 columnas— no sobra nada: `libre` da negativo, los
  /// nombres vuelven al mínimo y las celdas se quedan en [anchoCelda]. Esta
  /// función nunca achica por debajo de los mínimos; cuando falta ancho, la
  /// matriz scrollea.
  ({double nombre, double celda}) repartir({
    required double disponible,
    required int columnas,
    required double idealNombre,
  }) {
    // Los nombres se miden contra las celdas en su ancho MÍNIMO: primero se
    // resuelve si sobra o no, y recién con lo que quedó se engordan las celdas.
    // Al revés, unas celdas anchas se comerían el lugar del apellido.
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

    // A pixel entero: los bordes de media unidad sobre una posición fraccionaria
    // salen borrosos, y son 52 bordes en fila.
    return (nombre: nombre, celda: celda.floorToDouble());
  }

  factory MedidasGrilla.para(double ancho) {
    final aire = Aire.de(ancho);
    return switch (aire) {
      // En "medio" se recortan los nombres antes que las celdas: perder una
      // columna cuesta más que perder unas letras del apellido.
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
      // En "justo" la matriz no se muestra; las medidas quedan por si el
      // usuario fuerza la vista de matriz a mano.
      Aire.justo => const MedidasGrilla(
        anchoNombre: 120,
        anchoCelda: 32,
        altoFila: 30,
        altoCabecera: 46,
      ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS DE LA GRILLA
// ═══════════════════════════════════════════════════════════════════════════

/// `ene`, `feb`, … Sin `intl`: son doce palabras y se usan en tres lugares.
///
/// Estaba duplicado en la matriz y en la agenda. Que el mes se escriba distinto
/// en dos vistas del mismo dato es de las cosas que nadie reporta y todos notan.
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

/// `Enero`, `Febrero`, … Mismo criterio que [mesCorto]: la lista de los doce
/// nombres vive en un solo lugar.
///
/// Estaba encerrada adentro del selector de mes de la grilla, así que el título
/// de cualquier otra vista que quisiera decir «octubre» tenía que copiarla. Con
/// mayúscula inicial porque los dos usos son de rótulo, no de frase corrida.
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
/// **Existe para que las pantallas que muestran este dato lo digan igual.** En
/// la grilla aparece como «25/26» pegado al nombre y en «Grupos» como una línea
/// de texto, pero es el MISMO número: los sábados que le tocan en TODO el rol,
/// que es de un año. Con dos textos sueltos ya se estaba escribiendo de dos
/// formas, y es la clase de diferencia que nadie reporta y todos notan — el
/// mismo motivo por el que [mesCorto] vive acá.
///
/// **«en todo el año» no es relleno.** La grilla arranca filtrada por mes: se
/// ven las cinco columnas de agosto y al lado un 26. Sin esas cuatro palabras el
/// contador parece del mes que está en pantalla, que es exactamente lo que se
/// entendía mal.
///
/// Con meta 0 —alguien sin objetivo cargado— se omite: «de 0» se leería como una
/// meta de cero sábados y no como la ausencia de meta.
String sabadosDelAnio({required int turnos, required int meta}) =>
    meta > 0
        ? '$turnos sábados de $meta en todo el año'
        : '$turnos sábados en todo el año';

/// El círculo con la A o la B.
///
/// El grupo es lo que decide qué sábados le tocan a alguien, así que aparece en
/// la matriz, en la agenda y en la pantalla de grupos. Una sola definición para
/// que el mismo color signifique lo mismo en las tres.
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
/// **null es un dato**, no un faltante: en este modelo el libre es la ausencia
/// de la fila, así que el cuadrito sin pintar significa «ese día no le tocaba».
Color? fondoDeCelda(BuildContext context, CeldaTurnoEntity? celda) =>
    colorDeCelda(Theme.of(context).colorScheme, celda)?.fondo;

/// La letra de la celda. Sólo la letra.
///
/// La marca de intervención NO va acá: ver [MarcaDeIntervencion].
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
      // El color sale del mismo lugar que el fondo, no del tema: el fondo lleva
      // un tono aplicado y el par tiene que decidirse junto.
      style: (estiloTexto ?? context.numero(fuerte: true))?.copyWith(
        color: color.texto,
      ),
    );
  }
}

/// La esquinita que marca una celda escrita por una persona.
///
/// Significa que esa celda tiene origen 'M' o 'P' y que una **regeneración no
/// la va a pisar**. Aparece igual en la matriz y en la agenda: si la señal
/// cambiara de forma entre las dos vistas habría que aprenderla dos veces.
///
/// **Antes era un punto puesto con `Positioned` dentro de un `Stack` que
/// envolvía a la letra.** Ese Stack se encogía al tamaño del carácter —unos
/// 10×14 px— así que el punto caía ENCIMA de la letra y una `C` se leía `€`.
/// Un triángulo en la esquina del cuadro no puede solaparse con nada: ocupa un
/// lugar donde no hay glifo.
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
/// **Va abajo a la izquierda porque arriba a la derecha ya está ocupado.** Una
/// celda de cambio la escribió `trs_sp_corregirCelda`, así que su origen es 'M'
/// y siempre lleva además la [MarcaDeIntervencion]. Las dos señales conviven en
/// la misma celda de 42 px, y las esquinas opuestas son el único lugar donde
/// está garantizado que no se pisen entre ellas ni pisen la letra.
///
/// **Por qué hace falta si la `C` ya se ve.** La `C` cuenta sólo la mitad de la
/// historia: el que falta. La otra mitad es el `1` de quien vino a cubrirlo, y
/// ese `1` es idéntico al de un sábado que le tocaba por rotación. Sin esta
/// marca no hay manera de ver en la grilla que esa persona vino de más.
///
/// Es el mismo triángulo rotado media vuelta y no un ícono nuevo: a 7 px un
/// ícono se lee como una mancha, y dos formas distintas serían dos cosas que
/// aprender en vez de una.
///
/// **Va en `cs.tertiary` y no en `cs.secondary`.** El tema se arma con
/// `colorSchemeSeed`, así que primary y secondary salen del mismo tono con
/// distinta saturación: las dos esquinitas quedarían del mismo color y sólo se
/// distinguirían por la esquina. `tertiary` rota el tono y se lee distinto.
/// No choca con la familia `tertiaryContainer` de los estados V/P/A porque una
/// celda de cambio es siempre `C` o `1`, nunca una de esas.
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

/// Texto chico y apagado: un dato de apoyo que acompaña a otro más importante.
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

/// Un combo con buscador, para listas de gente.
///
/// **Por qué no un `DropdownButtonFormField`.** Con 85 personas, el desplegable
/// común obliga a recorrer una lista larguísima en el orden en que vinieron de
/// la base —que es el del organigrama, no uno que ayude a buscar— y sin forma de
/// escribir. Encontrar a alguien es scroll y suerte.
///
/// Acá las opciones vienen **ordenadas alfabéticamente** y se filtran a medida
/// que se escribe.
class ComboBuscable<T> extends StatelessWidget {
  const ComboBuscable({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onElegir,
    this.ayuda,
    this.pista,
  });

  final String etiqueta;
  final T? valor;

  /// Ya ordenadas por quien las arma: el orden depende de qué son.
  final List<DropdownMenuEntry<T>> opciones;

  final ValueChanged<T?> onElegir;
  final String? ayuda;
  final String? pista;

  @override
  Widget build(BuildContext context) => DropdownMenu<T>(
    // La clave incluye el valor para que el campo de texto se limpie solo
    // cuando el valor lo resetea alguien de afuera — al cambiar de sábado, por
    // ejemplo, donde las dos listas de personas dejan de servir.
    key: ValueKey('$etiqueta-$valor-${opciones.length}'),
    initialSelection: valor,
    label: Text(etiqueta),
    helperText: ayuda,
    hintText: pista ?? 'Escribe para buscar…',
    enableFilter: true,
    requestFocusOnTap: true,
    expandedInsets: EdgeInsets.zero,
    menuHeight: 320,
    leadingIcon: const Icon(Icons.search, size: 18),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    dropdownMenuEntries: opciones,
    onSelected: opciones.isEmpty ? null : onElegir,
  );
}

/// Las personas en orden alfabético, listas para un [ComboBuscable].
///
/// El orden de la base es el del organigrama —sucursal, nivel, cargo— que sirve
/// para repartir los grupos pero no para encontrar a alguien por el apellido.
List<DropdownMenuEntry<int>> entradasDePersonas(
  List<ParticipanteTurnoEntity> personas, {
  bool mostrarGrupo = true,
}) {
  final ordenadas = [...personas]..sort(
    (a, b) => a.nombreRol.toLowerCase().compareTo(b.nombreRol.toLowerCase()),
  );
  return [
    for (final p in ordenadas)
      DropdownMenuEntry(
        value: p.codEmpleado,
        label:
            mostrarGrupo ? '${p.nombreRol}  (${p.grupoRotacion})' : p.nombreRol,
      ),
  ];
}

/// Cuánto necesita la columna de nombres para que entren completos.
///
/// **Por qué se mide y no se estima.** Los apellidos de un rol real van de
/// «RAMOS RODRIGO» a «BALDERRAMA CRISTHIAN ALEJANDRO»: cualquier ancho fijo
/// corta a la mitad de la gente o desperdicia espacio con la otra mitad. Se mide
/// el más largo con la tipografía de verdad y se pide exactamente eso.
///
/// Se mide **uno solo** —el más largo en caracteres— y no los ochenta y cinco.
/// Con la misma fuente esa es una aproximación buena, y ochenta y cinco
/// `TextPainter` por cada `build` no lo son.
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

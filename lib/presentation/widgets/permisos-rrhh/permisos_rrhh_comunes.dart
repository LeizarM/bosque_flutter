/// Piezas compartidas por las pestañas de la consola de Permisos de RR.HH.
///
/// **El patrón visual de este módulo es el del Rol de Sábados**, no el de
/// `permisos-vacaciones`. Los dos módulos hablan de lo mismo, así que la
/// tentación de copiar el segundo es fuerte y sería un error: allá hay
/// `Colors.purple`, `Colors.grey[50]`, `Montserrat` escrito a mano y gradientes,
/// y esta app se arma con `colorSchemeSeed` sobre nueve semillas más modo
/// oscuro. Un hex fijo se ve de otra app con ocho de las nueve. De
/// `permisos-vacaciones` se copia sólo la forma del repositorio y el consumo de
/// los campos `*Txt`; el color y el espaciado salen de `core/ui/`.
library;

import 'package:bosque_flutter/core/ui/aviso.dart' as compartido;
import 'package:bosque_flutter/core/ui/piezas_bosque.dart' show fechaCorta;
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';

// Las piezas comunes viven en `core/ui/` y se re-exportan para que un widget del
// módulo tenga todo con un solo import.
export 'package:bosque_flutter/core/ui/aviso.dart';
export 'package:bosque_flutter/core/ui/piezas_bosque.dart';
export 'package:bosque_flutter/core/ui/tokens_bosque.dart'
    show
        Aire,
        ColorDeEstado,
        Esp,
        EstiloModulo,
        Peso,
        cifrasTabulares,
        colorDeTipoPermiso;

// Las dos constantes del ACL (`btnConsultaSaldo` y `btnCalculadora`) viven en
// `core/state/permisos_rrhh_provider.dart`: en el Rol de Sábados la decisión de
// permiso está toda en el provider del módulo (`administraRolProvider`,
// `permisoDeCeldaProvider`) y nada de autorización vive en el archivo de piezas.

// ═══════════════════════════════════════════════════════════════════════════
// AVISOS
// ═══════════════════════════════════════════════════════════════════════════

/// Cuenta un error, ya traducido al idioma de quien usa la app.
///
/// **Nunca `ScaffoldMessenger`**: el SnackBar lo dibuja el `Scaffold` de la ruta,
/// y un diálogo o una hoja modal son otra ruta montada encima. El aviso quedaría
/// abajo, detrás del velo — que es lo que le pasa hoy a `permisos-vacaciones`.
/// [compartido.avisar] se inserta en el Overlay **raíz**.
void avisarError(BuildContext context, Object error) => compartido.avisar(
  context,
  compartido.textoParaUsuario(error),
  esError: true,
);

// ═══════════════════════════════════════════════════════════════════════════
// LA BARRERA ANTES DE ESCRIBIR
// ═══════════════════════════════════════════════════════════════════════════

/// Pregunta antes de escribir, y **dice exactamente qué va a pasar**.
///
/// Es la misma barrera que `puente_sheet.dart`: la hoja ya muestra el dato,
/// pero apretar el botón mueve plata —una vacación asignada vale 15 a 30 días
/// pagados, un abono son días libres cobrados— y eso no se deshace desde
/// ninguna pantalla. El segundo paso es deliberado.
///
/// [mensaje] tiene que nombrar la cantidad, a quién y con qué fecha. «¿Estás
/// seguro?» no es una confirmación: no deja verificar nada.
///
/// [destructiva] pinta el botón con el rol de error del tema, nunca con un rojo
/// a mano.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String accion,
  bool destructiva = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) {
      final cs = Theme.of(c).colorScheme;
      return AlertDialog(
        title: Text(titulo),
        // Scroll adentro del diálogo: el mensaje de una carga colectiva lista
        // la cantidad, la fecha y a cuánta gente, y en 360 px de alto con el
        // teclado abierto no entra.
        content: SingleChildScrollView(child: Text(mensaje)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                destructiva
                    ? FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    )
                    : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(accion),
          ),
        ],
      );
    },
  );
  // Cerrar tocando afuera devuelve null, y null NO es que sí.
  return ok ?? false;
}

/// Un número de días como lo escribe el backend: coma decimal, sin ceros de
/// relleno.
///
/// **Sólo para números que todavía no existen del otro lado** —los que alguien
/// acaba de tipear y hay que repetirle en la confirmación—. Lo que ya vino del
/// servidor se muestra con su campo `*Txt` y no se reformatea, así que la app y
/// el reporte dicen lo mismo.
String numeroDeDias(double v) =>
    (v == v.roundToDouble() ? v.round().toString() : v.toString()).replaceAll(
      '.',
      ',',
    );

/// `HH:mm`, o `--` si no hay fecha. Sin `intl`, igual que [fechaCorta].
///
/// **La hora no es decorativa en este módulo**: `f_CalcularDiasHabilesPermiso`
/// conmuta a horario continuo cuando el fin pasa las 17:30 —el día pasa a
/// contar 600 minutos en vez de 480—, así que mostrar la fecha sin la hora
/// escondería justo el dato que decide el número.
String horaCorta(DateTime? f) =>
    f == null
        ? '--'
        : '${f.hour.toString().padLeft(2, '0')}:'
            '${f.minute.toString().padLeft(2, '0')}';

// ═══════════════════════════════════════════════════════════════════════════
// LA LÍNEA DE TIEMPO
// ═══════════════════════════════════════════════════════════════════════════
//
// Las cuatro funciones de abajo son lo que hace que una lista de permisos se lea
// como una historia y no como una planilla. Nacieron privadas dentro de
// `nomina_permisos_tab.dart`; viven acá desde que la pestaña «Permisos» de la
// ficha del trabajador pinta la misma línea de tiempo con otra entidad
// (`SolicitudPermisoEntity`, que además tiene estado). No toman entidades sino
// `DateTime?` sueltos, justamente para no atarse a ninguna de las dos.

const List<String> mesesCortos = [
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

/// Los meses escritos, para un encabezado que se lee en vez de escanearse.
///
/// Vive acá y no en cada pantalla porque ya había dos copias: el filtro de la
/// nómina individual y el título del cronograma de boletas. Dos listas de doce
/// literales cada una es dos lugares donde arreglar el mismo error de tipeo.
const List<String> mesesLargos = [
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

bool mismoDia(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

String diaMes(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')} ${mesesCortos[f.month - 1]}';

/// `31 mar` o `03 ago → 10 ago`. El año no se repite: lo dice el tramo.
String cuandoCompacto(DateTime? desde, DateTime? hasta) {
  if (desde == null) return 'Sin fecha';
  final d = diaMes(desde);
  // **`hasta` nulo se trata como el mismo día, no como un tramo.** Antes
  // `mismoDia(desde, null)` daba false y se caía en `diaMes(hasta!)`: un
  // «Null check operator used on a null value» que rompía la fila entera con
  // el recuadro rojo de error. `trh_permiso.hasta` admite null.
  if (hasta == null || mismoDia(desde, hasta)) return d;
  return '$d → ${diaMes(hasta)}';
}

/// Una sola expresión de fecha, con el año. El permiso de un día muestra la
/// fecha una vez —no dos, como hacía la tabla vieja— y el de varios muestra el
/// tramo, que es justo lo que distingue una vacación larga de un permiso de
/// tarde.
String cuandoLargo(DateTime? desde, DateTime? hasta) {
  if (desde == null) return 'Sin fecha';
  // Mismo motivo que en [cuandoCompacto]: las dos se arreglan igual, no una
  // sí y la otra no.
  if (hasta == null || mismoDia(desde, hasta)) return fechaCorta(desde);
  return '${fechaCorta(desde)} → ${fechaCorta(hasta)}';
}

/// Corta la lista en tramos por año, **respetando el orden en que viene**. No
/// reordena nada: sólo marca dónde cambia el año. Quien la llama es el que
/// decide el orden, y si la lista no viene ordenada por fecha el mismo año
/// aparecerá en varios tramos — que es la señal correcta de que algo no se
/// ordenó, no un error a tapar acá.
List<(String anio, List<T> filas)> agruparPorAnio<T>(
  List<T> lista,
  DateTime? Function(T) fechaDe,
) {
  final grupos = <(String, List<T>)>[];
  for (final e in lista) {
    final f = fechaDe(e);
    final anio = f == null ? 'Sin fecha' : '${f.year}';
    if (grupos.isEmpty || grupos.last.$1 != anio) {
      grupos.add((anio, [e]));
    } else {
      grupos.last.$2.add(e);
    }
  }
  return grupos;
}

/// Los motivos vienen del sistema anterior en mayúsculas —«PERSONAL», «PUENTE
/// SEMANA SANTA»—, que en pantalla grita. Se baja a oración sólo cuando el texto
/// **no** tiene ninguna minúscula: si alguien ya lo escribió bien, se respeta tal
/// cual, y el dato guardado nunca se toca.
String enOracion(String texto) {
  final t = texto.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  final minusculas = t.toLowerCase();
  return minusculas[0].toUpperCase() + minusculas.substring(1);
}

/// Lee los días que alguien tipeó, con coma o con punto.
///
/// `null` cuando no es un número: el teclado numérico de Android manda coma y
/// el de escritorio punto, y `double.tryParse('1,5')` es `null`. Sin esto,
/// «1,5 días» se leía como campo vacío.
double? diasDeTexto(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS DEL MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

/// Un campo de sólo lectura que abre un selector: una fecha, una hora.
///
/// `InputDecorator` y no un `TextField` con `readOnly`: se ve exactamente igual
/// —mismo borde, mismo rótulo flotante— y no hace falta un
/// `TextEditingController` por campo sólo para mostrar un texto que ya está en
/// el estado.
///
/// [texto] en `null` muestra [pista] en gris: todavía no se eligió nada.
class CampoElegido extends StatelessWidget {
  const CampoElegido({
    super.key,
    required this.etiqueta,
    required this.texto,
    required this.onTap,
    this.pista = 'Elegir fecha',
    this.icono = Icons.event_outlined,
    this.ayuda,
  });

  final String etiqueta;
  final String? texto;

  /// `null` deshabilita el campo: es la fecha de un abono que ya existe, que el
  /// modal legacy también deja `disabled`.
  final VoidCallback? onTap;

  final String pista;
  final IconData icono;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          isDense: true,
          enabled: onTap != null,
          suffixIcon: Icon(icono, size: 20),
        ),
        child: Text(
          texto ?? pista,
          style:
              texto == null
                  ? tema.textTheme.bodyMedium?.copyWith(color: tema.hintColor)
                  : tema.textTheme.bodyMedium?.copyWith(
                    fontFeatures: cifrasTabulares,
                    color: onTap == null ? tema.hintColor : null,
                  ),
        ),
      ),
    );
  }
}

/// Una advertencia que forma parte del dato, no de la acción.
///
/// **Por qué no es un [compartido.avisar].** Aquellos cuentan cómo salió algo
/// que alguien hizo y se van solos a los pocos segundos. Esto describe **al
/// dato que está en pantalla** —de qué relación laboral es el saldo, por qué no
/// hay desglose, que falta la fecha de beneficio— y tiene que seguir ahí
/// mientras el dato lo esté. Un aviso que se desvanece dejaría la cifra sin su
/// asterisco.
///
/// Va en la familia **terciaria** y no en un naranja escrito a mano: Material 3
/// no define un rol `warning`, y el terciario es el único que se separa de
/// `primary` y de `error` con las nueve semillas.
class AvisoDelDato extends StatelessWidget {
  const AvisoDelDato({
    super.key,
    required this.texto,
    this.icono = Icons.info_outline,
  });

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Esp.m,
        vertical: Esp.s + 2,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onTertiaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un número de días con su rótulo: la unidad de lectura de todo el módulo.
///
/// El número llega **ya formateado por el backend** (`diasNoUsadosTxt`, coma
/// decimal, sufijo « día»/« días»). No se reformatea acá: así la app y el
/// reporte impreso dicen exactamente lo mismo, que es contra lo que RR.HH.
/// compara.
///
/// El valor numérico se usa sólo para decidir el color: un saldo negativo va en
/// `colorScheme.error`, nunca en un rojo a mano.
class Metrica extends StatelessWidget {
  const Metrica({
    super.key,
    required this.rotulo,
    required this.texto,
    this.valor,
    this.destacada = false,
  });

  final String rotulo;
  final String texto;

  /// El mismo número, para pintar en rojo cuando es negativo. Null si el dato
  /// no admite signo.
  final double? valor;

  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final negativo = (valor ?? 0) < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: context.apagado()),
        const SizedBox(height: 2),
        Text(
          texto,
          style: (destacada
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
                fontWeight: Peso.dato,
                // Sin esto, `12,5` y `11` ocupan distinto y la fila de tres
                // métricas queda con los dígitos bailando entre empleados.
                fontFeatures: cifrasTabulares,
                color: negativo ? cs.error : null,
              ),
        ),
      ],
    );
  }
}

/// El marco de una sección: título, explicación de qué se está mirando y
/// contenido. Es el `_Bloque` del Rol de Sábados, que ya resuelve lo mismo.
class Bloque extends StatelessWidget {
  const Bloque({
    super.key,
    required this.titulo,
    required this.hijo,
    this.explicacion,
    this.icono,
  });

  final String titulo;
  final String? explicacion;
  final Widget hijo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icono != null) ...[
                Icon(icono, size: 18, color: Theme.of(context).hintColor),
                const SizedBox(width: Esp.s),
              ],
              Expanded(child: Text(titulo, style: context.tituloSeccion())),
            ],
          ),
          if (explicacion != null) ...[
            const SizedBox(height: 2),
            Text(explicacion!, style: context.apagado()),
          ],
          const SizedBox(height: Esp.m),
          hijo,
        ],
      ),
    ),
  );
}

/// Lo que se muestra mientras el dato viaja.
class Cargando extends StatelessWidget {
  const Cargando({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: Esp.xl),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// El error, dicho donde estaría el dato.
///
/// **Va en la pantalla y no sólo en un aviso pasajero**: si el saldo no se pudo
/// traer, el lugar del saldo no puede quedar vacío o se lee como «no tiene
/// días». El texto pasa por `humanizar`, que traduce el `DioException` crudo.
class ErrorDelDato extends StatelessWidget {
  const ErrorDelDato({super.key, required this.error, this.onReintentar});

  final Object error;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Esp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.error),
            const SizedBox(height: Esp.m),
            Text(
              compartido.textoParaUsuario(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: Esp.m),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

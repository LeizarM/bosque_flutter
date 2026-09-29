/// Las filas que dibuja la pantalla de porcentajes (tpr_porcentaje), ya
/// traducidas desde los mapas que devuelve el backend.
///
/// **Por que hay una clase y no se usan los mapas directamente.** Las tres
/// lecturas de porcentajes de `PreciosRepository` devuelven
/// `Map<String, dynamic>` y no la entity, porque lo que se muestra es el cruce
/// de tpr_porcentaje con tb_sucursal y tpr_clasificacionPrecio -nombre de la
/// sucursal, nombre de la lista, vpp- y nada de eso es columna de la tabla.
/// Ademas el margen llega en la clave `porcentaje` y en la tabla se llama
/// `porcen`. Este archivo es el UNICO lugar de la pantalla donde se tocan esas
/// claves: la tabla, las tarjetas y el guardado hablan con campos tipados.
///
/// El camino de vuelta tambien vive aca ([FilaPorcentaje.aMapa]), porque
/// `PorcentajesNotifier.guardarGrilla` y `validarPorcentajesAscendentes`
/// esperan exactamente esas mismas claves: si una se escribe mal, la validacion
/// se queda sin sucursal o sin vpp y deja de validar en silencio, que es
/// justamente el defecto que esta pantalla vino a no repetir.
library;

import 'package:flutter/foundation.dart';

/// Una lista de precios de una sucursal, con el margen que la familia tiene
/// -o tendria- en ella.
@immutable
class FilaPorcentaje {
  const FilaPorcentaje({
    required this.idPorcen,
    required this.idClasificacion,
    required this.codSucursal,
    required this.sucursal,
    required this.nombrePrecio,
    required this.vpp,
    required this.porcen,
  });

  /// PK de la fila de tpr_porcentaje. **Cero significa que la fila todavia no
  /// existe** y el guardado tiene que ser un alta: el listado devuelve cero
  /// -o null, por el LEFT JOIN- en las listas de precios que la familia aun no
  /// tiene cargadas. No es un error.
  final BigInt idPorcen;

  final BigInt idClasificacion;

  /// El codigo de sucursal es INT en tb_sucursal; se conserva asi porque la
  /// validacion ascendente agrupa por el.
  final int codSucursal;

  /// Nombre de la sucursal. Llega en la clave `nombre`, no en `sucursal`.
  final String sucursal;

  final String nombrePrecio;

  /// Numero de lista de precios. Es el orden dentro de la sucursal y, por lo
  /// tanto, el eje de la regla de porcentajes ascendentes.
  final int vpp;

  /// Margen sobre el costo en PUNTOS PORCENTUALES: 12.5 es 12,5 %.
  final double porcen;

  factory FilaPorcentaje.deMapa(Map<String, dynamic> fila) => FilaPorcentaje(
    idPorcen: granEntero(fila['idPorcen']),
    idClasificacion: granEntero(fila['idClasificacion']),
    codSucursal: entero(fila['codSucursal']),
    sucursal: texto(fila['nombre']),
    nombrePrecio: texto(fila['nombrePrecio']),
    vpp: entero(fila['vpp']),
    porcen: decimal(fila['porcentaje']),
  );

  /// La fila no existe en la tabla: guardar es insertar.
  bool get esAlta => idPorcen == BigInt.zero;

  /// Margen negativo: el precio quedaria por debajo del costo. Casi siempre es
  /// un error de carga, asi que la pantalla lo resalta en vez de aceptarlo sin
  /// decir nada.
  bool get esNegativo => porcen < 0;

  /// Como se nombra la lista en una linea: la sucursal manda, porque la regla
  /// ascendente se lee dentro de cada sucursal.
  String get destino => '$sucursal · $nombrePrecio';

  /// Como se rotula la lista en la grilla. En la base casi todas se llaman
  /// "Precio" a secas y lo que las distingue es el numero: "Precio 3". Si el
  /// nombre ya trae un numero se deja como esta.
  String get etiquetaLista {
    final nombre = nombrePrecio.trim();
    if (nombre.isEmpty) return 'Lista $vpp';
    return RegExp(r'\d').hasMatch(nombre) ? nombre : '$nombre $vpp';
  }

  /// Con que se reconoce esta fila dentro de la lista de choques que devuelve
  /// `validarPorcentajesAscendentes`.
  ///
  /// Esa funcion informa el choque con el codigo de sucursal y el nombre de la
  /// lista -no con el idClasificacion, que es lo que la pantalla usa de clave-,
  /// asi que para pintar de rojo la fila culpable hay que volver a armar la
  /// misma pareja. El nombre de la lista se repite entre sucursales, pero junto
  /// con el codigo de sucursal identifica una sola fila de la grilla.
  String get claveConflicto => claveDeConflicto(codSucursal, nombrePrecio);

  /// La misma clave, armada desde los datos de un [ConflictoPorcentaje].
  static String claveDeConflicto(int codSucursal, String nombrePrecio) =>
      '$codSucursal|$nombrePrecio';

  /// El mapa que esperan `validarPorcentajesAscendentes` y
  /// `porcentajeDesdeFila`, con [porcentaje] en lugar del valor original.
  ///
  /// [idPorcenForzado] existe para la edicion masiva por grupo: ahi la grilla
  /// de destinos NO trae idPorcen -el backend la devuelve sin esa columna- y
  /// cada familia tiene el suyo, que la pantalla resuelve contra la tabla
  /// cruda. Sin esto, todas las escrituras del grupo serian altas y se
  /// duplicarian las filas que ya existen.
  Map<String, dynamic> aMapa(double porcentaje, {BigInt? idPorcenForzado}) => {
    'idPorcen': (idPorcenForzado ?? idPorcen).toInt(),
    'idClasificacion': idClasificacion.toInt(),
    'codSucursal': codSucursal,
    'nombre': sucursal,
    'nombrePrecio': nombrePrecio,
    'vpp': vpp,
    'porcentaje': porcentaje,
  };

  /// Orden de la grilla: primero la sucursal y dentro de ella por numero de
  /// lista.
  ///
  /// **No es el orden del backend.** La rama de una familia ordena solo por
  /// vpp y la de la edicion masiva no ordena nada. Se reordena aca a proposito:
  /// la regla que la pantalla valida -que el margen no baje al subir el vpp
  /// dentro de una misma sucursal- solo se puede leer si las listas de cada
  /// sucursal estan juntas y en orden.
  static int comparar(FilaPorcentaje a, FilaPorcentaje b) {
    if (a.codSucursal != b.codSucursal) {
      return a.codSucursal.compareTo(b.codSucursal);
    }
    return a.vpp.compareTo(b.vpp);
  }
}

/// Una familia alcanzada por la edicion masiva de un grupo de familia SAP, con
/// lo que hoy tiene cargado.
///
/// `obtenerFamiliasPorGrupo` devuelve tres claves -codigoFamilia,
/// proveedorExtSap y grpFam-, asi que el resto de lo que el dialogo viejo
/// mostraba (presentacion, tipo, color, costo) no esta disponible en este
/// contrato y no se inventa. Lo que si se puede decir, y es lo que importa
/// antes de pisar 7.836 filas, es cuantas listas de precios tiene ya cargadas
/// la familia y entre que valores se mueven: eso sale de la tabla cruda.
@immutable
class FamiliaGrupoVista {
  FamiliaGrupoVista({
    required this.codigoFamilia,
    required this.proveedor,
    required this.grupo,
    required List<double> porcentajesActuales,
  }) : porcentajesActuales = List<double>.unmodifiable(
         List<double>.of(porcentajesActuales)..sort(),
       );

  final int codigoFamilia;
  final String proveedor;
  final String grupo;

  /// Los margenes que la familia tiene hoy, ordenados. Vacio cuando todavia no
  /// tiene ninguno.
  final List<double> porcentajesActuales;

  int get listasConPorcentaje => porcentajesActuales.length;

  bool get sinPorcentajes => porcentajesActuales.isEmpty;

  /// El margen actual en una linea. Un solo valor cuando todas las listas
  /// coinciden; el rango cuando no, que es lo normal.
  String get resumenActual {
    if (sinPorcentajes) return 'Sin porcentaje cargado';
    final minimo = porcentajesActuales.first;
    final maximo = porcentajesActuales.last;
    if ((maximo - minimo).abs() < 0.005) {
      return '${porcenTexto(minimo)} en $listasConPorcentaje lista'
          '${listasConPorcentaje == 1 ? '' : 's'}';
    }
    return '${porcenTexto(minimo)} a ${porcenTexto(maximo)} '
        'en $listasConPorcentaje listas';
  }

  /// Codigo con tres cifras, como se lo nombra en el sistema anterior.
  String get codigoLegible => codigoFamilia.toString().padLeft(3, '0');

  /// Texto sobre el que busca el filtro de la lista.
  String get textoBuscable =>
      '$codigoFamilia $codigoLegible $proveedor $grupo'.toLowerCase();

  /// Un guion en lugar de una celda en blanco: hay familias sin proveedor
  /// asignado y una celda vacia se lee como un error de carga.
  static String oGuion(String valor) =>
      valor.trim().isEmpty ? '—' : valor.trim();
}

// ═══════════════════════════════════════════════════════════════════════════
// Numeros en pantalla
// ═══════════════════════════════════════════════════════════════════════════

/// El margen listo para mostrar, siempre con dos decimales y coma decimal,
/// como el resto de los importes del modulo.
///
/// El double nunca se muestra crudo: `porcen` viaja en double porque Dart no
/// tiene BigDecimal, y crudo arrastra la basura binaria de la representacion
/// (un 12,5 puede imprimirse como 12.499999999999998).
String porcenTexto(double valor) => '${porcenEditable(valor)} %';

/// El mismo numero pero sin el simbolo, que es lo que se edita en el campo.
/// [porcenDesdeTexto] lo vuelve a leer: acepta la coma.
String porcenEditable(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');

/// Lo que el usuario escribio, convertido a puntos porcentuales.
///
/// Acepta la coma decimal ademas del punto: en Bolivia se escribe 12,5 y un
/// campo que solo entienda 12.5 obliga a cambiar de habito para cargar un
/// numero. Devuelve null cuando el texto no es un numero, y eso es distinto de
/// cero: cero es un margen valido -es el que traen las listas sin cargar- y
/// tomarlo por "vacio" borraria datos sin querer.
double? porcenDesdeTexto(String texto) {
  final limpio = texto.trim().replaceAll('%', '').replaceAll(',', '.').trim();
  if (limpio.isEmpty) return null;
  final v = double.tryParse(limpio);
  // double.tryParse acepta "NaN", "Infinity" y "1e999": ninguno es un margen,
  // y un NaN pasa todas las comparaciones y rompe el JSON al guardar.
  return v != null && v.isFinite ? v : null;
}

/// Dos margenes son el mismo valor si difieren en menos de medio centesimo.
///
/// Comparar dos double con == es una trampa conocida: el valor que vuelve del
/// backend y el que se arma parseando el texto del campo pueden diferir en el
/// ultimo bit y la pantalla creeria que hay un cambio donde no lo hay -y
/// escribiria la fila igual-. La pantalla muestra dos decimales, asi que dos
/// valores que se ven iguales tienen que contar como iguales.
bool mismoPorcentaje(double a, double b) => (a - b).abs() < 0.005;

// ── Lectura defensiva del mapa ─────────────────────────────────────────────
//
// El backend responde JSON: un bigint puede llegar como numero o como cadena
// segun por donde pase, y las columnas que salen de un LEFT JOIN llegan en
// null. Se lee todo con un valor por defecto en vez de confiar en el tipo.

int entero(Object? valor) => switch (valor) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v.trim()) ?? 0,
  _ => 0,
};

BigInt granEntero(Object? valor) => switch (valor) {
  BigInt v => v,
  int v => BigInt.from(v),
  num v => BigInt.from(v.toInt()),
  String v => BigInt.tryParse(v.trim()) ?? BigInt.zero,
  _ => BigInt.zero,
};

double decimal(Object? valor) => switch (valor) {
  double v => v,
  num v => v.toDouble(),
  String v => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0,
  _ => 0,
};

String texto(Object? valor) => valor?.toString().trim() ?? '';

/// Las filas de la pantalla de porcentajes (tpr_porcentaje), traducidas desde los
/// mapas del backend (cruzan tb_sucursal y tpr_clasificacionPrecio; el margen
/// llega como `porcentaje` y en la tabla es `porcen`). Este archivo es el ÚNICO
/// lugar que toca esas claves. [FilaPorcentaje.aMapa] hace el camino de vuelta:
/// `guardarGrilla` y `validarPorcentajesAscendentes` esperan las mismas claves y,
/// si una falla, la validación deja de validar en silencio.
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

  /// PK de tpr_porcentaje. **Cero significa que la fila aún no existe** y el
  /// guardado debe ser un alta: el listado devuelve cero (o null, por el LEFT
  /// JOIN) en las listas que la familia todavía no tiene cargadas.
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

  /// Margen negativo: el precio quedaría por debajo del costo. Casi siempre es un
  /// error de carga, así que la pantalla lo resalta.
  bool get esNegativo => porcen < 0;

  /// Como se nombra la lista en una linea: la sucursal manda, porque la regla
  /// ascendente se lee dentro de cada sucursal.
  String get destino => '$sucursal · $nombrePrecio';

  /// Cómo se rotula la lista en la grilla: en la base casi todas se llaman "Precio"
  /// y las distingue el número ("Precio 3"). Si el nombre ya trae un número, se deja.
  String get etiquetaLista {
    final nombre = nombrePrecio.trim();
    if (nombre.isEmpty) return 'Lista $vpp';
    return RegExp(r'\d').hasMatch(nombre) ? nombre : '$nombre $vpp';
  }

  /// Con qué se reconoce esta fila en los choques de
  /// `validarPorcentajesAscendentes`: esa función informa código de sucursal y
  /// nombre de lista (no idClasificacion), así que se rearma la misma pareja. El
  /// nombre se repite entre sucursales, pero con el código identifica una fila.
  String get claveConflicto => claveDeConflicto(codSucursal, nombrePrecio);

  /// La misma clave, armada desde los datos de un [ConflictoPorcentaje].
  static String claveDeConflicto(int codSucursal, String nombrePrecio) =>
      '$codSucursal|$nombrePrecio';

  /// El mapa que esperan `validarPorcentajesAscendentes` y `porcentajeDesdeFila`,
  /// con [porcentaje] en lugar del valor original. [idPorcenForzado] es para la
  /// edición masiva: la grilla de destinos no trae idPorcen y sin él todas las
  /// escrituras serían altas y duplicarían filas.
  Map<String, dynamic> aMapa(double porcentaje, {BigInt? idPorcenForzado}) => {
    'idPorcen': (idPorcenForzado ?? idPorcen).toInt(),
    'idClasificacion': idClasificacion.toInt(),
    'codSucursal': codSucursal,
    'nombre': sucursal,
    'nombrePrecio': nombrePrecio,
    'vpp': vpp,
    'porcentaje': porcentaje,
  };

  /// Orden de la grilla: sucursal y, dentro, número de lista. NO es el orden del
  /// backend (una familia ordena solo por vpp; la edición masiva no ordena): la
  /// regla de márgenes ascendentes por sucursal solo se lee con las listas de
  /// cada sucursal juntas y en orden.
  static int comparar(FilaPorcentaje a, FilaPorcentaje b) {
    if (a.codSucursal != b.codSucursal) {
      return a.codSucursal.compareTo(b.codSucursal);
    }
    return a.vpp.compareTo(b.vpp);
  }
}

/// Una familia alcanzada por la edición masiva de un grupo SAP, con lo que hoy
/// tiene cargado. `obtenerFamiliasPorGrupo` solo devuelve codigoFamilia,
/// proveedorExtSap y grpFam: cuántas listas tiene y entre qué valores se mueven
/// sale de la tabla cruda.
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

// Números en pantalla

/// El margen listo para mostrar, siempre con dos decimales y coma decimal,
/// como el resto de los importes del módulo. Nunca se muestra el double crudo:
/// arrastra basura binaria (12,5 puede imprimirse como 12.499999999999998).
String porcenTexto(double valor) => '${porcenEditable(valor)} %';

/// El mismo numero pero sin el simbolo, que es lo que se edita en el campo.
/// [porcenDesdeTexto] lo vuelve a leer: acepta la coma.
String porcenEditable(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');

/// Lo que el usuario escribió, en puntos porcentuales. Acepta coma decimal (en
/// Bolivia se escribe 12,5) además del punto. Devuelve null si no es un número,
/// que es distinto de cero: cero es un margen válido (el de las listas sin
/// cargar) y tomarlo por "vacío" borraría datos.
double? porcenDesdeTexto(String texto) {
  final limpio = texto.trim().replaceAll('%', '').replaceAll(',', '.').trim();
  if (limpio.isEmpty) return null;
  final v = double.tryParse(limpio);
  // double.tryParse acepta "NaN", "Infinity" y "1e999": ninguno es un margen,
  // y un NaN pasa todas las comparaciones y rompe el JSON al guardar.
  return v != null && v.isFinite ? v : null;
}

/// Dos márgenes son el mismo valor si difieren en menos de medio centésimo.
/// Comparar double con == falla: el valor del backend y el parseado del campo
/// pueden diferir en el último bit y la pantalla vería un cambio donde no lo hay.
bool mismoPorcentaje(double a, double b) => (a - b).abs() < 0.005;

// Lectura defensiva del mapa: el backend responde JSON, un bigint puede llegar
// como número o cadena y las columnas de un LEFT JOIN llegan en null. Se lee
// todo con un valor por defecto en vez de confiar en el tipo.

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

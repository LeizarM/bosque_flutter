/// Lo que la consulta de precios vigentes lee de las dos respuestas del backend
/// y cómo se muestra cada número. `obtenerFamilias` y `obtenerPreciosTonPorFamilia`
/// devuelven mapas a propósito (DTO de despliegue, sin entity): se leen UNA vez
/// aquí, tolerando null, texto o número, para que tabla y tarjetas no digan cosas
/// distintas si el backend cambia una clave.
library;

import 'package:bosque_flutter/presentation/widgets/precios/vista_preliminar_reporte.dart';

// Una fila de la grilla

/// El precio vigente de una familia en una lista de precios de una sucursal.
///
/// Es una fila de `p_list_precio` rama D, que ya filtra por lista activa
/// (`cp.estado = 1`): las listas dadas de baja no llegan hasta aquí.
class FilaPrecioVigente {
  const FilaPrecioVigente({
    required this.codigoFamilia,
    required this.codSucursal,
    required this.sucursal,
    required this.idClasificacion,
    required this.nombrePrecio,
    required this.idPrecio,
    required this.vpp,
    required this.porcentaje,
    required this.listNum,
    required this.precio,
    required this.iva,
    required this.it,
  });

  /// Lee una fila cruda. Las claves son las que documenta
  /// `PreciosRepository.obtenerPreciosTonPorFamilia`.
  factory FilaPrecioVigente.desdeMapa(Map<String, dynamic> m) =>
      FilaPrecioVigente(
        codigoFamilia: _entero(m['codigoFamilia']),
        codSucursal: _entero(m['codSucursal']),
        // `nombre` es el de la SUCURSAL, no el del precio: la confusión viene del propio
        // resultset del backend y por eso aquí cambia de nombre.
        sucursal: _texto(m['nombre']),
        idClasificacion: _entero(m['idClasificacion']),
        nombrePrecio: _texto(m['nombrePrecio']),
        idPrecio: _entero(m['idPrecio']),
        vpp: _entero(m['vpp']),
        porcentaje: _decimal(m['porcentaje']),
        listNum: _entero(m['listNum']),
        precio: _decimal(m['precio']),
        iva: _decimal(m['iva']),
        it: _decimal(m['it']),
      );

  final int codigoFamilia;

  /// Sucursal dueña de la lista de precios.
  final int codSucursal;
  final String sucursal;

  /// La lista de precios (tpr_clasificacionPrecio).
  final int idClasificacion;
  final String nombrePrecio;

  /// La fila de tpr_precio. Sirve para rastrear el dato con soporte.
  final int idPrecio;

  /// Numero de lista de venta del ERP.
  final int vpp;

  /// Margen sobre el costo en PUNTOS porcentuales: 22 es 22 %. No es base 1
  /// como la comision del modulo tcom.
  final double porcentaje;

  /// Numero de lista en SAP.
  final int listNum;

  /// Precio vigente por tonelada, en dolares (lo mismo que imprime el PDF).
  final double precio;

  /// IVA e IT vigentes. En el resultset son subconsultas escalares sin
  /// correlación: las N filas de una familia traen SIEMPRE el mismo par, por eso
  /// la pantalla los muestra una sola vez arriba.
  final double iva;
  final double it;

  /// Un cero en tpr_precio significa SIN PRECIO, no precio cero (la cuarta parte de
  /// la tabla): mostrarlo como "0,00" haría pensar que el producto se regala.
  bool get sinPrecio => precio <= 0;

  /// Cómo se nombra la lista en pantalla. `nombrePrecio` dice apenas "Precio" en
  /// casi todas las filas; lo que distingue una lista es el vpp. Es la misma
  /// concatenación de la rama C del procedimiento.
  String get listaLegible =>
      nombrePrecio.isEmpty ? 'Lista $vpp' : '$nombrePrecio $vpp';

  /// Sucursal con nombre util aunque el JOIN venga vacio.
  String get sucursalLegible =>
      sucursal.isEmpty ? 'Sucursal $codSucursal' : sucursal;

  /// El precio listo para mostrar. Sin precio devuelve un guion, nunca un cero.
  String get precioLegible => sinPrecio ? '—' : fmtImporte(precio);

  String get porcentajeLegible => fmtPorcentaje(porcentaje);
}

// La familia consultada

/// Una familia de producto con sus descripciones resueltas, tal como la
/// devuelve `obtenerFamilias`.
class FamiliaPrecio {
  const FamiliaPrecio({
    required this.codigoFamilia,
    required this.proveedorSap,
    required this.grupoFamilia,
    required this.presentacion,
    required this.tipo,
    required this.rangoGramaje,
    required this.gramaje,
    required this.formato,
    required this.color,
    required this.estado,
    required this.costoTM,
    required this.idPropuestaAprobada,
  });

  factory FamiliaPrecio.desdeMapa(Map<String, dynamic> m) => FamiliaPrecio(
    codigoFamilia: _entero(m['codigoFamilia']),
    proveedorSap: _sinSentinela(_texto(m['proveedorSap'])),
    grupoFamilia: _sinSentinela(_texto(m['grpFamilia'])),
    presentacion: _texto(m['presentacion']),
    tipo: _texto(m['tipo']),
    rangoGramaje: _texto(m['rangoGramaje']),
    gramaje: _texto(m['gramaje']),
    formato: _texto(m['formato']),
    color: _texto(m['color']),
    estado: _entero(m['estado']),
    costoTM: _decimal(m['costoTM']),
    idPropuestaAprobada: _enteroNulo(m['idPropuestaAprobada']),
  );

  final int codigoFamilia;

  /// Vacíos cuando la familia no tiene grupo o proveedor SAP asignado: el
  /// procedimiento devuelve una frase completa y [_sinSentinela] la quita (no
  /// entra en una celda ni en la etiqueta de un combo).
  final String proveedorSap;
  final String grupoFamilia;

  final String presentacion;
  final String tipo;

  /// Texto "[ min - max ]" que arma el propio procedimiento.
  final String rangoGramaje;

  /// Los dos son varchar en la base y muchas familias los tienen vacios.
  final String gramaje;
  final String formato;

  final String color;

  /// 1 activa, 0 dada de baja.
  final int estado;

  /// Costo en USD por tonelada que dejo la ultima propuesta aprobada.
  final double costoTM;

  /// La propuesta que fijo el costo. Null cuando la familia nunca se reprecio.
  final int? idPropuestaAprobada;

  bool get activa => estado == 1;

  bool get tieneCosto => costoTM > 0;

  /// Etiqueta del selector: el código primero (por donde se busca) y luego lo que
  /// deja reconocer la familia; los campos vacíos se saltan.
  String get etiqueta {
    final partes = <String>[
      '$codigoFamilia',
      if (grupoFamilia.isNotEmpty) grupoFamilia,
      if (proveedorSap.isNotEmpty) proveedorSap,
      if (gramaje.isNotEmpty) '$gramaje g',
      if (formato.isNotEmpty) formato,
      if (color.isNotEmpty) color,
    ];
    return partes.join(' · ');
  }

  /// Los atributos que se muestran en la ficha, ya sin los vacios.
  List<(String, String)> get atributos => <(String, String)>[
    ('Grupo SAP', grupoFamilia.isEmpty ? 'Sin asignar' : grupoFamilia),
    ('Proveedor SAP', proveedorSap.isEmpty ? 'Sin asignar' : proveedorSap),
    if (presentacion.isNotEmpty) ('Presentación', presentacion),
    if (tipo.isNotEmpty) ('Tipo', tipo),
    if (gramaje.isNotEmpty) ('Gramaje', gramaje),
    if (rangoGramaje.isNotEmpty) ('Rango', rangoGramaje),
    if (formato.isNotEmpty) ('Formato', formato),
    if (color.isNotEmpty) ('Color', color),
  ];
}

// Orden de la grilla

/// Agrupa las filas por sucursal y, dentro de cada una, por número de lista. El
/// procedimiento ordena solo por vpp: hoy las sucursales quedan contiguas por
/// casualidad y una lista nueva podría partir una en dos pedazos.
List<FilaPrecioVigente> ordenadasPorSucursal(List<FilaPrecioVigente> filas) {
  final copia = List<FilaPrecioVigente>.of(filas);
  copia.sort((a, b) {
    final porSucursal = a.sucursalLegible.toLowerCase().compareTo(
      b.sucursalLegible.toLowerCase(),
    );
    if (porSucursal != 0) return porSucursal;
    return a.vpp.compareTo(b.vpp);
  });
  return copia;
}

/// Las listas de una sucursal, tal como se muestran: un encabezado con el
/// resumen y debajo sus filas.
class GrupoSucursal {
  const GrupoSucursal({
    required this.indice,
    required this.nombre,
    required this.filas,
  });

  /// Posicion del grupo en la grilla, empezando en cero. Decide el color de la
  /// franja, igual en la tabla y en las tarjetas.
  final int indice;
  final String nombre;
  final List<FilaPrecioVigente> filas;

  int get sinPrecio => filas.where((f) => f.sinPrecio).length;

  String get listasLegible =>
      filas.length == 1 ? '1 lista' : '${filas.length} listas';
}

/// Corta las filas en bloques de sucursal. Espera las filas ya ordenadas por
/// [ordenadasPorSucursal]: una sucursal partida saldría como dos grupos.
List<GrupoSucursal> agruparPorSucursal(List<FilaPrecioVigente> filas) {
  final grupos = <GrupoSucursal>[];
  for (final fila in filas) {
    if (grupos.isEmpty ||
        grupos.last.filas.first.codSucursal != fila.codSucursal) {
      grupos.add(
        GrupoSucursal(
          indice: grupos.length,
          nombre: fila.sucursalLegible,
          filas: [fila],
        ),
      );
    } else {
      grupos.last.filas.add(fila);
    }
  }
  return grupos;
}

// Rango de precios

/// Entre qué valores se mueve el precio de unas filas, sin contar las que no
/// tienen precio. Null si ninguna tiene. No se promedia: el promedio de doce
/// listas de tres sucursales no es un precio que exista; mínimo y máximo sí.
({double menor, double mayor})? rangoDePrecios(
  Iterable<FilaPrecioVigente> filas,
) {
  double? menor;
  double? mayor;
  for (final f in filas) {
    if (f.sinPrecio) continue;
    if (menor == null || f.precio < menor) menor = f.precio;
    if (mayor == null || f.precio > mayor) mayor = f.precio;
  }
  return menor == null ? null : (menor: menor, mayor: mayor!);
}

/// El rango como texto: `3,555.72 – 3,816.51`, o un solo importe si coinciden.
String? rangoLegible(Iterable<FilaPrecioVigente> filas) {
  final r = rangoDePrecios(filas);
  if (r == null) return null;
  return r.menor == r.mayor
      ? fmtImporte(r.menor)
      : '${fmtImporte(r.menor)} – ${fmtImporte(r.mayor)}';
}

// Formato de los números, como los reportes del módulo: coma para los miles y
// punto para los decimales, con el formateador de la vista preliminar y el PDF.

/// Un importe con dos decimales: `4,561.37`.
String fmtImporte(double valor) => fmtComoPdf.format(valor);

/// Un porcentaje en puntos porcentuales, sin ceros de relleno: `22 %`,
/// `15.476 %`.
String fmtPorcentaje(double valor) {
  var texto = valor.toStringAsFixed(3);
  if (texto.contains('.')) {
    texto = texto.replaceAll(RegExp(r'0+$'), '');
    texto = texto.replaceAll(RegExp(r'\.$'), '');
  }
  return '$texto %';
}

// Lectura tolerante de los mapas: el backend serializa BigDecimal como número, pero
// una fila vieja puede traer null o un DTO mandarlo como texto; lo ilegible queda
// en cero.

String _texto(Object? v) => (v ?? '').toString().trim();

int _entero(Object? v) => _enteroNulo(v) ?? 0;

int? _enteroNulo(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

double _decimal(Object? v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim().replaceAll(',', '.')) ?? 0;
}

/// El procedimiento rellena el grupo y el proveedor sin asignar con una frase
/// entre guiones (`-Sin Grupo de Familia SAP Asignado-`); aquí vuelve a ser vacío.
String _sinSentinela(String valor) => valor.startsWith('-Sin') ? '' : valor;

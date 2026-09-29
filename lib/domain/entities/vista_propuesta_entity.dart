/// La vista preliminar de una propuesta con las mismas filas que su PDF
/// (rptPropuArt por familia, RptArtPropuPorArticulo por articulo). La arma
/// el backend con los mismos procedimientos que el reporte: lo que se ve en
/// pantalla es lo que se imprime.
///
/// Solo lectura: no tiene tabla propia, es la forma de `/price/vistaPropuesta`.
class VistaPropuestaEntity {
  /// 1 por familia, 2 por articulo.
  final int tipo;

  /// Si hay precio actual con que comparar: sin el, como en el PDF, no hay
  /// fila de precio actual ni leyenda de colores.
  final bool conComparacion;

  /// Si trae los precios por unidad (Bs, USD, Bs Productiva): los mismos que
  /// lleva el Excel de la generacion.
  final bool preciosPorUnidad;

  /// El tipo de cambio con que se convirtieron (el ultimo USD de SAP).
  final double? tipoCambio;

  /// Si los precios por unidad no se pudieron leer, por que.
  final String? avisoPreciosPorUnidad;

  /// Las listas activas por VPP, en orden: rotulan las doce columnas.
  final List<ListaVistaPropuestaEntity> listas;

  /// Un articulo por fila, agrupados por familia en el orden del PDF.
  final List<FilaVistaPropuestaEntity> filas;

  const VistaPropuestaEntity({
    required this.tipo,
    required this.conComparacion,
    this.preciosPorUnidad = false,
    this.tipoCambio,
    this.avisoPreciosPorUnidad,
    required this.listas,
    required this.filas,
  });

  bool get porArticulo => tipo == 2;
}

/// Una columna: el VPP de la lista y la sucursal que la agrupa.
class ListaVistaPropuestaEntity {
  final int vpp;
  final String sucursal;

  const ListaVistaPropuestaEntity({required this.vpp, required this.sucursal});
}

/// Un articulo con sus doce listas; el indice 0 es la lista (VPP) 1.
class FilaVistaPropuestaEntity {
  final int codigoFamilia;

  /// Grupo y proveedor de la familia; vacio si no vinieron.
  final String descripcionFamilia;

  /// Solo por articulo: la ultima propuesta aprobada de la familia.
  final BigInt? ultimaPropuesta;

  final String codArticulo;
  final String descripcion;
  final double utm;

  /// Costo por tonelada en USD (la columna COSTO del PDF).
  final double costoTM;

  /// Si trae la fila "Precio Ton. Actual".
  final bool conFilaActual;

  /// Vacia en las propuestas por articulo.
  final List<double?> porcentajes;

  /// Vacia si no hay comparacion.
  final List<double?> actuales;

  /// Precio por tonelada propuesto; por articulo, el vigente de la familia.
  final List<double?> propuestos;

  /// 1 sube, -1 baja, 0 igual, null sin comparacion.
  final List<int?> cambios;

  /// Precio por unidad en USD (Impexpap): por tonelada / UTM.
  final List<double?> unidadUsd;

  /// Precio por unidad en Bs (Impexpap): la columna IPX (BS) del Excel.
  final List<double?> unidadBs;

  /// Precio por unidad en Bs de Productiva: la columna PRODUCTIVA del Excel.
  final List<double?> unidadBsProductiva;

  const FilaVistaPropuestaEntity({
    required this.codigoFamilia,
    this.descripcionFamilia = '',
    this.ultimaPropuesta,
    required this.codArticulo,
    required this.descripcion,
    required this.utm,
    required this.costoTM,
    required this.conFilaActual,
    required this.porcentajes,
    required this.actuales,
    required this.propuestos,
    required this.cambios,
    this.unidadUsd = const [],
    this.unidadBs = const [],
    this.unidadBsProductiva = const [],
  });

  /// El valor de la lista [vpp] (1 a 12), o null si no viene.
  static T? de<T>(List<T?> valores, int vpp) =>
      vpp >= 1 && vpp <= valores.length ? valores[vpp - 1] : null;

  bool coincide(String texto) =>
      texto.isEmpty ||
      codArticulo.toLowerCase().contains(texto) ||
      descripcion.toLowerCase().contains(texto);
}

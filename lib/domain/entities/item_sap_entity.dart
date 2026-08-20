/// Un item del catalogo SAP (`text_ItemSAP`): de aqui salen los articulos de
/// una solicitud de corte con todas sus medidas.
class ItemSapEntity {
  final String codItem;
  final String datoItem;
  final double cantidadDisponible;
  final int codTipo;
  final String datoTipo;
  final int codFabricante;
  final String datoFabricante;
  final double gramaje;
  final double largo;
  final double ancho;
  final double utm;
  final double cantHojas;
  final String empaque;
  final String formato;

  const ItemSapEntity({
    required this.codItem,
    required this.datoItem,
    required this.cantidadDisponible,
    required this.codTipo,
    required this.datoTipo,
    required this.codFabricante,
    required this.datoFabricante,
    required this.gramaje,
    required this.largo,
    required this.ancho,
    required this.utm,
    required this.cantHojas,
    required this.empaque,
    required this.formato,
  });

  /// Lo que se muestra en el buscador: el codigo manda porque es lo que la
  /// gente conoce, y la descripcion desambigua.
  String get etiqueta => '$codItem - $datoItem';
}

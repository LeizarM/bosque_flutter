import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

class EntregasFilterUtils {
  /// Filtra y ordena las entregas agrupadas según parámetros de búsqueda y orden
  static List<MapEntry<int, List<EntregaEntity>>> getFilteredAndSortedEntregas(
    List<MapEntry<int, List<EntregaEntity>>> lista,
    String searchText,
    int? sortColumnIndex,
    bool sortAscending,
  ) {
    var filtered = lista.where((entry) {
      final entrega = entry.value.first;
      final search = searchText.toLowerCase();
      return entrega.cardName?.toLowerCase().contains(search) == true ||
             entrega.factura.toString().contains(search) ||
             (entrega.addressEntregaFac?.toLowerCase().contains(search) ?? false) ||
             (entrega.addressEntregaMat?.toLowerCase().contains(search) ?? false);
    }).toList();

    if (sortColumnIndex != null) {
      filtered.sort((a, b) {
        final ea = a.value.first;
        final eb = b.value.first;
        int cmp = 0;
        switch (sortColumnIndex) {
          case 0: // Cliente
            cmp = (ea.cardName ?? '').compareTo(eb.cardName ?? '');
            break;
          case 1: // Factura
            cmp = ea.factura.compareTo(eb.factura);
            break;
          case 2: // Fecha
            cmp = (ea.fechaEntrega ?? DateTime(1900)).compareTo(eb.fechaEntrega ?? DateTime(1900));
            break;
          case 3: // Dirección
            cmp = (ea.addressEntregaMat ?? '').compareTo(eb.addressEntregaFac ?? '');
            break;
          case 4: // Estado
            cmp = (a.value.every((e) => e.fueEntregado == 1) ? 1 : 0)
                .compareTo(b.value.every((e) => e.fueEntregado == 1) ? 1 : 0);
            break;
        }
        return sortAscending ? cmp : -cmp;
      });
    }
    return filtered;
  }

  /// Agrupa las entregas por número de documento
  static Map<int, List<EntregaEntity>> agruparEntregas(List<EntregaEntity> entregas) {
    final Map<int, List<EntregaEntity>> entregasAgrupadas = {};
    for (final entrega in entregas) {
      if (entregasAgrupadas.containsKey(entrega.docNum)) {
        entregasAgrupadas[entrega.docNum]!.add(entrega);
      } else {
        entregasAgrupadas[entrega.docNum] = [entrega];
      }
    }
    return entregasAgrupadas;
  }
}
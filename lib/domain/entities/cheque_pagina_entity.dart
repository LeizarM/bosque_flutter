import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';

/// Una pagina de la grilla de cheques (`/cheque/listar`). La paginacion es del
/// servidor: [total] cuenta todas las filas que cumplen el filtro, no solo las
/// de esta pagina.
class ChequePaginaEntity {
  final int total;

  /// Desde 1.
  final int pagina;

  final int tamanio;
  final List<ChequeFilaEntity> filas;

  const ChequePaginaEntity({
    required this.total,
    required this.pagina,
    required this.tamanio,
    required this.filas,
  });

  /// Sin resultados; es lo que llega con un 204.
  const ChequePaginaEntity.vacia({this.pagina = 1, this.tamanio = 20})
    : total = 0,
      filas = const [];

  int get totalPaginas => tamanio <= 0 ? 0 : (total + tamanio - 1) ~/ tamanio;

  bool get hayAnterior => pagina > 1;
  bool get haySiguiente => pagina < totalPaginas;

  /// Posicion (1..total) de la primera y la ultima fila de esta pagina, para
  /// «21 a 40 de 135». Cero si la pagina esta vacia.
  int get desde => filas.isEmpty ? 0 : (pagina - 1) * tamanio + 1;
  int get hasta => filas.isEmpty ? 0 : desde + filas.length - 1;
}

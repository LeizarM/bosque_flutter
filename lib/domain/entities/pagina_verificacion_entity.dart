/// Una pagina de resultados de «Verificar Cheques»: sirve a la lista de
/// verificaciones y a la de cheques pendientes (`{ total, pagina, tamanio,
/// filas }` del contrato). La paginacion es del servidor: [total] cuenta todas
/// las filas que cumplen el filtro, no solo las de esta pagina.
class PaginaVerificacionEntity<T> {
  final int total;

  /// Desde 1.
  final int pagina;

  final int tamanio;
  final List<T> filas;

  const PaginaVerificacionEntity({
    required this.total,
    required this.pagina,
    required this.tamanio,
    required this.filas,
  });

  /// Sin resultados; tambien lo que llega con un 204.
  const PaginaVerificacionEntity.vacia({this.pagina = 1, this.tamanio = 20})
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

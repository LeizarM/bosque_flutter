/// Lo que se pide a `/cheque/verificacion/listar`: el dia de la verificacion y la
/// pagina. Sin fecha se piden todas las verificaciones.
///
/// La pantalla abre con **hoy**, como el legacy (`buscFech = new Date()`). El
/// servidor no pone ninguna fecha por defecto.
class VerificacionFiltroEntity {
  /// Tamano de pagina por defecto (el servidor admite hasta 200).
  static const int tamanioPorDefecto = 20;

  /// El dia de la verificacion (`fechaBanco`), sin hora; null = todas.
  final DateTime? fechaBanco;

  /// Desde 1.
  final int pagina;

  final int tamanio;

  const VerificacionFiltroEntity({
    this.fechaBanco,
    this.pagina = 1,
    this.tamanio = tamanioPorDefecto,
  });

  VerificacionFiltroEntity copyWith({
    DateTime? fechaBanco,
    bool quitarFecha = false,
    int? pagina,
    int? tamanio,
  }) => VerificacionFiltroEntity(
    fechaBanco: quitarFecha ? null : (fechaBanco ?? this.fechaBanco),
    pagina: pagina ?? this.pagina,
    tamanio: tamanio ?? this.tamanio,
  );
}

/// Un número de la escala de una pregunta de la semana con cuántos lo eligieron
/// (`p_list_tcpe_PreguntaSemana` E), también si nadie lo eligió. [total] y
/// [promedio] son de toda la pregunta y se repiten en cada fila.
class TcpeEscalaSemanaEntity {
  final int valor;

  /// La etiqueta de un extremo («Muy mal», «Excelente»); null en los del medio.
  final String? etiqueta;
  final int cantidad;

  /// De 0 a 100, con un decimal.
  final double porcentaje;
  final int total;
  final double? promedio;

  const TcpeEscalaSemanaEntity({
    required this.valor,
    this.etiqueta,
    this.cantidad = 0,
    this.porcentaje = 0,
    this.total = 0,
    this.promedio,
  });

  TcpeEscalaSemanaEntity copyWith({
    int? valor,
    String? etiqueta,
    int? cantidad,
    double? porcentaje,
    int? total,
    double? promedio,
  }) => TcpeEscalaSemanaEntity(
    valor: valor ?? this.valor,
    etiqueta: etiqueta ?? this.etiqueta,
    cantidad: cantidad ?? this.cantidad,
    porcentaje: porcentaje ?? this.porcentaje,
    total: total ?? this.total,
    promedio: promedio ?? this.promedio,
  );
}

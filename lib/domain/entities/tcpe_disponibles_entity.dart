/// Cuántas preguntas válidas y distintas tiene una categoría (`p_list_tcpe_Lote` D).
class TcpeDisponiblesEntity {
  final BigInt codClasificacion;
  final int disponibles;

  const TcpeDisponiblesEntity({
    required this.codClasificacion,
    this.disponibles = 0,
  });

  TcpeDisponiblesEntity copyWith({
    BigInt? codClasificacion,
    int? disponibles,
  }) => TcpeDisponiblesEntity(
    codClasificacion: codClasificacion ?? this.codClasificacion,
    disponibles: disponibles ?? this.disponibles,
  );
}

class AnticipoPreviewEntity {
  final int codEmpleado;
  final String nombreCompleto;
  final String tipo;
  final double montoCalculado;
  final double montoSAP;
  final double sumaTotalCalculada;
  final double diferenciaGlobal;
  final bool esValido;

  AnticipoPreviewEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.tipo,
    required this.montoCalculado,
    required this.montoSAP,
    required this.sumaTotalCalculada,
    required this.diferenciaGlobal,
    required this.esValido,
  });
}

class AnticipoPreviewModel {
  static AnticipoPreviewEntity fromJson(Map<String, dynamic> json) {
    return AnticipoPreviewEntity(
      codEmpleado: json['codEmpleado'] ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? '',
      tipo: json['tipo'] ?? 'A',
      montoCalculado: (json['montoCalculado'] as num?)?.toDouble() ?? 0.0,
      montoSAP: (json['montoSAP'] as num?)?.toDouble() ?? 0.0,
      sumaTotalCalculada:
          (json['sumaTotalCalculada'] as num?)?.toDouble() ?? 0.0,
      diferenciaGlobal: (json['diferenciaGlobal'] as num?)?.toDouble() ?? 0.0,
      esValido: json['esValido'] == 1,
    );
  }
}

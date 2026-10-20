/// Los estados que calcula `p_list_tcpe_Rendir` y `p_list_tcpe_Resultado`.
enum EstadoExamenTcpe {
  sinIniciar('SIN_INICIAR', 'Sin iniciar'),
  enCurso('EN_CURSO', 'En curso'),
  vencido('VENCIDO', 'Vencido'),
  porRevisar('POR_REVISAR', 'Por revisar'),
  calificado('CALIFICADO', 'Calificado'),
  /// No empezó dentro de la ventana del lote: cuenta como reprobado.
  ausente('AUSENTE', 'Ausente'),
  desconocido('', 'Sin estado');

  const EstadoExamenTcpe(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoExamenTcpe desde(String? codigo) {
    final c = (codigo ?? '').trim().toUpperCase();
    for (final e in values) {
      if (e != desconocido && e.codigo == c) return e;
    }
    return desconocido;
  }

  /// Ya no se puede responder: se entregó o se le acabó el tiempo.
  bool get cerrado => this == vencido || this == porRevisar || this == calificado || this == ausente;
}

/// Cómo terminó `/examenes/banco/importar`: cuántas preguntas insertó
/// `p_abm_tcpe_BancoLote` I (`idGenerado`) y su resumen (`errormsg`).
class TcpeResultadoImportacionEntity {
  final int insertadas;
  final String? mensaje;

  const TcpeResultadoImportacionEntity({this.insertadas = 0, this.mensaje});

  TcpeResultadoImportacionEntity copyWith({int? insertadas, String? mensaje}) =>
      TcpeResultadoImportacionEntity(insertadas: insertadas ?? this.insertadas, mensaje: mensaje ?? this.mensaje);
}

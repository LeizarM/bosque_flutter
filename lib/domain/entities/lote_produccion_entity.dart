class LoteProduccionEntity {
  int idMa;
  int idLp;
  int numLote;
  int anio;
  DateTime fecha;
  String hraInicioCorte;
  String hraInicio;
  String hraFin;
  int cantBobinasIngresoTotal;
  double pesoKilosTotalIngreso;
  double pesoTotalSalida;
  double pesoPaletaSalida;
  double pesoMaterialSalida;
  int cantResmaSalida;
  double cantHojasSalida;
  double mermaTotal;
  double diferenciaProduccion;
  double diferenciaProdResma;
  double cantEstimadaResma;
  double pesoBalanzaTotal;
  int estado;
  String obs;
  int numCorte;
  int anioCorte;
  int docNumOrdFab;
  int codEmpresa;
  int audUsuario;
  String codArticulo;
  String datoArt;
  String articulo;
  double utm;
  String codArtEntrada;
  String codArtSalida;
  String db;

  LoteProduccionEntity({
    required this.idMa,
    required this.idLp,
    required this.numLote,
    required this.anio,
    required this.fecha,
    required this.hraInicioCorte,
    required this.hraInicio,
    required this.hraFin,
    required this.cantBobinasIngresoTotal,
    required this.pesoKilosTotalIngreso,
    required this.pesoTotalSalida,
    required this.pesoPaletaSalida,
    required this.pesoMaterialSalida,
    required this.cantResmaSalida,
    required this.cantHojasSalida,
    required this.mermaTotal,
    required this.diferenciaProduccion,
    required this.diferenciaProdResma,
    required this.cantEstimadaResma,
    required this.pesoBalanzaTotal,
    required this.estado,
    required this.obs,
    required this.numCorte,
    required this.anioCorte,
    required this.docNumOrdFab,
    required this.codEmpresa,
    required this.audUsuario,
    required this.codArticulo,
    required this.datoArt,
    required this.articulo,
    required this.utm,
    required this.codArtEntrada,
    required this.codArtSalida,
    required this.db,
  });

  /// Una copia independiente.
  ///
  /// Los campos son mutables, asi que editar un lote en el detalle tocaria el
  /// mismo objeto que dibuja la lista: al cancelar quedaban a la vista cambios
  /// que nunca se guardaron.
  LoteProduccionEntity clonar() => LoteProduccionEntity(
    idMa: idMa,
    idLp: idLp,
    numLote: numLote,
    anio: anio,
    fecha: fecha,
    hraInicioCorte: hraInicioCorte,
    hraInicio: hraInicio,
    hraFin: hraFin,
    cantBobinasIngresoTotal: cantBobinasIngresoTotal,
    pesoKilosTotalIngreso: pesoKilosTotalIngreso,
    pesoTotalSalida: pesoTotalSalida,
    pesoPaletaSalida: pesoPaletaSalida,
    pesoMaterialSalida: pesoMaterialSalida,
    cantResmaSalida: cantResmaSalida,
    cantHojasSalida: cantHojasSalida,
    mermaTotal: mermaTotal,
    diferenciaProduccion: diferenciaProduccion,
    diferenciaProdResma: diferenciaProdResma,
    cantEstimadaResma: cantEstimadaResma,
    pesoBalanzaTotal: pesoBalanzaTotal,
    estado: estado,
    obs: obs,
    numCorte: numCorte,
    anioCorte: anioCorte,
    docNumOrdFab: docNumOrdFab,
    codEmpresa: codEmpresa,
    audUsuario: audUsuario,
    codArticulo: codArticulo,
    datoArt: datoArt,
    articulo: articulo,
    utm: utm,
    codArtEntrada: codArtEntrada,
    codArtSalida: codArtSalida,
    db: db,
  );
}

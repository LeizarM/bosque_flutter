/// Configuración y avance de un bingo para el encargado. Con `codTipoTicket`,
/// cada vale de ese tipo da un cartón; sin él, los cartones son manuales.
class TtkBingoEntity {
  final BigInt? codBingo;
  final BigInt? codEvento;
  final String nombreEvento;
  final DateTime? fechaEvento;
  final int nroBolillos;
  final int filas;
  final int columnas;
  final String? letras;
  final bool conComodin;
  final int nroJuegos;
  final int nroCartones;
  final BigInt? codTipoTicket;
  final String? nombreTipoTicket;
  final int valesBingo;
  final int cartonesObjetivo;
  final int cartonesFaltantes;
  final int maxCartonesEmpleado;
  final int tamRanking;

  /// P en pantalla, I impreso, A ambos (el encargado decide por cartón).
  final String modalidad;
  final String modalidadTexto;

  /// Botón «¡Bingo!» del participante: solo avisa al encargado.
  final bool conAviso;

  /// Cómo se desempata si hay más de un ganador; se ve en la pantalla en vivo.
  final String? reglaEmpate;
  final String estado;
  final String estadoTexto;
  final int? nroGeneracion;
  final DateTime? fechaGeneracion;
  final int cartonesGenerados;
  final int cartonesAsignados;
  final int cartonesDisponibles;
  final int cartonesImpresos;
  final int empleadosConCarton;
  final int juegosFinalizados;
  final int? nroJuegoActual;
  final String? nombreJuegoActual;
  final String? rangos;
  final String mensajeEstado;
  final bool puedeConfigurar;
  final bool puedeGenerar;
  final bool puedeAbrirEleccion;
  final bool puedeIniciar;
  final bool puedeAsignar;
  final bool puedeFinalizar;
  final bool puedeImprimir;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkBingoEntity({
    this.codBingo,
    this.codEvento,
    this.nombreEvento = '',
    this.fechaEvento,
    this.nroBolillos = 75,
    this.filas = 5,
    this.columnas = 5,
    this.letras,
    this.conComodin = true,
    this.nroJuegos = 8,
    this.nroCartones = 100,
    this.codTipoTicket,
    this.nombreTipoTicket,
    this.valesBingo = 0,
    this.cartonesObjetivo = 0,
    this.cartonesFaltantes = 0,
    this.maxCartonesEmpleado = 1,
    this.tamRanking = 10,
    this.modalidad = 'A',
    this.modalidadTexto = '',
    this.conAviso = false,
    this.reglaEmpate,
    this.estado = '',
    this.estadoTexto = '',
    this.nroGeneracion,
    this.fechaGeneracion,
    this.cartonesGenerados = 0,
    this.cartonesAsignados = 0,
    this.cartonesDisponibles = 0,
    this.cartonesImpresos = 0,
    this.empleadosConCarton = 0,
    this.juegosFinalizados = 0,
    this.nroJuegoActual,
    this.nombreJuegoActual,
    this.rangos,
    this.mensajeEstado = '',
    this.puedeConfigurar = false,
    this.puedeGenerar = false,
    this.puedeAbrirEleccion = false,
    this.puedeIniciar = false,
    this.puedeAsignar = false,
    this.puedeFinalizar = false,
    this.puedeImprimir = false,
    this.audUsuario,
    this.audFecha,
  });

  /// Si cada vale de un tipo da un cartón (bingo por vales).
  bool get porVales => codTipoTicket != null;

  /// Con «ambos», el encargado decide cartón por cartón cuáles se imprimen.
  bool get formaPorCarton => modalidad == 'A';

  TtkBingoEntity copyWith({
    int? nroBolillos,
    int? filas,
    int? columnas,
    String? letras,
    bool? conComodin,
    int? nroJuegos,
    int? nroCartones,
    int? maxCartonesEmpleado,
    int? tamRanking,
    BigInt? codTipoTicket,
    bool sinTipoTicket = false,
    String? modalidad,
    bool? conAviso,
    String? reglaEmpate,
  }) => TtkBingoEntity(
    codBingo: codBingo,
    codEvento: codEvento,
    nombreEvento: nombreEvento,
    fechaEvento: fechaEvento,
    nroBolillos: nroBolillos ?? this.nroBolillos,
    filas: filas ?? this.filas,
    columnas: columnas ?? this.columnas,
    letras: letras ?? this.letras,
    conComodin: conComodin ?? this.conComodin,
    nroJuegos: nroJuegos ?? this.nroJuegos,
    nroCartones: nroCartones ?? this.nroCartones,
    codTipoTicket: sinTipoTicket ? null : (codTipoTicket ?? this.codTipoTicket),
    nombreTipoTicket: nombreTipoTicket,
    valesBingo: valesBingo,
    cartonesObjetivo: cartonesObjetivo,
    cartonesFaltantes: cartonesFaltantes,
    maxCartonesEmpleado: maxCartonesEmpleado ?? this.maxCartonesEmpleado,
    tamRanking: tamRanking ?? this.tamRanking,
    modalidad: modalidad ?? this.modalidad,
    modalidadTexto: modalidadTexto,
    conAviso: conAviso ?? this.conAviso,
    reglaEmpate: reglaEmpate ?? this.reglaEmpate,
    estado: estado,
    estadoTexto: estadoTexto,
    nroGeneracion: nroGeneracion,
    fechaGeneracion: fechaGeneracion,
    cartonesGenerados: cartonesGenerados,
    cartonesAsignados: cartonesAsignados,
    cartonesDisponibles: cartonesDisponibles,
    cartonesImpresos: cartonesImpresos,
    empleadosConCarton: empleadosConCarton,
    juegosFinalizados: juegosFinalizados,
    nroJuegoActual: nroJuegoActual,
    nombreJuegoActual: nombreJuegoActual,
    rangos: rangos,
    mensajeEstado: mensajeEstado,
    puedeConfigurar: puedeConfigurar,
    puedeGenerar: puedeGenerar,
    puedeAbrirEleccion: puedeAbrirEleccion,
    puedeIniciar: puedeIniciar,
    puedeAsignar: puedeAsignar,
    puedeFinalizar: puedeFinalizar,
    puedeImprimir: puedeImprimir,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}

// Destino final: lib/domain/entities/senal_cargo_entity.dart

/// Cargos por revisar (archivo SQL 82): una persona que no hizo ninguna de
/// sus últimas N ocurrencias de una tarea. Puede que le cambiaran las
/// funciones y su cargo no esté al día. El motivo lo arma el servidor.
class SenalCargo {
  final int codEmpleado;
  final String persona;
  final String? cargo;
  final DateTime? cargoDesde;
  final String? nombreSucursal;

  final int idTarRuti;
  final String tarea;
  final int ocurrencias;
  final DateTime? desde;
  final DateTime? ultimaHecha;
  final String? laHaceOtro;

  /// Cuántas tareas recibe hoy la persona: "no hace 17 de sus 19".
  final int tareasDeLaPersona;
  final String motivo;

  /// "Está bien así": hasta cuándo, por qué y quién la marcó.
  final int? idSC;
  final DateTime? calladaHasta;
  final String? obsCallada;
  final String? calladaPor;

  const SenalCargo({
    required this.codEmpleado,
    required this.persona,
    this.cargo,
    this.cargoDesde,
    this.nombreSucursal,
    required this.idTarRuti,
    required this.tarea,
    required this.ocurrencias,
    this.desde,
    this.ultimaHecha,
    this.laHaceOtro,
    required this.tareasDeLaPersona,
    required this.motivo,
    this.idSC,
    this.calladaHasta,
    this.obsCallada,
    this.calladaPor,
  });

  bool get callada => idSC != null;

  String get clave => '$codEmpleado|$idTarRuti';
}

/// Las señales de una persona, para mostrarlas juntas.
class PersonaConSenales {
  final SenalCargo primera;
  final List<SenalCargo> senales;

  const PersonaConSenales(this.primera, this.senales);

  int get codEmpleado => primera.codEmpleado;
  String get persona => primera.persona;

  /// Sin hacer de las que recibe hoy (las calladas no cuentan).
  int get sinHacer => senales.where((s) => !s.callada).length;
  int get deSusTareas => primera.tareasDeLaPersona;

  /// No hace ninguna: la señal más fuerte de un cargo que cambió.
  bool get ninguna => deSusTareas > 0 && sinHacer >= deSusTareas;
}

// Destino final: lib/domain/entities/dependiente_cargo_entity.dart
// Fila devuelta por /tareas-rutinarias/listar-dependientes-jefe — NO es una
// tabla propia, es la proyección de trh_cargo/tb_cargo_sucursal/tb_sucursal
// que arma el backend (ver DependienteCargo.java).
class DependienteCargoEntity {
  final int codCargo;
  final String descripcionCargo;
  final int codNivel;
  final int codEmpresa;
  final int? codCargoSucursal;
  final int codSucursal;
  final String nombreSucursal;
  final int profundidadNivel;
  final int? codEmpleadoActual;
  final String? nombreEmpleadoActual;

  const DependienteCargoEntity({
    required this.codCargo,
    required this.descripcionCargo,
    required this.codNivel,
    required this.codEmpresa,
    this.codCargoSucursal,
    required this.codSucursal,
    required this.nombreSucursal,
    required this.profundidadNivel,
    this.codEmpleadoActual,
    this.nombreEmpleadoActual,
  });

  /// Identificador único de la fila para selección en UI: un mismo cargo
  /// puede aparecer varias veces (una por sucursal) cuando el alcance es
  /// "todas las sucursales".
  String get claveSeleccion => '$codCargo-${codCargoSucursal ?? "todas"}';

  bool get vacante => codEmpleadoActual == null;
}

class CargoEntity {
  int codCargo;
  int codCargoPadre;
  String descripcion;
  int codEmpresa;
  int codNivel;
  int posicion;
  int estado;
  int audUsuario;
  String sucursal;
  String sucursalPlanilla;
  String nombreEmpresa;
  String nombreEmpresaPlanilla;
  int codEmpresaPlanilla;
  int codCargoPlanilla;
  String descripcionPlanilla;

  // Variables de apoyo
  int nivel;
  int tieneEmpleadosActivos;
  int tieneEmpleadosTotales;
  int estaAsignadoSucursal;
  int canDeactivate;
  int numDependientes;
  int numDependenciasTotales;
  int numDependenciasCompletas;
  int numDeDependencias;
  int numHijosActivos;
  int numHijosTotal;
  String resumenCompleto;
  String estadoPadre;
  int esVisible;

  List<CargoEntity> items;

  CargoEntity({
    required this.codCargo,
    required this.codCargoPadre,
    required this.descripcion,
    required this.codEmpresa,
    required this.codNivel,
    required this.posicion,
    required this.estado,
    required this.audUsuario,
    required this.sucursal,
    required this.sucursalPlanilla,
    required this.nombreEmpresa,
    required this.nombreEmpresaPlanilla,
    required this.codEmpresaPlanilla,
    required this.codCargoPlanilla,
    required this.descripcionPlanilla,

    //variables de apoyo
    required this.nivel,
    required this.tieneEmpleadosActivos,
    required this.tieneEmpleadosTotales,
    required this.estaAsignadoSucursal,
    required this.canDeactivate,
    required this.numDependientes,
    required this.numDependenciasTotales,
    required this.numDependenciasCompletas,
    required this.numDeDependencias,
    required this.numHijosActivos,
    required this.numHijosTotal,
    required this.resumenCompleto,
    required this.estadoPadre,
    required this.esVisible,
    required this.items,
  });
}

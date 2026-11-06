/// Un empleado activo de la rama de un aprobador (D34), con quién firma sus
/// reportes. Lo calcula `p_list_thex_Aprobador` R; la app solo lo muestra.
class HexRamaEmpleadoEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final BigInt? codCargo;
  final String? cargo;
  final BigInt? codSucursal;
  final String? nombreSucursal;

  /// 1 = depende directo del cargo del aprobador.
  final int profundidad;
  final String? vistoBueno;
  final String? aprueba;

  /// «Visto bueno: A · Aprueba: B» o el caso que corresponda, del SP.
  final String textoFirma;

  /// Cargo vigente de la persona consultada; el SP lo repite en cada fila.
  final String? cargoAprobador;

  /// Cargos desde el que está debajo de la persona hasta el del empleado,
  /// separados por «›».
  final String? rutaCargo;

  const HexRamaEmpleadoEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.codCargo,
    this.cargo,
    this.codSucursal,
    this.nombreSucursal,
    this.profundidad = 0,
    this.vistoBueno,
    this.aprueba,
    this.textoFirma = '',
    this.cargoAprobador,
    this.rutaCargo,
  });
}

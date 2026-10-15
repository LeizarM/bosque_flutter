// Destino final: lib/domain/entities/responsable_cierre_entity.dart
/// La matriz de Verificar Cierre (archivo SQL 81): un cargo en su sucursal o
/// una persona revisa una sección, de una sucursal o de todas. La deciden RRHH
/// o un administrador desde el organigrama.
class ResponsableCierre {
  final int idRC;
  final int idTarRuti;

  /// El código de la sección en el catálogo (archivo SQL 86).
  final String codigoSeccion;
  final String nombreSeccion;

  /// Si la sección se pide hoy; una quitada guarda a sus responsables.
  final bool seccionVigente;

  /// Null = todas las sucursales.
  final int? codSucursal;
  final String nombreSucursal;

  /// Uno de los dos: el cargo en su sucursal o la persona.
  final int? codCargoSucursal;
  final String? cargo;
  final String? sucursalDelCargo;
  final int? codEmpleado;

  /// Quién ocupa hoy ese cargo, o la persona asignada.
  final String? personas;
  final bool puedeAutorrevisar;
  final bool activo;

  const ResponsableCierre({
    required this.idRC,
    required this.idTarRuti,
    required this.codigoSeccion,
    required this.nombreSeccion,
    this.seccionVigente = true,
    this.codSucursal,
    required this.nombreSucursal,
    this.codCargoSucursal,
    this.cargo,
    this.sucursalDelCargo,
    this.codEmpleado,
    this.personas,
    this.puedeAutorrevisar = false,
    this.activo = true,
  });

  /// A quién se refiere la fila, para agruparlas.
  String get claveResponsable =>
      codCargoSucursal != null ? 'C$codCargoSucursal' : 'P$codEmpleado';
}

/// A quién se le puede asignar una sección: un cargo en su sucursal (quien lo
/// ocupe) o una persona.
class CandidatoCierre {
  final bool esCargo;
  final int? codCargoSucursal;
  final int? codEmpleado;
  final String cargo;
  final String sucursal;

  /// Para un cargo, quién lo ocupa hoy; para una persona, su nombre.
  final String? personas;
  final bool tieneLaTarea;
  final int secciones;

  const CandidatoCierre({
    required this.esCargo,
    this.codCargoSucursal,
    this.codEmpleado,
    required this.cargo,
    required this.sucursal,
    this.personas,
    this.tieneLaTarea = false,
    this.secciones = 0,
  });

  String get claveResponsable =>
      esCargo ? 'C$codCargoSucursal' : 'P$codEmpleado';

  /// Tiene la tarea asignada pero ninguna sección: no la recibe (SQL 101).
  bool get sinSecciones => tieneLaTarea && secciones == 0;
}

/// Una sección del catálogo de Verificar Cierre (archivo SQL 86). Las propias
/// (arqueos, caja fuerte, traspasos, cheques, tareas del día) tienen pantalla
/// programada; las demás leen sus filas de una fuente de otro módulo.
class SeccionCierre {
  final String codigo;
  final String nombre;
  final String? queRevisar;
  final bool porSucursal;
  final bool propia;
  final String? fuente;
  final String? nombreFuente;
  final bool marcaPorFila;
  final bool firmaSola;

  /// Desde cuántos hallazgos pide observación; 0 = nunca.
  final int obsDesde;

  /// H: el día hábil anterior; M: el mismo día.
  final String diaRevisado;
  final int orden;

  /// Si se pide hoy.
  final bool vigente;
  final int responsables;

  const SeccionCierre({
    required this.codigo,
    required this.nombre,
    this.queRevisar,
    this.porSucursal = false,
    this.propia = false,
    this.fuente,
    this.nombreFuente,
    this.marcaPorFila = true,
    this.firmaSola = true,
    this.obsDesde = 1,
    this.diaRevisado = 'H',
    this.orden = 100,
    this.vigente = true,
    this.responsables = 0,
  });
}

/// Una consulta de otro módulo registrada para usarla como sección. El
/// registro se administra desde la app (archivo SQL 87); la consulta misma la
/// escribe sistemas en SQL.
class FuenteCierre {
  /// El nombre de la función o el SP en la base (fn_tac_cierre_...).
  final String fuente;

  /// F función, P procedimiento.
  final String tipo;
  final String nombre;
  final String? descripcion;

  /// Opcional: el SP que guarda la marca en el módulo de la fila.
  final String? spMarcar;

  /// La marca de revisado queda en el módulo de la fila.
  final bool guardaEnSuModulo;
  final bool activa;

  /// Si su función o SP existe en la base, y si devuelve clave y titulo.
  final bool existe;
  final bool columnasOk;
  final int secciones;

  /// Las secciones que la usan, separadas por coma.
  final String? usadaPor;

  const FuenteCierre({
    required this.fuente,
    this.tipo = 'F',
    required this.nombre,
    this.descripcion,
    this.spMarcar,
    this.guardaEnSuModulo = false,
    this.activa = true,
    this.existe = true,
    this.columnasOk = true,
    this.secciones = 0,
    this.usadaPor,
  });

  bool get enUso => secciones > 0;
}

/// Una consulta del cierre que existe en la base y no se registró todavía.
class CandidatoFuente {
  final String fuente;
  final String tipo;
  final bool columnasOk;

  const CandidatoFuente({
    required this.fuente,
    this.tipo = 'F',
    this.columnasOk = true,
  });
}

class SucursalCaja {
  final int codSucursal;
  final String nombre;

  const SucursalCaja(this.codSucursal, this.nombre);
}

/// Una línea del asiento de planilla tal como va a SAP.
class AsientoSapLineaEntity {
  /// CodigoSN del SP: una cuenta de mayor o un socio de negocio.
  final String codigo;
  final String nombre;

  /// AccountCode: la cuenta de mayor, o la cuenta asociada del socio.
  final String cuenta;

  /// ShortName: el socio de negocio; null en las líneas de cuenta.
  final String? socio;
  final double debito;
  final double credito;

  const AsientoSapLineaEntity({
    required this.codigo,
    required this.nombre,
    required this.cuenta,
    this.socio,
    required this.debito,
    required this.credito,
  });
}

/// El asiento de planilla armado por el backend, antes de enviarlo a SAP.
class AsientoSapEntity {
  final int anio;
  final int mes;
  final int codEmpresa;
  final String empresa;
  final String baseSap;

  /// El nombre de la conexión a SAP a la que va.
  final String conexion;

  /// PRODUCCION o PRUEBA (ver SapConexionEntity): se destaca para no enviar a la base equivocada.
  final String ambiente;
  final String fecha;
  final String memo;
  final String referencia;
  final List<AsientoSapLineaEntity> lineas;
  final double totalDebito;
  final double totalCredito;
  final double diferencia;
  final bool cuadra;

  const AsientoSapEntity({
    required this.anio,
    required this.mes,
    required this.codEmpresa,
    this.empresa = '',
    required this.baseSap,
    this.conexion = '',
    this.ambiente = '',
    required this.fecha,
    required this.memo,
    required this.referencia,
    required this.lineas,
    required this.totalDebito,
    required this.totalCredito,
    required this.diferencia,
    required this.cuadra,
  });

  bool get esPrueba => ambiente == 'PRUEBA';
}

/// Una empresa que se puede enviar: habilitada, con su conexión habilitada y con la contraseña
/// del Service Layer cargada.
class AsientoSapEmpresaEntity {
  final int codEmpresa;
  final String empresa;

  const AsientoSapEmpresaEntity({
    required this.codEmpresa,
    required this.empresa,
  });
}

/// La configuración del asiento en SAP de una empresa (tsap_AsientoPlanilla).
///
/// Con qué SAP se conecta es la conexión [idConexion], que se administra en Administración >
/// Conexiones SAP. De ella llegan, solo para mostrar, el nombre, el ambiente, la base y si tiene
/// la contraseña cargada; la contraseña nunca.
class AsientoSapConfigEntity {
  final int codEmpresa;
  final String empresa;
  final bool habilitado;

  /// null mientras no se elija (en un alta).
  final int? idConexion;

  // De la conexión, solo para mostrar.
  final String conexion;
  final String ambiente;
  final bool conexionHabilitada;
  final String baseSap;
  final String linkedServer;
  final String esquema;
  final String sp;
  final String paramAnio;
  final String paramMes;
  final String colCodigo;
  final String colNombre;
  final String colCuenta;
  final String colDebito;
  final String colCredito;
  final String prefijosSocio;

  /// 0 = el día en que se envía a SAP; 1 a 31 = ese día del mes de la planilla (31: el último).
  final int diaDelMes;
  final String memo;
  final String referencia;
  final String campoReferencia;
  final bool evitarDuplicados;
  final double tolerancia;
  final bool claveCargada;
  final DateTime? audFecha;

  const AsientoSapConfigEntity({
    required this.codEmpresa,
    this.empresa = '',
    this.habilitado = true,
    this.idConexion,
    this.conexion = '',
    this.ambiente = '',
    this.conexionHabilitada = true,
    this.baseSap = '',
    this.linkedServer = '',
    this.esquema = 'dbo',
    this.sp = '',
    this.paramAnio = '',
    this.paramMes = '',
    this.colCodigo = '',
    this.colNombre = '',
    this.colCuenta = '',
    this.colDebito = '',
    this.colCredito = '',
    this.prefijosSocio = '',
    this.diaDelMes = 0,
    this.memo = '',
    this.referencia = '',
    this.campoReferencia = '',
    this.evitarDuplicados = true,
    this.tolerancia = 0,
    this.claveCargada = false,
    this.audFecha,
  });

  bool get esPrueba => ambiente == 'PRUEBA';

  /// Lo que trae el script de Node, para no escribirlo de nuevo en cada empresa.
  factory AsientoSapConfigEntity.plantilla({required int codEmpresa}) =>
      AsientoSapConfigEntity(
        codEmpresa: codEmpresa,
        sp: 'spAsientoSueldosDraft',
        paramAnio: 'Añio',
        paramMes: 'Mes',
        colCodigo: 'CodigoSN',
        colNombre: 'NombreSN',
        colCuenta: 'CuentaAsociada',
        colDebito: 'ColumnaDebito',
        colCredito: 'ColumnaCredito',
        prefijosSocio: 'SU,CO,AFT',
        memo: 'Asiento de Planilla - Periodo {mes}/{anio}',
        referencia: 'PLANILLA-{anio}-{mes2}',
        campoReferencia: 'Reference3',
      );
}

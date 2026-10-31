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
    required this.fecha,
    required this.memo,
    required this.referencia,
    required this.lineas,
    required this.totalDebito,
    required this.totalCredito,
    required this.diferencia,
    required this.cuadra,
  });
}

/// Una empresa que se puede enviar: habilitada y con la contraseña del Service Layer cargada.
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
/// La contraseña del Service Layer no viaja: el backend solo dice si está cargada.
class AsientoSapConfigEntity {
  final int codEmpresa;
  final String empresa;
  final bool habilitado;
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
  final int diaDelMes;
  final String memo;
  final String referencia;
  final String campoReferencia;
  final bool evitarDuplicados;
  final double tolerancia;
  final String slUrl;
  final String slUsuario;
  final bool claveCargada;
  final DateTime? audFecha;

  const AsientoSapConfigEntity({
    required this.codEmpresa,
    this.empresa = '',
    this.habilitado = true,
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
    this.diaDelMes = 30,
    this.memo = '',
    this.referencia = '',
    this.campoReferencia = '',
    this.evitarDuplicados = true,
    this.tolerancia = 0,
    this.slUrl = '',
    this.slUsuario = '',
    this.claveCargada = false,
    this.audFecha,
  });

  /// Lo que trae el script de Node, para no escribirlo de nuevo en cada empresa.
  factory AsientoSapConfigEntity.plantilla({required int codEmpresa}) =>
      AsientoSapConfigEntity(
        codEmpresa: codEmpresa,
        linkedServer: '192.168.3.114',
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
        slUrl: 'https://sequoia:50000/b1s/v1/',
      );
}

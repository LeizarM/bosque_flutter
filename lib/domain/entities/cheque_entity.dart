/// Cheque recibido de un cliente (tabla tch_cheque).
///
/// Espeja la fila tal cual: las 19 columnas, ninguna calculada. Casi todas son
/// NULL en la base, y aqui tambien: solo [codCheque] y [nrocheque] son NOT NULL.
/// Lo que sale de un JOIN (nombre del banco, del cliente, descripciones) vive en
/// [ChequeFilaEntity], que envuelve a esta.
///
/// Los nombres son los de la columna, tambien los raros: `nrocheque` va todo en
/// minuscula y `aOrdenDe` con la A minuscula.
class ChequeEntity {
  static const String pendiente = 'PEN';
  static const String cerrado = 'CER';

  /// PK, IDENTITY. Cero en un cheque que todavia no se guardo.
  final BigInt codCheque;

  final String nrocheque;

  /// CardCode del cliente en SAP. No hay FK: SAP es otra base.
  final String? codCliente;

  final String? aOrdenDe;

  /// Columna DATE: sin hora.
  final DateTime? fechaCheque;

  /// Columna DATE. Solo cambia con la accion «Fecha Cobro» o el formulario de
  /// administrador.
  final DateTime? fechaCobrar;

  /// `float` en la base: puede traer error de punto flotante. Se redondea al
  /// mostrar.
  final double? monto;

  /// Codigo del catalogo de monedas (v_tipos grupo 24).
  final String? moneda;

  /// Codigo del catalogo de tipos (v_tipos grupo 21). En la base de prueba la
  /// mayoria esta corrupto (bytes crudos dentro de un nvarchar): no asumir que
  /// es PAG o RES.
  final String? tipo;

  /// PEN o CER (v_tipos grupo 23).
  final String? estado;

  final int? codBanco;

  /// 0 = lo dejo el cliente; si no, el empleado (jefe de cobranzas, cobrador o
  /// chofer). El legacy escribe 0, nunca NULL.
  final int? codEmpleado;

  /// «0» cuando no hay recibo manual.
  final String? reciboManual;

  /// `bigint` en la base.
  final int? codSucursal;

  /// `bigint` en la base. Lo calcula el procedimiento: maximo de la sucursal + 1.
  final int? nroRecibo;

  /// «0» cuando no hay talonario.
  final String? nroTalonario;

  final int? codEmpresa;

  /// Solo lectura: el backend lo toma del token.
  final int? audUsuario;

  /// `datetimeoffset` como texto, por ejemplo
  /// «2026-08-31 14:54:51.5670000 +00:00». No es una fecha ISO: no se parsea.
  final String? audFecha;

  const ChequeEntity({
    required this.codCheque,
    required this.nrocheque,
    required this.codCliente,
    required this.aOrdenDe,
    required this.fechaCheque,
    required this.fechaCobrar,
    required this.monto,
    required this.moneda,
    required this.tipo,
    required this.estado,
    required this.codBanco,
    required this.codEmpleado,
    required this.reciboManual,
    required this.codSucursal,
    required this.nroRecibo,
    required this.nroTalonario,
    required this.codEmpresa,
    required this.audUsuario,
    required this.audFecha,
  });

  bool get esNuevo => codCheque == BigInt.zero;

  /// Compara el codigo sin espacios: la columna es varchar y el legacy compara
  /// con `equals`, pero un espacio de mas no debe abrir un cheque cerrado.
  bool get estaCerrado => (estado ?? '').trim() == cerrado;

  bool get estaPendiente => (estado ?? '').trim() == pendiente;

  /// Lo entrego el cliente en persona (codEmpleado 0).
  bool get loEntregoElCliente => codEmpleado == 0;

  /// Sin recibo manual: el legacy guarda «0».
  bool get sinReciboManual => (reciboManual ?? '0').trim() == '0';

  /// Sin talonario: el legacy guarda «0».
  bool get sinTalonario => (nroTalonario ?? '0').trim() == '0';
}

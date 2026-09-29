// Destino final: lib/domain/entities/cierre_operaciones_entity.dart
//
// La revisión de Cierre de Operaciones: lo que el sistema anterior mostraba en
// el diálogo dlgRevArqueo (WizardTareas.xhtml).
//
// Marcelo (2026-09-11), con ese diálogo a la vista: "Cierre de Operaciones es
// como una revisión de varias tareas para verificar que sí hicieron su trabajo
// los demás empleados: verificar monto entre sistemas, cheques, las tareas
// rutinarias automáticas, caja fuerte, arqueo de caja".
//
// Y ese mismo día, sacando el módulo del menú (archivo SQL 63): "será la tarea
// 'Verificar Cierre de Operaciones' donde está esta pantalla; esa tarea estará
// asignada a un cargo donde verificar cada sección si se cumplió, y tiene que
// revisar TODO; una vez que revise todo, recién se completa".
//
// De ahí las dos reglas de esta pantalla: **la tarea es el permiso** — quien
// tiene la ocurrencia del día ve y marca las cinco secciones, sin depender de
// los botones de la vista 78 — y **no se cierra hasta revisar todo**.

/// Con qué tarea se abrió la revisión. Decide cómo se cierra.
///
/// El sistema anterior usaba el mismo diálogo para las dos tareas de la cadena
/// y solo cambiaba el botón de abajo. Marcar, en cambio, ahora se puede en las
/// dos: la que revisa tiene que poder dejar constancia de lo que revisó.
enum ModoCierre {
  /// Cierre de Operaciones (2) y "Verficar Arqueo de Caja" (3), idATR 3:
  /// cierran su propia ocurrencia.
  cierre,

  /// "Verificar Cierre de Operaciones" (39), idATR 5: cierra las ocurrencias
  /// de todos para ese día. Es la que genera el Job y la que se usa.
  verificacion;

  /// El tipo de tarea, para la insignia de la pantalla.
  int get idATR => this == cierre ? 3 : 5;
}

/// Las secciones de la revisión, en el orden del diálogo del sistema anterior.
enum PanelCierre { arqueos, traspasos, cajaFuerte, cheques, tareas }

/// Un arqueo de caja del día que se revisa.
class ArqueoDelCierre {
  final int idAC;
  final DateTime? fecha;
  final String? hora;
  final String encargado;
  final String? sucursal;
  final String? tarea;
  final double saldoSap;
  final double total;

  /// Sobrante (positivo) o faltante (negativo).
  final double diferencia;
  final String? obs;

  /// Si ya tiene el visto bueno del supervisor.
  final bool revisado;

  const ArqueoDelCierre({
    required this.idAC,
    this.fecha,
    this.hora,
    required this.encargado,
    this.sucursal,
    this.tarea,
    this.saldoSap = 0,
    this.total = 0,
    this.diferencia = 0,
    this.obs,
    this.revisado = false,
  });

  bool get cuadra => diferencia.abs() <= 0.01;

  ArqueoDelCierre comoRevisado() => ArqueoDelCierre(
    idAC: idAC,
    fecha: fecha,
    hora: hora,
    encargado: encargado,
    sucursal: sucursal,
    tarea: tarea,
    saldoSap: saldoSap,
    total: total,
    diferencia: diferencia,
    obs: obs,
    revisado: true,
  );
}

/// Una llegada a caja fuerte del día que se revisa.
class LlegadaDelCierre {
  final int idRp;
  final DateTime? hora;
  final String? persona;
  final String? cliente;

  /// Como la guarda la base: 'BS' o 'USD'.
  final String? moneda;
  final double importe;
  final String? destino;
  final String? tipo;
  final String? sucursal;
  final String? obs;
  final bool verificada;

  const LlegadaDelCierre({
    required this.idRp,
    this.hora,
    this.persona,
    this.cliente,
    this.moneda,
    this.importe = 0,
    this.destino,
    this.tipo,
    this.sucursal,
    this.obs,
    this.verificada = false,
  });

  LlegadaDelCierre comoVerificada() => LlegadaDelCierre(
    idRp: idRp,
    hora: hora,
    persona: persona,
    cliente: cliente,
    moneda: moneda,
    importe: importe,
    destino: destino,
    tipo: tipo,
    sucursal: sucursal,
    obs: obs,
    verificada: true,
  );
}

/// Lo que encontró el cruce de un cheque contra SAP.
enum ResultadoCheque {
  /// SAP lo tiene cobrado ese mismo día.
  cobrado('Cobrado'),

  /// SAP lo tiene cobrado, pero registrado en otra fecha.
  otraFecha('Cobrado con otra fecha'),

  /// Está en Bosque y SAP no lo tiene cobrado.
  sinCobrar('Sin cobrar'),

  /// SAP lo cobró ese día y en Bosque salió con una fecha anterior.
  salidaAnterior('Salió con fecha anterior'),

  /// SAP lo cobró ese día y en Bosque no está.
  sinRegistro('Sin registro en Bosque'),

  otro('Otro');

  const ResultadoCheque(this.etiqueta);
  final String etiqueta;

  /// Los textos exactos de p_SAP_Rpt_ImpChequesPR 'A'.
  static ResultadoCheque desdeTexto(String? texto) => switch ((texto ?? '')
      .trim()
      .toUpperCase()) {
    'COBRADO' => cobrado,
    'COBRADO, CON OTRA FECHA' => otraFecha,
    'SIN COBRAR' => sinCobrar,
    'COBRADO - SALIDA CON FECHA ANTERIOR' => salidaAnterior,
    'SIN REGISTRO BOSQUE' => sinRegistro,
    _ => otro,
  };
}

/// Un cheque del día, cruzado contra SAP.
class ChequeDelCierre {
  final String nroCheque;
  final String? codCliente;
  final String? cliente;
  final double monto;

  /// 'BS', 'USD', o "--" cuando el cheque no está en Bosque.
  final String? moneda;
  final String? empresa;

  /// El texto tal como lo devuelve el SP, por si aparece uno nuevo.
  final String? textoResultado;

  const ChequeDelCierre({
    required this.nroCheque,
    this.codCliente,
    this.cliente,
    this.monto = 0,
    this.moneda,
    this.empresa,
    this.textoResultado,
  });

  ResultadoCheque get resultado => ResultadoCheque.desdeTexto(textoResultado);

  /// Lo que no es "cobrado ese día" merece una mirada.
  bool get paraRevisar => resultado != ResultadoCheque.cobrado;
}

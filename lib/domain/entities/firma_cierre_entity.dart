// Destino final: lib/domain/entities/firma_cierre_entity.dart
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';

/// Verificar Cierre por responsables (archivo SQL 81): la 39 es una sola tarea
/// que hacen varios. Cada uno firma las celdas que la matriz le asigna: una
/// sección de una sucursal (o de toda la empresa) en el día que revisa.

/// El código de cada sección en SQL.
extension CodigoSeccion on PanelCierre {
  String get codigo => switch (this) {
    PanelCierre.arqueos => 'A',
    PanelCierre.cajaFuerte => 'F',
    PanelCierre.traspasos => 'T',
    PanelCierre.cheques => 'C',
    PanelCierre.tareas => 'R',
  };

  static PanelCierre? deCodigo(String? codigo) => switch (codigo?.trim()) {
    'A' => PanelCierre.arqueos,
    'F' => PanelCierre.cajaFuerte,
    'T' => PanelCierre.traspasos,
    'C' => PanelCierre.cheques,
    'R' => PanelCierre.tareas,
    _ => null,
  };
}

/// Una celda que le toca a quien abrió su tarea 39, con su firma si la tiene.
class CeldaCierre {
  /// El panel programado; null en una sección con fuente (archivo SQL 86).
  final PanelCierre? seccion;

  /// El código de la sección en SQL (A, F, T, C, R o el de una nueva).
  final String codigo;
  final String nombreSeccion;

  /// Qué revisar, del catálogo de secciones.
  final String? queRevisar;

  /// Con fuente: si cada fila se marca como revisada.
  final bool marcaPorFila;

  /// Null = toda la empresa (traspasos, cheques, tareas del día).
  final int? codSucursal;
  final String nombreSucursal;
  final DateTime fechaRevisada;
  final bool puedeAutorrevisar;

  final int? idFC;
  final String? firmadoPor;
  final DateTime? fechaFirma;
  final int? filas;
  final int? filasRevisadas;
  final int? hallazgos;
  final String? obs;

  /// Sin firma: si lleva el botón Firmar. Arqueos y caja fuerte se firman
  /// solos con la última marca; lo decide el servidor.
  final bool conBoton;

  /// Sin firma: en qué está, en palabras del servidor.
  final String? detalle;

  const CeldaCierre({
    required this.seccion,
    required this.codigo,
    required this.nombreSeccion,
    this.queRevisar,
    this.marcaPorFila = true,
    this.codSucursal,
    required this.nombreSucursal,
    required this.fechaRevisada,
    this.puedeAutorrevisar = false,
    this.idFC,
    this.firmadoPor,
    this.fechaFirma,
    this.filas,
    this.filasRevisadas,
    this.hallazgos,
    this.obs,
    this.conBoton = true,
    this.detalle,
  });

  bool get firmada => idFC != null;

  /// Para no mandar dos veces la misma firma.
  String get clave => '$codigo|${codSucursal ?? 'E'}';

  /// Una sección nueva: sus filas salen de una fuente de otro módulo.
  bool get conFuente => seccion == null;
}

/// Una fila de una sección con fuente (archivo SQL 86): lo que devuelve la
/// consulta del módulo, con su marca. [codSucursalCelda] es la celda de la que
/// salió, para marcarla.
class FilaSeccion {
  final String clave;
  final int? codSucursalCelda;
  final String? nombreSucursal;
  final DateTime? fecha;
  final String titulo;
  final String? detalle;
  final double? monto;
  final bool hallazgo;
  final String? motivo;
  final bool revisada;
  final String? revisadaPor;
  final bool esPropia;

  const FilaSeccion({
    required this.clave,
    this.codSucursalCelda,
    this.nombreSucursal,
    this.fecha,
    required this.titulo,
    this.detalle,
    this.monto,
    this.hallazgo = false,
    this.motivo,
    this.revisada = false,
    this.revisadaPor,
    this.esPropia = false,
  });

  FilaSeccion conMarca(bool marca) => FilaSeccion(
    clave: clave,
    codSucursalCelda: codSucursalCelda,
    nombreSucursal: nombreSucursal,
    fecha: fecha,
    titulo: titulo,
    detalle: detalle,
    monto: monto,
    hallazgo: hallazgo,
    motivo: motivo,
    revisada: marca,
    revisadaPor: marca ? revisadaPor : null,
    esPropia: esPropia,
  );

  /// Para el estado "guardando" de la fila.
  String get id => '${codSucursalCelda ?? 'E'}|$clave';
}

/// Cómo quedó una celda en el tablero. Lo calcula el SP.
enum EstadoCelda {
  aTiempo('A tiempo'),
  tarde('Tarde'),
  sinFirmar('Sin firmar'),
  pendiente('Pendiente');

  final String etiqueta;
  const EstadoCelda(this.etiqueta);

  static EstadoCelda deTexto(String? texto) => EstadoCelda.values.firstWhere(
    (e) => e.etiqueta == texto?.trim(),
    orElse: () => EstadoCelda.pendiente,
  );
}

/// Una celda del tablero en un día.
class CeldaTablero {
  final DateTime fechaTarea;
  final DateTime fechaRevisada;

  /// Null en una sección con fuente (archivo SQL 86).
  final PanelCierre? seccion;
  final String nombreSeccion;
  final String nombreSucursal;
  final EstadoCelda estado;
  final String? firmadoPor;
  final DateTime? fechaFirma;
  final int? filas;
  final int? filasRevisadas;
  final int? autorrevisadas;
  final int? hallazgos;
  final String? obs;
  final String? responsables;

  /// Tu Verificar Cierre que revisa ese día: desde ella se firma (archivo SQL
  /// 108). Null si ese día no tenías la tarea.
  final int? idBitTarea;

  const CeldaTablero({
    required this.fechaTarea,
    required this.fechaRevisada,
    required this.seccion,
    required this.nombreSeccion,
    required this.nombreSucursal,
    required this.estado,
    this.firmadoPor,
    this.fechaFirma,
    this.filas,
    this.filasRevisadas,
    this.autorrevisadas,
    this.hallazgos,
    this.obs,
    this.responsables,
    this.idBitTarea,
  });

  bool get sinFirma =>
      estado == EstadoCelda.pendiente || estado == EstadoCelda.sinFirmar;
}

/// El cumplimiento de una persona en el rango del tablero.
class ResumenCierrePersona {
  final int codEmpleado;
  final String persona;
  final int leTocaban;
  final int hechasATiempo;
  final int hechasTarde;

  /// Celdas compartidas que firmó otro responsable.
  final int porOtro;
  final int noHechas;
  final int pendientes;
  final int autorrevisadas;
  final int hallazgos;

  const ResumenCierrePersona({
    required this.codEmpleado,
    required this.persona,
    required this.leTocaban,
    required this.hechasATiempo,
    required this.hechasTarde,
    required this.porOtro,
    required this.noHechas,
    required this.pendientes,
    required this.autorrevisadas,
    required this.hallazgos,
  });
}

// Destino final: lib/data/models/firma_cierre_model.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';

/// Lectura de las celdas, el tablero y el resumen de Verificar Cierre
/// (p_list_tac_FirmaCierre M, K y P, archivo SQL 81).
class FirmaCierreModel {
  FirmaCierreModel._();

  static int? _int(dynamic v) => (v as num?)?.toInt();

  static String? _texto(dynamic v) {
    final s = (v as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Null = una sección con fuente (archivo SQL 86): no tiene panel programado.
  static PanelCierre? _seccion(dynamic v, {dynamic propia}) =>
      _int(propia) == 0 ? null : CodigoSeccion.deCodigo(v as String?);

  static CeldaCierre celda(Map<String, dynamic> j) => CeldaCierre(
    seccion: _seccion(j['seccion'], propia: j['propia']),
    codigo: _texto(j['seccion']) ?? '?',
    nombreSeccion: _texto(j['nombreSeccion']) ?? '',
    queRevisar: _texto(j['queRevisar']),
    marcaPorFila: _int(j['marcaPorFila']) != 0,
    codSucursal: _int(j['codSucursal']),
    nombreSucursal: _texto(j['nombreSucursal']) ?? 'Toda la empresa',
    fechaRevisada: soloFecha(j['fechaRevisada']) ?? DateTime(1900),
    puedeAutorrevisar: _int(j['puedeAutorrevisar']) == 1,
    idFC: _int(j['idFC']),
    firmadoPor: _texto(j['firmadoPor']),
    fechaFirma: fechaHora(j['fechaFirma']),
    filas: _int(j['filas']),
    filasRevisadas: _int(j['filasRevisadas']),
    hallazgos: _int(j['hallazgos']),
    obs: _texto(j['obs']),
    // Un servidor sin el dato deja el botón, como antes.
    conBoton: _int(j['conBoton']) != 0,
    detalle: _texto(j['detalle']),
  );

  static CeldaTablero tablero(Map<String, dynamic> j) => CeldaTablero(
    fechaTarea: soloFecha(j['fechaTarea']) ?? DateTime(1900),
    fechaRevisada: soloFecha(j['fechaRevisada']) ?? DateTime(1900),
    seccion: _seccion(j['seccion']),
    nombreSeccion: _texto(j['nombreSeccion']) ?? '',
    nombreSucursal: _texto(j['nombreSucursal']) ?? 'Toda la empresa',
    estado: EstadoCelda.deTexto(j['estado'] as String?),
    firmadoPor: _texto(j['firmadoPor']),
    fechaFirma: fechaHora(j['fechaFirma']),
    filas: _int(j['filas']),
    filasRevisadas: _int(j['filasRevisadas']),
    autorrevisadas: _int(j['autorrevisadas']),
    hallazgos: _int(j['hallazgos']),
    obs: _texto(j['obs']),
    responsables: _texto(j['responsables']),
    idBitTarea: _int(j['idBitTarea']),
  );

  /// Una fila de una sección con fuente (p_list_tac_FirmaCierre G).
  static FilaSeccion fila(Map<String, dynamic> j, {int? codSucursalCelda}) =>
      FilaSeccion(
        clave: (j['clave'] ?? '').toString().trim(),
        codSucursalCelda: codSucursalCelda,
        nombreSucursal: _texto(j['nombreSucursal']),
        fecha: soloFecha(j['fecha']),
        titulo: _texto(j['titulo']) ?? '—',
        detalle: _texto(j['detalle']),
        monto: (j['monto'] as num?)?.toDouble(),
        hallazgo: _int(j['hallazgo']) == 1,
        motivo: _texto(j['motivo']),
        revisada: _int(j['revisada']) == 1,
        revisadaPor: _texto(j['nombreRevisadaPor']),
        esPropia: _int(j['esPropia']) == 1,
      );

  static ResumenCierrePersona resumen(Map<String, dynamic> j) =>
      ResumenCierrePersona(
        codEmpleado: _int(j['codEmpleado']) ?? 0,
        persona: _texto(j['persona']) ?? '—',
        leTocaban: _int(j['leTocaban']) ?? 0,
        hechasATiempo: _int(j['hechasATiempo']) ?? 0,
        hechasTarde: _int(j['hechasTarde']) ?? 0,
        porOtro: _int(j['porOtro']) ?? 0,
        noHechas: _int(j['noHechas']) ?? 0,
        pendientes: _int(j['pendientes']) ?? 0,
        autorrevisadas: _int(j['autorrevisadas']) ?? 0,
        hallazgos: _int(j['hallazgos']) ?? 0,
      );
}

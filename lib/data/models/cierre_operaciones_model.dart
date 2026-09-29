// Destino final: lib/data/models/cierre_operaciones_model.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';

/// Lectura de los paneles de la revisión de Cierre de Operaciones.
///
/// Arqueos y llegadas llegan como filas sueltas (el backend las pasa por
/// `ejecutarListadoDinamico`, sin DTO): las claves son los alias de las ramas
/// B de p_list_tac_ArqueoCajaSucursales y p_list_tac_Llegada. Los cheques,
/// los de p_SAP_Rpt_ImpChequesPR 'A' a través de ChequeCierreDto.
class CierreOperacionesModel {
  CierreOperacionesModel._();

  static int? _int(dynamic v) => (v as num?)?.toInt();

  static double _double(dynamic v) => (v as num?)?.toDouble() ?? 0;

  static String? _texto(dynamic v) {
    final s = (v as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static ArqueoDelCierre arqueo(Map<String, dynamic> j) => ArqueoDelCierre(
    idAC: _int(j['idAC']) ?? 0,
    fecha: soloFecha(j['fecha']),
    hora: _texto(j['hora']),
    encargado: _texto(j['nombreCompletoEncargado']) ?? 'Encargado sin nombre',
    sucursal: _texto(j['nombreSucursal']),
    tarea: _texto(j['nombreTarea']),
    saldoSap: _double(j['saldoMovSap']),
    total: _double(j['total']),
    diferencia: _double(j['diferencia']),
    obs: _texto(j['obs']),
    revisado: _int(j['fueRevisado']) == 1,
  );

  static LlegadaDelCierre llegada(Map<String, dynamic> j) => LlegadaDelCierre(
    idRp: _int(j['idRp']) ?? 0,
    hora: fechaHora(j['horallegada']),
    persona: _texto(j['persona']),
    cliente: _texto(j['cliente']),
    moneda: _texto(j['moneda']),
    importe: _double(j['importe']),
    destino: _texto(j['destino']),
    tipo: _texto(j['tipo']),
    sucursal: _texto(j['nombreSucursal']),
    obs: _texto(j['obs']),
    verificada: _int(j['fueVerificado']) == 1,
  );

  static ChequeDelCierre cheque(Map<String, dynamic> j) => ChequeDelCierre(
    nroCheque: _texto(j['nroCheque']) ?? '—',
    codCliente: _texto(j['codCliente']),
    cliente: _texto(j['cardName']),
    monto: _double(j['monto']),
    moneda: _texto(j['moneda']),
    empresa: _texto(j['nombre']),
    textoResultado: _texto(j['resultado']),
  );
}

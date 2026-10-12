import 'package:bosque_flutter/domain/entities/talonario_caja_chica_entity.dart';

int? _int(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

String _texto(dynamic v) => v == null ? '' : v.toString().trim();

/// Una fila de `p_list_tac_CajaChica` 'V'.
TalonarioCajaChica talonarioCajaChicaDeJson(Map<String, dynamic> j) =>
    TalonarioCajaChica(
      codTalonario: _int(j['codTalonario']) ?? 0,
      nroTalonario: _texto(j['nroTalonario']),
      desde: _int(j['numeracionInicial']) ?? 0,
      hasta: _int(j['numeracionFinal']) ?? 0,
      usados: _int(j['usados']) ?? 0,
      libres: _int(j['libres']) ?? 0,
      siguienteVale: _int(j['siguienteVale']),
      // El BIT llega como true/false o como 1/0 según el driver.
      activo: j['activo'] == true || _int(j['activo']) == 1,
      titular: _texto(j['titular']),
    );

/// La fila de `p_list_tac_CajaChica` 'G'.
ReglasReciboCajaChica reglasReciboDeJson(Map<String, dynamic> j) =>
    ReglasReciboCajaChica(
      titulo: _texto(j['titulo']),
      regla: _texto(j['regla']),
      obligatorio:
          j['reciboObligatorio'] == true || _int(j['reciboObligatorio']) == 1,
    );

/// Una fila de `p_list_tac_CajaChica` 'T'.
ValeCajaChica valeCajaChicaDeJson(Map<String, dynamic> j) => ValeCajaChica(
  numVale: _int(j['numVale']) ?? 0,
  // El BIT llega como true/false o como 1/0 según el driver.
  usado: j['usado'] == true || _int(j['usado']) == 1,
  fecha: j['fecha'] == null ? null : DateTime.tryParse(j['fecha'].toString()),
  nombreSucursal: _texto(j['nombreSucursal']),
  lote: _int(j['lote']),
  monto: (j['montoEg'] as num?)?.toDouble(),
  descripcion: _texto(j['descripcion']),
  entregadoA: _texto(j['nombreEmpDestino']),
);

import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';

/// Filtro de una bandeja paginada por el servidor. Lo nulo no viaja: el SP
/// aplica sus valores por defecto. [pagina] parte en 1.
typedef FiltroReportesHex =
    ({
      DateTime? desde,
      DateTime? hasta,
      String? estado,
      int pagina,
      int tamano,
    });

/// Reportes de horas extra: mis horas, revisión del encargado y aprobación del
/// jefe de área. Quién llama lo decide el backend por el token; aquí solo viaja
/// el id de lo que se toca.
abstract class HexReporteRepository {
  Future<HexLeyendaCodigosEntity?> leyendaCodigos();

  Future<PaginaHex<HexReporteEntity>> misReportes(FiltroReportesHex f);

  /// La hora la pone el SP. Desde D37 no hay confirmación: una salida ya
  /// registrada responde 409 y la tecla la habilita o no [hoy]. D41: sin
  /// motivo, que el SP toma de la asignación.
  Future<HexRespuesta> marcar({
    required String tipoMarca,
    required PosicionHex posicion,
  });

  /// D37: si «Mis horas extras» está habilitada y qué teclas de marcar valen
  /// ahora; nulo si el SP respondió 204. El actor sale del token.
  Future<HexVistaMarcacionEntity?> hoy();

  /// Solo cambia el motivo: las horas se pagan siempre en dinero.
  Future<HexRespuesta> actualizar({required BigInt idReporte, String? motivo});

  Future<HexRespuesta> anular({required BigInt idReporte, String? observacion});

  Future<HexReporteEntity?> detalle(BigInt idReporte);

  Future<List<HexReporteLineaEntity>> lineas(BigInt idReporte);

  /// Los segmentos de tiempo del reporte en orden (D36); vacío si el SP
  /// respondió 204.
  Future<List<HexReporteTramoEntity>> tramos(BigInt idReporte);

  Future<List<HexReporteEventoEntity>> historial(BigInt idReporte);

  /// Lo que el SP revisa antes de una marca, en su orden; vacío si respondió
  /// 204. El actor sale del token: el cuerpo va vacío.
  Future<List<HexRequisitoMarcaEntity>> requisitosMarca();

  Future<HexRolesEntity?> misRoles();

  Future<PaginaHex<HexReporteEntity>> bandejaEncargado(FiltroReportesHex f);

  /// [inicio] y [fin] son hora de reloj de La Paz; lo nulo no se corrige.
  Future<HexRespuesta> corregirHora({
    required BigInt idReporte,
    DateTime? inicio,
    DateTime? fin,
    required String observacion,
  });

  /// Sin salida marcada el SP responde [ConfirmacionHex] (adenda D37);
  /// [confirmado] solo vale `true` en el reenvío del mismo cuerpo.
  Future<HexRespuesta> vistoBueno({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  });

  Future<HexRespuesta> rechazarEncargado({
    required BigInt idReporte,
    required String observacion,
  });

  /// D43: jornadas pasadas sin reporte que el actor puede registrar; vacío
  /// (204) si la regularización está cerrada o no hay ninguna.
  Future<List<HexJornadaPasadaEntity>> jornadasPasadas();

  /// D43: crea el reporte de un día pasado sin marca; `id` es el reporte.
  Future<HexRespuesta> crearReportePasado(HexReportePasadoEntity reporte);

  Future<PaginaHex<HexReporteEntity>> bandejaJefe(FiltroReportesHex f);

  /// D45: la bandeja de solo lectura del observador, de todos los estados
  /// (`estado` nulo = todos). Mismas filas que [bandejaJefe].
  Future<PaginaHex<HexReporteEntity>> bandejaObservador(FiltroReportesHex f);

  /// Como [vistoBueno]: la aprobación directa sin salida marcada se confirma.
  Future<HexRespuesta> aprobar({
    required BigInt idReporte,
    String? observacion,
    bool confirmado = false,
  });

  /// Aprueba todo lo que el SP encuentre del encargado en ese mes, también lo
  /// que la bandeja paginada no muestra. `id` es la cantidad aprobada.
  Future<HexRespuesta> aprobarGrupo({
    required BigInt codEncargado,
    required int anio,
    required int mes,
    String? observacion,
  });

  Future<HexRespuesta> rechazarJefe({
    required BigInt idReporte,
    required String observacion,
  });
}

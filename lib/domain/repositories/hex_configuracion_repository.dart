import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Filtro de la bitácora de configuración. [entidad] siempre viaja (vacía, el
/// SP la leería como «todas»); lo nulo no viaja. [pagina] parte en 1.
typedef FiltroHistorialHex =
    ({
      String entidad,
      BigInt? idRegistro,
      DateTime? desde,
      DateTime? hasta,
      int pagina,
      int tamano,
    });

/// Filtro de la lista de aprobadores; lo nulo no filtra. Sin sucursal (D34):
/// el rol cubre la rama entera.
typedef FiltroAprobadoresHex = ({BigInt? codEmpleado, int? nivel});

/// Lo que pide el simulador; sin [inicio] o [fin] los decide el SP.
typedef FiltroSimulacionHex =
    ({
      BigInt codEmpleado,
      DateTime fechaJornada,
      DateTime? inicio,
      DateTime? fin,
    });

/// Parámetros, tramos, comidas y aprobadores del módulo. Nada se pisa: un
/// cambio de valor es una vigencia nueva con la fila completa. Solo la leyenda
/// se edita en su lugar y solo se elimina lo que el SP deja eliminar.
abstract class HexConfiguracionRepository {
  Future<List<HexParametroEntity>> parametros({String? clave});

  /// [p] se arma con `nuevaVigencia()` de la fila anterior.
  Future<HexRespuesta> nuevaVigenciaParametro(HexParametroEntity p);

  Future<HexRespuesta> editarLeyendaParametro(BigInt id, String leyenda);

  Future<HexRespuesta> eliminarParametro(BigInt id);

  /// Las claves que usa el módulo, con el aviso de las obligatorias sin valor.
  Future<List<HexParametroClaveEntity>> catalogoParametros();

  /// Los valores para elegir de una lista de una clave con `conOpciones`.
  Future<List<HexParametroOpcionEntity>> opcionesParametro(String clave);

  /// [sinUsoDesde] es el primer día sin el parámetro; el SP valida el resto.
  Future<HexRespuesta> dejarDeUsarParametro(
    BigInt idParametro,
    DateTime sinUsoDesde,
  );

  Future<List<HexTramoEntity>> tramos({String? tipoDia, String? codigo});

  /// [t] se arma con `nuevaVigencia()` de la fila anterior. Si deja huecos o
  /// cruces el SP pregunta (`ConfirmacionHex`) y se reenvía con [confirmado].
  Future<HexRespuesta> nuevaVigenciaTramo(
    HexTramoEntity t, {
    bool confirmado = false,
  });

  /// El día 00–24 h por tipo de día en [fecha] (hoy si es nula): tramos,
  /// huecos y cruces. Con tipo, código y horas, incluye esa propuesta.
  Future<List<HexTramoMapaEntity>> mapaTramos({
    String? tipoDia,
    DateTime? fecha,
    String? codigo,
    String? horaDesde,
    String? horaHasta,
  });

  /// Simula la jornada sin guardar nada. Sin [inicio] o [fin], los decide el
  /// SP (biométrico, reporte u horario) y los devuelve en la jornada.
  Future<HexSimulacionEntity> simularJornada({
    required BigInt codEmpleado,
    required DateTime fechaJornada,
    DateTime? inicio,
    DateTime? fin,
  });

  Future<HexRespuesta> editarLeyendaTramo(BigInt id, String leyenda);

  Future<HexRespuesta> eliminarTramo(BigInt id);

  Future<List<HexComidaEntity>> comidas({String? codigo});

  /// [c] se arma con `nuevaVigencia()` de la fila anterior.
  Future<HexRespuesta> nuevaVigenciaComida(HexComidaEntity c);

  /// D40: otra configuración de [c] solo entre `vigenteDesde` y [hasta] (sin
  /// [hasta], sin fin), también hacia atrás. El SP parte la historia y avisa
  /// qué reportes ya se pagaron.
  Future<HexRespuesta> periodoComida(HexComidaEntity c, {DateTime? hasta});

  /// Lo nulo no se toca: la leyenda simple y la doble se editan por separado.
  Future<HexRespuesta> editarLeyendaComida(
    BigInt id, {
    String? leyenda,
    String? leyendaDoble,
  });

  Future<HexRespuesta> eliminarComida(BigInt id);

  Future<List<HexAprobadorEntity>> aprobadores({
    BigInt? codEmpleado,
    int? nivel,
  });

  /// Los empleados activos de la rama de [codEmpleado] (el aprobador que se
  /// consulta, no quien llama) y quién firma a cada uno.
  Future<List<HexRamaEmpleadoEntity>> ramaAprobador(BigInt codEmpleado);

  /// Quienes tienen rol de encargado vigente o futuro, para asignarlos a un
  /// jefe de área (D35), con su rama y los jefes que ya los aprueban.
  Future<List<HexEncargadoOpcionEntity>> encargadosParaJefe();

  Future<HexRespuesta> asignarAprobador(HexAprobadorEntity a);

  /// Sin [vigenteHasta] la asignación deja de regir hoy.
  Future<HexRespuesta> cerrarAprobador(BigInt id, {DateTime? vigenteHasta});

  Future<HexRespuesta> eliminarAprobador(BigInt id);

  /// Bitácora de una entidad, del cambio más reciente al más antiguo; el
  /// total es el `totalFilas` que repite cada fila.
  Future<PaginaHex<HexConfiguracionEventoEntity>> historial(
    FiltroHistorialHex f,
  );
}

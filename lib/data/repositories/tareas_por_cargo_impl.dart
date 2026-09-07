// Destino final: lib/data/repositories/tareas_por_cargo_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';

/// Repositorio del diálogo admin "Tareas Rutinarias por Cargo" (reemplaza
/// dlgTarFunXCargo de WizardEstOrg.java — solo el lado de Tareas Rutinarias).
/// Devuelve Map crudo en vez de una entidad tipada: el listado es un JOIN de
/// despliegue (tac_tarRuXCargo + tac_tareaRutinaria + tac_frecuencia, ACCION='C'
/// de p_list_tac_TarRuXCargo), no el CRUD estándar de una tabla — mismo
/// criterio que ejecutarListadoDinamico en el backend.
class TareasPorCargoImpl extends BaseApiRepository {
  Future<List<Map<String, dynamic>>> obtenerPorCargo(int codCargo) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarObtenerTareasPorCargo,
      data: {'codCargo': codCargo},
      fromJson: (json) => json,
    );
  }

  /// Crea una tarea rutinaria y la asigna a uno o más cargos, sin
  /// restricción de subárbol (modo admin — el backend lo fuerza server-side,
  /// esto NO es una bandera que viaje desde acá). [cargos]: mapas con
  /// codCargo (obligatorio) y opcionalmente codCargoSucursal/fechaInicio/fechaFin.
  Future<BigInt> registrarPorCargoAdmin({
    required String descripcion,
    required int idFrec,
    int? idArea,
    required DateTime fechaPartida,
    int? idATR,
    required List<Map<String, dynamic>> cargos,
  }) {
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTareaPorCargoAdmin,
      data: {
        'descripcion': descripcion,
        'idFrec': idFrec,
        'idArea': idArea,
        'fechaPartida': fechaPartida.toIso8601String(),
        'idATR': idATR,
        'cargos': cargos,
      },
      errorMessage: 'No se pudo registrar la tarea rutinaria.',
    );
  }
}

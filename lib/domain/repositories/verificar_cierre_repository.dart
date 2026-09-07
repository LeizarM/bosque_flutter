// Destino final: lib/domain/repositories/verificar_cierre_repository.dart
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

abstract class VerificarCierreRepository {
  /// Arqueos/llegadas de HOY, enriquecidos (empleado/sucursal/tarea vía
  /// ACCION='B') — forma dinámica (Map crudo), no un DTO fijo: es un JOIN
  /// de despliegue, igual criterio que el resto de listados enriquecidos
  /// de este módulo (ver p_list_tac_TarRuXCargo ACCION='C').
  /// [todasSucursales]: replica el checkbox real "Mostrar otras
  /// sucursales" (gated por el botón chkSuc en la pantalla).
  Future<List<Map<String, dynamic>>> obtenerArqueosDeHoy(
    int idBitTarea, {
    bool todasSucursales = false,
  });
  Future<List<Map<String, dynamic>>> obtenerLlegadasDeHoy(
    int idBitTarea, {
    bool todasSucursales = false,
  });

  /// El legacy también le muestra los traspasos del día al supervisor
  /// (panel plMovCaja, sin botón de guardar en este rol) — solo lectura,
  /// reutiliza el mismo listado genérico que usa Cierre de Operaciones.
  Future<List<TraspasoMovCajaEntity>> obtenerTraspasosDeHoy();

  Future<void> marcarArqueoRevisado(int idAC);
  Future<void> marcarLlegadaVerificada(int idRp, int fueVerificado);

  /// Devuelve la cantidad de ocurrencias de bitácora cerradas (puede ser
  /// más de una — esta tarea puede tener más de un cargo asignado el mismo
  /// día, y todas se cierran juntas).
  Future<int> confirmar(int idBitTarea);
}

import 'package:bosque_flutter/domain/entities/detalle_resmando_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';

abstract class ResmadoRepository {
  /// Artículos disponibles para resmado (vía /resmado/articulos).
  Future<List<LoteProduccionEntity>> obtenerArticulos();

  /// Grupos de producción (vía /resmado/grupoProduccion).
  Future<List<GrupoProduccionEntity>> obtenerGrupoProduccion();

  /// Lista de empresas (vía /loteProduccion/lst-empresas).
  Future<List<EmpresaEntity>> obtenerEmpresas();

  /// Órdenes de fabricación por empresa (vía /loteProduccion/lstDocNumOrdFabXEmpresa).
  Future<List<LoteProduccionEntity>> obtenerDocNumXEmpresa(int codEmpresa);

  /// Registra la cabecera del resmado.
  Future<bool> registrarResmado(ResmadoEntity resmado);

  /// Registra el detalle del resmado.
  Future<bool> registrarDetalleResmado(List<DetalleResmadoEntity> detalles);

  // ── Ver resmado ────────────────────────────────────────────────────────────

  /// Resmados de un rango de fechas, con grupo, empleado y empresa resueltos.
  Future<List<ResmadoEntity>> obtenerResmados(DateTime desde, DateTime hasta);

  /// Articulos resmados de un resmado.
  Future<List<DetalleResmadoEntity>> obtenerDetalleResmado(int idRes);

  /// Actualiza solo la orden de fabricacion y la empresa de un resmado.
  Future<bool> actualizarOrdenFabricacion(ResmadoEntity resmado);
}

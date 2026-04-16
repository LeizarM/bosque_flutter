import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';

abstract class LoteProduccionRepository {
  /// Retorna el siguiente número de lote para la máquina indicada.
  Future<LoteProduccionEntity?> obtenerNuevoLote(int idMa);

  /// Catálogo general de artículos (ingreso, salida, merma).
  Future<List<LoteProduccionEntity>> obtenerArticulos();

  /// Lista de máquinas de producción.
  Future<List<MaquinaProduccionEntity>> obtenerMaquinas();

  /// Lista de empresas.
  Future<List<EmpresaEntity>> obtenerEmpresas();

  /// Órdenes de fabricación disponibles para una empresa.
  Future<List<LoteProduccionEntity>> obtenerDocNumXEmpresa(int codEmpresa);

  /// Registra la cabecera del lote (INSERT o UPDATE según idLp == 0).
  Future<bool> registrarLoteProduccion(LoteProduccionEntity lote);

  /// Registra los materiales de ingreso.
  Future<bool> registrarMaterialIngreso(List<MaterialIngresoEntity> lista);

  /// Registra los materiales de salida.
  Future<bool> registrarMaterialSalida(List<MaterialSalidaEntity> lista);

  /// Registra la merma.
  Future<bool> registrarMerma(List<MermaEntity> lista);
}

import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';
import 'package:bosque_flutter/data/models/planilla_model.dart';

abstract class PlanillaRepository {
  Future<List<PlanillaEntity>> listarPlanilla({
    required int pagina,
    required int tamanoPagina,
    int? codEmpresa,
    String? estado,
    int? filtroMes,
    int? filtroAnio,
  });

  Future<List<PlanillaDetalleEntity>> listarPlanillaDetalle({
    required int pagina,
    required int tamanoPagina,
    required int codPlanilla,
    String? search,
  });

  Future<PlanillaResponse> generarPlanilla({required int audUsuarioI});

  Future<PlanillaResponse> ejecutarPlanilla();

  Future<List<Map<String, dynamic>>> obtenerPagosBancarios({
    required int mes,
    required int anio,
    required int codBanco,
    int? codEmpresa,
  });
}

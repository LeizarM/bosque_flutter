import 'dart:typed_data';
import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';

abstract class IndemnizacionRepository {
  Future<List<IndemnizacionEntity>> listarIndemnizaciones({
    int? codEmpleado,
    String? buscar,
    String? fechaActual,
    int? codEmpresa,
    int? codArea,
    int? pagina,
    int? tamanoPagina,
  });

  Future<List<IndemnizacionEntity>> listarHistorialIndemnizaciones({
    int? codEmpleado,
    String? buscar,
    String? fechaActual,
    int? codEmpresa,
    int? codArea,
    int? pagina,
    int? tamanoPagina,
  });

  Future<Map<String, dynamic>> abmIndemnizacion({
    required IndemnizacionEntity indemnizacion,
    required int audUsuarioI,
  });

  Future<Uint8List> descargarReportePdf({
    required String endpoint,
    required Map<String, dynamic> params,
  });
}

import 'dart:typed_data';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:bosque_flutter/data/models/prestamo_model.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';

abstract class PrestamoRepository {
  Future<List<PrestamoEntity>> getPrestamosSAP(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    String? fechaDesde,
    String? fechaHasta,
    String? estadoFiltro,
    int? codEmpleado,
  );

  Future<List<PrestamoEntity>> getPrestamosVigentes(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    String? fechaDesde,
    String? fechaHasta,
    String? estadoFiltro,
    int? codEmpleado,
  );

  Future<List<PrestamoEntity>> getPrestamosVigentesPorEmpleado(
    int? codEmpresa,
    String? search,
  );

  Future<double> getTotalPrestamos(
    int? codEmpresa,
    String? fechaDesde,
    String? fechaHasta,
  );

  Future<double> getTotalPrestamosSAP(
    int? codEmpresa,
    String? fechaDesde,
    String? fechaHasta,
  );

  Future<PrestamoResponse> asignarPagos(List<PrestamoDetalleEntity> pagos);

  Future<PrestamoResponse> asignarPrestamosMasivo({
    required PrestamoEntity sapRecord,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    int forzar = 0,
    String? xmlCuotas,
    String? tipoCalculo,
  });

  Future<PrestamoResponse> asignarPagosMasivo({
    required String xmlPagos,
    required int audUsuario,
  });

  Future<PrestamoResponse> crearPrestamoManualMasivo({
    required int codEmpresa,
    required String db,
    required double montoPrestamo,
    required String descripcion,
    required DateTime fechaDesembolso,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    String? tipoCalculo,
  });

  Future<List<PrestamoDetalleEntity>> listarDetallesPrestamo(
    int codPrestamo,
    int mostrarAnulados,
  );

  Future<List<PrestamoEntity>> listarEmpleadosAsignados({
    required int codEmpresa,
    required String db,
    required int transIdSAP,
    int? codPrestamo,
  });
  Future<List<TipoPrestamoEntity>> getEstadosPrestamo();
  Future<List<TipoPrestamoEntity>> getTiposPagoPrestamo();

  Future<Uint8List> getReporteCuotas(int codPrestamo);
  Future<Uint8List> getReportePersonal(Map<String, dynamic> params);
  Future<Uint8List> getReporteMayorGlobalResumido(Map<String, dynamic> params);
  Future<Uint8List> getReporteGlobalDetallado(Map<String, dynamic> params);
  Future<Uint8List> getReporteCortoLargoPlazo(Map<String, dynamic> params);
  Future<Uint8List> getReporteMayorGeneral(Map<String, dynamic> params);

  Future<PrestamoResponse> actualizarCuotaPrestamo({
    required int codPrestDetalle,
    required String tipoPago,
    required DateTime fechaPago,
    required int audUsuario,
    String? estadoCuota,
  });

  // Future<String> asignarPrestamo({
  //   required int codEmpleado,
  //   required double montoPrestamo,
  //   required DateTime fecIniPago,
  //   required int audUsuario,
  //   required int transIdSAP,
  // });

  Future<String> anularPrestamo({
    required int codPrestamo,
    required int audUsuario,
  });

  Future<PrestamoResponse> revertirPagoMasivo({
    required int codPrestDetalle,
    required int audUsuario,
  });

  Future<PrestamoResponse> adelantarCuotaPrestamo({
    required int codPrestamo,
    required double montoPago,
    required DateTime fechaPago,
    required String detalle,
    required int audUsuario,
  });

  Future<PrestamoResponse> editarPrestamoMasivo({
    required int codEmpresa,
    required String db,
    required int transIdSAP,
    required String xmlEmpleados,
    required int audUsuarioI,
    required double montoPrestamo,
    String? descripcion,
    DateTime? fechaDesembolso,
    int forzar = 0,
    String? xmlCuotas,
    String? tipoCalculo,
  });
}

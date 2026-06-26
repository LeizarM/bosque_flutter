import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/asiento_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/canales_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/config_comisiones_banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/log_estados_entity.dart';
import 'package:bosque_flutter/domain/entities/monedas_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_transaccion_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';

abstract class PagosExtranjerosRepository {
  // ══ FASE 1 ─ Solicitud ════════════════════════════════════════════

  /// Crea o actualiza la solicitud completa en una única TX ACID.
  /// Retorna el idSolicitud generado/existente.
  Future<BigInt> guardarSolicitudCompleta(Map<String, dynamic> payload);

  /// Cambia el estado de la solicitud (PENDIENTE → APROBADA, etc.) + log.
  Future<BigInt> aprobarSolicitud(Map<String, dynamic> payload);

  // ══ Aprobación granular ════════════════════════════════════════════
  // Cada cuota (DetalleSolicitud) se aprueba por separado.
  // Cuando todas las cuotas de un proveedor están aprobadas, el backend
  // marca automáticamente al SolicitudProveedor como APROBADO.

  /// Aprueba una cuota individual (DetalleSolicitud).
  /// Payload: { idDetalle, audUsuario }
  Future<BigInt> aprobarCuota(Map<String, dynamic> payload);

  /// Revierte la aprobación de una cuota previamente aprobada.
  /// Payload: { idDetalle, audUsuario }
  Future<BigInt> revertirAprobacionCuota(Map<String, dynamic> payload);

  /// Aprueba manualmente todas las cuotas de un proveedor.
  /// Payload: { idSolicitudProveedor, obsAprobacion, audUsuario }
  Future<BigInt> aprobarProveedor(Map<String, dynamic> payload);

  /// Rechaza un proveedor (queda excluido del cálculo de cotizaciones).
  /// Payload: { idSolicitudProveedor, obsAprobacion, audUsuario }
  Future<BigInt> rechazarProveedor(Map<String, dynamic> payload);

  // ══ FASE 2 ─ Cotización ═════════════════════════════════════════

  /// Registra una cotización con sus cargos en una única TX ACID.
  Future<BigInt> guardarCotizacionCompleta(Map<String, dynamic> payload);

  // ══ FASE 3 ─ Comparativa y elección ══════════════════════════════

  /// Acepta la cotización ganadora. El SP rechaza las demás internamente.
  Future<BigInt> aceptarCotizacion(Map<String, dynamic> payload);

  /// Carga todas las cotizaciones de una solicitud para la comparativa.
  Future<List<CotizacionesEntity>> getCotizacionesPorSolicitud(
    BigInt idSolicitud,
  );

  // ══ FASE 4 ─ Transacción ═════════════════════════════════════════

  /// Registra la transacción con sus cargos en una única TX ACID.
  Future<BigInt> guardarTransaccionCompleta(Map<String, dynamic> payload);

  /// Cambia el estado de la transacción (PENDIENTE → PROCESADO, etc.) + log.
  Future<BigInt> cambiarEstadoTransaccion(Map<String, dynamic> payload);

  /// Carga las transacciones de una solicitud.
  Future<List<TransaccionesEntity>> getTransaccionesPorSolicitud(
    BigInt idSolicitud, {
    int codEmpresa = 0,
  });

  // ══ FASE 5 ─ Confirmación ═════════════════════════════════════════

  /// Confirma el débito y cierra la solicitud como PAGADA en una TX ACID.
  Future<BigInt> confirmarPago(Map<String, dynamic> payload);

  // ══ Lecturas generales ═════════════════════════════════════════════

  Future<List<EmpresaEntity>> getEmpresas();
  Future<List<ProveedorEmpresaEntity>> getProveedoresXEmpresa(int codEmpresa);
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompra(int codEmpresa);
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompraPorProyecto(
    int codEmpresa,
    String project,
  );
  Future<List<SolicitudPagoEntity>> getSolicitudesRegistradas(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codEmpresa,
  );

  /// Obtener solicitudes por empresa (0 = todas).
  Future<List<SolicitudPagoEntity>> getObtenerSolicitudes(int codEmpresa);

  /// Proveedores de una solicitud.
  Future<List<SolicitudProveedorEntity>> getSolicitudProveedores(
    int idSolicitud,
  );

  /// Facturas/detalles de una solicitud.
  Future<List<DetalleSolicitudEntity>> getDetalleSolicitud(int idSolicitud);

  /// Cargos bancarios de una cotización.
  Future<List<CargoPagoEntity>> getCargosCotizacion(int idCotizacion);

  /// Detalle de una transacción individual.
  Future<TransaccionesEntity?> getTransaccion({
    required int idTransaccion,
    required int codEmpresa,
  });

  /// Reporte de transacciones por rango de fechas.
  Future<List<TransaccionesEntity>> getReporteTransaccionesFechas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int codEmpresa,
  });

  /// Cargos de una transacción.
  Future<List<CargoPagoEntity>> getCargosTransaccion(int idTransaccion);

  Future<List<LogEstadosEntity>> getLogPorSolicitud(BigInt idSolicitud);
  Future<List<LogEstadosEntity>> getLogPorTransaccion(BigInt idTransaccion);

  /// Sube un voucher (imagen/PDF) asociado a una transacción.
  /// En móvil se usa [filePath]; en web se usa [fileBytes] + [fileName].
  Future<void> subirVoucher({
    required BigInt idTransaccion,
    required int audUsuario,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  });

  /// Descarga el voucher de una transacción vía POST (envía JWT).
  /// Retorna los bytes crudos y el content-type.
  Future<(Uint8List bytes, String contentType)> descargarVoucher(
    BigInt idTransaccion, {
    int codEmpresa = 0,
  });

  Future<List<LogEstadosEntity>> getTimelineSolicitud(BigInt idSolicitud);

  // ══ Catálogos de lectura (para dropdowns) ══════════════════════════════

  Future<List<CanalesPagoEntity>> getCanalesPago();
  Future<List<MonedasEntity>> getMonedas();
  Future<List<TiposCambioEntity>> getTiposCambioPorBanco(int codBanco);
  Future<List<TiposCargoEntity>> getTiposCargo();
  Future<List<TiposTransaccionEntity>> getTiposTransaccion();
  Future<List<ConfigComisionesBancoEntity>> getConfigComisionesPorBanco(
    int codBanco,
  );

  // ══ Catálogos de escritura ════════════════════════════════════════════─

  Future<BigInt> registrarCanalPago(Map<String, dynamic> payload);
  Future<BigInt> eliminarCanalPago(Map<String, dynamic> payload);
  Future<BigInt> registrarMoneda(Map<String, dynamic> payload);
  Future<BigInt> eliminarMoneda(Map<String, dynamic> payload);
  Future<BigInt> registrarTipoCambio(Map<String, dynamic> payload);
  Future<BigInt> eliminarTipoCambio(Map<String, dynamic> payload);
  Future<BigInt> registrarTipoCargo(Map<String, dynamic> payload);
  Future<BigInt> eliminarTipoCargo(Map<String, dynamic> payload);
  Future<BigInt> registrarTipoTransaccion(Map<String, dynamic> payload);
  Future<BigInt> eliminarTipoTransaccion(Map<String, dynamic> payload);
  Future<BigInt> registrarConfigComisiones(Map<String, dynamic> payload);
  Future<BigInt> eliminarConfigComisiones(Map<String, dynamic> payload);

  /// Corrige SOLO el comprobante de una transacción (N° bancario, fecha valor
  /// y/o voucher), incluso si ya está CONFIRMADA. No reabre el pago.
  /// Payload: { idTransaccion, numeroTransaccion?, fechaValor?, rutaVoucher?, audUsuario }
  Future<BigInt> corregirComprobante(Map<String, dynamic> payload);

  // ══ Asientos contables ════════════════════════════════════════════════════

  Future<BigInt> registrarAsiento(Map<String, dynamic> payload);
  Future<BigInt> eliminarAsiento(Map<String, dynamic> payload);
  Future<List<AsientoEntity>> getAsientosPorTransaccion(BigInt idTransaccion);
  Future<AsientoEntity?> validarCuadreAsientos(BigInt idTransaccion);

  // ══ Participantes (split de transacción) ════════════════════════════════════

  Future<BigInt> registrarParticipante(Map<String, dynamic> payload);
  Future<BigInt> eliminarParticipante(Map<String, dynamic> payload);
  Future<List<TransaccionParticipanteEntity>> getParticipantesPorTransaccion(
    BigInt idTransaccion,
  );
  Future<TransaccionParticipanteEntity?> validarCuadreParticipantes(
    BigInt idTransaccion,
  );
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/asiento_entity.dart';
import 'package:bosque_flutter/data/repositories/registro_empleado_impl.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/canales_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/config_comisiones_banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/log_estados_entity.dart';
import 'package:bosque_flutter/domain/entities/monedas_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_transaccion_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';

// ═══════════════════════════════════════════════════════════════════════
// Modelos auxiliares del formulario (solo para el estado de UI)
// ═══════════════════════════════════════════════════════════════════════

class DetalleFormItem {
  final int idDetalle;
  final String tipoDocumento;
  final String numeroDocumento;
  final int facturaProvSap;
  final String codigoImportacion;
  final double montoFacturaUsd;
  final double montoAmortizadoUsd;
  final double montoAPagarUsd;
  final DateTime fechaFactura;
  final DateTime fechaVencimiento;
  final String concepto;
  final String obs;

  DetalleFormItem({
    this.idDetalle = 0,
    this.tipoDocumento = '',
    this.numeroDocumento = '',
    this.facturaProvSap = 0,
    this.codigoImportacion = '',
    this.montoFacturaUsd = 0.0,
    this.montoAmortizadoUsd = 0.0,
    this.montoAPagarUsd = 0.0,
    DateTime? fechaFactura,
    DateTime? fechaVencimiento,
    this.concepto = '',
    this.obs = '',
  }) : fechaFactura = fechaFactura ?? DateTime.now(),
       fechaVencimiento = fechaVencimiento ?? DateTime.now();

  DetalleFormItem copyWith({
    int? idDetalle,
    String? tipoDocumento,
    String? numeroDocumento,
    int? facturaProvSap,
    String? codigoImportacion,
    double? montoFacturaUsd,
    double? montoAmortizadoUsd,
    double? montoAPagarUsd,
    DateTime? fechaFactura,
    DateTime? fechaVencimiento,
    String? concepto,
    String? obs,
  }) {
    return DetalleFormItem(
      idDetalle: idDetalle ?? this.idDetalle,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      facturaProvSap: facturaProvSap ?? this.facturaProvSap,
      codigoImportacion: codigoImportacion ?? this.codigoImportacion,
      montoFacturaUsd: montoFacturaUsd ?? this.montoFacturaUsd,
      montoAmortizadoUsd: montoAmortizadoUsd ?? this.montoAmortizadoUsd,
      montoAPagarUsd: montoAPagarUsd ?? this.montoAPagarUsd,
      fechaFactura: fechaFactura ?? this.fechaFactura,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      concepto: concepto ?? this.concepto,
      obs: obs ?? this.obs,
    );
  }
}

class ProveedorFormItem {
  final int idSolicitudProveedor;
  final String cardCode;
  final String cardName;
  final String obs;
  final List<DetalleFormItem> detalles;
  final List<int> detallesAEliminar;

  ProveedorFormItem({
    this.idSolicitudProveedor = 0,
    this.cardCode = '',
    this.cardName = '',
    this.obs = '',
    this.detalles = const [],
    this.detallesAEliminar = const [],
  });

  double get totalFacturasUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoFacturaUsd);
  double get totalAmortizadoUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoAmortizadoUsd);
  double get totalAPagarUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoAPagarUsd);

  ProveedorFormItem copyWith({
    int? idSolicitudProveedor,
    String? cardCode,
    String? cardName,
    String? obs,
    List<DetalleFormItem>? detalles,
    List<int>? detallesAEliminar,
  }) {
    return ProveedorFormItem(
      idSolicitudProveedor: idSolicitudProveedor ?? this.idSolicitudProveedor,
      cardCode: cardCode ?? this.cardCode,
      cardName: cardName ?? this.cardName,
      obs: obs ?? this.obs,
      detalles: detalles ?? this.detalles,
      detallesAEliminar: detallesAEliminar ?? this.detallesAEliminar,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Estado principal
// ═══════════════════════════════════════════════════════════════════════

class PagosExtranjerosState {
  final int idSolicitud;
  final List<EmpresaEntity> empresas;
  final EmpresaEntity? empresaSeleccionada;
  final DateTime fechaSolicitud;
  final List<ProveedorFormItem> proveedores;
  final List<int> proveedoresAEliminar;
  final bool cargando;
  final bool cargandoEmpresas;
  final String? mensajeExito;
  final String? mensajeError;

  PagosExtranjerosState({
    this.idSolicitud = 0,
    this.empresas = const [],
    this.empresaSeleccionada,
    DateTime? fechaSolicitud,
    this.proveedores = const [],
    this.proveedoresAEliminar = const [],
    this.cargando = false,
    this.cargandoEmpresas = false,
    this.mensajeExito,
    this.mensajeError,
  }) : fechaSolicitud = fechaSolicitud ?? DateTime.now();

  double get montoTotalSolicitud =>
      proveedores.fold(0.0, (sum, p) => sum + p.totalAPagarUsd);

  PagosExtranjerosState copyWith({
    int? idSolicitud,
    List<EmpresaEntity>? empresas,
    EmpresaEntity? empresaSeleccionada,
    bool clearEmpresa = false,
    DateTime? fechaSolicitud,
    List<ProveedorFormItem>? proveedores,
    List<int>? proveedoresAEliminar,
    bool? cargando,
    bool? cargandoEmpresas,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
  }) {
    return PagosExtranjerosState(
      idSolicitud: idSolicitud ?? this.idSolicitud,
      empresas: empresas ?? this.empresas,
      empresaSeleccionada:
          clearEmpresa
              ? null
              : (empresaSeleccionada ?? this.empresaSeleccionada),
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      proveedores: proveedores ?? this.proveedores,
      proveedoresAEliminar: proveedoresAEliminar ?? this.proveedoresAEliminar,
      cargando: cargando ?? this.cargando,
      cargandoEmpresas: cargandoEmpresas ?? this.cargandoEmpresas,
      mensajeExito:
          clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError:
          clearMensajeError ? null : (mensajeError ?? this.mensajeError),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Notifier
// ═══════════════════════════════════════════════════════════════════════

class PagosExtranjerosNotifier extends StateNotifier<PagosExtranjerosState> {
  final PagosExtranjerosImpl _repo = PagosExtranjerosImpl();
  final Ref ref;

  PagosExtranjerosNotifier(this.ref) : super(PagosExtranjerosState()) {
    _cargarEmpresas();
  }

  // ── Inicialización ──────────────────────────────────────────────────

  Future<void> _cargarEmpresas() async {
    state = state.copyWith(cargandoEmpresas: true);
    try {
      final empresas = await _repo.getEmpresas();
      state = state.copyWith(empresas: empresas, cargandoEmpresas: false);
    } catch (e) {
      console('Error cargando empresas pagos extranjeros: $e');
      state = state.copyWith(cargandoEmpresas: false);
    }
  }

  // ── Datos cabecera ───────────────────────────────────────────────────

  void setEmpresa(EmpresaEntity empresa) {
    // Si la empresa cambia, borrar todos los proveedores y las listas de eliminación
    final cambioEmpresa =
        state.empresaSeleccionada?.codEmpresa != empresa.codEmpresa;
    state = state.copyWith(
      empresaSeleccionada: empresa,
      proveedores: cambioEmpresa ? [] : state.proveedores,
      proveedoresAEliminar: cambioEmpresa ? [] : state.proveedoresAEliminar,
    );
  }

  void setFechaSolicitud(DateTime fecha) {
    state = state.copyWith(fechaSolicitud: fecha);
  }

  // ── Gestión de proveedores ───────────────────────────────────────────

  /// Retorna `true` si se agregó exitosamente, `false` si el proveedor
  /// ya existe en la lista (cardCode duplicado).
  bool agregarProveedor(ProveedorFormItem proveedor) {
    final duplicado = state.proveedores.any(
      (p) =>
          p.cardCode.trim().toUpperCase() ==
          proveedor.cardCode.trim().toUpperCase(),
    );
    if (duplicado) return false;
    state = state.copyWith(proveedores: [...state.proveedores, proveedor]);
    return true;
  }

  /// Retorna `true` si se actualizó, `false` si el nuevo cardCode ya lo
  /// usa otro proveedor de la lista (excluye el propio índice).
  bool actualizarProveedor(int index, ProveedorFormItem proveedor) {
    final duplicado = state.proveedores.asMap().entries.any(
      (e) =>
          e.key != index &&
          e.value.cardCode.trim().toUpperCase() ==
              proveedor.cardCode.trim().toUpperCase(),
    );
    if (duplicado) return false;
    final lista = [...state.proveedores];
    lista[index] = proveedor;
    state = state.copyWith(proveedores: lista);
    return true;
  }

  void eliminarProveedor(int index) {
    final prov = state.proveedores[index];
    final lista = [...state.proveedores];
    lista.removeAt(index);
    final eliminados = [...state.proveedoresAEliminar];
    if (prov.idSolicitudProveedor > 0) {
      eliminados.add(prov.idSolicitudProveedor);
    }
    state = state.copyWith(
      proveedores: lista,
      proveedoresAEliminar: eliminados,
    );
  }

  // ── Gestión de detalles de un proveedor ─────────────────────────────

  void agregarDetalle(int proveedorIndex, DetalleFormItem detalle) {
    final proveedores = [...state.proveedores];
    final prov = proveedores[proveedorIndex];
    proveedores[proveedorIndex] = prov.copyWith(
      detalles: [...prov.detalles, detalle],
    );
    state = state.copyWith(proveedores: proveedores);
  }

  void actualizarDetalle(
    int proveedorIndex,
    int detalleIndex,
    DetalleFormItem detalle,
  ) {
    final proveedores = [...state.proveedores];
    final prov = proveedores[proveedorIndex];
    final detalles = [...prov.detalles];
    detalles[detalleIndex] = detalle;
    proveedores[proveedorIndex] = prov.copyWith(detalles: detalles);
    state = state.copyWith(proveedores: proveedores);
  }

  void eliminarDetalle(int proveedorIndex, int detalleIndex) {
    final proveedores = [...state.proveedores];
    final prov = proveedores[proveedorIndex];
    final det = prov.detalles[detalleIndex];
    final detalles = [...prov.detalles];
    detalles.removeAt(detalleIndex);
    final eliminados = [...prov.detallesAEliminar];
    if (det.idDetalle > 0) {
      eliminados.add(det.idDetalle);
    }
    proveedores[proveedorIndex] = prov.copyWith(
      detalles: detalles,
      detallesAEliminar: eliminados,
    );
    state = state.copyWith(proveedores: proveedores);
  }

  // ── Limpiar mensajes ─────────────────────────────────────────────────

  void limpiarMensajes() {
    state = state.copyWith(clearMensajeExito: true, clearMensajeError: true);
  }

  // ── Reset completo ───────────────────────────────────────────────────

  void resetState() {
    state = PagosExtranjerosState(
      empresas: state.empresas, // conservar lista cargada
    );
  }

  Future<bool> _cambiarEstadoSolicitud({
    required int idSolicitud,
    required int codEmpresa,
    required double montoTotalSolicitud,
    required int audUsuario,
    required String estado,
    required String mensajeExito,
    required String logContext,
  }) async {
    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      await _repo.aprobarSolicitud({
        'idSolicitud': idSolicitud,
        'codEmpresa': codEmpresa,
        'montoTotalSolicitud': montoTotalSolicitud,
        'estado': estado,
        'audUsuario': audUsuario,
      });
      state = state.copyWith(cargando: false, mensajeExito: mensajeExito);
      return true;
    } catch (e) {
      console('Error $logContext solicitud: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Aprobar solicitud (PENDIENTE → APROBADA) ──────────────────────────

  Future<bool> aprobarSolicitud({
    required int idSolicitud,
    required int codEmpresa,
    required double montoTotalSolicitud,
    required int audUsuario,
  }) => _cambiarEstadoSolicitud(
    idSolicitud: idSolicitud,
    codEmpresa: codEmpresa,
    montoTotalSolicitud: montoTotalSolicitud,
    audUsuario: audUsuario,
    estado: 'APROBADA',
    mensajeExito: 'Solicitud aprobada exitosamente.',
    logContext: 'aprobando',
  );

  Future<bool> rechazarSolicitud({
    required int idSolicitud,
    required int codEmpresa,
    required double montoTotalSolicitud,
    required int audUsuario,
  }) => _cambiarEstadoSolicitud(
    idSolicitud: idSolicitud,
    codEmpresa: codEmpresa,
    montoTotalSolicitud: montoTotalSolicitud,
    audUsuario: audUsuario,
    estado: 'RECHAZADA',
    mensajeExito: 'Solicitud rechazada exitosamente.',
    logContext: 'rechazando',
  );

  // ── Guardar solicitud completa (endpoint único transaccional) ────────

  /// Construye el payload completo y lo envía en un único POST transaccional.
  /// [audUsuario] es el código del usuario autenticado.
  Future<bool> guardarSolicitud(int audUsuario) async {
    // Validaciones básicas
    if (state.empresaSeleccionada == null) {
      state = state.copyWith(mensajeError: 'Debe seleccionar una empresa.');
      return false;
    }
    if (state.proveedores.isEmpty) {
      state = state.copyWith(
        mensajeError: 'Debe agregar al menos un proveedor.',
      );
      return false;
    }
    for (int i = 0; i < state.proveedores.length; i++) {
      final prov = state.proveedores[i];
      if (prov.cardCode.trim().isEmpty || prov.cardName.trim().isEmpty) {
        state = state.copyWith(
          mensajeError: 'El proveedor ${i + 1} requiere código y nombre.',
        );
        return false;
      }
      if (prov.detalles.isEmpty) {
        state = state.copyWith(
          mensajeError:
              'El proveedor "${prov.cardName}" necesita al menos una factura.',
        );
        return false;
      }
      for (int j = 0; j < prov.detalles.length; j++) {
        final det = prov.detalles[j];
        if (det.montoAPagarUsd <= 0) {
          state = state.copyWith(
            mensajeError:
                'La factura "${det.facturaProvSap}" del proveedor "${prov.cardName}" tiene monto a pagar inválido.',
          );
          return false;
        }
      }
    }

    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );

    try {
      // Formatea una fecha como "yyyy-MM-ddT00:00:00.000" (sin componente horario)
      String formatDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}T00:00:00.000';

      final payload = <String, dynamic>{
        'idSolicitud': state.idSolicitud,
        'codEmpresa': state.empresaSeleccionada!.codEmpresa,
        'fechaSolicitud': formatDate(state.fechaSolicitud),
        'montoTotalSolicitud': state.montoTotalSolicitud,
        'estado': null, // el backend asigna el estado inicial automáticamente
        'audUsuario': audUsuario,
        'proveedoresAEliminar': state.proveedoresAEliminar,
        'proveedores':
            state.proveedores
                .map(
                  (prov) => {
                    'idSolicitudProveedor': prov.idSolicitudProveedor,
                    'cardCode': prov.cardCode,
                    'cardName': prov.cardName,
                    'totalFacturasUsd': prov.totalFacturasUsd,
                    'totalAmortizadoUsd': prov.totalAmortizadoUsd,
                    'totalAPagarUsd': prov.totalAPagarUsd,
                    'obs': prov.obs,
                    'audUsuario': audUsuario,
                    'detallesAEliminar': prov.detallesAEliminar,
                    'detalles':
                        prov.detalles
                            .map(
                              (det) => {
                                'idDetalle': det.idDetalle,
                                'tipoDocumento': det.tipoDocumento,
                                'numeroDocumento': det.numeroDocumento,
                                'facturaProvSap': det.facturaProvSap,
                                'codigoImportacion': det.codigoImportacion,
                                'montoFacturaUsd': det.montoFacturaUsd,
                                'montoAmortizadoUsd': det.montoAmortizadoUsd,
                                'montoAPagarUsd': det.montoAPagarUsd,
                                'fechaFactura': formatDate(det.fechaFactura),
                                'fechaVencimiento': formatDate(
                                  det.fechaVencimiento,
                                ),
                                'concepto': det.concepto,
                                'obs': det.obs,
                                'audUsuario': audUsuario,
                              },
                            )
                            .toList(),
                  },
                )
                .toList(),
      };

      final idSolicitud = await _repo.guardarSolicitudCompleta(payload);
      console('Solicitud guardada con ID: $idSolicitud');

      state = state.copyWith(
        cargando: false,
        idSolicitud: idSolicitud.toInt(),
        mensajeExito: 'Solicitud registrada exitosamente.',
      );
      return true;
    } catch (e) {
      console('Error en guardarSolicitud: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════════

final pagosExtranjerosProvider =
    StateNotifierProvider<PagosExtranjerosNotifier, PagosExtranjerosState>(
      (ref) => PagosExtranjerosNotifier(ref),
    );

/// Carga la lista de proveedores disponibles para una empresa específica.
/// Se usa en el diálogo de agregar/editar proveedor.
final proveedoresXEmpresaProvider =
    FutureProvider.family<List<ProveedorEmpresaEntity>, int>((
      ref,
      codEmpresa,
    ) async {
      if (codEmpresa <= 0) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getProveedoresXEmpresa(codEmpresa);
    });

/// Carga las facturas de proveedor y órdenes de compra desde SAP
/// filtradas por empresa. Se usa en el diálogo de agregar factura.
final facProvYOrdCompraProvider = FutureProvider.autoDispose
    .family<List<DetalleSolicitudEntity>, int>((ref, codEmpresa) async {
      if (codEmpresa <= 0) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getFacProvYOrdCompra(codEmpresa);
    });

// ═══════════════════════════════════════════════════════════════════════
// Provider para listar solicitudes registradas
// ═══════════════════════════════════════════════════════════════════════

/// Parámetro para el provider de solicitudes registradas.
class FechaRangoParam {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int codEmpresa;

  const FechaRangoParam({
    required this.fechaInicio,
    required this.fechaFin,
    required this.codEmpresa,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FechaRangoParam &&
          other.fechaInicio == fechaInicio &&
          other.fechaFin == fechaFin &&
          other.codEmpresa == codEmpresa;

  @override
  int get hashCode => Object.hash(fechaInicio, fechaFin, codEmpresa);
}

/// Carga las solicitudes de pago registradas filtradas por fecha inicio/fin y empresa.
final solicitudesRegistradasProvider = FutureProvider.autoDispose
    .family<List<SolicitudPagoEntity>, FechaRangoParam>((ref, param) async {
      final repo = PagosExtranjerosImpl();
      return repo.getSolicitudesRegistradas(
        param.fechaInicio,
        param.fechaFin,
        param.codEmpresa,
      );
    });

// ═══════════════════════════════════════════════════════════════════════
// Modelo auxiliar para cargos en cotización / transacción
// ═══════════════════════════════════════════════════════════════════════

class CargoPagoFormItem {
  final BigInt idTipoCargo;
  final String nombreCargo;
  final bool esPorcentaje;
  final double porcentaje;
  final double valorFijo;
  final double baseCalculo;
  final int idMoneda;

  CargoPagoFormItem({
    BigInt? idTipoCargo,
    this.nombreCargo = '',
    this.esPorcentaje = true,
    this.porcentaje = 0.0,
    this.valorFijo = 0.0,
    this.baseCalculo = 0.0,
    this.idMoneda = 0,
  }) : idTipoCargo = idTipoCargo ?? BigInt.zero;

  double get montoCargo =>
      esPorcentaje ? baseCalculo * porcentaje / 100 : valorFijo;

  CargoPagoFormItem copyWith({
    BigInt? idTipoCargo,
    String? nombreCargo,
    bool? esPorcentaje,
    double? porcentaje,
    double? valorFijo,
    double? baseCalculo,
    int? idMoneda,
  }) {
    return CargoPagoFormItem(
      idTipoCargo: idTipoCargo ?? this.idTipoCargo,
      nombreCargo: nombreCargo ?? this.nombreCargo,
      esPorcentaje: esPorcentaje ?? this.esPorcentaje,
      porcentaje: porcentaje ?? this.porcentaje,
      valorFijo: valorFijo ?? this.valorFijo,
      baseCalculo: baseCalculo ?? this.baseCalculo,
      idMoneda: idMoneda ?? this.idMoneda,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FASE 2-3 — Estado del formulario de cotización
// ═══════════════════════════════════════════════════════════════════════

class CotizacionFormState {
  final int idCotizacion;
  final BigInt idSolicitud;
  final int codBanco;
  final DateTime fechaCotizacion;
  final double montoCompra;
  final int idMoneda;
  final int nroGiros;
  final double tipoCambioOfrecido;
  final double tcVigenteReferencia;
  final String observaciones;
  final List<CargoPagoFormItem> cargos;
  // Fase 3: lista comparativa cargada desde servidor
  final List<CotizacionesEntity> cotizaciones;
  final bool cargando;
  final bool cargandoTc;
  final bool cargandoComparativa;
  final String? mensajeExito;
  final String? mensajeError;

  CotizacionFormState({
    this.idCotizacion = 0,
    BigInt? idSolicitud,
    this.codBanco = 0,
    DateTime? fechaCotizacion,
    this.montoCompra = 0.0,
    this.idMoneda = 0,
    this.nroGiros = 1,
    this.tipoCambioOfrecido = 0.0,
    this.tcVigenteReferencia = 0.0,
    this.observaciones = '',
    this.cargos = const [],
    this.cotizaciones = const [],
    this.cargando = false,
    this.cargandoTc = false,
    this.cargandoComparativa = false,
    this.mensajeExito,
    this.mensajeError,
  }) : idSolicitud = idSolicitud ?? BigInt.zero,
       fechaCotizacion = fechaCotizacion ?? DateTime.now();

  double get totalCargos => cargos.fold(0.0, (s, c) => s + c.montoCargo);
  double get montoConvertido => montoCompra * tipoCambioOfrecido;
  double get totalBolivianos => montoConvertido + totalCargos;

  CotizacionFormState copyWith({
    int? idCotizacion,
    BigInt? idSolicitud,
    int? codBanco,
    DateTime? fechaCotizacion,
    double? montoCompra,
    int? idMoneda,
    int? nroGiros,
    double? tipoCambioOfrecido,
    double? tcVigenteReferencia,
    String? observaciones,
    List<CargoPagoFormItem>? cargos,
    List<CotizacionesEntity>? cotizaciones,
    bool? cargando,
    bool? cargandoTc,
    bool? cargandoComparativa,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
  }) {
    return CotizacionFormState(
      idCotizacion: idCotizacion ?? this.idCotizacion,
      idSolicitud: idSolicitud ?? this.idSolicitud,
      codBanco: codBanco ?? this.codBanco,
      fechaCotizacion: fechaCotizacion ?? this.fechaCotizacion,
      montoCompra: montoCompra ?? this.montoCompra,
      idMoneda: idMoneda ?? this.idMoneda,
      nroGiros: nroGiros ?? this.nroGiros,
      tipoCambioOfrecido: tipoCambioOfrecido ?? this.tipoCambioOfrecido,
      tcVigenteReferencia: tcVigenteReferencia ?? this.tcVigenteReferencia,
      observaciones: observaciones ?? this.observaciones,
      cargos: cargos ?? this.cargos,
      cotizaciones: cotizaciones ?? this.cotizaciones,
      cargando: cargando ?? this.cargando,
      cargandoTc: cargandoTc ?? this.cargandoTc,
      cargandoComparativa: cargandoComparativa ?? this.cargandoComparativa,
      mensajeExito:
          clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError:
          clearMensajeError ? null : (mensajeError ?? this.mensajeError),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FASE 2-3 — Notifier de cotización
// ═══════════════════════════════════════════════════════════════════════

class CotizacionNotifier extends StateNotifier<CotizacionFormState> {
  final PagosExtranjerosImpl _repo = PagosExtranjerosImpl();

  CotizacionNotifier() : super(CotizacionFormState());

  // ── Inicializar con la solicitud activa ─────────────────────────────

  void init({required BigInt idSolicitud, int? codBanco}) {
    state = CotizacionFormState(
      idSolicitud: idSolicitud,
      codBanco: codBanco ?? 0,
      fechaCotizacion: DateTime.now(),
    );
  }

  // ── Campos del formulario ──────────────────────────────────────────

  void setCodBanco(int codBanco) {
    state = state.copyWith(codBanco: codBanco);
  }

  void setFechaCotizacion(DateTime fecha) {
    state = state.copyWith(fechaCotizacion: fecha);
  }

  void setMontoCompra(double monto) {
    state = state.copyWith(montoCompra: monto);
  }

  void setIdMoneda(int idMoneda) {
    state = state.copyWith(idMoneda: idMoneda);
  }

  void setNroGiros(int nroGiros) {
    state = state.copyWith(nroGiros: nroGiros);
  }

  void setTipoCambioOfrecido(double tc) {
    state = state.copyWith(tipoCambioOfrecido: tc);
  }

  void setObservaciones(String obs) {
    state = state.copyWith(observaciones: obs);
  }

  // ── PRE-CARGA: Tipo de cambio vigente del banco ─────────────────────

  Future<void> cargarTcVigente(int codBanco) async {
    state = state.copyWith(cargandoTc: true);
    try {
      final lista = await _repo.getTiposCambioPorBanco(codBanco);
      // Usar la tasa de compra del primer registro vigente
      final tc = lista.isNotEmpty ? lista.first.tasaCompra.toDouble() : 0.0;
      state = state.copyWith(
        tcVigenteReferencia: tc,
        tipoCambioOfrecido: tc,
        cargandoTc: false,
      );
    } catch (e) {
      console('Error cargando TC vigente: $e');
      state = state.copyWith(cargandoTc: false);
    }
  }

  // ── Gestión de cargos ──────────────────────────────────────────────

  void agregarCargo(CargoPagoFormItem cargo) {
    state = state.copyWith(cargos: [...state.cargos, cargo]);
  }

  void actualizarCargo(int index, CargoPagoFormItem cargo) {
    final lista = [...state.cargos];
    lista[index] = cargo;
    state = state.copyWith(cargos: lista);
  }

  void eliminarCargo(int index) {
    final lista = [...state.cargos];
    lista.removeAt(index);
    state = state.copyWith(cargos: lista);
  }

  // ── FASE 2: Guardar cotización ACID ────────────────────────────────

  Future<bool> guardarCotizacion(int audUsuario) async {
    if (state.codBanco <= 0) {
      state = state.copyWith(mensajeError: 'Debe seleccionar un banco.');
      return false;
    }
    if (state.idMoneda <= 0) {
      state = state.copyWith(mensajeError: 'Debe seleccionar una moneda.');
      return false;
    }
    if (state.montoCompra <= 0) {
      state = state.copyWith(
        mensajeError: 'El monto de compra debe ser mayor a 0.',
      );
      return false;
    }
    if (state.tipoCambioOfrecido <= 0) {
      state = state.copyWith(
        mensajeError: 'El tipo de cambio ofrecido debe ser mayor a 0.',
      );
      return false;
    }
    if (state.nroGiros <= 0) {
      state = state.copyWith(
        mensajeError: 'El número de giros debe ser al menos 1.',
      );
      return false;
    }

    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );

    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} 00:00:00';

      final payload = <String, dynamic>{
        'idCotizacion': state.idCotizacion,
        'idSolicitud': state.idSolicitud.toInt(),
        'fechaCotizacion': fmtDate(state.fechaCotizacion),
        'codBanco': state.codBanco,
        'montoCompra': state.montoCompra,
        'idMoneda': state.idMoneda,
        'nroGiros': state.nroGiros,
        'tipoCambioOfrecido': state.tipoCambioOfrecido,
        'montoConvertido': state.montoConvertido,
        'totalBolivianos': state.totalBolivianos,
        'observaciones': state.observaciones,
        'audUsuario': audUsuario,
        'cargos':
            state.cargos
                .map(
                  (c) => {
                    'idTipoCargo': c.idTipoCargo.toInt(),
                    'porcentaje': c.esPorcentaje ? c.porcentaje : 0.0,
                    'valorFijo': c.esPorcentaje ? 0.0 : c.valorFijo,
                    'baseCalculo': c.baseCalculo,
                    'idMoneda': c.idMoneda,
                  },
                )
                .toList(),
      };

      final idCotizacion = await _repo.guardarCotizacionCompleta(payload);
      console('Cotización guardada con ID: $idCotizacion');

      state = state.copyWith(
        cargando: false,
        idCotizacion: idCotizacion.toInt(),
        mensajeExito: 'Cotización registrada exitosamente.',
      );
      return true;
    } catch (e) {
      console('Error guardando cotización: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── FASE 3: Cargar comparativa ─────────────────────────────────────

  Future<void> cargarComparativa(BigInt idSolicitud) async {
    state = state.copyWith(cargandoComparativa: true);
    try {
      final lista = await _repo.getCotizacionesPorSolicitud(idSolicitud);
      // Ordenar por totalBolivianos ASC (mejor oferta primero)
      lista.sort((a, b) => a.totalBolivianos.compareTo(b.totalBolivianos));
      state = state.copyWith(cotizaciones: lista, cargandoComparativa: false);
    } catch (e) {
      console('Error cargando comparativa: $e');
      state = state.copyWith(cargandoComparativa: false);
    }
  }

  // ── FASE 3: Aceptar cotización ganadora ACID ───────────────────────

  Future<bool> aceptarCotizacion({
    required CotizacionesEntity cotizacion,
    required int audUsuario,
  }) async {
    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      await _repo.aceptarCotizacion({
        'idCotizacion': cotizacion.idCotizacion.toInt(),
        'idSolicitud': cotizacion.idSolicitud.toInt(),
        'fechaCotizacion':
            '${cotizacion.fechaCotizacion.year.toString().padLeft(4, '0')}-'
            '${cotizacion.fechaCotizacion.month.toString().padLeft(2, '0')}-'
            '${cotizacion.fechaCotizacion.day.toString().padLeft(2, '0')}',
        'montoCompra': cotizacion.montoCompra,
        'idMoneda': cotizacion.idMoneda,
        'nroGiros': cotizacion.nroGiros,
        'codBanco': cotizacion.codBanco,
        'tipoCambioOfrecido': cotizacion.tipoCambioOfrecido,
        'montoConvertido': cotizacion.montoConvertido,
        'totalBolivianos': cotizacion.totalBolivianos,
        'observaciones': cotizacion.observaciones,
        'estado': 'ACEPTADA',
        'audUsuario': audUsuario,
      });
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Cotización aceptada. Las demás fueron rechazadas.',
      );
      return true;
    } catch (e) {
      console('Error aceptando cotización: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(clearMensajeExito: true, clearMensajeError: true);
  }

  void resetForm() {
    state = CotizacionFormState(idSolicitud: state.idSolicitud);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FASE 2-3 — Provider de cotización
// ═══════════════════════════════════════════════════════════════════════

final cotizacionFormProvider =
    StateNotifierProvider<CotizacionNotifier, CotizacionFormState>(
      (ref) => CotizacionNotifier(),
    );

// ═══════════════════════════════════════════════════════════════════════
// FASE 4-5 — Estado del formulario de transacción
// ═══════════════════════════════════════════════════════════════════════

class TransaccionFormState {
  final int idTransaccion;
  final BigInt idSolicitud;
  final BigInt idCotizacion;
  final BigInt idTipoTransaccion;
  final int codBanco;
  final int idCanal;
  final int codEmpresa;
  final String cardCode;
  final DateTime fechaTransaccion;
  final DateTime fechaValor;
  final double montoOrigen;
  final int idMonedaOrigen;
  final double tipoCambioAplicado;
  final int idMonedaDestino;
  final double tipoCambioReferencia;
  final double totalFinal;
  // Campos opcionales (forwards, exportadora, etc.)
  final String numeroContrato;
  final DateTime? fechaPactado;
  final DateTime? fechaVencimiento;
  final double tipoCambioForward;
  final String nombreExportadora;
  final double tcNegociadoExportadora;
  final double comisionExportadora;
  final String metodoExportadora;
  final String observaciones;
  final List<CargoPagoFormItem> cargos;
  final bool cargando;
  final bool cargandoTcRef;
  final bool subiendoVoucher;
  final bool tieneVoucher;
  final String? mensajeExito;
  final String? mensajeError;
  final String? errorVoucher;

  TransaccionFormState({
    this.idTransaccion = 0,
    BigInt? idSolicitud,
    BigInt? idCotizacion,
    BigInt? idTipoTransaccion,
    this.codBanco = 0,
    this.idCanal = 0,
    this.codEmpresa = 0,
    this.cardCode = '',
    DateTime? fechaTransaccion,
    DateTime? fechaValor,
    this.montoOrigen = 0.0,
    this.idMonedaOrigen = 0,
    this.tipoCambioAplicado = 0.0,
    this.idMonedaDestino = 0,
    this.tipoCambioReferencia = 0.0,
    this.totalFinal = 0.0,
    this.numeroContrato = '',
    this.fechaPactado,
    this.fechaVencimiento,
    this.tipoCambioForward = 0.0,
    this.nombreExportadora = '',
    this.tcNegociadoExportadora = 0.0,
    this.comisionExportadora = 0.0,
    this.metodoExportadora = '',
    this.observaciones = '',
    this.cargos = const [],
    this.cargando = false,
    this.cargandoTcRef = false,
    this.subiendoVoucher = false,
    this.tieneVoucher = false,
    this.mensajeExito,
    this.mensajeError,
    this.errorVoucher,
  }) : idSolicitud = idSolicitud ?? BigInt.zero,
       idCotizacion = idCotizacion ?? BigInt.zero,
       idTipoTransaccion = idTipoTransaccion ?? BigInt.zero,
       fechaTransaccion = fechaTransaccion ?? DateTime.now(),
       fechaValor = fechaValor ?? DateTime.now();

  double get totalCargos => cargos.fold(0.0, (s, c) => s + c.montoCargo);
  double get montoConvertido => montoOrigen * tipoCambioAplicado;
  double get equivalenteUsdRef =>
      tipoCambioReferencia > 0 ? montoOrigen * tipoCambioReferencia : 0.0;
  double get diferenciaDeMas =>
      equivalenteUsdRef > 0 ? montoConvertido - equivalenteUsdRef : 0.0;
  double get porcentajeDiferencia =>
      equivalenteUsdRef > 0 ? (diferenciaDeMas / equivalenteUsdRef) * 100 : 0.0;

  TransaccionFormState copyWith({
    int? idTransaccion,
    BigInt? idSolicitud,
    BigInt? idCotizacion,
    BigInt? idTipoTransaccion,
    int? codBanco,
    int? idCanal,
    int? codEmpresa,
    String? cardCode,
    DateTime? fechaTransaccion,
    DateTime? fechaValor,
    double? montoOrigen,
    int? idMonedaOrigen,
    double? tipoCambioAplicado,
    int? idMonedaDestino,
    double? tipoCambioReferencia,
    double? totalFinal,
    String? numeroContrato,
    DateTime? fechaPactado,
    DateTime? fechaVencimiento,
    double? tipoCambioForward,
    String? nombreExportadora,
    double? tcNegociadoExportadora,
    double? comisionExportadora,
    String? metodoExportadora,
    String? observaciones,
    List<CargoPagoFormItem>? cargos,
    bool? cargando,
    bool? cargandoTcRef,
    bool? subiendoVoucher,
    bool? tieneVoucher,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
    String? errorVoucher,
    bool clearErrorVoucher = false,
  }) {
    return TransaccionFormState(
      idTransaccion: idTransaccion ?? this.idTransaccion,
      idSolicitud: idSolicitud ?? this.idSolicitud,
      idCotizacion: idCotizacion ?? this.idCotizacion,
      idTipoTransaccion: idTipoTransaccion ?? this.idTipoTransaccion,
      codBanco: codBanco ?? this.codBanco,
      idCanal: idCanal ?? this.idCanal,
      codEmpresa: codEmpresa ?? this.codEmpresa,
      cardCode: cardCode ?? this.cardCode,
      fechaTransaccion: fechaTransaccion ?? this.fechaTransaccion,
      fechaValor: fechaValor ?? this.fechaValor,
      montoOrigen: montoOrigen ?? this.montoOrigen,
      idMonedaOrigen: idMonedaOrigen ?? this.idMonedaOrigen,
      tipoCambioAplicado: tipoCambioAplicado ?? this.tipoCambioAplicado,
      idMonedaDestino: idMonedaDestino ?? this.idMonedaDestino,
      tipoCambioReferencia: tipoCambioReferencia ?? this.tipoCambioReferencia,
      totalFinal: totalFinal ?? this.totalFinal,
      numeroContrato: numeroContrato ?? this.numeroContrato,
      fechaPactado: fechaPactado ?? this.fechaPactado,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      tipoCambioForward: tipoCambioForward ?? this.tipoCambioForward,
      nombreExportadora: nombreExportadora ?? this.nombreExportadora,
      tcNegociadoExportadora:
          tcNegociadoExportadora ?? this.tcNegociadoExportadora,
      comisionExportadora: comisionExportadora ?? this.comisionExportadora,
      metodoExportadora: metodoExportadora ?? this.metodoExportadora,
      observaciones: observaciones ?? this.observaciones,
      cargos: cargos ?? this.cargos,
      cargando: cargando ?? this.cargando,
      cargandoTcRef: cargandoTcRef ?? this.cargandoTcRef,
      subiendoVoucher: subiendoVoucher ?? this.subiendoVoucher,
      tieneVoucher: tieneVoucher ?? this.tieneVoucher,
      mensajeExito:
          clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError:
          clearMensajeError ? null : (mensajeError ?? this.mensajeError),
      errorVoucher:
          clearErrorVoucher ? null : (errorVoucher ?? this.errorVoucher),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FASE 4-5 — Notifier de transacción
// ═══════════════════════════════════════════════════════════════════════

class TransaccionNotifier extends StateNotifier<TransaccionFormState> {
  final PagosExtranjerosImpl _repo = PagosExtranjerosImpl();

  TransaccionNotifier() : super(TransaccionFormState());

  // ── PRE-CARGA 1: desde cotización ganadora ─────────────────────────

  void precargarDesdeCotizacion({
    required CotizacionesEntity cotizacion,
    required int codEmpresa,
    required String cardCode,
  }) {
    state = state.copyWith(
      idSolicitud: cotizacion.idSolicitud,
      idCotizacion: cotizacion.idCotizacion,
      codBanco: cotizacion.codBanco,
      codEmpresa: codEmpresa,
      cardCode: cardCode,
      montoOrigen: cotizacion.montoCompra,
      idMonedaOrigen: cotizacion.idMoneda,
      tipoCambioAplicado: cotizacion.tipoCambioOfrecido,
      totalFinal: cotizacion.totalBolivianos,
      observaciones: cotizacion.observaciones,
    );
  }

  // ── PRE-CARGA 1b: desde transacción existente (para Fase 5 re-apertura) ──

  void precargarDesdeTransaccion(TransaccionesEntity txn) {
    // Convert entity cargos → form items so totalCargos is computed correctly
    final formCargos =
        txn.cargos
            .map(
              (c) => CargoPagoFormItem(
                idTipoCargo: c.idTipoCargo,
                nombreCargo: c.descripcion,
                esPorcentaje: c.porcentaje > 0,
                porcentaje: c.porcentaje,
                valorFijo: c.valorFijo,
                baseCalculo: c.baseCalculo,
                idMoneda: c.idMoneda,
              ),
            )
            .toList();

    state = state.copyWith(
      idTransaccion: txn.idTransaccion.toInt(),
      idSolicitud: txn.idSolicitud,
      idCotizacion: txn.idCotizacion,
      idTipoTransaccion: txn.idTipoTransaccion,
      codBanco: txn.codBanco,
      idCanal: txn.idCanal,
      codEmpresa: txn.codEmpresa,
      cardCode: txn.cardCode,
      fechaTransaccion: txn.fechaTransaccion,
      fechaValor: txn.fechaValor,
      montoOrigen: txn.montoOrigen,
      idMonedaOrigen: txn.idMonedaOrigen,
      tipoCambioAplicado: txn.tipoCambioAplicado,
      idMonedaDestino: txn.idMonedaDestino,
      tipoCambioReferencia: txn.tipoCambioReferencia,
      totalFinal: txn.totalFinal,
      observaciones: txn.observaciones,
      numeroContrato: txn.numeroContrato,
      fechaPactado: txn.fechaPactado.year > 2000 ? txn.fechaPactado : null,
      fechaVencimiento:
          txn.fechaVencimiento.year > 2000 ? txn.fechaVencimiento : null,
      tipoCambioForward: txn.tipoCambioForward,
      nombreExportadora: txn.nombreExportadora,
      tcNegociadoExportadora: txn.tcNegociadoExportadora,
      comisionExportadora: txn.comisionExportadora,
      metodoExportadora: txn.metodoExportadora,
      cargos: formCargos,
      tieneVoucher: txn.tieneVoucher,
    );
  }

  // ── PRE-CARGA 2: TC de referencia BCB del banco ────────────────────

  Future<void> cargarTcReferencia(int codBanco) async {
    if (codBanco <= 0) return;
    state = state.copyWith(cargandoTcRef: true);
    try {
      final lista = await _repo.getTiposCambioPorBanco(codBanco);
      final tc = lista.isNotEmpty ? lista.first.tasaCompra.toDouble() : 0.0;
      state = state.copyWith(tipoCambioReferencia: tc, cargandoTcRef: false);
    } catch (e) {
      console('Error cargando TC referencia: $e');
      state = state.copyWith(cargandoTcRef: false);
    }
  }

  // ── Campos del formulario ──────────────────────────────────────────

  void setIdTipoTransaccion(BigInt id) =>
      state = state.copyWith(idTipoTransaccion: id);
  void setCodBanco(int id) => state = state.copyWith(codBanco: id);
  void setIdCanal(int id) => state = state.copyWith(idCanal: id);
  void setMontoOrigen(double v) => state = state.copyWith(montoOrigen: v);
  void setTipoCambioAplicado(double v) =>
      state = state.copyWith(tipoCambioAplicado: v);
  void setIdMonedaOrigen(int id) => state = state.copyWith(idMonedaOrigen: id);
  void setIdMonedaDestino(int id) =>
      state = state.copyWith(idMonedaDestino: id);
  void setTotalFinal(double v) => state = state.copyWith(totalFinal: v);
  void setFechaTransaccion(DateTime d) =>
      state = state.copyWith(fechaTransaccion: d);
  void setFechaValor(DateTime d) => state = state.copyWith(fechaValor: d);
  void setNumeroContrato(String v) => state = state.copyWith(numeroContrato: v);
  void setTipoCambioForward(double v) =>
      state = state.copyWith(tipoCambioForward: v);
  void setFechaPactado(DateTime d) => state = state.copyWith(fechaPactado: d);
  void setFechaVencimiento(DateTime d) =>
      state = state.copyWith(fechaVencimiento: d);
  void setNombreExportadora(String v) =>
      state = state.copyWith(nombreExportadora: v);
  void setTcNegociadoExportadora(double v) =>
      state = state.copyWith(tcNegociadoExportadora: v);
  void setComisionExportadora(double v) =>
      state = state.copyWith(comisionExportadora: v);
  void setMetodoExportadora(String v) =>
      state = state.copyWith(metodoExportadora: v);
  void setObservaciones(String v) => state = state.copyWith(observaciones: v);

  // ── Gestión de cargos ──────────────────────────────────────────────

  void agregarCargo(CargoPagoFormItem cargo) {
    state = state.copyWith(cargos: [...state.cargos, cargo]);
  }

  void actualizarCargo(int index, CargoPagoFormItem cargo) {
    final lista = [...state.cargos];
    lista[index] = cargo;
    state = state.copyWith(cargos: lista);
  }

  void eliminarCargo(int index) {
    final lista = [...state.cargos];
    lista.removeAt(index);
    state = state.copyWith(cargos: lista);
  }

  // ── FASE 4: Guardar transacción ACID ──────────────────────────────

  Future<bool> guardarTransaccion(int audUsuario) async {
    if (state.idCotizacion == BigInt.zero) {
      state = state.copyWith(
        mensajeError: 'Debe asociar una cotización aceptada.',
      );
      return false;
    }
    if (state.idTipoTransaccion == BigInt.zero) {
      state = state.copyWith(
        mensajeError: 'Debe seleccionar un tipo de transacción.',
      );
      return false;
    }
    if (state.codBanco <= 0) {
      state = state.copyWith(mensajeError: 'Debe seleccionar un banco.');
      return false;
    }
    if (state.idCanal <= 0) {
      state = state.copyWith(
        mensajeError: 'Debe seleccionar un canal de pago.',
      );
      return false;
    }
    if (state.montoOrigen <= 0) {
      state = state.copyWith(
        mensajeError: 'El monto origen debe ser mayor a 0.',
      );
      return false;
    }
    if (state.idMonedaOrigen <= 0) {
      state = state.copyWith(
        mensajeError: 'Debe seleccionar la moneda de origen.',
      );
      return false;
    }
    if (state.idMonedaDestino <= 0) {
      state = state.copyWith(
        mensajeError: 'Debe seleccionar la moneda de destino.',
      );
      return false;
    }
    if (state.tipoCambioAplicado <= 0) {
      state = state.copyWith(mensajeError: 'El tipo de cambio no puede ser 0.');
      return false;
    }

    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );

    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} 00:00:00';

      final payload = <String, dynamic>{
        'idTransaccion': state.idTransaccion,
        'idSolicitud': state.idSolicitud.toInt(),
        'idCotizacion': state.idCotizacion.toInt(),
        'idTipoTransaccion': state.idTipoTransaccion.toInt(),
        'codBanco': state.codBanco,
        'idCanal': state.idCanal,
        'codEmpresa': state.codEmpresa,
        'cardCode': state.cardCode,
        'fechaTransaccion': fmtDate(state.fechaTransaccion),
        // fechaValor: NULL al crear — solo se llena en Fase 5 (confirmar-pago)
        'montoOrigen': state.montoOrigen,
        'idMonedaOrigen': state.idMonedaOrigen,
        'tipoCambioAplicado': state.tipoCambioAplicado,
        'idMonedaDestino': state.idMonedaDestino,
        // tipoCambioReferencia: el controller lo autocompleta si es null
        if (state.tipoCambioReferencia > 0)
          'tipoCambioReferencia': state.tipoCambioReferencia,
        // El SP recalcula estos campos, pero el backend Java valida que
        // totalFinal > 0 antes de llamar al SP (primitivo double = 0).
        // Enviamos los valores computados como safety net.
        'montoConvertido': state.montoConvertido,
        'totalCargos': state.totalCargos,
        'totalFinal': state.montoConvertido + state.totalCargos,
        'observaciones': state.observaciones,
        'audUsuario': audUsuario,
        // Campos FORWARD (solo si aplica)
        'numeroContrato':
            state.numeroContrato.isNotEmpty ? state.numeroContrato : null,
        'fechaPactado':
            state.fechaPactado != null ? fmtDate(state.fechaPactado!) : null,
        'fechaVencimiento':
            state.fechaVencimiento != null
                ? fmtDate(state.fechaVencimiento!)
                : null,
        'tipoCambioForward':
            state.tipoCambioForward > 0 ? state.tipoCambioForward : null,
        // Campos EXPORTADORA (solo si aplica)
        'nombreExportadora':
            state.nombreExportadora.isNotEmpty ? state.nombreExportadora : null,
        'tcNegociadoExportadora':
            state.tcNegociadoExportadora > 0
                ? state.tcNegociadoExportadora
                : null,
        'comisionExportadora':
            state.comisionExportadora > 0 ? state.comisionExportadora : null,
        'metodoExportadora':
            state.metodoExportadora.isNotEmpty ? state.metodoExportadora : null,
        'cargos':
            state.cargos
                .map(
                  (c) => {
                    'idTipoCargo': c.idTipoCargo.toInt(),
                    'porcentaje': c.esPorcentaje ? c.porcentaje : 0.0,
                    'valorFijo': c.esPorcentaje ? 0.0 : c.valorFijo,
                    'baseCalculo': c.baseCalculo,
                    'idMoneda': c.idMoneda,
                  },
                )
                .toList(),
      };

      final idTransaccion = await _repo.guardarTransaccionCompleta(payload);
      console('Transacción guardada con ID: $idTransaccion');

      state = state.copyWith(
        cargando: false,
        idTransaccion: idTransaccion.toInt(),
        mensajeExito: 'Transacción registrada exitosamente.',
      );
      return true;
    } catch (e) {
      console('Error guardando transacción: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── FASE 4b: Cambiar estado (PENDIENTE → PROCESADO) ───────────────

  Future<bool> cambiarEstado({
    required BigInt idTransaccion,
    required String estado,
    required int audUsuario,
    String? numeroTransaccion,
    DateTime? fechaValor,
  }) async {
    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      await _repo.cambiarEstadoTransaccion({
        'idTransaccion': idTransaccion.toInt(),
        'estado': estado,
        if (numeroTransaccion != null) 'numeroTransaccion': numeroTransaccion,
        if (fechaValor != null)
          'fechaValor':
              '${fechaValor.year.toString().padLeft(4, '0')}-'
              '${fechaValor.month.toString().padLeft(2, '0')}-'
              '${fechaValor.day.toString().padLeft(2, '0')} 00:00:00',
        'audUsuario': audUsuario,
      });
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Estado cambiado a $estado exitosamente.',
      );
      return true;
    } catch (e) {
      console('Error cambiando estado: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── FASE 5: Confirmar pago ──────────────────────────────────────────
  // El SP requiere transición escalonada:
  //   PENDIENTE → PROCESADO → CONFIRMADO
  // Por eso se hacen dos llamadas secuenciales.

  Future<bool> confirmarPago({
    required BigInt idTransaccion,
    required BigInt idSolicitud,
    required String numeroTransaccion,
    required DateTime fechaValor,
    required int audUsuario,
    String? observaciones,
    String estadoActual = 'PENDIENTE',
  }) async {
    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} 00:00:00';

      // Helper: payload completo con todos los campos del state.
      // El backend Java deserializa en modelo completo: los primitivos que
      // no se envían defaultean a 0 y el SP hace ISNULL(0, valorActual) = 0,
      // sobreescribiendo valores reales. Por eso enviamos TODO en cada paso.
      Map<String, dynamic> fullPayload({
        required String estado,
        String? nroTransaccion,
        DateTime? fValor,
      }) {
        return {
          'idTransaccion': idTransaccion.toInt(),
          'idSolicitud': idSolicitud.toInt(),
          'idCotizacion': state.idCotizacion.toInt(),
          'idTipoTransaccion': state.idTipoTransaccion.toInt(),
          'codBanco': state.codBanco,
          'idCanal': state.idCanal,
          'codEmpresa': state.codEmpresa,
          'cardCode': state.cardCode,
          'fechaTransaccion': fmtDate(state.fechaTransaccion),
          'montoOrigen': state.montoOrigen,
          'idMonedaOrigen': state.idMonedaOrigen,
          'tipoCambioAplicado': state.tipoCambioAplicado,
          'montoConvertido': state.montoConvertido,
          'idMonedaDestino': state.idMonedaDestino,
          'totalCargos': state.totalCargos,
          'totalFinal': state.montoConvertido + state.totalCargos,
          'estado': estado,
          'audUsuario': audUsuario,
          if (nroTransaccion != null) 'numeroTransaccion': nroTransaccion,
          if (fValor != null) 'fechaValor': fmtDate(fValor),
          if (state.tipoCambioReferencia > 0)
            'tipoCambioReferencia': state.tipoCambioReferencia,
          if (state.observaciones.isNotEmpty)
            'observaciones': state.observaciones,
        };
      }

      // Paso 1: PENDIENTE → PROCESADO (solo si aún está en PENDIENTE)
      if (estadoActual.toUpperCase() == 'PENDIENTE') {
        await _repo.cambiarEstadoTransaccion(fullPayload(estado: 'PROCESADO'));
      }

      // Paso 2: PROCESADO → CONFIRMADO (con numeroTransaccion + fechaValor)
      final confirmPayload = fullPayload(
        estado: 'CONFIRMADO',
        nroTransaccion: numeroTransaccion,
        fValor: fechaValor,
      );
      // Sobrescribir observaciones si el usuario puso nuevas en la confirmación
      if (observaciones != null && observaciones.trim().isNotEmpty) {
        confirmPayload['observaciones'] = observaciones.trim();
      }
      await _repo.confirmarPago(confirmPayload);

      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Pago confirmado. Solicitud cerrada como PAGADA.',
      );
      return true;
    } catch (e) {
      console('Error confirmando pago: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(
      clearMensajeExito: true,
      clearMensajeError: true,
      clearErrorVoucher: true,
    );
  }

  void resetForm() {
    state = TransaccionFormState();
  }

  /// Sube un voucher (imagen/PDF) asociado a la transacción actual.
  /// En móvil se usa [filePath]; en web se usa [fileBytes] + [fileName].
  Future<bool> subirVoucher({
    required BigInt idTransaccion,
    required int audUsuario,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    state = state.copyWith(subiendoVoucher: true, clearErrorVoucher: true);
    try {
      await _repo.subirVoucher(
        idTransaccion: idTransaccion,
        audUsuario: audUsuario,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      state = state.copyWith(
        subiendoVoucher: false,
        tieneVoucher: true,
        mensajeExito: 'Voucher subido correctamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        subiendoVoucher: false,
        errorVoucher: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FASE 4-5 — Provider de transacción
// ═══════════════════════════════════════════════════════════════════════

final transaccionFormProvider =
    StateNotifierProvider<TransaccionNotifier, TransaccionFormState>(
      (ref) => TransaccionNotifier(),
    );

// ═══════════════════════════════════════════════════════════════════════
// Providers de lectura para las fases
// ═══════════════════════════════════════════════════════════════════════

/// Cotizaciones de una solicitud (para comparativa — Fase 3).
final cotizacionesXSolicitudProvider = FutureProvider.autoDispose
    .family<List<CotizacionesEntity>, BigInt>((ref, idSolicitud) async {
      if (idSolicitud == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      final lista = await repo.getCotizacionesPorSolicitud(idSolicitud);
      lista.sort((a, b) => a.totalBolivianos.compareTo(b.totalBolivianos));
      return lista;
    });

/// Transacciones de una solicitud.
final transaccionesXSolicitudProvider = FutureProvider.autoDispose
    .family<List<TransaccionesEntity>, ({BigInt idSolicitud, int codEmpresa})>((
      ref,
      params,
    ) async {
      if (params.idSolicitud == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getTransaccionesPorSolicitud(
        params.idSolicitud,
        codEmpresa: params.codEmpresa,
      );
    });

/// Log de estados de una solicitud.
final logSolicitudProvider = FutureProvider.autoDispose
    .family<List<LogEstadosEntity>, BigInt>((ref, idSolicitud) async {
      if (idSolicitud == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getLogPorSolicitud(idSolicitud);
    });

/// Log de estados de una transacción.
final logTransaccionProvider = FutureProvider.autoDispose
    .family<List<LogEstadosEntity>, BigInt>((ref, idTransaccion) async {
      if (idTransaccion == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getLogPorTransaccion(idTransaccion);
    });

/// Timeline completo de una solicitud (solicitud + cotizaciones + transacciones).
final timelineSolicitudProvider = FutureProvider.autoDispose
    .family<List<LogEstadosEntity>, BigInt>((ref, idSolicitud) async {
      if (idSolicitud == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getTimelineSolicitud(idSolicitud);
    });

// ═══════════════════════════════════════════════════════════════════════
// Providers de catálogos (para dropdowns y tablas de configuración)
// ═══════════════════════════════════════════════════════════════════════

/// Lista de canales de pago activos.
final canalesPagoProvider = FutureProvider.autoDispose<List<CanalesPagoEntity>>(
  (ref) async {
    final repo = PagosExtranjerosImpl();
    return repo.getCanalesPago();
  },
);

/// Lista de monedas activas.
final monedasProvider = FutureProvider.autoDispose<List<MonedasEntity>>((
  ref,
) async {
  final repo = PagosExtranjerosImpl();
  return repo.getMonedas();
});

/// Tipos de cargo activos.
final tiposCargoProvider = FutureProvider.autoDispose<List<TiposCargoEntity>>((
  ref,
) async {
  final repo = PagosExtranjerosImpl();
  return repo.getTiposCargo();
});

/// Tipos de transacción activos.
final tiposTransaccionProvider =
    FutureProvider.autoDispose<List<TiposTransaccionEntity>>((ref) async {
      final repo = PagosExtranjerosImpl();
      return repo.getTiposTransaccion();
    });

/// Tipos de cambio vigentes para un banco específico (usado en Fases 2 y 4).
final tiposCambioPorBancoProvider = FutureProvider.autoDispose
    .family<List<TiposCambioEntity>, int>((ref, codBanco) async {
      if (codBanco <= 0) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getTiposCambioPorBanco(codBanco);
    });

/// Configuración de comisiones de un banco específico.
final configComisionesBancoProvider = FutureProvider.autoDispose
    .family<List<ConfigComisionesBancoEntity>, int>((ref, codBanco) async {
      if (codBanco <= 0) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getConfigComisionesPorBanco(codBanco);
    });

/// Asientos contables de una transacción (ACCION="T").
final asientosTransaccionProvider = FutureProvider.autoDispose
    .family<List<AsientoEntity>, BigInt>((ref, idTransaccion) async {
      if (idTransaccion == BigInt.zero) return [];
      final repo = PagosExtranjerosImpl();
      return repo.getAsientosPorTransaccion(idTransaccion);
    });

/// Resumen de cuadre de asientos de una transacción (ACCION="V").
final cuadreAsientosProvider = FutureProvider.autoDispose
    .family<AsientoEntity?, BigInt>((ref, idTransaccion) async {
      if (idTransaccion == BigInt.zero) return null;
      final repo = PagosExtranjerosImpl();
      return repo.validarCuadreAsientos(idTransaccion);
    });

/// Lista de bancos disponibles para cotización TPEX.
final bancosTPEXProvider = FutureProvider.autoDispose<List<BancoEntity>>((
  ref,
) async {
  final repo = RegistroEmpleadoImpl();
  return repo.getBancos();
});

// ═══════════════════════════════════════════════════════════════════════
// Providers de lectura adicionales (spec v2)
// ═══════════════════════════════════════════════════════════════════════

/// Cargos bancarios de una cotización.
final cargosCotizacionProvider = FutureProvider.autoDispose
    .family<List<CargoPagoEntity>, int>((ref, idCotizacion) async {
      final repo = PagosExtranjerosImpl();
      return repo.getCargosCotizacion(idCotizacion);
    });

/// Detalle de una transacción individual.
/// Parámetro: (idTransaccion, codEmpresa).
final transaccionDetalleProvider = FutureProvider.autoDispose
    .family<TransaccionesEntity?, ({int idTransaccion, int codEmpresa})>((
      ref,
      params,
    ) async {
      final repo = PagosExtranjerosImpl();
      return repo.getTransaccion(
        idTransaccion: params.idTransaccion,
        codEmpresa: params.codEmpresa,
      );
    });

/// Cargos de una transacción.
final cargosTransaccionProvider = FutureProvider.autoDispose
    .family<List<CargoPagoEntity>, int>((ref, idTransaccion) async {
      final repo = PagosExtranjerosImpl();
      return repo.getCargosTransaccion(idTransaccion);
    });

/// Reporte de transacciones por rango de fechas y empresa.
final reporteTransaccionesFechasProvider = FutureProvider.autoDispose.family<
  List<TransaccionesEntity>,
  ({DateTime fechaInicio, DateTime fechaFin, int codEmpresa})
>((ref, params) async {
  final repo = PagosExtranjerosImpl();
  return repo.getReporteTransaccionesFechas(
    fechaInicio: params.fechaInicio,
    fechaFin: params.fechaFin,
    codEmpresa: params.codEmpresa,
  );
});

/// Último tipo de cambio vigente del BCB (codBanco=null) para USD→BOB.
/// idMonedaOrigen=3 (USD), idMonedaDestino=4 (BOB)
final tcVigenteRefProvider = FutureProvider.autoDispose
    .family<TiposCambioEntity?, ({int? codBanco, int idMonedaOrigen, int idMonedaDestino})>(
        (ref, params) async {
  final repo = PagosExtranjerosImpl();
  return repo.getTCVigenteRef(
    codBanco: params.codBanco,
    idMonedaOrigen: params.idMonedaOrigen,
    idMonedaDestino: params.idMonedaDestino,
  );
});

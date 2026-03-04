import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════
// Modelos auxiliares del formulario (solo para el estado de UI)
// ═══════════════════════════════════════════════════════════════════════

class DetalleFormItem {
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
  final String cardCode;
  final String cardName;
  final String obs;
  final List<DetalleFormItem> detalles;

  ProveedorFormItem({
    this.cardCode = '',
    this.cardName = '',
    this.obs = '',
    this.detalles = const [],
  });

  double get totalFacturasUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoFacturaUsd);
  double get totalAmortizadoUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoAmortizadoUsd);
  double get totalAPagarUsd =>
      detalles.fold(0.0, (sum, d) => sum + d.montoAPagarUsd);

  ProveedorFormItem copyWith({
    String? cardCode,
    String? cardName,
    String? obs,
    List<DetalleFormItem>? detalles,
  }) {
    return ProveedorFormItem(
      cardCode: cardCode ?? this.cardCode,
      cardName: cardName ?? this.cardName,
      obs: obs ?? this.obs,
      detalles: detalles ?? this.detalles,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Estado principal
// ═══════════════════════════════════════════════════════════════════════

class PagosExtranjerosState {
  final List<EmpresaEntity> empresas;
  final EmpresaEntity? empresaSeleccionada;
  final DateTime fechaSolicitud;
  final List<ProveedorFormItem> proveedores;
  final bool cargando;
  final bool cargandoEmpresas;
  final String? mensajeExito;
  final String? mensajeError;

  PagosExtranjerosState({
    this.empresas = const [],
    this.empresaSeleccionada,
    DateTime? fechaSolicitud,
    this.proveedores = const [],
    this.cargando = false,
    this.cargandoEmpresas = false,
    this.mensajeExito,
    this.mensajeError,
  }) : fechaSolicitud = fechaSolicitud ?? DateTime.now();

  double get montoTotalSolicitud =>
      proveedores.fold(0.0, (sum, p) => sum + p.totalAPagarUsd);

  PagosExtranjerosState copyWith({
    List<EmpresaEntity>? empresas,
    EmpresaEntity? empresaSeleccionada,
    bool clearEmpresa = false,
    DateTime? fechaSolicitud,
    List<ProveedorFormItem>? proveedores,
    bool? cargando,
    bool? cargandoEmpresas,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
  }) {
    return PagosExtranjerosState(
      empresas: empresas ?? this.empresas,
      empresaSeleccionada:
          clearEmpresa
              ? null
              : (empresaSeleccionada ?? this.empresaSeleccionada),
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      proveedores: proveedores ?? this.proveedores,
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
    // Si la empresa cambia, borrar todos los proveedores y facturas
    final cambioEmpresa =
        state.empresaSeleccionada?.codEmpresa != empresa.codEmpresa;
    state = state.copyWith(
      empresaSeleccionada: empresa,
      proveedores: cambioEmpresa ? [] : state.proveedores,
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
    final lista = [...state.proveedores];
    lista.removeAt(index);
    state = state.copyWith(proveedores: lista);
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
    final detalles = [...prov.detalles];
    detalles.removeAt(detalleIndex);
    proveedores[proveedorIndex] = prov.copyWith(detalles: detalles);
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

  // ── Guardar solicitud completa (flujo 3 endpoints) ──────────────────

  /// Ejecuta el guardado en cascada:
  /// 1. POST solicitud pago → obtiene idSolicitud
  /// 2. Para cada proveedor: POST proveedor → obtiene idSolicitudProveedor
  /// 3. Para cada detalle: POST detalle
  ///
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
    }

    state = state.copyWith(
      cargando: true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );

    try {
      // ── Paso 1: Registrar cabecera de solicitud ────────────────────
      final idSolicitud = await _repo.registrarSolicitudPago(
        SolicitudPagoEntity(
          idSolicitud: BigInt.zero,
          codEmpresa: state.empresaSeleccionada!.codEmpresa,
          fechaSolicitud: state.fechaSolicitud,
          montoTotalSolicitud: state.montoTotalSolicitud,
          estado: 'PENDIENTE',
          audUsuario: audUsuario,
        ),
      );

      console('SolicitudPago creada con ID: $idSolicitud');

      // ── Paso 2 & 3: Proveedor + sus detalles ──────────────────────
      for (final prov in state.proveedores) {
        final idSolicitudProveedor = await _repo.registrarSolicitudProveedor(
          SolicitudProveedorEntity(
            idSolicitudProveedor: BigInt.zero,
            idSolicitud: idSolicitud,
            cardCode: prov.cardCode,
            cardName: prov.cardName,
            totalFacturasUsd: prov.totalFacturasUsd,
            totalAmortizadoUsd: prov.totalAmortizadoUsd,
            totalAPagarUsd: prov.totalAPagarUsd,
            obs: prov.obs,
            audUsuario: audUsuario,
            codEmpresa: state.empresaSeleccionada!.codEmpresa,
          ),
        );

        console('  Proveedor "${prov.cardCode}" → ID: $idSolicitudProveedor');

        for (final det in prov.detalles) {
          await _repo.registrarDetalleSolicitud(
            DetalleSolicitudEntity(
              idDetalle: BigInt.zero,
              idSolicitudProveedor: idSolicitudProveedor,
              tipoDocumento: det.tipoDocumento,
              numeroDocumento: det.numeroDocumento,
              facturaProvSap: det.facturaProvSap,
              codigoImportacion: det.codigoImportacion,
              montoFacturaUsd: det.montoFacturaUsd,
              montoAmortizadoUsd: det.montoAmortizadoUsd,
              montoAPagarUsd: det.montoAPagarUsd,
              fechaFactura: det.fechaFactura,
              fechaVencimiento: det.fechaVencimiento,
              concepto: det.concepto,
              obs: det.obs,
              esAprobado: 0,
              audUsuario: audUsuario,
              codEmpresa: state.empresaSeleccionada!.codEmpresa,
            ),
          );
        }
        console('   ${prov.detalles.length} detalle(s) registrados');
      }

      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Solicitud registrada exitosamente.',
      );
      return true;
    } catch (e) {
      console(' Error en guardarSolicitud: $e');
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

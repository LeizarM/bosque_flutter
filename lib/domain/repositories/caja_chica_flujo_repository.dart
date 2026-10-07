// Destino final: lib/domain/repositories/caja_chica_flujo_repository.dart
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';

abstract class CajaChicaFlujoRepository {
  Future<List<CajaChicaEntity>> listarDelLote({required int idBitTarea});

  /// Lanza una excepción con el mensaje del servidor (p.ej. "Saldo
  /// insuficiente...") si la validación falla — no hay caso de éxito
  /// silencioso con dato descartado, a diferencia del legacy.
  ///
  /// Manda lo que haya en el formulario, aunque falte algo: monto, descripción,
  /// destinatario y saldo los valida p_abm_tac_CajaChica 'R' (errores 10 a 14),
  /// para poder cambiar esas reglas sin recompilar. Sin [moneda], el servidor
  /// pone 'BS'.
  Future<void> registrarEgreso({
    required int idBitTarea,
    required double montoEg,
    required String descripcion,
    int? codEmpDestino,
    int? numFactura,
    int? numVale,
    String? moneda,
  });

  /// Cierra el lote vigente de la sucursal (del cargo actual del empleado
  /// dueño de esta ocurrencia) y abre el siguiente con su saldo inicial ya
  /// sembrado — reemplaza la mitad "esto reiniciara su caja chica" del
  /// legacy "Generar PDF" (el reporte en sí lo migra un esfuerzo aparte).
  /// No cierra la ocurrencia del día: eso lo hace registrar un egreso.
  Future<void> cerrarLote(int idBitTarea);

  /// "Ver Cajas Chicas" del legacy — histórico de lotes de la sucursal de
  /// esta ocurrencia (lote/desde/hasta/sucursal/total egresos).
  Future<List<Map<String, dynamic>>> obtenerHistorialLotes(int idBitTarea);

  /// Picker "Empleado Destino" — búsqueda real por nombre/cargo (no un id
  /// crudo tipeado a mano, como en el legacy). Devuelve el JSON crudo del
  /// backend (Empleado anidado con persona/cargo) — se resuelve el label
  /// en la UI, no hace falta una entidad propia para una búsqueda liviana.
  Future<List<Map<String, dynamic>>> buscarEmpleados(String texto);

  /// PDF "Caja Chica" (RptCajaChica) — botón "Generar PDF" del legacy, por
  /// fila del histórico. [codSucursal] viene de esa misma fila (ya resuelta
  /// server-side por [obtenerHistorialLotes]), nunca de un valor local.
  Future<Uint8List> generarReportePdf({
    required int lote,
    required int codSucursal,
  });
}

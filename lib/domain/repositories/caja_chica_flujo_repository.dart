// Destino final: lib/domain/repositories/caja_chica_flujo_repository.dart
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_caja_chica_entity.dart';

/// Caja Chica sin ocurrencia (archivo SQL 96): nada viaja para decir de qué
/// sucursal es. El backend la saca del cargo vigente de quien inició sesión.
abstract class CajaChicaFlujoRepository {
  Future<List<CajaChicaEntity>> listarDelLote();

  /// Lanza una excepción con el mensaje del servidor (p.ej. "Saldo
  /// insuficiente...") si la validación falla — no hay caso de éxito
  /// silencioso con dato descartado, a diferencia del legacy.
  ///
  /// Manda lo que haya en el formulario, aunque falte algo: monto, descripción,
  /// destinatario y saldo los valida p_abm_tac_CajaChica 'R' (errores 10 a 14),
  /// para poder cambiar esas reglas sin recompilar. Sin [moneda], el servidor
  /// pone 'BS'.
  Future<void> registrarEgreso({
    required double montoEg,
    required String descripcion,
    int? codEmpDestino,
    int? numFactura,
    int? numVale,
    String? moneda,
  });

  /// Cierra el lote vigente de la sucursal y abre el siguiente con su saldo
  /// inicial ya sembrado — reemplaza la mitad "esto reiniciara su caja chica"
  /// del legacy "Generar PDF".
  Future<void> cerrarLote();

  /// "Ver Cajas Chicas" del legacy — histórico de lotes de la sucursal
  /// (lote/desde/hasta/sucursal/total egresos).
  Future<List<Map<String, dynamic>>> obtenerHistorialLotes();

  /// Talonarios de vales de caja chica entregados a la sucursal (o a la
  /// persona), con el vale que sigue. Vacío = la sucursal no tiene talonario.
  /// Qué vale vale lo decide el SP al registrar.
  Future<List<TalonarioCajaChica>> talonarios();

  /// Las reglas del número de recibo en palabras (archivo SQL 99); null si el
  /// servidor no las devolvió.
  Future<ReglasReciboCajaChica?> reglasRecibo();

  /// Picker "Empleado Destino" — búsqueda real por nombre/cargo (no un id
  /// crudo tipeado a mano, como en el legacy). Devuelve el JSON crudo del
  /// backend (Empleado anidado con persona/cargo) — se resuelve el label
  /// en la UI, no hace falta una entidad propia para una búsqueda liviana.
  Future<List<Map<String, dynamic>>> buscarEmpleados(String texto);

  /// PDF "Caja Chica" (RptCajaChica) — botón "Generar PDF" del legacy, por
  /// fila del histórico. El backend rechaza un lote de otra sucursal.
  Future<Uint8List> generarReportePdf({required int lote});
}

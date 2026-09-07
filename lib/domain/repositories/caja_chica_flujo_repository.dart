// Destino final: lib/domain/repositories/caja_chica_flujo_repository.dart
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';

abstract class CajaChicaFlujoRepository {
  Future<List<CajaChicaEntity>> listarDelLote({required int idBitTarea});

  /// Lanza una excepción con el mensaje del servidor (p.ej. "Saldo
  /// insuficiente...") si la validación falla — no hay caso de éxito
  /// silencioso con dato descartado, a diferencia del legacy.
  Future<void> registrarEgreso({
    required int idBitTarea,
    required double montoEg,
    required String descripcion,
    required int codEmpDestino,
    int? numFactura,
    int? numVale,
    String moneda = 'BS',
  });

  Future<void> finalizar(int idBitTarea);

  /// "Ver Cajas Chicas" del legacy — histórico de lotes de la sucursal de
  /// esta ocurrencia (lote/desde/hasta/sucursal/total egresos).
  Future<List<Map<String, dynamic>>> obtenerHistorialLotes(int idBitTarea);

  /// Picker "Empleado Destino" — búsqueda real por nombre/cargo (no un id
  /// crudo tipeado a mano, como en el legacy). Devuelve el JSON crudo del
  /// backend (Empleado anidado con persona/cargo) — se resuelve el label
  /// en la UI, no hace falta una entidad propia para una búsqueda liviana.
  Future<List<Map<String, dynamic>>> buscarEmpleados(String texto);
}

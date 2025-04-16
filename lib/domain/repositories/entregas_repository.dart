import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

abstract class EntregasRepository {
  
  Future<List<EntregaEntity>> getEntregas(int uchofer);
  
  // Método para sincronizar entregas completadas con el servidor
  Future<bool> sincronizarEntregasCompletadas(List<EntregaEntity> entregas);

  Future<void> registrarInicioEntrega(EntregaEntity entrega);
  
  // Método para marcar como entregado todo un documento (grupo de entregas)
  Future<bool> marcarDocumentoEntregado(int docNum, {
    required int docEntry,
    required String db,
    required double latitud,
    required double longitud,
    required String direccionEntrega,
    required DateTime fechaEntrega,
    required int audUsuario,
    required int codSucursalChofer,
    required int codCiudadChofer,
    String? observaciones,
  });
}
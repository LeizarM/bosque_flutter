// Destino final: lib/domain/repositories/traspaso_mov_caja_repository.dart
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

abstract class TraspasoMovCajaRepository {
  Future<List<TraspasoMovCajaEntity>> obtener();
  Future<BigInt> registrar(TraspasoMovCajaEntity item);
  Future<void> eliminar(int idTrasp, int audUsuario);

  // ===== Tarea 289 "Verificar Traspaso de Efectivo Entre Sistemas" =====

  /// Los traspasos de un dia, con su estado de verificacion.
  ///
  /// No es un listado de la tabla: el servidor le pregunta a SAP y cruza
  /// contra lo ya verificado. Puede tardar, y si el enlace con SAP no
  /// responde lanza en vez de devolver vacio: una lista vacia se leeria
  /// como "no hubo traspasos", que sobre dinero es una afirmacion falsa.
  Future<List<TraspasoMovCajaEntity>> obtenerDelDia(DateTime fecha);

  /// Marca una fila como que cuadra o como que no.
  ///
  /// [obs] es obligatoria cuando [cuadra] es false; lo valida el servidor.
  Future<void> verificar({
    required int idBitTarRuti,
    required TraspasoMovCajaEntity fila,
    required bool cuadra,
    String? obs,
  });

  /// Cierra el dia como "sin novedad".
  ///
  /// El servidor vuelve a preguntarle a SAP y rechaza si hay traspasos en
  /// esa fecha, asi que esto no puede usarse para saltearse el trabajo.
  Future<void> sinNovedad({required int idBitTarRuti, required DateTime fecha});
}

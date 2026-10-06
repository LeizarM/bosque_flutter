import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';

/// Bancos (tch_banco, vista 43). Espeja las dos ultimas filas de API_CHEQUES.md
/// y la lectura `/banco/bancosX`.
///
/// La lectura de otros modulos sigue donde estaba: `getBancos()` y
/// `getBancosPlanilla()` de `RegistroEmpleadoRepository` devuelven una lista
/// pelada y **tragan los errores** (un fallo se ve como lista vacia). Por eso
/// esta pantalla lee con [listar], que si los propaga.
///
/// Un 400 llega como el mensaje del backend. El usuario de auditoria sale del
/// token. Tocar un banco afecta a Depositos y a Pagos al Exterior, que lo
/// referencian por FK.
abstract class BancosRepository {
  /// Todos los bancos, en el orden alfabetico que da el servidor. Un 204 es
  /// lista vacia; cualquier fallo se lanza.
  Future<List<BancoEntity>> listar();

  /// Alta ([BancoRegistroEntity.codBanco] 0; btnNuevoB) o edicion
  /// (btnEditarB). Devuelve el codBanco.
  Future<BigInt> registrar(BancoRegistroEntity registro);

  /// Baja (btnEliminarB). El backend responde 400 si el banco tiene filas en
  /// Depositos o en Pagos al Exterior (error 547). Devuelve el codBanco.
  Future<BigInt> eliminar(int codBanco);
}

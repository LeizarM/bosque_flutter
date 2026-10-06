import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pagina_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';

/// «Verificar Cheques» (tabla `tch_verificacionDeposito`, vista 77). Espeja la
/// seccion «Verificar Cheques» de `API_CHEQUES.md`: un metodo por endpoint.
///
/// No hay permisos por boton: la vista no los tiene y el servidor exige solo el
/// rol. Un 400 llega como el mensaje del backend, completo y tal cual (varios
/// errores van separados por salto de linea). El usuario de auditoria sale del
/// token.
abstract class VerificacionesRepository {
  /// Las verificaciones del dia de [filtro] (o todas), una pagina. Un 204 es una
  /// pagina vacia.
  Future<PaginaVerificacionEntity<VerificacionFilaEntity>> listar(
    VerificacionFiltroEntity filtro,
  );

  /// Los cheques que todavia no tienen una verificacion valida, una pagina: el
  /// modal «Cheques pendientes sin regularizar».
  Future<PaginaVerificacionEntity<ChequePendienteVerificacionEntity>>
  listarPendientes(PendientesVerificacionFiltroEntity filtro);

  /// El cheque elegido tal como esta ahora y la fecha que se propone. El
  /// servidor responde 400 si ya tiene una verificacion valida, esta cerrado o
  /// no existe.
  Future<VerificacionPreparadaEntity> preparar(BigInt codCheque);

  /// Alta ([VerificacionRegistroEntity.codvd] 0) o edicion. Devuelve el `codvd`.
  Future<BigInt> registrar(VerificacionRegistroEntity registro);

  /// «Cancelar» del legacy: pasa la verificacion a Anulada (no se borra).
  /// Devuelve el mensaje del servidor, que distingue «Verificacion anulada» de
  /// «ya estaba anulada».
  Future<String> anular(BigInt codvd);

  /// Los estados de cheque (`PEN` / `CER`) para el filtro del modal. Salen de
  /// `/cheque/catalogos`, el mismo catalogo que usa la pantalla de Cheques.
  Future<List<OpcionChequeEntity>> obtenerEstadosCheque();
}

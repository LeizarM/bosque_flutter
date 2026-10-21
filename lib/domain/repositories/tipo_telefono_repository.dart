import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';

/// Mantenimiento de tipos de teléfono (trh_tipoTelefono, vista 28).
abstract class TipoTelefonoRepository {
  /// Todos los tipos, con cuántos teléfonos usa cada uno.
  Future<List<TipoTelefonoEntity>> listar();

  /// Alta si `codTipoTel` es 0, edición si es mayor.
  Future<ResultadoEscrituraEntity> registrar(TipoTelefonoEntity tipo);

  Future<ResultadoEscrituraEntity> eliminar(int codTipoTel);
}

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/catalogos_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_pendiente_verificacion_model.dart';
import 'package:bosque_flutter/data/models/pagina_verificacion_model.dart';
import 'package:bosque_flutter/data/models/pendientes_verificacion_filtro_model.dart';
import 'package:bosque_flutter/data/models/verificacion_fila_model.dart';
import 'package:bosque_flutter/data/models/verificacion_filtro_model.dart';
import 'package:bosque_flutter/data/models/verificacion_preparada_model.dart';
import 'package:bosque_flutter/data/models/verificacion_registro_model.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pagina_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';
import 'package:bosque_flutter/domain/repositories/verificaciones_repository.dart';

/// «Verificar Cheques» contra el backend Spring (`/cheque/verificacion/**`).
///
/// Los helpers de [BaseApiRepository] resuelven el envelope, el 204 y el 400: el
/// `message` de un 400 es texto de negocio y llega tal cual a quien llame.
class VerificacionesImpl extends BaseApiRepository
    implements VerificacionesRepository {
  @override
  Future<PaginaVerificacionEntity<VerificacionFilaEntity>> listar(
    VerificacionFiltroEntity filtro,
  ) async {
    final modelo = await postAndReturnObject<
      PaginaVerificacionModel<VerificacionFilaModel, VerificacionFilaEntity>
    >(
      endpoint: AppConstants.chqVerificacionListar,
      data: VerificacionFiltroModel.fromEntity(filtro).toJson(),
      fromJson:
          (json) => PaginaVerificacionModel.fromJson(
            json,
            fila: VerificacionFilaModel.fromJson,
          ),
      errorMessage: 'No se pudieron cargar las verificaciones.',
    );
    return modelo?.toEntity((f) => f.toEntity()) ??
        PaginaVerificacionEntity<VerificacionFilaEntity>.vacia(
          pagina: filtro.pagina,
          tamanio: filtro.tamanio,
        );
  }

  @override
  Future<PaginaVerificacionEntity<ChequePendienteVerificacionEntity>>
  listarPendientes(PendientesVerificacionFiltroEntity filtro) async {
    final modelo = await postAndReturnObject<
      PaginaVerificacionModel<
        ChequePendienteVerificacionModel,
        ChequePendienteVerificacionEntity
      >
    >(
      endpoint: AppConstants.chqVerificacionPendientes,
      data: PendientesVerificacionFiltroModel.fromEntity(filtro).toJson(),
      fromJson:
          (json) => PaginaVerificacionModel.fromJson(
            json,
            fila: ChequePendienteVerificacionModel.fromJson,
          ),
      errorMessage: 'No se pudieron cargar los cheques pendientes.',
    );
    return modelo?.toEntity((f) => f.toEntity()) ??
        PaginaVerificacionEntity<ChequePendienteVerificacionEntity>.vacia(
          pagina: filtro.pagina,
          tamanio: filtro.tamanio,
        );
  }

  @override
  Future<VerificacionPreparadaEntity> preparar(BigInt codCheque) async {
    final modelo = await postAndReturnObject<VerificacionPreparadaModel>(
      endpoint: AppConstants.chqVerificacionPreparar,
      data: {'id': codCheque.toInt()},
      fromJson: VerificacionPreparadaModel.fromJson,
      errorMessage: 'No se pudo preparar la verificación del cheque.',
    );
    // Sin cuerpo no hay con que armar el formulario: es un fallo, no un vacio.
    if (modelo == null) {
      throw Exception('El servidor no devolvió los datos del cheque.');
    }
    return modelo.toEntity();
  }

  @override
  Future<BigInt> registrar(VerificacionRegistroEntity registro) =>
      postAndReturnId(
        endpoint: AppConstants.chqVerificacionRegistrar,
        data: VerificacionRegistroModel.fromEntity(registro).toJson(),
        errorMessage: 'No se pudo guardar la verificación.',
      );

  @override
  Future<String> anular(BigInt codvd) => postAndReturnFullResponse<String>(
    endpoint: AppConstants.chqVerificacionAnular,
    data: {'id': codvd.toInt()},
    // La raiz del envelope: el message dice si ya estaba anulada.
    fromJson: (raiz) => (raiz['message'] ?? 'Verificación anulada.').toString(),
    errorMessage: 'No se pudo anular la verificación.',
  );

  @override
  Future<List<OpcionChequeEntity>> obtenerEstadosCheque() async {
    final modelo = await postAndReturnObject<CatalogosChequeModel>(
      endpoint: AppConstants.chqCatalogos,
      data: const {},
      fromJson: CatalogosChequeModel.fromJson,
      errorMessage: 'No se pudieron cargar los estados de cheque.',
    );
    return modelo?.toEntity().estadosCheque ?? const [];
  }
}

// Destino final: lib/data/repositories/documentacion_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/documentacion_model.dart';
import 'package:bosque_flutter/domain/entities/documentacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/documentacion_repository.dart';

class DocumentacionImpl extends BaseApiRepository
    implements DocumentacionRepository {
  @override
  Future<List<DocumentacionEntity>> obtener() async {
    final modelos = await postAndReturnList<DocumentacionModel>(
      endpoint: AppConstants.tarObtenerDocumentacion,
      fromJson: (json) => DocumentacionModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(DocumentacionEntity item) async {
    final model = DocumentacionModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarDocumentacion,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la documentación.',
    );
  }

  @override
  Future<void> eliminar(int idDoc, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarDocumentacion,
      data: {'idDoc': idDoc, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la documentación.',
    );
  }
}
